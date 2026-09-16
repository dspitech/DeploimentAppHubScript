#cloud-config

# ==============================================================================================
# PLG - 2026 / Groupe 24 : ESTIAM - Paris
# cloud-init.yaml — Noeud de supervision (Prometheus + Grafana, provisionnés automatiquement)
# Généré depuis un template Terraform (templatefile) — modifier cloud-init/monitoring-node.yaml.tpl
# ===============================================================================================

package_update: true
package_upgrade: true

packages:
  - git
  - curl
  - wget
  - unzip
  - vim
  - htop
  - ufw
  - fail2ban
  - apt-transport-https
  - ca-certificates
  - gnupg
  - lsb-release

write_files:
  - path: /opt/monitoring/docker-compose.yml
    owner: root:root
    permissions: '0644'
    content: |
      version: "3.8"

      networks:
        monitoring:
          driver: bridge

      volumes:
        prometheus_data: {}
        grafana_data: {}

      services:
        prometheus:
          image: prom/prometheus:v2.53.0
          container_name: prometheus
          restart: unless-stopped
          networks: [monitoring]
          volumes:
            - /opt/monitoring/prometheus/prometheus.yml:/etc/prometheus/prometheus.yml:ro
            - prometheus_data:/prometheus
          command:
            - "--config.file=/etc/prometheus/prometheus.yml"
            - "--storage.tsdb.retention.time=15d"
          ports:
            - "9090:9090"

        grafana:
          image: grafana/grafana-oss:11.1.0
          container_name: grafana
          restart: unless-stopped
          networks: [monitoring]
          depends_on:
            - prometheus
          environment:
            - GF_SECURITY_ADMIN_USER=${grafana_admin_user}
            - GF_SECURITY_ADMIN_PASSWORD=${grafana_admin_password}
            - GF_USERS_ALLOW_SIGN_UP=false
          volumes:
            - grafana_data:/var/lib/grafana
            - /opt/monitoring/grafana/provisioning:/etc/grafana/provisioning:ro
            - /opt/monitoring/grafana/dashboards:/var/lib/grafana/dashboards:ro
          ports:
            - "3000:3000"

  - path: /opt/monitoring/prometheus/prometheus.yml
    owner: root:root
    permissions: '0644'
    content: |
      global:
        scrape_interval: 15s
        evaluation_interval: 15s

      scrape_configs:
        - job_name: "prometheus"
          static_configs:
            - targets: ["localhost:9090"]

        - job_name: "node_exporter"
          static_configs:
            - targets:
                - "${vm1_ip}:9100"
                - "${vm2_ip}:9100"
              labels:
                environment: "production"

  - path: /opt/monitoring/grafana/provisioning/datasources/datasource.yml
    owner: root:root
    permissions: '0644'
    content: |
      apiVersion: 1
      datasources:
        - name: Prometheus
          type: prometheus
          uid: prometheus
          access: proxy
          url: http://prometheus:9090
          isDefault: true
          editable: false

        # Base de données du site (Supabase PostgreSQL).
        # Utiliser idéalement un rôle en lecture seule dédié (grafana_reader),
        # voir README section "Grafana <-> base de données du site".
        - name: Supabase PostgreSQL
          type: postgres
          uid: supabase-postgres
          access: proxy
          url: "${supabase_db_host}:${supabase_db_port}"
          database: "${supabase_db_name}"
          user: "${supabase_db_user}"
          editable: false
          jsonData:
            sslmode: require
            postgresVersion: 1500
            timescaledb: false
            maxOpenConns: 5
            maxIdleConns: 2
            connMaxLifetime: 14400
          secureJsonData:
            password: "${supabase_db_password}"

  - path: /opt/monitoring/grafana/provisioning/dashboards/dashboards.yml
    owner: root:root
    permissions: '0644'
    content: |
      apiVersion: 1
      providers:
        - name: "PLG AppHub - Groupe 24"
          orgId: 1
          folder: "PLG AppHub - Groupe 24"
          type: file
          disableDeletion: false
          updateIntervalSeconds: 30
          allowUiUpdates: true
          options:
            path: /var/lib/grafana/dashboards

  # ----------------------------------------------------------
  # Alertes Grafana (unified alerting) -provisionnées par fichier,
  # sans étape manuelle. Voir README section 12.3.
  # ----------------------------------------------------------
  - path: /opt/monitoring/grafana/provisioning/alerting/contact-points.yaml
    owner: root:root
    permissions: '0644'
    content: |
      apiVersion: 1
      contactPoints:
        - orgId: 1
          name: apphub-webhook
          receivers:
            - uid: apphub-webhook-1
              type: webhook
              settings:
                url: "${grafana_alert_webhook_url}"
                httpMethod: POST

  - path: /opt/monitoring/grafana/provisioning/alerting/notification-policies.yaml
    owner: root:root
    permissions: '0644'
    content: |
      apiVersion: 1
      policies:
        - orgId: 1
          receiver: apphub-webhook
          group_by: ['alertname']
          group_wait: 30s
          group_interval: 5m
          repeat_interval: 3h

  - path: /opt/monitoring/grafana/provisioning/alerting/rules.yaml
    owner: root:root
    permissions: '0644'
    content: |
      apiVersion: 1
      groups:
        - orgId: 1
          name: apphub-business-alerts
          folder: "PLG AppHub - Groupe 24"
          interval: 5m
          rules:
            - uid: apphub-contact-spike
              title: "Pic de messages de contact (>20 / 1h)"
              condition: C
              for: 5m
              noDataState: OK
              execErrState: Error
              labels:
                severity: warning
                source: apphub-business
              annotations:
                summary: "Plus de 20 messages de contact recus dans la derniere heure -verifier un eventuel abus (spam/formulaire)."
              data:
                - refId: A
                  relativeTimeRange: { from: 3600, to: 0 }
                  datasourceUid: supabase-postgres
                  model:
                    refId: A
                    format: table
                    rawSql: "SELECT count(*) AS value FROM public.contact_messages WHERE created_at > now() - interval '1 hour'"
                - refId: C
                  datasourceUid: "-100"
                  model:
                    refId: C
                    type: threshold
                    expression: A
                    conditions:
                      - evaluator: { type: gt, params: [20] }

            - uid: apphub-trash-spike
              title: "Suppression massive detectee (>10 elements / 1h)"
              condition: C
              for: 5m
              noDataState: OK
              execErrState: Error
              labels:
                severity: critical
                source: apphub-business
              annotations:
                summary: "Plus de 10 elements (scripts/ressources/categories) envoyes a la corbeille en une heure -verifier qu'il ne s'agit pas d'une suppression accidentelle ou malveillante."
              data:
                - refId: A
                  relativeTimeRange: { from: 3600, to: 0 }
                  datasourceUid: supabase-postgres
                  model:
                    refId: A
                    format: table
                    rawSql: "SELECT count(*) AS value FROM public.trash_items WHERE created_at > now() - interval '1 hour'"
                - refId: C
                  datasourceUid: "-100"
                  model:
                    refId: C
                    type: threshold
                    expression: A
                    conditions:
                      - evaluator: { type: gt, params: [10] }

            - uid: apphub-audit-spike
              title: "Pic d'activite d'audit (>150 evenements / 15 min)"
              condition: C
              for: 5m
              noDataState: OK
              execErrState: Error
              labels:
                severity: warning
                source: apphub-security
              annotations:
                summary: "Plus de 150 evenements d'audit en 15 minutes -volume inhabituel, potentiellement un abus ou un script en boucle."
              data:
                - refId: A
                  relativeTimeRange: { from: 900, to: 0 }
                  datasourceUid: supabase-postgres
                  model:
                    refId: A
                    format: table
                    rawSql: "SELECT count(*) AS value FROM public.audit_logs WHERE created_at > now() - interval '15 minutes'"
                - refId: C
                  datasourceUid: "-100"
                  model:
                    refId: C
                    type: threshold
                    expression: A
                    conditions:
                      - evaluator: { type: gt, params: [150] }

  - path: /opt/monitoring/grafana/dashboards/hub-spoke-overview.json
    owner: root:root
    permissions: '0644'
    content: |
      {
        "title": "Hub & Spoke - Vue d'ensemble infrastructure",
        "uid": "hubspoke-overview",
        "schemaVersion": 39,
        "version": 1,
        "refresh": "30s",
        "time": { "from": "now-6h", "to": "now" },
        "tags": ["hub-spoke", "azure", "node-exporter"],
        "panels": [
          {
            "id": 1,
            "type": "timeseries",
            "title": "Utilisation CPU (%) par instance",
            "gridPos": { "h": 8, "w": 12, "x": 0, "y": 0 },
            "targets": [
              {
                "expr": "100 - (avg by (instance) (rate(node_cpu_seconds_total{mode=\"idle\"}[5m])) * 100)",
                "legendFormat": "{{instance}}"
              }
            ],
            "fieldConfig": { "defaults": { "unit": "percent", "min": 0, "max": 100 }, "overrides": [] }
          },
          {
            "id": 2,
            "type": "timeseries",
            "title": "Mémoire utilisée (%) par instance",
            "gridPos": { "h": 8, "w": 12, "x": 12, "y": 0 },
            "targets": [
              {
                "expr": "100 * (1 - ((node_memory_MemAvailable_bytes) / (node_memory_MemTotal_bytes)))",
                "legendFormat": "{{instance}}"
              }
            ],
            "fieldConfig": { "defaults": { "unit": "percent", "min": 0, "max": 100 }, "overrides": [] }
          },
          {
            "id": 3,
            "type": "timeseries",
            "title": "Espace disque utilisé (%) par instance",
            "gridPos": { "h": 8, "w": 12, "x": 0, "y": 8 },
            "targets": [
              {
                "expr": "100 - ((node_filesystem_avail_bytes{fstype!~\"tmpfs|overlay\"} * 100) / node_filesystem_size_bytes{fstype!~\"tmpfs|overlay\"})",
                "legendFormat": "{{instance}} {{mountpoint}}"
              }
            ],
            "fieldConfig": { "defaults": { "unit": "percent", "min": 0, "max": 100 }, "overrides": [] }
          },
          {
            "id": 4,
            "type": "timeseries",
            "title": "Trafic réseau (octets/s) par instance",
            "gridPos": { "h": 8, "w": 12, "x": 12, "y": 8 },
            "targets": [
              {
                "expr": "rate(node_network_receive_bytes_total{device!~\"lo\"}[5m])",
                "legendFormat": "{{instance}} rx {{device}}"
              },
              {
                "expr": "rate(node_network_transmit_bytes_total{device!~\"lo\"}[5m])",
                "legendFormat": "{{instance}} tx {{device}}"
              }
            ],
            "fieldConfig": { "defaults": { "unit": "Bps" }, "overrides": [] }
          },
          {
            "id": 5,
            "type": "stat",
            "title": "Instances UP",
            "gridPos": { "h": 6, "w": 8, "x": 0, "y": 16 },
            "targets": [
              { "expr": "count(up{job=\"node_exporter\"} == 1)" }
            ]
          },
          {
            "id": 6,
            "type": "stat",
            "title": "Uptime moyen (heures)",
            "gridPos": { "h": 6, "w": 8, "x": 8, "y": 16 },
            "targets": [
              { "expr": "avg(node_time_seconds - node_boot_time_seconds) / 3600" }
            ],
            "fieldConfig": { "defaults": { "unit": "h" }, "overrides": [] }
          },
          {
            "id": 7,
            "type": "stat",
            "title": "Load average (1m)",
            "gridPos": { "h": 6, "w": 8, "x": 16, "y": 16 },
            "targets": [
              { "expr": "avg(node_load1)" }
            ]
          }
        ]
      }

  - path: /opt/monitoring/grafana/dashboards/apphub-business-overview.json
    owner: root:root
    permissions: '0644'
    content: |
      {
        "title": "AppHub - Vue d'ensemble métier (base de données du site)",
        "uid": "apphub-business-overview",
        "schemaVersion": 39,
        "version": 1,
        "refresh": "5m",
        "time": { "from": "now-30d", "to": "now" },
        "tags": ["apphub", "supabase", "postgres", "business"],
        "panels": [
          { "id": 1, "type": "row", "title": "Indicateurs cles", "gridPos": { "h": 1, "w": 24, "x": 0, "y": 0 } },
          {
            "id": 2, "type": "stat", "title": "Scripts actifs",
            "gridPos": { "h": 4, "w": 6, "x": 0, "y": 1 },
            "datasource": { "type": "postgres", "uid": "supabase-postgres" },
            "targets": [ { "format": "table", "rawSql": "SELECT count(*) FROM public.scripts WHERE status = 'active'" } ],
            "fieldConfig": { "defaults": { "color": { "mode": "thresholds" } }, "overrides": [] }
          },
          {
            "id": 3, "type": "stat", "title": "Utilisateurs inscrits",
            "gridPos": { "h": 4, "w": 6, "x": 6, "y": 1 },
            "datasource": { "type": "postgres", "uid": "supabase-postgres" },
            "targets": [ { "format": "table", "rawSql": "SELECT count(*) FROM public.profiles" } ]
          },
          {
            "id": 4, "type": "stat", "title": "Invites (guest_users)",
            "gridPos": { "h": 4, "w": 6, "x": 12, "y": 1 },
            "datasource": { "type": "postgres", "uid": "supabase-postgres" },
            "targets": [ { "format": "table", "rawSql": "SELECT count(*) FROM public.guest_users" } ]
          },
          {
            "id": 5, "type": "stat", "title": "Messages de contact (7j)",
            "gridPos": { "h": 4, "w": 6, "x": 18, "y": 1 },
            "datasource": { "type": "postgres", "uid": "supabase-postgres" },
            "targets": [ { "format": "table", "rawSql": "SELECT count(*) FROM public.contact_messages WHERE created_at > now() - interval '7 days'" } ],
            "fieldConfig": { "defaults": { "thresholds": { "mode": "absolute", "steps": [ { "color": "green", "value": null }, { "color": "orange", "value": 10 } ] } }, "overrides": [] }
          },

          { "id": 6, "type": "row", "title": "Contenu - Scripts", "gridPos": { "h": 1, "w": 24, "x": 0, "y": 5 } },
          {
            "id": 7, "type": "piechart", "title": "Scripts par statut",
            "gridPos": { "h": 8, "w": 8, "x": 0, "y": 6 },
            "datasource": { "type": "postgres", "uid": "supabase-postgres" },
            "targets": [ { "format": "table", "rawSql": "SELECT status::text AS \"Statut\", count(*) AS \"Nombre\" FROM public.scripts GROUP BY status ORDER BY 2 DESC" } ]
          },
          {
            "id": 8, "type": "barchart", "title": "Scripts par categorie",
            "gridPos": { "h": 8, "w": 8, "x": 8, "y": 6 },
            "datasource": { "type": "postgres", "uid": "supabase-postgres" },
            "targets": [ { "format": "table", "rawSql": "SELECT COALESCE(c.name,'Sans categorie') AS \"Categorie\", count(s.id) AS \"Scripts\" FROM public.scripts s LEFT JOIN public.categories c ON c.id = s.category_id GROUP BY c.name ORDER BY 2 DESC LIMIT 10" } ]
          },
          {
            "id": 9, "type": "timeseries", "title": "Nouveaux scripts par jour",
            "gridPos": { "h": 8, "w": 8, "x": 16, "y": 6 },
            "datasource": { "type": "postgres", "uid": "supabase-postgres" },
            "targets": [ { "format": "time_series", "rawSql": "SELECT $__timeGroup(created_at,'1d') AS time, count(*) AS \"Nouveaux scripts\" FROM public.scripts WHERE $__timeFilter(created_at) GROUP BY 1 ORDER BY 1" } ]
          },
          {
            "id": 10, "type": "table", "title": "Top 10 scripts les plus consultes",
            "gridPos": { "h": 8, "w": 12, "x": 0, "y": 14 },
            "datasource": { "type": "postgres", "uid": "supabase-postgres" },
            "targets": [ { "format": "table", "rawSql": "SELECT name AS \"Script\", views_count AS \"Vues\", downloads_count AS \"Telechargements\", favorites_count AS \"Favoris\", status::text AS \"Statut\" FROM public.scripts ORDER BY views_count DESC LIMIT 10" } ]
          },
          {
            "id": 11, "type": "piechart", "title": "Repartition par criticite",
            "gridPos": { "h": 8, "w": 12, "x": 12, "y": 14 },
            "datasource": { "type": "postgres", "uid": "supabase-postgres" },
            "targets": [ { "format": "table", "rawSql": "SELECT criticality::text AS \"Criticite\", count(*) AS \"Nombre\" FROM public.scripts GROUP BY criticality ORDER BY 2 DESC" } ]
          },

          { "id": 12, "type": "row", "title": "Utilisateurs et invites", "gridPos": { "h": 1, "w": 24, "x": 0, "y": 22 } },
          {
            "id": 13, "type": "timeseries", "title": "Nouveaux utilisateurs par jour",
            "gridPos": { "h": 8, "w": 12, "x": 0, "y": 23 },
            "datasource": { "type": "postgres", "uid": "supabase-postgres" },
            "targets": [ { "format": "time_series", "rawSql": "SELECT $__timeGroup(created_at,'1d') AS time, count(*) AS \"Nouveaux comptes\" FROM public.profiles WHERE $__timeFilter(created_at) GROUP BY 1 ORDER BY 1" } ]
          },
          {
            "id": 14, "type": "timeseries", "title": "Nouveaux invites par jour",
            "gridPos": { "h": 8, "w": 12, "x": 12, "y": 23 },
            "datasource": { "type": "postgres", "uid": "supabase-postgres" },
            "targets": [ { "format": "time_series", "rawSql": "SELECT $__timeGroup(created_at,'1d') AS time, count(*) AS \"Nouveaux invites\" FROM public.guest_users WHERE $__timeFilter(created_at) GROUP BY 1 ORDER BY 1" } ]
          },

          { "id": 15, "type": "row", "title": "Contact et securite", "gridPos": { "h": 1, "w": 24, "x": 0, "y": 31 } },
          {
            "id": 16, "type": "barchart", "title": "Messages de contact par categorie",
            "gridPos": { "h": 8, "w": 8, "x": 0, "y": 32 },
            "datasource": { "type": "postgres", "uid": "supabase-postgres" },
            "targets": [ { "format": "table", "rawSql": "SELECT category AS \"Categorie\", count(*) AS \"Messages\" FROM public.contact_messages GROUP BY category ORDER BY 2 DESC" } ]
          },
          {
            "id": 17, "type": "piechart", "title": "Messages de contact par statut",
            "gridPos": { "h": 8, "w": 8, "x": 8, "y": 32 },
            "datasource": { "type": "postgres", "uid": "supabase-postgres" },
            "targets": [ { "format": "table", "rawSql": "SELECT status AS \"Statut\", count(*) AS \"Nombre\" FROM public.contact_messages GROUP BY status ORDER BY 2 DESC" } ]
          },
          {
            "id": 18, "type": "timeseries", "title": "Activite d'audit (evenements/heure)",
            "gridPos": { "h": 8, "w": 8, "x": 16, "y": 32 },
            "datasource": { "type": "postgres", "uid": "supabase-postgres" },
            "targets": [ { "format": "time_series", "rawSql": "SELECT $__timeGroup(created_at,'1h') AS time, count(*) AS \"Evenements\" FROM public.audit_logs WHERE $__timeFilter(created_at) GROUP BY 1 ORDER BY 1" } ]
          },
          {
            "id": 19, "type": "table", "title": "Derniers messages de contact recus",
            "gridPos": { "h": 8, "w": 12, "x": 0, "y": 40 },
            "datasource": { "type": "postgres", "uid": "supabase-postgres" },
            "targets": [ { "format": "table", "rawSql": "SELECT created_at AS \"Recu le\", name AS \"Nom\", email AS \"Email\", subject AS \"Sujet\", status AS \"Statut\" FROM public.contact_messages ORDER BY created_at DESC LIMIT 10" } ]
          },
          {
            "id": 20, "type": "table", "title": "Top actions d'audit (periode selectionnee)",
            "gridPos": { "h": 8, "w": 12, "x": 12, "y": 40 },
            "datasource": { "type": "postgres", "uid": "supabase-postgres" },
            "targets": [ { "format": "table", "rawSql": "SELECT action AS \"Action\", resource AS \"Ressource\", count(*) AS \"Occurrences\" FROM public.audit_logs WHERE $__timeFilter(created_at) GROUP BY action, resource ORDER BY 3 DESC LIMIT 10" } ]
          },
          {
            "id": 21, "type": "table", "title": "Top 10 scripts - likes et partages",
            "gridPos": { "h": 8, "w": 24, "x": 0, "y": 48 },
            "datasource": { "type": "postgres", "uid": "supabase-postgres" },
            "targets": [ { "format": "table", "rawSql": "SELECT s.name AS \"Script\", count(DISTINCT sl.id) AS \"Likes\", count(DISTINCT ss.id) AS \"Partages\" FROM public.scripts s LEFT JOIN public.script_likes sl ON sl.script_id = s.id LEFT JOIN public.script_shares ss ON ss.script_id = s.id GROUP BY s.name ORDER BY 2 DESC LIMIT 10" } ]
          },

          { "id": 22, "type": "row", "title": "Ressources documentaires", "gridPos": { "h": 1, "w": 24, "x": 0, "y": 56 } },
          {
            "id": 23, "type": "piechart", "title": "Ressources par type",
            "gridPos": { "h": 8, "w": 8, "x": 0, "y": 57 },
            "datasource": { "type": "postgres", "uid": "supabase-postgres" },
            "targets": [ { "format": "table", "rawSql": "SELECT resource_type::text AS \"Type\", count(*) AS \"Nombre\" FROM public.resources GROUP BY resource_type ORDER BY 2 DESC" } ]
          },
          {
            "id": 24, "type": "piechart", "title": "Ressources par statut",
            "gridPos": { "h": 8, "w": 8, "x": 8, "y": 57 },
            "datasource": { "type": "postgres", "uid": "supabase-postgres" },
            "targets": [ { "format": "table", "rawSql": "SELECT status::text AS \"Statut\", count(*) AS \"Nombre\" FROM public.resources GROUP BY status ORDER BY 2 DESC" } ]
          },
          {
            "id": 25, "type": "table", "title": "Top 10 ressources les plus telechargees",
            "gridPos": { "h": 8, "w": 8, "x": 16, "y": 57 },
            "datasource": { "type": "postgres", "uid": "supabase-postgres" },
            "targets": [ { "format": "table", "rawSql": "SELECT name AS \"Ressource\", resource_type::text AS \"Type\", downloads_count AS \"Telechargements\", views_count AS \"Vues\" FROM public.resources ORDER BY downloads_count DESC LIMIT 10" } ]
          },

          { "id": 26, "type": "row", "title": "Corbeille (suppressions)", "gridPos": { "h": 1, "w": 24, "x": 0, "y": 65 } },
          {
            "id": 27, "type": "timeseries", "title": "Suppressions par jour",
            "gridPos": { "h": 8, "w": 12, "x": 0, "y": 66 },
            "datasource": { "type": "postgres", "uid": "supabase-postgres" },
            "targets": [ { "format": "time_series", "rawSql": "SELECT $__timeGroup(created_at,'1d') AS time, count(*) AS \"Suppressions\" FROM public.trash_items WHERE $__timeFilter(created_at) GROUP BY 1 ORDER BY 1" } ]
          },
          {
            "id": 28, "type": "barchart", "title": "Suppressions par type d'element",
            "gridPos": { "h": 8, "w": 12, "x": 12, "y": 66 },
            "datasource": { "type": "postgres", "uid": "supabase-postgres" },
            "targets": [ { "format": "table", "rawSql": "SELECT resource_type AS \"Type\", count(*) AS \"Suppressions\" FROM public.trash_items GROUP BY resource_type ORDER BY 2 DESC" } ]
          },
          {
            "id": 29, "type": "table", "title": "Derniers elements supprimes",
            "gridPos": { "h": 8, "w": 24, "x": 0, "y": 74 },
            "datasource": { "type": "postgres", "uid": "supabase-postgres" },
            "targets": [ { "format": "table", "rawSql": "SELECT created_at AS \"Supprime le\", resource_type AS \"Type\", resource_id AS \"ID\", deleted_by_email AS \"Par\", reason AS \"Raison\" FROM public.trash_items ORDER BY created_at DESC LIMIT 15" } ]
          }
        ]
      }

runcmd:
  # --- Docker ---
  - curl -fsSL https://get.docker.com | sh
  - systemctl enable docker
  - systemctl start docker
  - apt-get install -y docker-compose-plugin

  # --- Lancement de la stack de supervision ---
  - cd /opt/monitoring && docker compose up -d

  # --- ufw : seul le nécessaire, le filtrage fin est fait par le NSG Azure ---
  - ufw default deny incoming
  - ufw default allow outgoing
  - ufw allow 22/tcp
  - ufw allow 3000/tcp
  - ufw allow 9090/tcp
  - ufw --force enable

  # --- fail2ban ---
  - systemctl enable fail2ban
  - systemctl start fail2ban

final_message: "PLG - 2026 : noeud de supervision prêt après $UPTIME secondes. Prometheus (:9090) et Grafana (:3000) sont provisionnés automatiquement."

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
          access: proxy
          url: http://prometheus:9090
          isDefault: true
          editable: false

  - path: /opt/monitoring/grafana/provisioning/dashboards/dashboards.yml
    owner: root:root
    permissions: '0644'
    content: |
      apiVersion: 1
      providers:
        - name: "Infrastructure"
          orgId: 1
          folder: "Infrastructure"
          type: file
          disableDeletion: false
          updateIntervalSeconds: 30
          allowUiUpdates: true
          options:
            path: /var/lib/grafana/dashboards

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

#cloud-config

# ==============================================================================================
# PLG - 2026 / Groupe 24 : ESTIAM - Paris
# cloud-init.yaml — Noeud applicatif (Node.js + Nginx + monitoring agent)
# Généré depuis un template Terraform (templatefile) — modifier cloud-init/app-node.yaml.tpl
# ===============================================================================================

package_update: true
package_upgrade: true

packages:
  - git
  - curl
  - wget
  - unzip
  - zip
  - vim
  - nano
  - htop
  - tree
  - tmux
  - jq
  - make
  - build-essential
  - software-properties-common
  - apt-transport-https
  - ca-certificates
  - gnupg
  - lsb-release
  - net-tools
  - nmap
  - rsync
  - dnsutils
  - iputils-ping
  - traceroute
  - netcat
  - python3
  - python3-pip
  - python3-venv
  - postgresql-client
  - redis-tools
  - nginx
  - ufw
  - fail2ban

runcmd:
  # --- Docker ---
  - curl -fsSL https://get.docker.com | sh
  - usermod -aG docker ${admin_username}
  - systemctl enable docker
  - systemctl start docker
  - apt-get install -y docker-compose-plugin

  # --- Node.js LTS ---
  - curl -fsSL https://deb.nodesource.com/setup_lts.x | bash -
  - apt-get install -y nodejs

  # --- Packages npm globaux ---
  - npm install -g pm2 nodemon typescript ts-node prettier eslint

  # --- Python packages ---
  - pip3 install --upgrade pip
  - pip3 install httpie rich requests fastapi uvicorn black flake8

  # --- Azure CLI ---
  - curl -sL https://aka.ms/InstallAzureCLIDeb | bash

  # --- GitHub CLI ---
  - curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
  - chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
  - echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" > /etc/apt/sources.list.d/github-cli.list
  - apt-get update
  - apt-get install -y gh

  # --- Supabase CLI ---
  - curl -L https://github.com/supabase/cli/releases/latest/download/supabase_linux_amd64.tar.gz -o /tmp/supabase.tar.gz
  - tar -xvzf /tmp/supabase.tar.gz -C /tmp
  - mv /tmp/supabase /usr/local/bin/supabase
  - chmod +x /usr/local/bin/supabase

  # --- Terraform (utile pour debug depuis le noeud) ---
  - wget -O /tmp/terraform.zip https://releases.hashicorp.com/terraform/1.8.5/terraform_1.8.5_linux_amd64.zip
  - unzip /tmp/terraform.zip -d /usr/local/bin/
  - chmod +x /usr/local/bin/terraform

  # --- node_exporter (métriques système pour Prometheus) ---
  - useradd --no-create-home --shell /usr/sbin/nologin node_exporter || true
  - curl -L https://github.com/prometheus/node_exporter/releases/download/v${node_exporter_version}/node_exporter-${node_exporter_version}.linux-amd64.tar.gz -o /tmp/node_exporter.tar.gz
  - tar -xvzf /tmp/node_exporter.tar.gz -C /tmp
  - mv /tmp/node_exporter-${node_exporter_version}.linux-amd64/node_exporter /usr/local/bin/node_exporter
  - chown node_exporter:node_exporter /usr/local/bin/node_exporter
  - |
    cat > /etc/systemd/system/node_exporter.service << 'EOF'
    [Unit]
    Description=Prometheus Node Exporter
    After=network.target

    [Service]
    User=node_exporter
    Group=node_exporter
    Type=simple
    ExecStart=/usr/local/bin/node_exporter --web.listen-address=:9100

    [Install]
    WantedBy=multi-user.target
    EOF
  - systemctl daemon-reload
  - systemctl enable node_exporter
  - systemctl start node_exporter

  # --- Dossier de travail ---
  - mkdir -p /home/${admin_username}/projects
  - chown -R ${admin_username}:${admin_username} /home/${admin_username}/projects

  # --- GitHub Actions self-hosted runner (déploiement continu, sans ouvrir SSH sur Internet) ---
  - mkdir -p /home/${admin_username}/actions-runner
  - chown ${admin_username}:${admin_username} /home/${admin_username}/actions-runner
  - |
    sudo -H -u ${admin_username} bash -c '
      set -e
      cd /home/${admin_username}/actions-runner
      curl -o actions-runner.tar.gz -L https://github.com/actions/runner/releases/download/v${runner_version}/actions-runner-linux-x64-${runner_version}.tar.gz
      tar xzf actions-runner.tar.gz
      REG_TOKEN=$(curl -s -X POST -H "Authorization: token ${github_pat}" -H "Accept: application/vnd.github+json" https://api.github.com/repos/${github_owner}/${repo_name}/actions/runners/registration-token | jq -r .token)
      ./config.sh --unattended --url https://github.com/${github_owner}/${repo_name} --token "$REG_TOKEN" --name "${runner_label}" --labels "${runner_label}" --work _work --replace
    '
  - /home/${admin_username}/actions-runner/svc.sh install ${admin_username}
  - /home/${admin_username}/actions-runner/svc.sh start

  # --- Fichier d'environnement de l'application (secrets injectés par Terraform, jamais commités dans Git) ---
  - |
    cat > /home/${admin_username}/projects/app.env << 'EOF'
    SUPABASE_URL=${supabase_url}
    SUPABASE_ANON_KEY=${supabase_anon_key}
    DATABASE_URL=${database_url}
    PORT=3000
    NODE_ENV=production
    EOF
  - chown ${admin_username}:${admin_username} /home/${admin_username}/projects/app.env
  - chmod 600 /home/${admin_username}/projects/app.env

  # --- Clone + build + démarrage initial de l'application (idempotent, rejoué par le CI/CD ensuite) ---
  - |
    sudo -H -u ${admin_username} bash -c '
      set -e
      cd /home/${admin_username}/projects
      if [ ! -d "${repo_name}" ]; then
        git clone ${github_repo_url} ${repo_name}
      fi
      cd ${repo_name}
      cp ../app.env .env
      npm install --legacy-peer-deps
      npm run build
    '
  - npm install -g serve
  - |
    sudo -H -u ${admin_username} bash -c '
      export PATH=$PATH:/usr/local/bin
      cd /home/${admin_username}/projects/${repo_name}
      pm2 delete webapp 2>/dev/null || true
      pm2 start $(which serve) --name "webapp" -- -s dist -l 3000
      pm2 save
    '

  # --- PM2 : démarrage automatique au reboot ---
  - env PATH=$PATH:/usr/bin pm2 startup systemd -u ${admin_username} --hp /home/${admin_username}
  - systemctl enable pm2-${admin_username}

  # --- Nginx : reverse proxy port 80 -> Node.js :3000 ---
  - |
    cat > /etc/nginx/sites-available/webapp << 'EOF'
    server {
        listen 80;
        server_name _;

        location /health {
            return 200 'OK';
            add_header Content-Type text/plain;
        }

        location / {
            proxy_pass http://localhost:3000;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection 'upgrade';
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_cache_bypass $http_upgrade;
        }
    }
    EOF
  - ln -sf /etc/nginx/sites-available/webapp /etc/nginx/sites-enabled/webapp
  - rm -f /etc/nginx/sites-enabled/default
  - systemctl enable nginx
  - systemctl restart nginx

  # --- ufw : seuls les ports réellement nécessaires localement, le filtrage fin est fait par les NSG Azure ---
  - ufw default deny incoming
  - ufw default allow outgoing
  - ufw allow 22/tcp
  - ufw allow 80/tcp
  - ufw allow 443/tcp
  - ufw allow 9100/tcp
  - ufw --force enable

  # --- fail2ban ---
  - systemctl enable fail2ban
  - systemctl start fail2ban

final_message: "PLG - 2026 : noeud applicatif prêt après $UPTIME secondes. Nginx, PM2, node_exporter et l'application sont déployés."

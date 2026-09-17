============================================================
 PLG 2026 - GROUPE 24 - GUIDE DE DEPLOIEMENT (PRIORITE -> ORDRE)
============================================================
A suivre dans l'ordre. Ne pas sauter d'etape.
Duree estimee totale : 30-45 min (hors attente Azure ~10-15 min).


############################################################
# PRIORITE 0 - PREREQUIS (a verifier AVANT de commencer)
############################################################

[ ] Azure CLI installe et connecte :
    az login
    az account show
    (verifier que c'est le bon abonnement Azure)

[ ] Terraform installe (>= 1.2.0) :
    terraform version

[ ] Une paire de cles SSH existe (chemin par defaut attendu :
    ~/clouddrive/hubspoke_rsa.pub). Sinon la generer :
    ssh-keygen -t rsa -b 4096 -f ~/clouddrive/hubspoke_rsa -N ""

[ ] Vous avez sous la main :
    - l'URL et la cle anon Supabase (Project Settings > API)
    - la chaine de connexion Postgres "application" (Project Settings >
      Database > Connection string > URI)
    - un GitHub Personal Access Token (scope repo + workflow) pour
      l'auto-enregistrement des runners


############################################################
# PRIORITE 1 - SUPABASE : creer le role Grafana en lecture seule
############################################################
A faire UNE SEULE FOIS, avant terraform apply, sinon Grafana ne pourra
pas afficher le dashboard metier (section 12.2 du README).

1) Aller dans Supabase > SQL Editor du projet, executer :

CREATE ROLE grafana_reader WITH LOGIN PASSWORD 'CHOISIR_UN_MDP_FORT_ICI';
GRANT USAGE ON SCHEMA public TO grafana_reader;
GRANT SELECT ON
  public.scripts,
  public.categories,
  public.profiles,
  public.guest_users,
  public.contact_messages,
  public.audit_logs,
  public.script_likes,
  public.script_shares,
  public.resources,
  public.trash_items
TO grafana_reader;

2) Noter le mot de passe choisi (il servira a l'etape 3).

3) Recuperer l'hote du CONNECTION POOLER (pas la connexion directe) :
   Supabase > Project Settings > Database > Connection pooling
   -> copier l'hote (ex: aws-0-eu-west-3.pooler.supabase.com)
   -> le user complet a utiliser est: grafana_reader.<ref-du-projet>
      (Supabase l'affiche directement dans l'onglet pooling)


############################################################
# PRIORITE 2 - TERRAFORM.TFVARS (dans le dossier Terraform)
############################################################

1) Copier l'exemple :
   cp terraform.tfvars.example terraform.tfvars

2) Editer terraform.tfvars et remplir AU MINIMUM :
   - ssh_public_key_path       (si different du defaut)
   - grafana_allowed_source    (mettre votre IP publique en /32 si vous
                                 voulez acceder a Grafana directement,
                                 sinon laisser la valeur par defaut
                                 10.0.0.0/16 = acces via VNet uniquement)
   - github_repo_url, repo_name, github_owner
   - supabase_url
   - supabase_db_host          (hote du pooler, etape 1.3 ci-dessus)
   - supabase_db_user          (grafana_reader.<ref-projet>)

   NE PAS mettre dans ce fichier (secrets -> variables d'environnement,
   voir Priorite 3) :
   - supabase_anon_key
   - database_url
   - github_pat
   - grafana_admin_password
   - supabase_db_password
   - grafana_alert_webhook_url (optionnel)

3) Verifier que terraform.tfvars est bien dans .gitignore (ne JAMAIS
   committer ce fichier une fois rempli).


############################################################
# PRIORITE 3 - SECRETS EN VARIABLES D'ENVIRONNEMENT
############################################################
A executer dans le meme terminal, juste avant terraform apply.

export TF_VAR_supabase_anon_key="COLLER_LA_CLE_ANON_SUPABASE"
export TF_VAR_database_url="COLLER_LA_CONNECTION_STRING_APPLICATIVE"
export TF_VAR_github_pat="COLLER_LE_PAT_GITHUB"
export TF_VAR_grafana_admin_password="CHOISIR_UN_MDP_FORT_GRAFANA"
export TF_VAR_supabase_db_password="LE_MDP_DE_grafana_reader_ETAPE_1"

# Optionnel (notifications de deploiement, peut rester vide) :
export TF_VAR_grafana_alert_webhook_url=""


############################################################
# PRIORITE 4 - DEPLOIEMENT TERRAFORM
############################################################

cd DeploimentAppHubScript

terraform init

terraform validate

terraform plan -out=tfplan
# -> RELIRE le plan : verifier le nombre de ressources a creer
#    (VNets, NSG, Firewall, Bastion, LB, 3 VMs, IPs publiques...)

terraform apply tfplan
# -> Prendre un cafe, compter 10-15 min (Firewall Azure est lent a
#    provisionner, c'est normal).

# A la fin, RECUPERER et NOTER les outputs :
terraform output


############################################################
# PRIORITE 5 - VERIFICATIONS POST-DEPLOIEMENT (infra)
############################################################

[ ] Site accessible via le Load Balancer :
    curl -I $(terraform output -raw load_balancer_public_ip)
    (ou ouvrir l'IP dans un navigateur)
    -> Normal a ce stade : le code applicatif n'est pas encore deploye
       (VMs juste provisionnees), donc 502/503 possible tant que le
       pipeline CI/CD (Priorite 6) n'a pas tourne au moins une fois.

[ ] Grafana accessible :
    -> ouvrir : terraform output grafana_url
    -> se connecter avec grafana_admin_user / TF_VAR_grafana_admin_password
    -> verifier le dossier "PLG AppHub - Groupe 24" :
         - dashboard "Hub-Spoke Overview" (metriques serveur, doit
           deja afficher des donnees CPU/RAM/disque)
         - dashboard "AppHub - Vue d'ensemble metier" (necessite que
           la datasource Postgres soit verte : Connections > Data
           sources > Supabase PostgreSQL > Save & Test)
    -> verifier Alerting > Alert rules : les 3 regles doivent
       apparaitre en etat "Normal" (pas "Error")

[ ] Si la datasource Postgres est en erreur : verifier que
    supabase_db_host / supabase_db_user / TF_VAR_supabase_db_password
    sont corrects, et que le role grafana_reader existe bien (Priorite 1).


############################################################
# PRIORITE 6 - CI/CD (dans le depot GIT DU SITE, pas Terraform)
############################################################

1) Copier UNIQUEMENT ces deux fichiers dans le depot du site
   (ne pas ecraser tout le depot) :
   - .github/workflows/deploy.yml
   - scripts/deploy.sh
   puis :
   chmod +x scripts/deploy.sh
   git add .github/workflows/deploy.yml scripts/deploy.sh
   git commit -m "ci: pipeline deploy avec quality gate, rollback auto et smoke-test"

2) (Optionnel mais recommande) Dans GitHub, Settings > Secrets and
   variables > Actions du depot du SITE :
   - Variable "PROD_URL"          = http://<load_balancer_public_ip>
                                     (valeur de terraform output
                                     load_balancer_public_ip)
   - Secret   "DEPLOY_WEBHOOK_URL" = URL webhook Slack/Discord/Teams
                                     (laisser vide si non utilise)

3) Verifier que les 2 runners auto-heberges sont bien enregistres et
   "Idle" (pas "Offline") :
   GitHub > depot du site > Settings > Actions > Runners
   -> doit lister 2 runners avec les labels vm-spoke-1 et vm-spoke-2

4) Declencher le premier deploiement :
   git push origin main
   -> suivre l'execution dans l'onglet "Actions" du depot GitHub
   -> ordre attendu : quality -> deploy-vm1 -> deploy-vm2 -> smoke-test

5) Une fois le pipeline vert, revalider :
   curl -I http://<load_balancer_public_ip>
   -> doit repondre 200 OK avec le site


############################################################
# EN CAS DE PROBLEME - COMMANDES DE DEPANNAGE RAPIDES
############################################################

# Se connecter a une VM via le Bastion (pas d'IP publique sur VM1/VM2) :
az network bastion ssh --name <nom-bastion> \
  --resource-group <rg_name> \
  --target-resource-id <id-vm> \
  --auth-type ssh-key \
  --username scripttools_plgEstiam \
  --ssh-key ~/clouddrive/hubspoke_rsa

# Sur la VM, verifier le runner GitHub Actions :
sudo systemctl status actions.runner.*
sudo journalctl -u 'actions.runner.*' -n 100 --no-pager

# Sur la VM, verifier l'appli :
pm2 status
pm2 logs webapp --lines 50
curl -I http://localhost:3000
curl -I http://localhost/health

# Revenir manuellement a la version precedente si besoin (rollback manuel) :
cd ~/projects/<repo_name>
rm -rf dist && mv dist_previous dist
pm2 reload webapp

# Sur la VM monitoring, verifier les containers :
docker ps
docker logs grafana --tail 100
docker logs prometheus --tail 100


############################################################
# RAPPEL SECURITE - A NE JAMAIS FAIRE
############################################################
- Ne jamais committer terraform.tfvars une fois rempli
- Ne jamais committer de valeur reelle pour :
  supabase_anon_key, database_url, github_pat, grafana_admin_password,
  supabase_db_password, grafana_alert_webhook_url
- Toujours passer ces valeurs par TF_VAR_xxx (export shell) ou secrets
  GitHub Actions, jamais en dur dans un fichier versionne

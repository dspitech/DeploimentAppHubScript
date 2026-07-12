# Rapport de projet -Rendu n°07

![Terraform](https://img.shields.io/badge/Terraform-%3E%3D1.2-844FBA?logo=terraform&logoColor=white)
![Azure](https://img.shields.io/badge/Cloud-Microsoft%20Azure-0089D6?logo=microsoftazure&logoColor=white)
![Monitoring](https://img.shields.io/badge/Monitoring-Prometheus%20%2B%20Grafana-E6522C?logo=prometheus&logoColor=white)
![CI/CD](https://img.shields.io/badge/CI%2FCD-GitHub%20Actions-2088FF?logo=githubactions&logoColor=white)
![Status](https://img.shields.io/badge/Statut-Rendu%2007-success)

## Informations du projet 
 
| Élément | Détails |
|---|---|
| **Titre du projet** | Cloud Script Manager |
| **Domaine** | Cloud Computing – Architecture Azure – Sécurité – DevOps |
| **Entreprise** | DSPI-TECH |
| **Technologies principales** | Microsoft Azure, React.js, Docker, Azure Firewall, Linux, Supabase, Terraform, Prometheus, Grafana, GitHub Actions |
| **Année académique** | 2025 – 2026 |
| **Niveau** | E4 – E5 |
| **Lieu** | Paris – France |
| **Groupe** | 24 |
| **Nombre de personnes** | 5 |
| **Date début** | Janvier 2026 |
| **Date fin** | Septembre 2026 |

## Membres de l'équipe

| Membre | Rôle | Classe |
|---|---|---|
| **Amir Minihadji AMINA** | Dev + Admin | E5 - CCSN |
| **LO Pape** | Chef de projet + Dev backend + Admin | E4 - CCSN |
| **Neylie NDJUMKENG-NGUEMO** | Architecte logiciel | E4 - CCSN |
| **Steve John BIAMOU HOUMGA** | Expert cybersécurité | E4 - CCSN |
| **Gauyet NGUEFACK-TCHAMI** | Experte cybersécurité | E4 - CCSN |
| **Mhand BOUFALA** | Superviseur | -|

---

## Objet de ce rendu

Ce document constitue le **rapport du rendu n°07** du projet **Cloud Script
Manager**. Il couvre les deux tâches réalisées sur cette itération :

1. **Réorganisation des dossiers et fichiers du code du site web** -
   restructuration de l'arborescence `src/pages` en modules fonctionnels
   cohérents (feature-based), sans régression sur les routes, les imports
   ou le build TypeScript.
2. **Hébergement et déploiement automatisé avec Terraform & supervision du
   site web dans Azure** -refonte de l'infrastructure Azure Hub & Spoke en
   modules Terraform réutilisables, automatisation complète du provisioning
   applicatif via `cloud-init`, mise en place d'une supervision
   Prometheus/Grafana et d'un pipeline CI/CD GitHub Actions.

Ces deux tâches s'inscrivent directement dans les exigences non
fonctionnelles du projet définies au cadrage (maintenabilité, portabilité,
haute disponibilité, observabilité, résilience -voir Chapitre 4 du dossier
de cadrage) et dans l'objectif d'**architecture professionnelle** fixé comme
objectif spécifique du projet.

---

## Sommaire général

- **[Tâche 1 -Réorganisation des dossiers et fichiers du code du site web](#tâche-1--réorganisation-des-dossiers-et-fichiers-du-code-du-site-web)**
  1. Principes directeurs
  2. Arborescence `src/pages/` - Avant / Après
  3. Mapping des déplacements
  4. Fichiers touchés par la mise à jour des imports
  5. Structure globale de référence
  6. Conventions à respecter à partir de cette modification
  7. Bénéfices obtenus et résultat final

- **[Tâche 2 -Hébergement et déploiement automatisé avec Terraform & supervision du site web dans Azure](#tâche-2--hébergement-et-déploiement-automatisé-avec-terraform--supervision-du-site-web-dans-azure)**
  1. Vue d'ensemble de l'architecture
  2. Pourquoi une architecture en modules ?
  3. Structure complète des fichiers
  4. Fichiers racine
  5. Module `network`
  6. Module `security`
  7. Module `firewall`
  8. Module `bastion`
  9. Module `loadbalancer`
  10. Module `compute`
  11. Cloud-init : provisioning automatique des VMs
  12. Supervision : dashboard Grafana
  13. CI/CD : pipeline GitHub Actions
  14. Synthèse des choix d'architecture
  15. Guide de déploiement pas à pas
  16. Où mettre chaque clé -récapitulatif
  17. Vérifications et destruction
  18. Glossaire

---

## Tâche 1 : Réorganisation des dossiers et fichiers du code du site web

**Objectif** · Restructurer l'arborescence `src/pages` en modules fonctionnels cohérents, sans casser aucune route, ni aucun import, ni le build TypeScript. Cette réorganisation prépare le projet à sa mise en production et facilite l'ajout de nouveaux dossiers ou fichiers.

---

### 1. Principes directeurs

1. **Découpage par domaine métier** (feature-based), pas par type technique.
2. **Séparation stricte des espaces** : `public/` (visiteurs), `app/` (utilisateurs authentifiés), `admin/` (rôles à privilèges), `auth/` (flux d'authentification).
3. **Zéro régression** : toutes les routes définies dans `src/App.tsx` restent identiques, seuls les chemins d'import changent.
4. **Alias `@/` conservés** partout : aucune ré-écriture d'imports relatifs dans les composants ou hooks.

---

### 2. Arborescence `src/pages/` - Avant / Après

#### Avant (24 fichiers dans un seul dossier)

```text
src/pages/
├── AccessPages.tsx
├── AdminUsersPage.tsx
├── ArchivesPage.tsx
├── AuditLogsPage.tsx
├── CategoriesPage.tsx
├── CategoryPage.tsx
├── ContactPage.tsx
├── DashboardPage.tsx
├── EditScriptPage.tsx
├── ForgotPasswordPage.tsx
├── Index.tsx
├── LoginPage.tsx
├── NewCategoryPage.tsx
├── NewScriptPage.tsx
├── NotFound.tsx
├── ProfilePage.tsx
├── ResetPasswordPage.tsx
├── ResourcesPage.tsx
├── ScriptDetailPage.tsx
├── ScriptsPage.tsx
├── SetPasswordPage.tsx
├── SettingsPage.tsx
├── SignupPage.tsx
├── TrashPage.tsx
└── public/            (déjà organisé)
```

#### Après (7 modules fonctionnels)

```text
src/pages/
├── NotFound.tsx                 # Fallback global 404
│
├── auth/                        # Flux d'authentification & pages d'accès
│   ├── AccessPages.tsx          #   Forbidden / Suspended / NoSignup
│   ├── ForgotPasswordPage.tsx
│   ├── LoginPage.tsx
│   ├── ResetPasswordPage.tsx
│   ├── SetPasswordPage.tsx
│   └── SignupPage.tsx
│
├── app/                         # Espace utilisateur authentifié (général)
│   ├── ContactPage.tsx
│   ├── DashboardPage.tsx
│   ├── Index.tsx                #   Hub /admin (accueil connecté)
│   ├── ProfilePage.tsx
│   └── SettingsPage.tsx
│
├── scripts/                     # Domaine Scripts (CRUD interne)
│   ├── EditScriptPage.tsx
│   ├── NewScriptPage.tsx
│   ├── ScriptDetailPage.tsx
│   └── ScriptsPage.tsx
│
├── categories/                  # Domaine Catégories (CRUD interne)
│   ├── CategoriesPage.tsx
│   ├── CategoryPage.tsx
│   └── NewCategoryPage.tsx
│
├── resources/                   # Domaine Ressources (CRUD interne)
│   └── ResourcesPage.tsx
│
├── admin/                       # Réservé aux rôles `global_admin` / `admin`
│   ├── AdminUsersPage.tsx
│   ├── ArchivesPage.tsx
│   ├── AuditLogsPage.tsx
│   └── TrashPage.tsx
│
└── public/                      # Site vitrine -visiteurs anonymes
    ├── AboutPage.tsx
    ├── CategoriesPublicPage.tsx
    ├── CategoryPublicPage.tsx
    ├── ContactPublicPage.tsx
    ├── HomePage.tsx
    ├── LegalPages.tsx
    ├── ResourcesPublicPage.tsx
    ├── ScriptPublicDetailPage.tsx
    └── ScriptsPublicPage.tsx
```

---

### 3. Mapping des déplacements

| Ancien chemin | Nouveau chemin |
|---|---|
| `pages/LoginPage.tsx` | `pages/auth/LoginPage.tsx` |
| `pages/SignupPage.tsx` | `pages/auth/SignupPage.tsx` |
| `pages/ForgotPasswordPage.tsx` | `pages/auth/ForgotPasswordPage.tsx` |
| `pages/ResetPasswordPage.tsx` | `pages/auth/ResetPasswordPage.tsx` |
| `pages/SetPasswordPage.tsx` | `pages/auth/SetPasswordPage.tsx` |
| `pages/AccessPages.tsx` | `pages/auth/AccessPages.tsx` |
| `pages/Index.tsx` | `pages/app/Index.tsx` |
| `pages/DashboardPage.tsx` | `pages/app/DashboardPage.tsx` |
| `pages/ProfilePage.tsx` | `pages/app/ProfilePage.tsx` |
| `pages/SettingsPage.tsx` | `pages/app/SettingsPage.tsx` |
| `pages/ContactPage.tsx` | `pages/app/ContactPage.tsx` |
| `pages/ScriptsPage.tsx` | `pages/scripts/ScriptsPage.tsx` |
| `pages/NewScriptPage.tsx` | `pages/scripts/NewScriptPage.tsx` |
| `pages/EditScriptPage.tsx` | `pages/scripts/EditScriptPage.tsx` |
| `pages/ScriptDetailPage.tsx` | `pages/scripts/ScriptDetailPage.tsx` |
| `pages/CategoriesPage.tsx` | `pages/categories/CategoriesPage.tsx` |
| `pages/CategoryPage.tsx` | `pages/categories/CategoryPage.tsx` |
| `pages/NewCategoryPage.tsx` | `pages/categories/NewCategoryPage.tsx` |
| `pages/ResourcesPage.tsx` | `pages/resources/ResourcesPage.tsx` |
| `pages/AdminUsersPage.tsx` | `pages/admin/AdminUsersPage.tsx` |
| `pages/AuditLogsPage.tsx` | `pages/admin/AuditLogsPage.tsx` |
| `pages/ArchivesPage.tsx` | `pages/admin/ArchivesPage.tsx` |
| `pages/TrashPage.tsx` | `pages/admin/TrashPage.tsx` |
| `pages/NotFound.tsx` | *(inchangé - fallback racine)* |

**Total : 23 fichiers déplacés, 7 modules créés.**

---

### 4. Fichiers touchés par la mise à jour des imports

Seuls deux fichiers référençaient les anciens chemins :

| Fichier | Changement |
|---|---|
| `src/App.tsx` | 23 imports mis à jour vers les nouveaux chemins modulaires |
| `src/pages/scripts/EditScriptPage.tsx` | Réutilisation de constantes : `@/pages/NewScriptPage` → `@/pages/scripts/NewScriptPage` |

Tous les autres imports du projet utilisent l'alias `@/components/*`, `@/lib/*`, `@/hooks/*`, `@/contexts/*` -**aucune modification requise** dans les composants, hooks, contextes, ou intégrations Supabase.

---

### 5. Structure globale de référence

```text
azure-script-hub/
├── public/                      # Assets statiques Vite
├── src/
│   ├── assets/                  # Images bundlées (imports ES6)
│   ├── components/
│   │   ├── auth/                # Guards & primitives d'authentification
│   │   ├── dashboard/           # Cards, stats, widgets du dashboard admin
│   │   ├── layout/              # DashboardLayout, Header, Sidebar
│   │   ├── public/              # PublicLayout, PublicHeader, PublicFooter
│   │   ├── scripts/             # Détail script, éditeur Monaco
│   │   ├── ui/                  # shadcn/ui -primitives réutilisables
│   │   └── NavLink.tsx
│   ├── contexts/                # AuthContext (React Context API)
│   ├── data/                    # Données statiques / seed
│   ├── hooks/                   # Hooks React réutilisables
│   ├── integrations/supabase/   # Client + types générés
│   ├── lib/                     # Utilitaires purs (audit, trash, toast, …)
│   ├── pages/                   # ⇐ Réorganisé (voir §2)
│   ├── test/                    # Setup Vitest + tests d'exemple
│   ├── App.tsx                  # Routing central
│   ├── main.tsx                 # Bootstrap React
│   └── index.css                # Design tokens + overrides globaux
├── supabase/
│   ├── functions/               # Edge Functions Deno
│   │   ├── admin-invite-user/
│   │   ├── admin-delete-user/
│   │   └── public-contact-submit/
│   ├── migrations/              # Migrations SQL versionnées
│   └── config.toml
├── README.md                    # Rapport d'audit sécurité complet
```

---

### 6. Conventions à respecter à partir de cette modification

#### 6.1 Ajout d'une nouvelle page

1. Identifier le domaine cible (`auth`, `app`, `scripts`, `categories`, `resources`, `admin`, `public`).
2. Créer le fichier `<Nom>Page.tsx` dans le sous-dossier correspondant.
3. Enregistrer la route dans `src/App.tsx` en respectant le regroupement existant.
4. Si la page est protégée, wrapper avec `<ProtectedRoute>` (et `role=` / `permission=` si nécessaire).

#### 6.2 Nommage

| Type | Convention | Exemple |
|---|---|---|
| Page | `PascalCase` + suffixe `Page` | `AuditLogsPage.tsx` |
| Composant | `PascalCase` | `ScriptCard.tsx` |
| Hook | `camelCase` préfixé `use` | `useUserData.ts` |
| Utilitaire | `camelCase` | `auditLogs.ts` |
| Edge Function | `kebab-case` | `public-contact-submit/` |

#### 6.3 Imports

- **Toujours** utiliser l'alias `@/` -jamais de chemins relatifs `../../`.
- Les pages importent des composants, jamais l'inverse.
- Les composants `ui/` ne dépendent d'aucun composant `dashboard/`, `public/`, `layout/`.

#### 6.4 Ce qui reste hors de `src/pages/`

- `NotFound.tsx` -reste à la racine `pages/` car c'est le fallback universel `*`.

---

### 7. Bénéfices obtenus et résultat final

- **Lisibilité** : dossier `pages/` passe de 24 fichiers plats à 7 modules autoportants.
- **Scalabilité** : ajout de nouvelles pages par domaine sans polluer la racine.
- **Sécurité** : séparation physique entre `public/`, `app/`, `admin/` matérialise la frontière de privilèges déjà en place dans le routage.
- **Onboarding** : un nouveau développeur identifie immédiatement où intervenir selon la feature.
- **Maintenance** : les changements liés à un domaine (par exemple *Scripts*) restent isolés dans un seul dossier.
-e 
---

## Tâche 2 : Hébergement et déploiement automatisé avec Terraform & supervision du site web dans Azure


| | |
|---|---|
| **Stack** | Terraform · Azure (VNet, Firewall, Bastion, Load Balancer, VM) · Node.js · Nginx · PM2 · Docker · Prometheus · Grafana · GitHub Actions |

---

### Résumé exécutif

Cette documente la refonte et l'automatisation complète du déploiement
d'une architecture **Hub & Spoke** sur Microsoft Azure. L'objectif était de
transformer un ensemble de commandes manuelles et un fichier Terraform
monolithique en une **infrastructure modulaire, versionnée et reproductible**,
répondant à trois exigences :

1. **Infrastructure as Code professionnelle** -le réseau, la sécurité et les
   machines virtuelles sont découpés en modules Terraform réutilisables
   plutôt qu'un fichier unique, avec une séparation stricte entre
   configuration sensible (secrets) et configuration versionnable.
2. **Déploiement applicatif entièrement automatisé** -chaque VM se
   configure elle-même au démarrage via `cloud-init` (dépendances, build,
   reverse-proxy, agents de supervision), sans intervention manuelle post-provisioning.
3. **Exploitation continue** -une VM de supervision Prometheus/Grafana est
   provisionnée avec un dashboard prêt à l'emploi, et un pipeline CI/CD
   GitHub Actions redéploie automatiquement l'application à chaque mise à
   jour du code source, sans exposer le moindre port entrant supplémentaire.

---

### Sommaire

1. [Vue d'ensemble de l'architecture](#1-vue-densemble-de-larchitecture)
2. [Pourquoi une architecture en modules ?](#2-pourquoi-une-architecture-en-modules-)
3. [Structure complète des fichiers](#3-structure-complète-des-fichiers)
4. [Fichiers racine](#4-fichiers-racine)
5. [Module `network`](#5-module-network)
6. [Module `security`](#6-module-security)
7. [Module `firewall`](#7-module-firewall)
8. [Module `bastion`](#8-module-bastion)
9. [Module `loadbalancer`](#9-module-loadbalancer)
10. [Module `compute`](#10-module-compute)
11. [Cloud-init : provisioning automatique des VMs](#11-cloud-init--provisioning-automatique-des-vms)
12. [Supervision : dashboard Grafana](#12-supervision--dashboard-grafana)
13. [CI/CD : pipeline GitHub Actions](#13-cicd--pipeline-github-actions)
14. [Synthèse des choix d'architecture](#14-synthèse-des-choix-darchitecture)
15. [Guide de déploiement pas à pas](#15-guide-de-déploiement-pas-à-pas)
16. [Où mettre chaque clé -récapitulatif](#16-où-mettre-chaque-clé--récapitulatif)
17. [Vérifications et destruction](#17-vérifications-et-destruction)
18. [Glossaire](#18-glossaire)

---

### 1. Vue d'ensemble de l'architecture

```mermaid
flowchart TB
    Internet((Internet))
    LB[Load Balancer Standard<br/>IP publique]
    VM1[VM-SPOKE-1<br/>Nginx + PM2 + Node.js]
    VM2[VM-SPOKE-2<br/>Nginx + PM2 + Node.js]
    MON[VM-MONITORING<br/>Prometheus + Grafana]
    FW[Azure Firewall]
    BAST[Azure Bastion]
    ADMIN((Administrateur))
    S1[VnetSpoke1<br/>192.168.0.0/24]
    S2[VnetSpoke2<br/>172.16.0.0/24]

    Internet --> LB
    LB --> VM1
    LB --> VM2
    VM1 -. métriques :9100 .-> MON
    VM2 -. métriques :9100 .-> MON
    ADMIN -->|HTTPS portail Azure| BAST
    BAST -.->|SSH interne| VM1
    BAST -.->|SSH interne| VM2
    BAST -.->|SSH interne| MON

    subgraph HUB[VnetHub 10.0.0.0/16]
        LB
        VM1
        VM2
        MON
        FW
        BAST
    end

    S1 <-->|peering + UDR via FW| FW
    S2 <-->|peering + UDR via FW| FW
```

**Principes de sécurité structurants** :

- **Aucune VM n'a d'IP publique.** Le trafic web entre uniquement par le
  Load Balancer, le trafic d'administration (SSH) entre uniquement par
  Azure Bastion.
- **Le CI/CD n'ouvre aucun port entrant** : chaque VM applicative fait
  tourner un runner GitHub Actions auto-hébergé qui interroge GitHub en
  sortant (polling), jamais l'inverse.
- **Le trafic inter-spoke** (Spoke1 ↔ Spoke2) est forcé de transiter par
  l'Azure Firewall via des tables de routage (UDR), ce qui permet d'y
  appliquer des règles de filtrage centralisées, conformément au modèle
  Hub & Spoke.

---

### 2. Pourquoi une architecture en modules ?

La version initiale du déploiement vu dans le rendu numéro 04 était un unique fichier `main.tf` de plus de 500 lignes mélangeant réseau, sécurité, VMs et règles au même endroit. Cela pose plusieurs problèmes en environnement professionnel :

| Problème avec un fichier unique | Solution apportée par les modules |
|---|---|
| Impossible de réutiliser un bloc de code (ex: NSG) sans copier-coller | Le module `security` est **paramétrable** et instancié 3 fois (VM1, VM2, monitoring) avec des règles différentes |
| Une erreur dans un bloc peut bloquer la lecture de tout le fichier | Chaque module est indépendant, plus facile à relire et à tester isolément |
| Difficile de savoir "qui dépend de qui" | Les dépendances passent par des `output` explicites (ex: `module.network.vm1_subnet_id`) |
| Pas de séparation claire des responsabilités | Un module = une responsabilité (réseau, sécurité, firewall, bastion, LB, compute) |
| Impossible de versionner/partager un module indépendamment | Chaque dossier sous `modules/` pourrait être extrait dans son propre dépôt Git si besoin |

Le module racine (`main.tf` à la racine) ne fait plus que de
**l'orchestration** : il appelle les modules dans le bon ordre et relie
leurs outputs/variables entre eux. C'est la structure recommandée par
HashiCorp pour tout projet Terraform dépassant une poignée de ressources.

---

### 3. Structure complète des fichiers

```
terraform-azure-hubspoke/
|-- main.tf                        Orchestration : appelle tous les modules
|-- variables.tf                   Déclaration de toutes les variables d'entrée
|-- outputs.tf                     Valeurs affichées après `terraform apply`
|-- providers.tf                   Provider azurerm + backend distant (optionnel)
|-- terraform.tfvars.example       Exemple de variables (sans secrets réels)
|-- .gitignore                     Exclut secrets, état Terraform, etc. de Git
|
|-- modules/
|   |-- network/                   VNets, Subnets, Peerings
|   |-- security/                  NSG générique paramétrable
|   |-- firewall/                  Azure Firewall + règles + UDR
|   |-- bastion/                   Azure Bastion
|   |-- loadbalancer/              Load Balancer Standard
|   `-- compute/                   VM Linux générique (NIC + VM)
|
|-- cloud-init/
|   |-- app-node.yaml.tpl          Provisioning VM-SPOKE-1 / VM-SPOKE-2
|   `-- monitoring-node.yaml.tpl   Provisioning VM-MONITORING
|
|-- monitoring/
|   `-- grafana/dashboards/hub-spoke-overview.json   Dashboard de référence
|
`-- github-actions-for-app-repo/   A copier dans le dépôt de l'application
    |-- .github/workflows/deploy.yml
    `-- scripts/deploy.sh
```

Chaque module suit la même convention à 3 fichiers, standard en Terraform :

- `variables.tf` : ce que le module attend en entrée
- `main.tf` : les ressources qu'il crée
- `outputs.tf` : ce qu'il expose aux autres modules / au module racine

---

### 4. Fichiers racine

#### 4.1 `providers.tf`

```hcl
# ============================================================
# PLG - 2026 / Groupe 24 : ESTIAM - Paris
# providers.tf -Configuration du provider Azure et du backend
# ============================================================

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
  required_version = ">= 1.2.0"

  # Recommandé pour un projet "professionnel" : état distant partagé
  # (à décommenter et adapter une fois le storage account créé)
  #
  # backend "azurerm" {
  #   resource_group_name  = "RG-TFSTATE"
  #   storage_account_name = "sttfstatehubspoke"
  #   container_name       = "tfstate"
  #   key                  = "hub-spoke.terraform.tfstate"
  # }
}

provider "azurerm" {
  features {}
}
```

**Rôle** : déclare le provider Azure (`azurerm`) et la version minimale de
Terraform requise. Contient aussi, en commentaire, la configuration d'un
**backend distant** (`azurerm` backend) prête à activer.

**Pourquoi ce choix** :
- Épingler la version du provider (`~> 3.0`) évite qu'une montée de version
  automatique casse le déploiement sans prévenir.
- Le backend distant est laissé en commentaire plutôt qu'activé par défaut
  car il nécessite un Storage Account déjà existant (`RG-TFSTATE`) -à
  décommenter une fois ce compte de stockage créé, pour que l'état Terraform
  soit partagé en équipe au lieu de rester sur un poste local.

---

#### 4.2 `variables.tf`

```hcl
# ============================================================
# PLG - 2026 / Groupe 24 : ESTIAM - Paris
# variables.tf -Déclarations des variables du module racine
# ============================================================

# ----------------------------
# Général
# ----------------------------
variable "rg_name" {
  description = "Nom du Resource Group Azure"
  type        = string
  default     = "RG-PLG-ESTIAM-Paris-2026"
}

variable "location" {
  description = "Région Azure cible"
  type        = string
  default     = "norwayeast"
}

variable "tags" {
  description = "Tags appliqués à toutes les ressources"
  type        = map(string)
  default = {
    Project     = "Deployment-Script-Tools"
    Environment = "Production"
    ManagedBy   = "Terraform"
    Author      = "PLG-Groupe24-ESTIAM-2026"
  }
}

# ----------------------------
# Authentification VMs
# ----------------------------
variable "admin_username" {
  description = "Nom du compte administrateur sur les VMs Linux"
  type        = string
  default     = "scripttools_plgEstiam"
}

variable "ssh_public_key_path" {
  description = "Chemin vers la clé publique SSH pour les VMs"
  type        = string
  default     = "~/clouddrive/hubspoke_rsa.pub"
}

# ----------------------------
# Réseau - VNets
# ----------------------------
variable "hub_vnet_name" {
  type    = string
  default = "VnetHub"
}

variable "hub_address_space" {
  type    = list(string)
  default = ["10.0.0.0/16"]
}

variable "spoke1_vnet_name" {
  type    = string
  default = "VnetSpoke1"
}

variable "spoke1_address_space" {
  type    = list(string)
  default = ["192.168.0.0/24"]
}

variable "spoke2_vnet_name" {
  type    = string
  default = "VnetSpoke2"
}

variable "spoke2_address_space" {
  type    = list(string)
  default = ["172.16.0.0/24"]
}

# ----------------------------
# Réseau - Subnets Hub
# ----------------------------
variable "subnet_firewall_prefix" {
  type    = string
  default = "10.0.2.0/24"
}

variable "subnet_bastion_prefix" {
  type    = string
  default = "10.0.4.0/24"
}

variable "subnet_hub_prod_prefix" {
  type    = string
  default = "10.0.1.0/24"
}

variable "subnet_vm1_prefix" {
  type    = string
  default = "10.0.10.0/24"
}

variable "subnet_vm2_prefix" {
  type    = string
  default = "10.0.11.0/24"
}

variable "subnet_monitoring_prefix" {
  description = "CIDR du subnet hébergeant la VM de supervision (Prometheus/Grafana)"
  type        = string
  default     = "10.0.12.0/24"
}

# ----------------------------
# Réseau - Subnets Spokes
# ----------------------------
variable "spoke1_prod_prefix" {
  type    = string
  default = "192.168.0.0/24"
}

variable "spoke2_prod_prefix" {
  type    = string
  default = "172.16.0.0/24"
}

# ----------------------------
# Machines Virtuelles applicatives
# ----------------------------
variable "vm_size" {
  type    = string
  default = "Standard_B2s"
}

variable "vm_image" {
  type = object({
    publisher = string
    offer     = string
    sku       = string
    version   = string
  })
  default = {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }
}

# ----------------------------
# VM de supervision (Prometheus/Grafana)
# ----------------------------
variable "monitoring_vm_size" {
  description = "Taille de la VM de supervision (peut rester modeste)"
  type        = string
  default     = "Standard_B2s"
}

variable "node_exporter_version" {
  description = "Version de node_exporter à installer sur les noeuds applicatifs"
  type        = string
  default     = "1.8.2"
}

variable "grafana_admin_user" {
  description = "Utilisateur admin Grafana"
  type        = string
  default     = "admin"
}

variable "grafana_admin_password" {
  description = "Mot de passe admin Grafana (à définir via TF_VAR_grafana_admin_password ou terraform.tfvars non commité)"
  type        = string
  sensitive   = true
}

variable "grafana_allowed_source" {
  description = "Préfixe CIDR autorisé à accéder à Grafana (3000) et Prometheus (9090) depuis l'extérieur du VNet. Par défaut, accès restreint au VNet ; ajoutez votre IP publique en /32 si besoin d'un accès direct."
  type        = string
  default     = "10.0.0.0/16"
}

# ----------------------------
# Load Balancer
# ----------------------------
variable "lb_name" {
  type    = string
  default = "LB-HUB-SPOKE"
}

variable "lb_probe_interval" {
  type    = number
  default = 15
}

variable "lb_probe_count" {
  type    = number
  default = 2
}

# ----------------------------
# Firewall
# ----------------------------
variable "firewall_name" {
  type    = string
  default = "AzureFireWall"
}

# ----------------------------
# Application / GitHub / Supabase
# ----------------------------
variable "github_repo_url" {
  description = "URL HTTPS du dépôt GitHub de l'application"
  type        = string
  default     = "https://github.com/dspitech/azure-script-hub-fa365d79.git"
}

variable "repo_name" {
  description = "Nom du dossier local du dépôt cloné"
  type        = string
  default     = "azure-script-hub-fa365d79"
}

variable "supabase_url" {
  description = "URL du projet Supabase"
  type        = string
}

variable "supabase_anon_key" {
  description = "Clé publique (anon) Supabase"
  type        = string
  sensitive   = true
}

variable "database_url" {
  description = "Chaîne de connexion PostgreSQL Supabase (postgresql://...)"
  type        = string
  sensitive   = true
}

# ----------------------------
# CI/CD -GitHub Actions self-hosted runner
# Les VMs n'ayant pas d'IP publique SSH exposée (accès uniquement via Bastion),
# le déploiement continu se fait via un runner auto-hébergé qui va chercher
# le travail sur GitHub (aucun port entrant à ouvrir).
# ----------------------------
variable "github_owner" {
  description = "Propriétaire (org ou user) du dépôt GitHub"
  type        = string
  default     = "dspitech"
}

variable "github_pat" {
  description = "GitHub Personal Access Token (scope 'repo' + 'workflow') utilisé uniquement au démarrage de la VM pour enregistrer le runner auto-hébergé. Fournir via TF_VAR_github_pat, jamais en dur dans un fichier commité."
  type        = string
  sensitive   = true
}

variable "runner_version" {
  description = "Version du GitHub Actions runner à installer"
  type        = string
  default     = "2.319.1"
}
```

**Rôle** : centralise **toutes** les variables d'entrée du projet, avec une
valeur par défaut quand elle a du sens (tailles de VM, plages d'adresses...)
et **sans** valeur par défaut pour les secrets (`supabase_anon_key`,
`database_url`, `github_pat`, `grafana_admin_password`), ce qui force
Terraform à les demander explicitement si elles ne sont pas fournies.

**Pourquoi ce choix** :
- Toutes les variables sont regroupées ici plutôt que dispersées dans les
  modules, pour avoir un point d'entrée unique et lisible de tout ce qui est
  configurable.
- Les 4 variables marquées `sensitive = true` ne s'affichent jamais en clair
  dans les logs Terraform (`terraform plan`/`apply`), même si le fichier
  d'état les stocke en clair (d'où l'importance du backend distant chiffré,
  voir section 14).

---

#### 4.3 `main.tf`

```hcl
# ============================================================
# PLG - 2026 / Groupe 24 : ESTIAM - Paris
# main.tf -Orchestration des modules (réseau, sécurité, compute, supervision)
# ============================================================

resource "azurerm_resource_group" "rg" {
  name     = var.rg_name
  location = var.location
  tags     = var.tags
}

# ============================================================
# Réseau
# ============================================================
module "network" {
  source = "./modules/network"

  rg_name              = azurerm_resource_group.rg.name
  location             = azurerm_resource_group.rg.location
  tags                 = var.tags

  hub_vnet_name            = var.hub_vnet_name
  hub_address_space        = var.hub_address_space
  spoke1_vnet_name         = var.spoke1_vnet_name
  spoke1_address_space     = var.spoke1_address_space
  spoke2_vnet_name         = var.spoke2_vnet_name
  spoke2_address_space     = var.spoke2_address_space

  subnet_firewall_prefix   = var.subnet_firewall_prefix
  subnet_bastion_prefix    = var.subnet_bastion_prefix
  subnet_hub_prod_prefix   = var.subnet_hub_prod_prefix
  subnet_vm1_prefix        = var.subnet_vm1_prefix
  subnet_vm2_prefix        = var.subnet_vm2_prefix
  subnet_monitoring_prefix = var.subnet_monitoring_prefix

  spoke1_prod_prefix = var.spoke1_prod_prefix
  spoke2_prod_prefix = var.spoke2_prod_prefix
}

# ============================================================
# Firewall + routage inter-spoke
# ============================================================
module "firewall" {
  source = "./modules/firewall"

  name     = var.firewall_name
  location = azurerm_resource_group.rg.location
  rg_name  = azurerm_resource_group.rg.name
  tags     = var.tags

  firewall_subnet_id    = module.network.firewall_subnet_id
  spoke1_prod_prefix    = var.spoke1_prod_prefix
  spoke2_prod_prefix    = var.spoke2_prod_prefix
  spoke1_prod_subnet_id = module.network.spoke1_prod_subnet_id
  spoke2_prod_subnet_id = module.network.spoke2_prod_subnet_id
}

# ============================================================
# Bastion (accès admin sécurisé, sans IP publique sur les VMs)
# ============================================================
module "bastion" {
  source = "./modules/bastion"

  location          = azurerm_resource_group.rg.location
  rg_name           = azurerm_resource_group.rg.name
  tags              = var.tags
  bastion_subnet_id = module.network.bastion_subnet_id
}

# ============================================================
# Load Balancer Standard
# ============================================================
module "loadbalancer" {
  source = "./modules/loadbalancer"

  name           = var.lb_name
  location       = azurerm_resource_group.rg.location
  rg_name        = azurerm_resource_group.rg.name
  tags           = var.tags
  probe_interval = var.lb_probe_interval
  probe_count    = var.lb_probe_count
}

# ============================================================
# NSG -Noeuds applicatifs (SubnetVM1 / SubnetVM2)
# Durci par rapport à la version initiale : plus de "*" en source,
# les ports de debug (3000/3001/5432/8080/8443/54321) ne sont plus
# exposés publiquement (Nginx sert déjà le tout sur 80/443).
# ============================================================
locals {
  app_nsg_rules = [
    {
      name                       = "Allow-SSH-From-Bastion"
      priority                   = 100
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "22"
      source_address_prefix      = var.subnet_bastion_prefix
      destination_address_prefix = "*"
    },
    {
      name                       = "Allow-HTTP-Internet"
      priority                   = 110
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "80"
      source_address_prefix      = "Internet"
      destination_address_prefix = "*"
    },
    {
      name                       = "Allow-HTTPS-Internet"
      priority                   = 120
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "443"
      source_address_prefix      = "Internet"
      destination_address_prefix = "*"
    },
    {
      name                       = "Allow-NodeExporter-From-Monitoring"
      priority                   = 130
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "9100"
      source_address_prefix      = var.subnet_monitoring_prefix
      destination_address_prefix = "*"
    },
    {
      name                       = "Allow-Ping-Internal"
      priority                   = 200
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Icmp"
      source_port_range          = "*"
      destination_port_range     = "*"
      source_address_prefix      = "VirtualNetwork"
      destination_address_prefix = "*"
    },
    {
      # CRITIQUE : autorise les health probes du Load Balancer Standard
      name                       = "Allow-AzureLoadBalancer"
      priority                   = 210
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "*"
      source_port_range          = "*"
      destination_port_range     = "*"
      source_address_prefix      = "AzureLoadBalancer"
      destination_address_prefix = "*"
    },
  ]
}

module "nsg_vm1" {
  source = "./modules/security"

  name           = "NSG-VM1"
  location       = azurerm_resource_group.rg.location
  rg_name        = azurerm_resource_group.rg.name
  tags           = var.tags
  subnet_id      = module.network.vm1_subnet_id
  security_rules = local.app_nsg_rules
}

module "nsg_vm2" {
  source = "./modules/security"

  name           = "NSG-VM2"
  location       = azurerm_resource_group.rg.location
  rg_name        = azurerm_resource_group.rg.name
  tags           = var.tags
  subnet_id      = module.network.vm2_subnet_id
  security_rules = local.app_nsg_rules
}

# ============================================================
# NSG -Noeud de supervision (Prometheus/Grafana)
# ============================================================
module "nsg_monitoring" {
  source = "./modules/security"

  name      = "NSG-Monitoring"
  location  = azurerm_resource_group.rg.location
  rg_name   = azurerm_resource_group.rg.name
  tags      = var.tags
  subnet_id = module.network.monitoring_subnet_id

  security_rules = [
    {
      name                       = "Allow-SSH-From-Bastion"
      priority                   = 100
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "22"
      source_address_prefix      = var.subnet_bastion_prefix
      destination_address_prefix = "*"
    },
    {
      name                       = "Allow-Grafana"
      priority                   = 110
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "3000"
      source_address_prefix      = var.grafana_allowed_source
      destination_address_prefix = "*"
    },
    {
      name                       = "Allow-Prometheus"
      priority                   = 120
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "9090"
      source_address_prefix      = var.grafana_allowed_source
      destination_address_prefix = "*"
    },
  ]
}

# ============================================================
# Cloud-init -noeuds applicatifs (un runner GitHub Actions distinct par VM)
# ============================================================
locals {
  app_cloud_init_common = {
    admin_username        = var.admin_username
    github_repo_url       = var.github_repo_url
    repo_name             = var.repo_name
    supabase_url          = var.supabase_url
    supabase_anon_key     = var.supabase_anon_key
    database_url          = var.database_url
    node_exporter_version = var.node_exporter_version
    github_owner          = var.github_owner
    github_pat            = var.github_pat
    runner_version        = var.runner_version
  }

  app_cloud_init_vm1 = templatefile("${path.module}/cloud-init/app-node.yaml.tpl", merge(
    local.app_cloud_init_common, { runner_label = "vm-spoke-1" }
  ))

  app_cloud_init_vm2 = templatefile("${path.module}/cloud-init/app-node.yaml.tpl", merge(
    local.app_cloud_init_common, { runner_label = "vm-spoke-2" }
  ))
}

# ============================================================
# VM applicative 1
# ============================================================
module "vm_spoke1" {
  source = "./modules/compute"

  vm_name             = "VM-SPOKE-1"
  location            = azurerm_resource_group.rg.location
  rg_name             = azurerm_resource_group.rg.name
  tags                = var.tags
  subnet_id           = module.network.vm1_subnet_id
  vm_size             = var.vm_size
  admin_username      = var.admin_username
  ssh_public_key_path = var.ssh_public_key_path
  vm_image            = var.vm_image
  custom_data_base64  = base64encode(local.app_cloud_init_vm1)
  backend_pool_id     = module.loadbalancer.backend_pool_id
}

# ============================================================
# VM applicative 2
# ============================================================
module "vm_spoke2" {
  source = "./modules/compute"

  vm_name             = "VM-SPOKE-2"
  location            = azurerm_resource_group.rg.location
  rg_name             = azurerm_resource_group.rg.name
  tags                = var.tags
  subnet_id           = module.network.vm2_subnet_id
  vm_size             = var.vm_size
  admin_username      = var.admin_username
  ssh_public_key_path = var.ssh_public_key_path
  vm_image            = var.vm_image
  custom_data_base64  = base64encode(local.app_cloud_init_vm2)
  backend_pool_id     = module.loadbalancer.backend_pool_id
}

# ============================================================
# Cloud-init -noeud de supervision (Prometheus + Grafana)
# ============================================================
locals {
  monitoring_cloud_init = templatefile("${path.module}/cloud-init/monitoring-node.yaml.tpl", {
    grafana_admin_user     = var.grafana_admin_user
    grafana_admin_password = var.grafana_admin_password
    vm1_ip                 = module.vm_spoke1.private_ip
    vm2_ip                 = module.vm_spoke2.private_ip
  })
}

# ============================================================
# VM de supervision -Prometheus + Grafana (dashboard auto-provisionné)
# ============================================================
module "vm_monitoring" {
  source = "./modules/compute"

  vm_name             = "VM-MONITORING"
  location            = azurerm_resource_group.rg.location
  rg_name             = azurerm_resource_group.rg.name
  tags                = var.tags
  subnet_id           = module.network.monitoring_subnet_id
  vm_size             = var.monitoring_vm_size
  admin_username      = var.admin_username
  ssh_public_key_path = var.ssh_public_key_path
  vm_image            = var.vm_image
  custom_data_base64  = base64encode(local.monitoring_cloud_init)
}
```

**Rôle** : c'est le chef d'orchestre. Il crée le Resource Group, puis appelle
dans l'ordre les modules `network` -> `firewall` -> `bastion` ->
`loadbalancer` -> `security` (x3) -> `compute` (x3, dont la VM de
supervision), en reliant les `output` d'un module aux `variable` du suivant.

**Points clés à noter pour le rapport** :
- Les règles NSG sont définies en `locals` (`app_nsg_rules`) puis passées au
  module `security`, instancié une fois par subnet (VM1, VM2, monitoring).
  Cela évite de dupliquer la même liste de règles 2 fois pour VM1 et VM2.
- Le cloud-init de chaque VM applicative est généré par `templatefile()`
  avec un `runner_label` différent (`vm-spoke-1` / `vm-spoke-2`), pour que
  chaque VM enregistre un runner GitHub Actions distinct et identifiable.
- Le cloud-init de la VM de supervision reçoit les IP privées de VM1 et VM2
  (`module.vm_spoke1.private_ip`, `module.vm_spoke2.private_ip`) pour
  pré-configurer les cibles Prometheus **sans intervention manuelle**.

**Pourquoi ce choix** :
- Séparer "orchestration" (ce fichier) et "implémentation" (les modules)
  suit le principe de responsabilité unique : ce fichier répond à la
  question *"que déploie-t-on et dans quel ordre ?"*, les modules répondent
  à *"comment chaque brique est-elle construite ?"*.

---

#### 4.4 `outputs.tf`

```hcl
# ============================================================
# PLG - 2026 / Groupe 24 : ESTIAM - Paris
# outputs.tf -Valeurs exposées après terraform apply
# ============================================================

# ----------------------------
# Load Balancer / Application
# ----------------------------
output "load_balancer_public_ip" {
  description = "IP publique du Load Balancer (point d'entrée web)"
  value       = module.loadbalancer.public_ip
}

output "web_url" {
  description = "URL publique de l'application web"
  value       = "http://${module.loadbalancer.public_ip}"
}

output "lb_health_probe_url" {
  description = "URL de la health probe du Load Balancer"
  value       = "http://${module.loadbalancer.public_ip}/health"
}

# ----------------------------
# Firewall
# ----------------------------
output "firewall_public_ip" {
  value = module.firewall.public_ip
}

output "firewall_private_ip" {
  value = module.firewall.private_ip
}

# ----------------------------
# VMs applicatives
# ----------------------------
output "vm_spoke1_private_ip" {
  value = module.vm_spoke1.private_ip
}

output "vm_spoke2_private_ip" {
  value = module.vm_spoke2.private_ip
}

# ----------------------------
# Supervision
# ----------------------------
output "monitoring_vm_private_ip" {
  description = "IP privée de la VM de supervision (Prometheus/Grafana)"
  value       = module.vm_monitoring.private_ip
}

output "grafana_url" {
  description = "URL Grafana (accessible depuis le CIDR défini par grafana_allowed_source)"
  value       = "http://${module.vm_monitoring.private_ip}:3000"
}

output "prometheus_url" {
  description = "URL Prometheus (accessible depuis le CIDR défini par grafana_allowed_source)"
  value       = "http://${module.vm_monitoring.private_ip}:9090"
}

# ----------------------------
# Bastion
# ----------------------------
output "bastion_name" {
  value = module.bastion.name
}

output "bastion_public_ip" {
  value = module.bastion.public_ip
}

# ----------------------------
# Réseau
# ----------------------------
output "hub_vnet_id" {
  value = module.network.hub_vnet_id
}

output "spoke1_vnet_id" {
  value = module.network.spoke1_vnet_id
}

output "spoke2_vnet_id" {
  value = module.network.spoke2_vnet_id
}

# ----------------------------
# Divers
# ----------------------------
output "resource_group_name" {
  value = azurerm_resource_group.rg.name
}

output "ping_test_vm1_to_vm2" {
  value = "ping ${module.vm_spoke2.private_ip}"
}

output "ping_test_vm2_to_vm1" {
  value = "ping ${module.vm_spoke1.private_ip}"
}
```

**Rôle** : expose après `terraform apply` toutes les informations utiles
pour utiliser l'infrastructure sans avoir à aller les chercher manuellement
dans le portail Azure : IP du Load Balancer, URL Grafana/Prometheus, IPs
privées des VMs, nom du Bastion, etc.

**Pourquoi ce choix** :
- `web_url` et `lb_health_probe_url` sont pré-construits (`http://${ip}`)
  pour pouvoir être testés immédiatement avec `curl` sans reconstruction
  manuelle de l'URL.
- `ping_test_vm1_to_vm2` / `ping_test_vm2_to_vm1` donnent directement la
  commande à taper depuis une VM (via Bastion) pour valider le routage
  inter-spoke à travers le firewall.

---

#### 4.5 `terraform.tfvars.example`

```hcl
# ============================================================
# PLG - 2026 / Groupe 24 : ESTIAM - Paris
# terraform.tfvars.example
# ============================================================

# ----------------------------
# Général
# ----------------------------
rg_name  = "RG-PLG-ESTIAM-Paris-2026"
location = "norwayeast"

# ----------------------------
# Authentification VMs
# ----------------------------
admin_username      = "scripttools_plgEstiam"
ssh_public_key_path = "~/clouddrive/hubspoke_rsa.pub"

# ----------------------------
# Application / GitHub
# ----------------------------
github_repo_url = "https://github.com/dspitech/azure-script-hub-fa365d79.git"
repo_name       = "azure-script-hub-fa365d79"
github_owner    = "dspitech"

# GitHub PAT (scope repo + workflow), utilisé une seule fois au boot de la VM
# pour enregistrer le runner auto-hébergé. A fournir de préférence via :
#   export TF_VAR_github_pat="ghp_xxxxxxxxxxxx"
github_pat = "CHANGE-ME"

# ----------------------------
# Supabase (SECRETS -à ne jamais committer avec de vraies valeurs)
# Astuce : définissez-les plutôt via variables d'environnement :
#   export TF_VAR_supabase_url="https://xxxx.supabase.co"
#   export TF_VAR_supabase_anon_key="sb_publishable_xxx"
#   export TF_VAR_database_url="postgresql://postgres:xxx@db.xxxx.supabase.co:5432/postgres"
# ----------------------------
supabase_url      = "https://CHANGE-ME.supabase.co"
supabase_anon_key = "CHANGE-ME"
database_url      = "postgresql://postgres:CHANGE-ME@db.CHANGE-ME.supabase.co:5432/postgres"

# ----------------------------
# Supervision (Grafana admin password -SECRET)
#   export TF_VAR_grafana_admin_password="un-mot-de-passe-fort"
# ----------------------------
grafana_admin_user     = "admin"
grafana_admin_password = "CHANGE-ME"
grafana_allowed_source = "10.0.0.0/16" # ajoutez votre IP publique en /32 si besoin d'accès direct

# ----------------------------
# Tags
# ----------------------------
tags = {
  Project     = "Deployment-Script-Tools"
  Environment = "Production"
  ManagedBy   = "Terraform"
  Author      = "PLG-Groupe24-ESTIAM-2026"
}
```

**Rôle** : modèle de fichier de configuration. À copier en
`terraform.tfvars` (fichier réel, jamais commité) et à compléter avec les
valeurs **non sensibles** du projet.

**Pourquoi ce choix** :
- Le nom `.example` signale explicitement qu'il ne contient pas de vraies
  valeurs et peut donc être commité sans risque, contrairement à
  `terraform.tfvars` qui est exclu via `.gitignore`.
- Les commentaires rappellent, directement dans le fichier, de passer les
  secrets par variables d'environnement plutôt que de les écrire ici.

---

#### 4.6 `.gitignore`

```text
# Terraform
**/.terraform/*
*.tfstate
*.tfstate.*
crash.log
crash.*.log
*.tfvars
!terraform.tfvars.example
override.tf
override.tf.json
*_override.tf
*_override.tf.json
.terraformrc
terraform.rc
.terraform.lock.hcl

# Secrets locaux
.env
*.pem
*.key
!*.pub
```

**Rôle** : empêche que les fichiers sensibles ou générés (état Terraform,
`terraform.tfvars`, clés privées, `.env`) ne soient commités par erreur dans
Git.

**Pourquoi ce choix** :
- `*.tfstate` : le fichier d'état Terraform contient **en clair** toutes les
  valeurs, y compris les secrets marqués `sensitive` côté variables -il ne
  doit donc jamais partir dans un dépôt Git public ou privé partagé sans
  chiffrement.
- `*.tfvars` avec l'exception `!terraform.tfvars.example` : bloque tous les
  fichiers de variables réels tout en gardant le modèle d'exemple versionné.
- `*.pem` / `*.key` (avec exception `*.pub`) : bloque les clés privées SSH
  tout en autorisant les clés publiques, qui n'ont pas besoin d'être secrètes.

---
### 5. Module `network`

**Rôle général** : crée les 3 VNets (Hub, Spoke1, Spoke2), tous les subnets
(firewall, bastion, VM1, VM2, monitoring, prod) et les peerings bidirectionnels
Hub<->Spoke1 et Hub<->Spoke2.

**Pourquoi les VMs sont dans VnetHub et pas dans les VNets Spoke** : le Load
Balancer Standard d'Azure exige que toutes les NIC de son backend pool soient
dans le **même VNet** que lui. Comme le Load Balancer est une ressource
partagée "hub", les VMs applicatives restent dans `VnetHub` (subnets `SubnetVM1`
/ `SubnetVM2`), tandis que les VNets Spoke1/Spoke2 restent disponibles pour
d'autres charges de travail (bases de données, services internes...) qui,
elles, communiquent via le Firewall.

#### 5.1 `modules/network/variables.tf`

```hcl
variable "rg_name" {
  description = "Nom du Resource Group"
  type        = string
}

variable "location" {
  description = "Région Azure"
  type        = string
}

variable "tags" {
  description = "Tags communs"
  type        = map(string)
}

variable "hub_vnet_name" {
  type = string
}

variable "hub_address_space" {
  type = list(string)
}

variable "spoke1_vnet_name" {
  type = string
}

variable "spoke1_address_space" {
  type = list(string)
}

variable "spoke2_vnet_name" {
  type = string
}

variable "spoke2_address_space" {
  type = list(string)
}

variable "subnet_firewall_prefix" {
  type = string
}

variable "subnet_bastion_prefix" {
  type = string
}

variable "subnet_hub_prod_prefix" {
  type = string
}

variable "subnet_vm1_prefix" {
  type = string
}

variable "subnet_vm2_prefix" {
  type = string
}

variable "subnet_monitoring_prefix" {
  description = "CIDR du subnet hébergeant la VM de supervision (Prometheus/Grafana)"
  type        = string
}

variable "spoke1_prod_prefix" {
  type = string
}

variable "spoke2_prod_prefix" {
  type = string
}
```

**Explication** : toutes les variables sont des chaînes ou listes de chaînes
(noms, CIDR). Aucune valeur par défaut n'est fixée ici : c'est le module
racine (`main.tf`) qui les fournit, ce qui garde le module `network`
totalement indépendant du reste du projet -il pourrait être réutilisé tel
quel dans un autre projet Terraform.

---

#### 5.2 `modules/network/main.tf`

```hcl
# ============================================================
# Module network -VNets, Subnets, Peerings
# ============================================================

resource "azurerm_virtual_network" "hub" {
  name                = var.hub_vnet_name
  address_space       = var.hub_address_space
  location            = var.location
  resource_group_name = var.rg_name
  tags                = var.tags
}

resource "azurerm_virtual_network" "spoke1" {
  name                = var.spoke1_vnet_name
  address_space       = var.spoke1_address_space
  location            = var.location
  resource_group_name = var.rg_name
  tags                = var.tags
}

resource "azurerm_virtual_network" "spoke2" {
  name                = var.spoke2_vnet_name
  address_space       = var.spoke2_address_space
  location            = var.location
  resource_group_name = var.rg_name
  tags                = var.tags
}

# ----- Subnets Hub : services partagés -----
resource "azurerm_subnet" "firewall_subnet" {
  name                 = "AzureFirewallSubnet"
  resource_group_name  = var.rg_name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = [var.subnet_firewall_prefix]
}

resource "azurerm_subnet" "bastion_subnet" {
  name                 = "AzureBastionSubnet"
  resource_group_name  = var.rg_name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = [var.subnet_bastion_prefix]
}

resource "azurerm_subnet" "hub_prod" {
  name                 = "Prod"
  resource_group_name  = var.rg_name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = [var.subnet_hub_prod_prefix]
}

# ----- Subnets Hub : VMs applicatives -----
# NB : les VMs restent dans VnetHub pour respecter la contrainte du
# Load Balancer Standard (toutes les NIC doivent être dans le même VNet).
resource "azurerm_subnet" "hub_vm1" {
  name                 = "SubnetVM1"
  resource_group_name  = var.rg_name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = [var.subnet_vm1_prefix]
}

resource "azurerm_subnet" "hub_vm2" {
  name                 = "SubnetVM2"
  resource_group_name  = var.rg_name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = [var.subnet_vm2_prefix]
}

# ----- Subnet Hub : supervision (Prometheus/Grafana) -----
resource "azurerm_subnet" "hub_monitoring" {
  name                 = "SubnetMonitoring"
  resource_group_name  = var.rg_name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = [var.subnet_monitoring_prefix]
}

# ----- Subnets Spokes -----
resource "azurerm_subnet" "spoke1_prod" {
  name                 = "Prod"
  resource_group_name  = var.rg_name
  virtual_network_name = azurerm_virtual_network.spoke1.name
  address_prefixes     = [var.spoke1_prod_prefix]
}

resource "azurerm_subnet" "spoke2_prod" {
  name                 = "Prod"
  resource_group_name  = var.rg_name
  virtual_network_name = azurerm_virtual_network.spoke2.name
  address_prefixes     = [var.spoke2_prod_prefix]
}

# ----- Peerings Hub <-> Spokes -----
resource "azurerm_virtual_network_peering" "hub_to_spoke1" {
  name                         = "HubToSpoke1"
  resource_group_name          = var.rg_name
  virtual_network_name         = azurerm_virtual_network.hub.name
  remote_virtual_network_id    = azurerm_virtual_network.spoke1.id
  allow_forwarded_traffic      = true
  allow_virtual_network_access = true
}

resource "azurerm_virtual_network_peering" "spoke1_to_hub" {
  name                         = "Spoke1ToHub"
  resource_group_name          = var.rg_name
  virtual_network_name         = azurerm_virtual_network.spoke1.name
  remote_virtual_network_id    = azurerm_virtual_network.hub.id
  allow_forwarded_traffic      = true
  allow_virtual_network_access = true
}

resource "azurerm_virtual_network_peering" "hub_to_spoke2" {
  name                         = "HubToSpoke2"
  resource_group_name          = var.rg_name
  virtual_network_name         = azurerm_virtual_network.hub.name
  remote_virtual_network_id    = azurerm_virtual_network.spoke2.id
  allow_forwarded_traffic      = true
  allow_virtual_network_access = true
}

resource "azurerm_virtual_network_peering" "spoke2_to_hub" {
  name                         = "Spoke2ToHub"
  resource_group_name          = var.rg_name
  virtual_network_name         = azurerm_virtual_network.spoke2.name
  remote_virtual_network_id    = azurerm_virtual_network.hub.id
  allow_forwarded_traffic      = true
  allow_virtual_network_access = true
}
```

**Explication** :
- Les 3 `azurerm_virtual_network` sont créés avec leurs espaces d'adressage
  respectifs (10.0.0.0/16 pour le hub, 192.168.0.0/24 et 172.16.0.0/24 pour
  les spokes -volontairement dans des plages différentes pour ne jamais se
  chevaucher, condition indispensable au peering).
- `AzureFirewallSubnet` et `AzureBastionSubnet` doivent porter **exactement**
  ces noms : ce sont des noms réservés par Azure, sans quoi le Firewall et le
  Bastion refusent de s'y déployer.
- Les 4 `azurerm_virtual_network_peering` établissent la relation dans les
  deux sens (Hub->Spoke ET Spoke->Hub) avec `allow_forwarded_traffic = true`,
  nécessaire pour que le trafic **routé via le Firewall** (donc "forwardé",
  pas originaire direct de la VM) soit accepté à travers le peering.

**Pourquoi un subnet dédié pour la supervision (`SubnetMonitoring`)** : isoler
la VM Prometheus/Grafana dans son propre subnet permet de lui appliquer un NSG
spécifique (voir module `security`) sans toucher aux règles des VMs
applicatives, et de raisonner plus simplement en "un rôle = un subnet = un
NSG".

---

#### 5.3 `modules/network/outputs.tf`

```hcl
output "hub_vnet_id" {
  value = azurerm_virtual_network.hub.id
}

output "hub_vnet_name" {
  value = azurerm_virtual_network.hub.name
}

output "spoke1_vnet_id" {
  value = azurerm_virtual_network.spoke1.id
}

output "spoke2_vnet_id" {
  value = azurerm_virtual_network.spoke2.id
}

output "firewall_subnet_id" {
  value = azurerm_subnet.firewall_subnet.id
}

output "bastion_subnet_id" {
  value = azurerm_subnet.bastion_subnet.id
}

output "hub_prod_subnet_id" {
  value = azurerm_subnet.hub_prod.id
}

output "vm1_subnet_id" {
  value = azurerm_subnet.hub_vm1.id
}

output "vm2_subnet_id" {
  value = azurerm_subnet.hub_vm2.id
}

output "monitoring_subnet_id" {
  value = azurerm_subnet.hub_monitoring.id
}

output "spoke1_prod_subnet_id" {
  value = azurerm_subnet.spoke1_prod.id
}

output "spoke2_prod_subnet_id" {
  value = azurerm_subnet.spoke2_prod.id
}
```

**Explication** : ce module n'expose que des **IDs** (jamais de ressources
entières), qui sont ensuite consommés par les autres modules
(`firewall_subnet_id` par le module `firewall`, `vm1_subnet_id` par le module
`compute`, etc.). C'est le seul point de couplage entre `network` et le reste
du projet -un contrat d'interface clair et minimal.

---

### 6. Module `security`

**Rôle général** : module **générique** de Network Security Group (NSG). Il
ne connaît aucune règle "en dur" : la liste des règles lui est passée en
paramètre (`security_rules`), ce qui permet de l'instancier 3 fois dans
`main.tf` (VM1, VM2, monitoring) avec des règles différentes sans dupliquer
de code Terraform.

#### 6.1 `modules/security/variables.tf`

```hcl
variable "name" {
  description = "Nom du NSG"
  type        = string
}

variable "location" {
  type = string
}

variable "rg_name" {
  type = string
}

variable "tags" {
  type = map(string)
}

variable "subnet_id" {
  description = "Subnet auquel associer ce NSG"
  type        = string
}

variable "security_rules" {
  description = "Liste des règles de sécurité du NSG"
  type = list(object({
    name                       = string
    priority                   = number
    direction                  = string
    access                     = string
    protocol                   = string
    source_port_range          = string
    destination_port_range    = optional(string)
    destination_port_ranges   = optional(list(string))
    source_address_prefix     = optional(string)
    source_address_prefixes   = optional(list(string))
    destination_address_prefix = string
  }))
  default = []
}
```

**Explication** : `security_rules` est typé comme une liste d'objets avec des
champs `optional(...)`, ce qui permet à un même appelant de définir soit
`destination_port_range` (un seul port), soit `destination_port_ranges`
(plusieurs ports), soit `source_address_prefix` (une seule source), soit
`source_address_prefixes` (plusieurs sources), sans avoir à remplir tous les
champs à chaque fois.

---

#### 6.2 `modules/security/main.tf`

```hcl
# ============================================================
# Module security -NSG générique + association au subnet
# ============================================================

resource "azurerm_network_security_group" "this" {
  name                = var.name
  location            = var.location
  resource_group_name = var.rg_name
  tags                = var.tags

  dynamic "security_rule" {
    for_each = var.security_rules
    content {
      name                        = security_rule.value.name
      priority                    = security_rule.value.priority
      direction                   = security_rule.value.direction
      access                      = security_rule.value.access
      protocol                    = security_rule.value.protocol
      source_port_range           = security_rule.value.source_port_range
      destination_port_range      = try(security_rule.value.destination_port_range, null)
      destination_port_ranges     = try(security_rule.value.destination_port_ranges, null)
      source_address_prefix       = try(security_rule.value.source_address_prefix, null)
      source_address_prefixes     = try(security_rule.value.source_address_prefixes, null)
      destination_address_prefix  = security_rule.value.destination_address_prefix
    }
  }
}

resource "azurerm_subnet_network_security_group_association" "this" {
  subnet_id                 = var.subnet_id
  network_security_group_id = azurerm_network_security_group.this.id
}
```

**Explication** : le bloc `dynamic "security_rule"` génère une règle NSG par
élément de la liste `var.security_rules` -c'est ce qui rend le module
générique : le nombre et le contenu des règles ne sont pas fixés dans le
module, mais décidés par celui qui l'appelle (ici, le `main.tf` racine, via
`local.app_nsg_rules` pour VM1/VM2 et une liste dédiée pour la supervision).
L'association `azurerm_subnet_network_security_group_association` relie
ensuite ce NSG au subnet cible.

**Pourquoi ce choix plutôt qu'un NSG "en dur" par VM** : sans généricité,
chaque nouvelle VM (ou modification d'une règle commune) obligerait à
copier-coller un bloc de règles NSG complet. Ici, faire évoluer les règles
communes à VM1 et VM2 se fait à un seul endroit (`local.app_nsg_rules` dans
`main.tf`).

---

#### 6.3 `modules/security/outputs.tf`

```hcl
output "nsg_id" {
  value = azurerm_network_security_group.this.id
}

output "nsg_name" {
  value = azurerm_network_security_group.this.name
}
```

**Explication** : expose l'ID et le nom du NSG créé, utile si un autre module
avait besoin de l'associer ailleurs (non utilisé actuellement, mais garde le
module réutilisable dans d'autres contextes).

---
### 7. Module `firewall`

**Rôle général** : déploie l'Azure Firewall, une règle réseau autorisant le
trafic ICMP (ping) entre Spoke1 et Spoke2, ainsi que les tables de routage
(UDR) qui forcent ce trafic inter-spoke à transiter par le firewall.

#### 7.1 `modules/firewall/variables.tf`

```hcl
variable "name" {
  type = string
}

variable "location" {
  type = string
}

variable "rg_name" {
  type = string
}

variable "tags" {
  type = map(string)
}

variable "firewall_subnet_id" {
  type = string
}

variable "spoke1_prod_prefix" {
  type = string
}

variable "spoke2_prod_prefix" {
  type = string
}

variable "spoke1_prod_subnet_id" {
  type = string
}

variable "spoke2_prod_subnet_id" {
  type = string
}
```

**Explication** : le module a besoin à la fois des préfixes CIDR (pour écrire
les règles de filtrage et les routes) et des IDs de subnet (pour associer les
tables de routage) -d'où la présence des deux formats pour Spoke1 et Spoke2.

---

#### 7.2 `modules/firewall/main.tf`

```hcl
# ============================================================
# Module firewall -Azure Firewall + règles + tables de routage
# ============================================================

resource "azurerm_public_ip" "fw_pip" {
  name                = "IP-${var.name}"
  location            = var.location
  resource_group_name = var.rg_name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

resource "azurerm_firewall" "this" {
  name                = var.name
  location            = var.location
  resource_group_name = var.rg_name
  sku_name            = "AZFW_VNet"
  sku_tier            = "Standard"
  tags                = var.tags

  ip_configuration {
    name                 = "FW-Config"
    subnet_id            = var.firewall_subnet_id
    public_ip_address_id = azurerm_public_ip.fw_pip.id
  }
}

resource "azurerm_firewall_network_rule_collection" "inter_spoke" {
  name                = "Allow-InterSpoke"
  azure_firewall_name = azurerm_firewall.this.name
  resource_group_name = var.rg_name
  priority            = 100
  action              = "Allow"

  rule {
    name                  = "Spoke1-to-Spoke2-Ping"
    protocols             = ["ICMP"]
    source_addresses      = [var.spoke1_prod_prefix]
    destination_addresses = [var.spoke2_prod_prefix]
    destination_ports     = ["*"]
  }

  rule {
    name                  = "Spoke2-to-Spoke1-Ping"
    protocols             = ["ICMP"]
    source_addresses      = [var.spoke2_prod_prefix]
    destination_addresses = [var.spoke1_prod_prefix]
    destination_ports     = ["*"]
  }
}

# ----- Tables de routage (UDR) : forcent le trafic inter-spoke via le firewall -----
resource "azurerm_route_table" "udr_spoke1" {
  name                = "UdrSpoke1"
  location            = var.location
  resource_group_name = var.rg_name
  tags                = var.tags

  route {
    name                   = "To-Spoke2"
    address_prefix         = var.spoke2_prod_prefix
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = azurerm_firewall.this.ip_configuration[0].private_ip_address
  }
}

resource "azurerm_route_table" "udr_spoke2" {
  name                = "UdrSpoke2"
  location            = var.location
  resource_group_name = var.rg_name
  tags                = var.tags

  route {
    name                   = "To-Spoke1"
    address_prefix         = var.spoke1_prod_prefix
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = azurerm_firewall.this.ip_configuration[0].private_ip_address
  }
}

resource "azurerm_subnet_route_table_association" "udr_spoke1_assoc" {
  subnet_id      = var.spoke1_prod_subnet_id
  route_table_id = azurerm_route_table.udr_spoke1.id
}

resource "azurerm_subnet_route_table_association" "udr_spoke2_assoc" {
  subnet_id      = var.spoke2_prod_subnet_id
  route_table_id = azurerm_route_table.udr_spoke2.id
}
```

**Explication** :
- `azurerm_firewall_network_rule_collection` : autorise explicitement le
  ping (`ICMP`) dans les deux sens entre les plages Spoke1 et Spoke2. Sans
  cette règle, le firewall bloque par défaut tout trafic non explicitement
  autorisé (politique "deny by default").
- `azurerm_route_table` (une par spoke) : chaque table contient une route
  vers l'autre spoke avec `next_hop_type = "VirtualAppliance"` et
  `next_hop_in_ip_address` pointant vers l'**IP privée du firewall**
  (`azurerm_firewall.this.ip_configuration[0].private_ip_address`). C'est ce
  qui force concrètement le trafic Spoke1->Spoke2 (et inversement) à passer
  par le firewall plutôt que par un chemin réseau direct.
- Les associations `azurerm_subnet_route_table_association` appliquent
  chaque table au bon subnet.

**Pourquoi regrouper firewall + routage dans le même module (et pas un
module `routing` séparé)** : la table de routage d'un spoke n'a de sens
qu'en présence du firewall (elle référence son IP privée) -les garder
ensemble évite une dépendance circulaire entre deux modules distincts tout
en gardant la logique "tout ce qui concerne le filtrage inter-spoke" au même
endroit.

---

#### 7.3 `modules/firewall/outputs.tf`

```hcl
output "public_ip" {
  value = azurerm_public_ip.fw_pip.ip_address
}

output "private_ip" {
  value = azurerm_firewall.this.ip_configuration[0].private_ip_address
}

output "firewall_name" {
  value = azurerm_firewall.this.name
}
```

**Explication** : expose l'IP publique (utile pour du NAT sortant si
nécessaire), l'IP privée (utilisée ailleurs si d'autres routes devaient être
ajoutées) et le nom du firewall.

---

### 8. Module `bastion`

**Rôle général** : déploie Azure Bastion, qui permet de se connecter en SSH
aux VMs **depuis le portail Azure**, sans jamais exposer le port 22 sur
Internet ni donner d'IP publique aux VMs.

#### 8.1 `modules/bastion/variables.tf`

```hcl
variable "name" {
  type    = string
  default = "AzureBastion"
}

variable "location" {
  type = string
}

variable "rg_name" {
  type = string
}

variable "tags" {
  type = map(string)
}

variable "bastion_subnet_id" {
  type = string
}
```

**Explication** : variables minimalistes -un nom, un emplacement, et l'ID
du subnet `AzureBastionSubnet` créé par le module `network`.

---

#### 8.2 `modules/bastion/main.tf`

```hcl
# ============================================================
# Module bastion -Azure Bastion (accès SSH/RDP sécurisé, sans IP publique sur les VMs)
# ============================================================

resource "azurerm_public_ip" "bastion_pip" {
  name                = "IP-Bastion"
  location            = var.location
  resource_group_name = var.rg_name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

resource "azurerm_bastion_host" "this" {
  name                = var.name
  location            = var.location
  resource_group_name = var.rg_name
  tags                = var.tags

  ip_configuration {
    name                 = "Bastion-Config"
    subnet_id            = var.bastion_subnet_id
    public_ip_address_id = azurerm_public_ip.bastion_pip.id
  }
}
```

**Explication** : Azure Bastion a besoin de sa propre IP publique
(`azurerm_public_ip.bastion_pip`, SKU Standard obligatoire) mais celle-ci ne
sert qu'à Bastion lui-même -jamais les VMs ne sont exposées directement.
L'administrateur se connecte au portail Azure (HTTPS, authentifié par son
compte Azure AD/Entra ID), et c'est Bastion qui relaie la session SSH vers la
VM en interne.

**Pourquoi ce choix plutôt qu'une IP publique + NSG restrictif sur chaque
VM** : même avec un NSG limitant le SSH à une IP source précise, une IP
publique reste une IP publique (scannable, ciblable). Bastion supprime
totalement cette surface d'attaque et centralise l'accès admin avec les logs
d'audit du portail Azure.

---

#### 8.3 `modules/bastion/outputs.tf`

```hcl
output "name" {
  value = azurerm_bastion_host.this.name
}

output "public_ip" {
  value = azurerm_public_ip.bastion_pip.ip_address
}
```

**Explication** : expose le nom du Bastion (pour le retrouver facilement dans
le portail) et son IP publique (informative uniquement).

---

### 9. Module `loadbalancer`

**Rôle général** : déploie un Load Balancer Standard avec une IP publique,
un backend pool, une health probe HTTP sur `/health`, et deux règles
d'équilibrage (port 80 et port 443).

#### 9.1 `modules/loadbalancer/variables.tf`

```hcl
variable "name" {
  type = string
}

variable "location" {
  type = string
}

variable "rg_name" {
  type = string
}

variable "tags" {
  type = map(string)
}

variable "probe_interval" {
  type    = number
  default = 15
}

variable "probe_count" {
  type    = number
  default = 2
}
```

**Explication** : `probe_interval` et `probe_count` sont paramétrables
(par défaut 15 secondes / 2 échecs) pour ajuster la réactivité de la
détection de panne sans modifier le code du module.

---

#### 9.2 `modules/loadbalancer/main.tf`

```hcl
# ============================================================
# Module loadbalancer -Azure Load Balancer Standard (HTTP/HTTPS)
# ============================================================

resource "azurerm_public_ip" "lb_pip" {
  name                = "IP-LoadBalancer"
  location            = var.location
  resource_group_name = var.rg_name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

resource "azurerm_lb" "this" {
  name                = var.name
  location            = var.location
  resource_group_name = var.rg_name
  sku                 = "Standard"
  tags                = var.tags

  frontend_ip_configuration {
    name                 = "FrontEnd"
    public_ip_address_id = azurerm_public_ip.lb_pip.id
  }
}

resource "azurerm_lb_backend_address_pool" "backend_pool" {
  name            = "BackEndPool"
  loadbalancer_id = azurerm_lb.this.id
}

resource "azurerm_lb_probe" "http_probe" {
  name                = "HttpProbe"
  loadbalancer_id     = azurerm_lb.this.id
  protocol            = "Http"
  port                = 80
  request_path        = "/health"
  interval_in_seconds = var.probe_interval
  number_of_probes    = var.probe_count
}

resource "azurerm_lb_rule" "lb_rule_http" {
  name                           = "LBRuleHTTP"
  loadbalancer_id                = azurerm_lb.this.id
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "FrontEnd"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.backend_pool.id]
  probe_id                       = azurerm_lb_probe.http_probe.id
  enable_floating_ip             = false
  idle_timeout_in_minutes        = 4
}

resource "azurerm_lb_rule" "lb_rule_https" {
  name                           = "LBRuleHTTPS"
  loadbalancer_id                = azurerm_lb.this.id
  protocol                       = "Tcp"
  frontend_port                  = 443
  backend_port                   = 443
  frontend_ip_configuration_name = "FrontEnd"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.backend_pool.id]
  probe_id                       = azurerm_lb_probe.http_probe.id
  enable_floating_ip             = false
  idle_timeout_in_minutes        = 4
}
```

**Explication** :
- `azurerm_lb_probe` interroge `GET /health` sur chaque VM du backend pool.
  C'est précisément la route exposée par Nginx dans le cloud-init des VMs
  applicatives (`location /health { return 200 'OK'; }`) -si une VM ne
  répond pas, le Load Balancer cesse de lui envoyer du trafic automatiquement.
- Deux `azurerm_lb_rule` distinctes (HTTP 80, HTTPS 443) pointent vers le
  même backend pool, avec la même probe.

**Pourquoi une health probe applicative (`/health`) plutôt qu'une probe TCP
simple** : une probe TCP vérifierait seulement que le port 80 accepte une
connexion, même si Nginx tourne mais que l'application Node.js derrière est
plantée. La probe HTTP `/health` garantit que la VM sert réellement une
réponse applicative valide.

---

#### 9.3 `modules/loadbalancer/outputs.tf`

```hcl
output "public_ip" {
  value = azurerm_public_ip.lb_pip.ip_address
}

output "backend_pool_id" {
  value = azurerm_lb_backend_address_pool.backend_pool.id
}
```

**Explication** : `backend_pool_id` est l'output le plus important du module
-c'est lui que le module `compute` utilise pour rattacher chaque VM au Load
Balancer.

---

### 10. Module `compute`

**Rôle général** : module **générique** de VM Linux. Il est instancié 3 fois
dans `main.tf` : `VM-SPOKE-1`, `VM-SPOKE-2` (avec `backend_pool_id` renseigné)
et `VM-MONITORING` (sans backend pool, puisqu'elle n'est pas derrière le Load
Balancer).

#### 10.1 `modules/compute/variables.tf`

```hcl
variable "vm_name" {
  type = string
}

variable "location" {
  type = string
}

variable "rg_name" {
  type = string
}

variable "tags" {
  type = map(string)
}

variable "subnet_id" {
  type = string
}

variable "vm_size" {
  type = string
}

variable "admin_username" {
  type = string
}

variable "ssh_public_key_path" {
  type = string
}

variable "vm_image" {
  type = object({
    publisher = string
    offer     = string
    sku       = string
    version   = string
  })
}

variable "custom_data_base64" {
  description = "cloud-init déjà encodé en base64"
  type        = string
}

variable "os_disk_type" {
  type    = string
  default = "Premium_LRS"
}

variable "os_disk_size_gb" {
  type    = number
  default = null
}

variable "backend_pool_id" {
  description = "ID du backend pool du Load Balancer à associer (optionnel)"
  type        = string
  default     = null
}

variable "private_ip_address" {
  description = "IP privée statique (optionnel, sinon Dynamic)"
  type        = string
  default     = null
}
```

**Explication** : `backend_pool_id` et `private_ip_address` ont une valeur
par défaut `null` -c'est ce qui permet de réutiliser le **même module** pour
une VM applicative (avec backend pool) et pour la VM de supervision (sans
backend pool), sans avoir à écrire deux modules quasi identiques.

---

#### 10.2 `modules/compute/main.tf`

```hcl
# ============================================================
# Module compute -NIC + VM Linux réutilisable (app ou supervision)
# ============================================================

resource "azurerm_network_interface" "this" {
  name                = "${var.vm_name}-nic"
  location            = var.location
  resource_group_name = var.rg_name
  tags                = var.tags

  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = var.private_ip_address != null ? "Static" : "Dynamic"
    private_ip_address            = var.private_ip_address
  }
}

resource "azurerm_network_interface_backend_address_pool_association" "this" {
  count                   = var.backend_pool_id != null ? 1 : 0
  network_interface_id    = azurerm_network_interface.this.id
  ip_configuration_name   = "internal"
  backend_address_pool_id = var.backend_pool_id
}

resource "azurerm_linux_virtual_machine" "this" {
  name                = var.vm_name
  resource_group_name = var.rg_name
  location            = var.location
  size                = var.vm_size
  admin_username      = var.admin_username
  tags                = var.tags

  network_interface_ids = [azurerm_network_interface.this.id]

  admin_ssh_key {
    username   = var.admin_username
    public_key = file(var.ssh_public_key_path)
  }

  custom_data = var.custom_data_base64

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = var.os_disk_type
    disk_size_gb         = var.os_disk_size_gb
  }

  source_image_reference {
    publisher = var.vm_image.publisher
    offer     = var.vm_image.offer
    sku       = var.vm_image.sku
    version   = var.vm_image.version
  }
}
```

**Explication** :
- La NIC (`azurerm_network_interface`) est créée avec une IP privée
  `Dynamic` par défaut, ou `Static` si `private_ip_address` est fourni.
- L'association au backend pool (`azurerm_network_interface_backend_address_pool_association`)
  utilise `count = var.backend_pool_id != null ? 1 : 0` : elle n'est créée
  **que si** un backend pool est passé en paramètre -c'est ce mécanisme qui
  rend le module utilisable aussi bien pour les VMs applicatives (derrière le
  LB) que pour la VM de supervision (pas derrière le LB).
- `admin_ssh_key` avec `file(var.ssh_public_key_path)` : l'authentification
  se fait uniquement par clé SSH (aucun mot de passe), lu depuis le fichier
  local indiqué dans `terraform.tfvars`.
- `custom_data` reçoit le cloud-init **déjà encodé en base64** (format
  attendu par Azure) -l'encodage est fait dans `main.tf` racine
  (`base64encode(local.app_cloud_init_vm1)`), pas dans ce module, pour que le
  module reste agnostique du contenu du cloud-init.

**Pourquoi un seul module `compute` plutôt qu'un module par rôle
(`app-vm`, `monitoring-vm`)** : la VM applicative et la VM de supervision
sont structurellement identiques (une NIC + une VM Linux) ; seul le
**contenu du cloud-init** et la présence ou non d'un backend pool changent.
Dupliquer le module aurait signifié maintenir deux fois le même code pour
une différence purement paramétrique.

---

#### 10.3 `modules/compute/outputs.tf`

```hcl
output "private_ip" {
  value = azurerm_network_interface.this.private_ip_address
}

output "vm_id" {
  value = azurerm_linux_virtual_machine.this.id
}

output "vm_name" {
  value = azurerm_linux_virtual_machine.this.name
}
```

**Explication** : `private_ip` est l'output le plus utilisé ailleurs dans le
projet -c'est lui qui permet à `main.tf` de transmettre les IPs de VM1 et
VM2 au cloud-init de la VM de supervision, afin que Prometheus sache
immédiatement où trouver les `node_exporter` à interroger, sans aucune
configuration manuelle après le déploiement.

---
### 11. Cloud-init : provisioning automatique des VMs

Le cloud-init est le mécanisme standard Azure/cloud-init qui exécute un
script de configuration **au tout premier démarrage** d'une VM. Il remplace
ici toutes les commandes manuelles (`ssh` puis taper des commandes une par
une) par un fichier déclaratif exécuté automatiquement. Ces fichiers sont des
**templates** (`.tpl`) : les `${...}` sont remplacés par Terraform
(`templatefile()`) avec les vraies valeurs avant d'être envoyés à la VM.

#### 11.1 `cloud-init/app-node.yaml.tpl` (VM-SPOKE-1 et VM-SPOKE-2)

```yaml
#cloud-config

# ==============================================================================================
# PLG - 2026 / Groupe 24 : ESTIAM - Paris
# cloud-init.yaml -Noeud applicatif (Node.js + Nginx + monitoring agent)
# Généré depuis un template Terraform (templatefile) -modifier cloud-init/app-node.yaml.tpl
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
```

**Explication section par section** :

| Section | Rôle |
|---|---|
| `packages` | Paquets systèmes de base (git, outils réseau, nginx, ufw, fail2ban...) |
| Docker, Node.js, npm globaux, Python, Azure CLI, GitHub CLI, Supabase CLI, Terraform | Outillage complet pour développer/debugger directement sur la VM si besoin (via Bastion) |
| `node_exporter` | Agent qui expose les métriques système (CPU/RAM/disque/réseau) sur le port 9100, interrogé par Prometheus |
| Fichier `app.env` | Écrit les secrets applicatifs (Supabase) **une seule fois**, avec des permissions `600` (lecture propriétaire uniquement) |
| Clone + build + PM2 | Clone le dépôt, installe les dépendances, build, puis démarre l'app avec `serve` sous PM2 |
| Runner GitHub Actions | S'enregistre automatiquement auprès de GitHub via l'API (`registration-token`), avec un label unique (`vm-spoke-1` ou `vm-spoke-2`) passé par Terraform |
| Nginx | Reverse-proxy `80 -> 3000`, et sert la route `/health` utilisée par la probe du Load Balancer |
| `ufw` | Pare-feu local, redondant avec les NSG Azure mais bonne pratique de "defense in depth" |
| `fail2ban` | Bannit automatiquement les IP qui multiplient les tentatives de connexion échouées |

**Pourquoi un cloud-init plutôt qu'un script exécuté manuellement après
coup** : le cloud-init s'exécute **avant** que quiconque puisse se connecter
à la VM -l'application et le monitoring sont donc opérationnels dès la fin
du `terraform apply`, sans étape manuelle oubliable, et le processus est
**reproductible** à l'identique sur une nouvelle VM en cas de recréation.

**Pourquoi enregistrer un runner GitHub Actions plutôt qu'ouvrir SSH pour le
CI/CD** : les VMs applicatives n'ayant pas d'IP publique (SSH uniquement via
Bastion), un système CI/CD classique (connexion SSH depuis GitHub) n'est pas
possible sans exposer un port. Le runner auto-hébergé résout ce problème en
**allant chercher le travail sur GitHub** (connexion sortante uniquement) -
aucune ouverture de port entrant n'est nécessaire.

---

#### 11.2 `cloud-init/monitoring-node.yaml.tpl` (VM-MONITORING)

```yaml
#cloud-config

# ==============================================================================================
# PLG - 2026 / Groupe 24 : ESTIAM - Paris
# cloud-init.yaml -Noeud de supervision (Prometheus + Grafana, provisionnés automatiquement)
# Généré depuis un template Terraform (templatefile) -modifier cloud-init/monitoring-node.yaml.tpl
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
```

**Explication section par section** :

| Fichier généré (`write_files`) | Rôle |
|---|---|
| `docker-compose.yml` | Définit les 2 conteneurs `prometheus` et `grafana`, avec volumes persistants |
| `prometheus/prometheus.yml` | Cible directement `${vm1_ip}:9100` et `${vm2_ip}:9100` -ces IPs sont **injectées par Terraform**, calculées après création des VMs applicatives |
| `grafana/provisioning/datasources/datasource.yml` | Déclare Prometheus comme datasource par défaut dans Grafana, **sans avoir à le faire manuellement dans l'UI** |
| `grafana/provisioning/dashboards/dashboards.yml` | Indique à Grafana de charger automatiquement tout dashboard JSON présent dans `/var/lib/grafana/dashboards` |
| `grafana/dashboards/hub-spoke-overview.json` | Le dashboard lui-même (voir section 12) |

**Pourquoi `docker-compose` plutôt qu'une installation "nue" de Prometheus et
Grafana** : les images officielles `prom/prometheus` et
`grafana/grafana-oss` sont maintenues à jour par leurs éditeurs, isolées du
reste du système (pas de conflit de dépendances), et permettent une mise à
jour ou un redémarrage propre (`docker compose restart`) sans toucher au
système d'exploitation de la VM.

**Pourquoi le mot de passe Grafana passe par une variable Terraform
(`grafana_admin_password`)** : il est injecté directement dans la variable
d'environnement `GF_SECURITY_ADMIN_PASSWORD` du conteneur au démarrage -cela
évite d'avoir un mot de passe par défaut ("admin/admin") qu'il faudrait
penser à changer manuellement après coup.

---

### 12. Supervision : dashboard Grafana

#### 12.1 `monitoring/grafana/dashboards/hub-spoke-overview.json`

```json
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
```

**Explication des 7 panels** :

| Panel | Métrique Prometheus (PromQL) | Ce qu'il montre |
|---|---|---|
| Utilisation CPU (%) | `100 - (avg by (instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)` | Charge CPU par VM, calculée à partir du temps "idle" inversé |
| Mémoire utilisée (%) | `100 * (1 - (MemAvailable / MemTotal))` | Pourcentage de RAM réellement utilisée par VM |
| Espace disque utilisé (%) | `100 - (avail*100/size)` sur les filesystems réels (hors `tmpfs`/`overlay`) | Alerte visuelle avant saturation disque |
| Trafic réseau (octets/s) | `rate(node_network_receive/transmit_bytes_total[5m])` | Débit entrant/sortant par interface et par VM |
| Instances UP | `count(up{job="node_exporter"} == 1)` | Nombre de VMs actuellement joignables par Prometheus |
| Uptime moyen | `(node_time_seconds - node_boot_time_seconds) / 3600` | Depuis combien de temps les VMs tournent, en heures |
| Load average (1m) | `avg(node_load1)` | Charge système moyenne sur la dernière minute |

**Pourquoi un dashboard "maison" plutôt qu'un import du dashboard communautaire
"Node Exporter Full" (ID 1860)** : ce dashboard officiel fait plus de 3000
lignes de JSON avec des dizaines de panels ; pour un rapport de 2 VMs, un
dashboard de 7 panels ciblés (CPU/RAM/disque/réseau/disponibilité) est plus
lisible et plus facile à commenter/justifier dans un rapport que d'expliquer
un dashboard tiers non maîtrisé.

**Pourquoi le provisioning automatique plutôt qu'un import manuel** : le
fichier JSON est copié par cloud-init dans
`/opt/monitoring/grafana/dashboards/`, monté dans le conteneur Grafana, et
chargé automatiquement grâce au provider défini dans `dashboards.yml`
(section 11.2) -le dashboard est donc visible **dès la première connexion**
à Grafana, sans étape manuelle "Import dashboard" à réaliser après coup.

---
### 13. CI/CD : pipeline GitHub Actions

Ces deux fichiers ne vivent pas dans ce dépôt Terraform : ils sont préparés
dans `github-actions-for-app-repo/` pour être **copiés dans le dépôt de
l'application** (`azure-script-hub-fa365d79`), puisque c'est ce dépôt qui
doit déclencher le déploiement à chaque `push`.

#### 13.1 `.github/workflows/deploy.yml`

```yaml
# ============================================================
# PLG - 2026 / Groupe 24 : ESTIAM - Paris
# .github/workflows/deploy.yml
# À copier dans le dépôt de l'application (azure-script-hub-fa365d79)
#
# Fonctionnement :
# - Déclenché à chaque push sur "main"
# - Les deux VMs (VM-SPOKE-1 / VM-SPOKE-2) exécutent chacune un runner
#   GitHub Actions auto-hébergé (installé par cloud-init), identifié
#   par le label "vm-spoke-1" / "vm-spoke-2"
# - Aucune ouverture de port SSH entrant n'est nécessaire : le runner
#   va chercher le travail sur GitHub (connexion sortante uniquement)
# - Le déploiement se fait un noeud après l'autre (rolling deploy) pour
#   garder le site disponible via le Load Balancer pendant la mise à jour
# ============================================================

name: Deploy Web App

on:
  push:
    branches: [main]
  workflow_dispatch: {}

concurrency:
  group: deploy-production
  cancel-in-progress: false

jobs:
  deploy-vm1:
    name: Déploiement VM-SPOKE-1
    runs-on: [self-hosted, vm-spoke-1]
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Déployer l'application
        run: bash scripts/deploy.sh

      - name: Vérifier la santé locale (nginx / health)
        run: curl -f http://localhost/health

  deploy-vm2:
    name: Déploiement VM-SPOKE-2
    needs: deploy-vm1
    runs-on: [self-hosted, vm-spoke-2]
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Déployer l'application
        run: bash scripts/deploy.sh

      - name: Vérifier la santé locale (nginx / health)
        run: curl -f http://localhost/health
```

**Explication** :
- `on: push: branches: [main]` : déclenche le workflow à chaque push sur
  `main` (et manuellement via `workflow_dispatch` si besoin de rejouer un
  déploiement sans nouveau commit).
- `concurrency` : empêche deux déploiements de tourner en même temps si
  plusieurs push arrivent rapprochés (le second attend la fin du premier).
- Deux jobs, `deploy-vm1` et `deploy-vm2`, chacun ciblé sur un runner précis
  via ses labels (`[self-hosted, vm-spoke-1]` / `[self-hosted, vm-spoke-2]`)
  -ce sont exactement les labels enregistrés par le cloud-init (section 11.1).
- `deploy-vm2` a `needs: deploy-vm1` : **VM2 n'est mise à jour que si VM1 a
  réussi**, avec vérification `curl -f http://localhost/health` avant de
  passer à la suite.

**Pourquoi un déploiement séquentiel (rolling deploy) plutôt que simultané**
: si les deux VMs étaient mises à jour en même temps et que le nouveau code
contient un bug bloquant, le site entier tomberait. En séquentiel, VM2 reste
disponible pendant la mise à jour de VM1 (et inversement), et si VM1 échoue
sa vérification `/health`, VM2 n'est jamais touchée -le site reste
disponible sur l'ancienne version.

---

#### 13.2 `scripts/deploy.sh`

```bash
#!/usr/bin/env bash
# ============================================================
# PLG - 2026 / Groupe 24 : ESTIAM - Paris
# scripts/deploy.sh dans le dépôt de l'applicationdans le dépôt de l'application
# ============================================================
set -euo pipefail

REPO_NAME="$(basename "$(git rev-parse --show-toplevel)")"
APP_DIR="$HOME/projects/$REPO_NAME"
ENV_FILE="$HOME/projects/app.env"

echo "==> Déploiement de $REPO_NAME vers $APP_DIR"

# Le fichier d'environnement persistant (créé une fois par cloud-init, jamais
# committé dans Git) est copié dans le workspace AVANT le build, car les
# variables VITE_*/NEXT_PUBLIC_* sont injectées au moment du build, pas au runtime.
if [ -f "$ENV_FILE" ]; then
  cp -f "$ENV_FILE" .env
else
  echo "ATTENTION : $ENV_FILE introuvable, build sans variables d'environnement."
fi

npm ci --legacy-peer-deps
npm run build

mkdir -p "$APP_DIR"
rsync -a --delete dist/ "$APP_DIR/dist/"

cd "$APP_DIR"

# Redémarrage sans coupure si le process existe déjà, sinon premier démarrage
if pm2 describe webapp > /dev/null 2>&1; then
  pm2 reload webapp
else
  pm2 start "$(which serve)" --name "webapp" -- -s dist -l 3000
fi

pm2 save

echo "==> Déploiement terminé avec succès."
```

**Explication** :
- Le fichier `$HOME/projects/app.env` (créé une seule fois par le cloud-init,
  jamais commité dans Git) est copié en `.env` **avant** le build : c'est
  nécessaire car les variables `VITE_*`/`NEXT_PUBLIC_*` (Supabase côté
  frontend) sont injectées **au moment du build**, pas au runtime -les
  copier après le build n'aurait aucun effet.
- `npm ci` (plutôt que `npm install`) : installe exactement les versions du
  `package-lock.json`, garantissant un build reproductible et plus rapide
  en CI.
- `rsync -a --delete` : synchronise le dossier `dist/` du build vers le
  dossier réellement servi par PM2, en supprimant les anciens fichiers qui
  n'existent plus dans le nouveau build.
- `pm2 reload webapp` (plutôt que `pm2 restart`) : `reload` redémarre
  l'application **sans temps d'arrêt** (zero-downtime reload), alors que
  `restart` couperait brièvement le service.

**Pourquoi ce script est séparé du workflow YAML** : le garder dans un
fichier `.sh` dédié permet de le tester manuellement en SSH (via Bastion)
sans avoir à déclencher tout le pipeline GitHub Actions, et de le réutiliser
si un jour un autre déclencheur (webhook, cron) devait appeler le même
déploiement.

---

### 14. Synthèse des choix d'architecture

Cette section résume, pour le rapport, les décisions structurantes et leur
justification :

| Choix | Alternative rejetée | Justification |
|---|---|---|
| Modules Terraform séparés (`network`, `security`, `firewall`, `bastion`, `loadbalancer`, `compute`) | Un seul fichier `main.tf` monolithique | Réutilisabilité, lisibilité, isolation des responsabilités |
| NSG paramétrable (module `security`) instancié 3 fois | Un NSG "en dur" copié-collé par VM | Un seul endroit à modifier pour changer une règle commune |
| Suppression des règles `source = "*"` sur les ports de debug | Garder l'exposition initiale (3000/3001/5432/8080/8443/54321 ouverts à tout Internet) | Réduction drastique de la surface d'attaque ; ces ports ne servent qu'en interne (Nginx expose déjà 80/443) |
| Azure Bastion pour l'accès admin | IP publique + NSG restrictif sur chaque VM | Aucune IP publique exposée sur les VMs, audit centralisé côté Azure |
| VM de supervision dédiée (`VM-MONITORING`) | Installer Prometheus/Grafana directement sur les VMs applicatives | Isolation des responsabilités, pas de consommation de ressources applicative par le monitoring, NSG dédié |
| Prometheus + Grafana en `docker-compose` | Installation "nue" sur l'OS | Images officielles à jour, isolation, mise à jour simplifiée |
| Dashboard Grafana provisionné automatiquement (fichier JSON + `docker-compose` volumes) | Import manuel dans l'UI Grafana après déploiement | Reproductibilité totale : le dashboard est présent dès le premier accès, sans étape oubliable |
| Runner GitHub Actions auto-hébergé sur chaque VM | Déploiement SSH classique depuis un runner GitHub hébergé | Aucune IP publique/port SSH à exposer, cohérent avec l'absence d'IP publique sur les VMs applicatives |
| Déploiement séquentiel VM1 puis VM2 (`needs:` + vérification `/health`) | Déploiement simultané des deux VMs | Le site reste disponible même si le nouveau code casse le déploiement |
| Secrets sensibles en variables d'environnement `TF_VAR_*` | Secrets écrits en clair dans `terraform.tfvars` | Aucun secret ne peut être commité par erreur dans Git |
| Table de routage (UDR) forçant le trafic inter-spoke via le Firewall | Peering direct Spoke1<->Spoke2 sans passer par le hub | Permet d'inspecter/filtrer centralement le trafic entre environnements, conforme au modèle Hub & Spoke |

---
### 15. Guide de déploiement pas à pas

#### 15.1 Prérequis

| Outil | Vérifier | Installer |
|---|---|---|
| Terraform ≥ 1.2 | `terraform -version` | https://developer.hashicorp.com/terraform/install |
| Azure CLI | `az version` | https://learn.microsoft.com/cli/azure/install-azure-cli |
| Git | `git --version` | déjà présent sur la plupart des systèmes |
| Une paire de clés SSH | `ls ~/.ssh` | `ssh-keygen -t rsa -b 4096 -f ~/.ssh/hubspoke_rsa` |


- Se conencter à Azure
<img width="1912" height="822" alt="image" src="https://github.com/user-attachments/assets/fd691a76-2f2f-4f1f-9393-cb1c6ea9a7f4" />

- Récupérer le projet
<img width="1401" height="400" alt="image" src="https://github.com/user-attachments/assets/4b84e0c0-8cc8-45a4-a5c6-a03ea9a2fde2" />
<img width="1636" height="342" alt="image" src="https://github.com/user-attachments/assets/74847ba9-7272-40cf-a383-9576d73d1da0" />



#### 15.2 Récupérer les clés (voir détail section 16)

1. Clé SSH : `ssh-keygen -t rsa -b 4096 -f ~/.ssh/hubspoke_rsa -C "admin-hubspoke"`
<img width="1744" height="667" alt="image" src="https://github.com/user-attachments/assets/ae84c810-de92-4225-9fbc-611adb8197b6" />

2. Identifiants Supabase : Project Settings -> Data API (URL + clé anon) et
   Database -> Connection string (URI)
3. GitHub PAT : Settings -> Developer settings -> Personal access tokens
   (classic) -> scopes `repo` + `workflow`

<img width="1912" height="842" alt="image" src="https://github.com/user-attachments/assets/94dd2e33-d01d-42cf-ad74-cef0bebc91bf" />
<img width="1555" height="314" alt="image" src="https://github.com/user-attachments/assets/c0bee20f-428b-4dfa-a908-b3e2468f7f2f" />



4. Mot de passe admin Grafana : à choisir


#### 15.3 Configurer les valeurs non sensibles

```bash
cp terraform.tfvars.example terraform.tfvars
```

<img width="1692" height="441" alt="image" src="https://github.com/user-attachments/assets/d7da2afd-f913-475e-b92a-095529a13f7d" />


Éditez `terraform.tfvars` avce les vraies valeurs du projet :

```hcl
ssh_public_key_path    = "~/.ssh/hubspoke_rsa.pub"
supabase_url           = "https://xxxx.supabase.co"
github_repo_url        = "https://github.com/dspitech/azure-script-hub-fa365d79.git"
repo_name              = "azure-script-hub-fa365d79"
github_owner           = "dspitech"
grafana_allowed_source = "10.0.0.0/16"
```

#### 15.4 Définir les secrets en variables d'environnement

```bash
export TF_VAR_supabase_anon_key="sb_publishable_xxxxxxxxxxxx"
export TF_VAR_database_url="postgresql://postgres:VOTRE_MDP@db.xxxx.supabase.co:5432/postgres"
export TF_VAR_github_pat="ghp_xxxxxxxxxxxxxxxxxxxx"
export TF_VAR_grafana_admin_password="UnMotDePasseTresFort123!"
```

<img width="1868" height="697" alt="image" src="https://github.com/user-attachments/assets/c0ecaaa0-3bf4-4177-b282-40c83c32ec3e" />


#### 15.5 Déployer

```bash
terraform init && terraform fmt && terraform validate && terraform plan && terraform apply -auto-approve
```
<img width="1926" height="792" alt="image" src="https://github.com/user-attachments/assets/83f66e36-44b7-41d5-b680-3f940e80a5ae" />

Durée : 10 à 20 minutes (création réseau/firewall/bastion/VMs puis exécution
complète des cloud-init).

<img width="1880" height="822" alt="image" src="https://github.com/user-attachments/assets/4c98f266-de4d-4685-817c-3ac6e982ca46" />
<img width="1857" height="806" alt="image" src="https://github.com/user-attachments/assets/e7d24c7e-aa6d-429f-9079-2858371f700b" />
<img width="1796" height="146" alt="image" src="https://github.com/user-attachments/assets/2185f02c-5bcb-4c78-918d-f7331e2ec1b0" />

- Load-Balancer
<img width="1917" height="817" alt="image" src="https://github.com/user-attachments/assets/f21f1f63-1c0d-4462-8d41-d6f8cc085c33" />
<img width="1892" height="827" alt="image" src="https://github.com/user-attachments/assets/d87ee049-bac0-4426-a144-5b1169cb677b" />

- Trois VMs
<img width="1917" height="520" alt="image" src="https://github.com/user-attachments/assets/7b424f89-e304-417c-8618-13406649fc1f" />



#### 15.6 Activer le CI/CD dans le dépôt applicatif

les trois dossiers à copier au niveau du code de l'application : 


```bash
.github 
scripts 
```

Ces deux dossiers permettent à chaque nouveau `push` sur `main` déclenche automatiquement le déploiement
(VM1 puis VM2).

---

### 16. Où mettre chaque clé -récapitulatif

| # | Clé / valeur | Où la mettre | Nom de la variable Terraform |
|---|---|---|---|
| 1 | Clé publique SSH | `terraform.tfvars` | `ssh_public_key_path` |
| 2 | URL Supabase | `terraform.tfvars` | `supabase_url` |
| 3 | Clé anon Supabase | variable d'environnement | `TF_VAR_supabase_anon_key` |
| 4 | Chaîne de connexion base | variable d'environnement | `TF_VAR_database_url` |
| 5 | GitHub PAT | variable d'environnement | `TF_VAR_github_pat` |
| 6 | Mot de passe admin Grafana | variable d'environnement | `TF_VAR_grafana_admin_password` |


---

### 17. Vérifications et destruction

#### 17.1 Vérifications après déploiement

```bash
terraform output                                    
```

```bash                                 
curl -I $(terraform output -raw web_url)             
```

```bash          
curl $(terraform output -raw lb_health_probe_url)   
```

Connexion Grafana : 
<img width="1905" height="866" alt="image" src="https://github.com/user-attachments/assets/ba39fb37-750a-4dcd-ae30-225b76b5a016" />
<img width="1892" height="861" alt="image" src="https://github.com/user-attachments/assets/87978474-a93d-45a1-9d69-b99db0b4070a" />

- Prometheus
<img width="1917" height="787" alt="image" src="https://github.com/user-attachments/assets/4beb2fda-09e9-4050-820a-6190d0be5361" />
<img width="1917" height="876" alt="image" src="https://github.com/user-attachments/assets/9eb7ba12-cc00-4691-bb2a-2cee7fbf8d52" />

Connexion aux VMs : portail Azure -> Bastion -> sélectionner
- `VM-SPOKE-1` : 
<img width="1801" height="419" alt="image" src="https://github.com/user-attachments/assets/2150b184-7e6c-4d91-a704-73af069a2ca2" />


 
- Site web
<img width="1917" height="977" alt="image" src="https://github.com/user-attachments/assets/552877a2-d4fd-4137-aee8-ce0a7d5bc97f" />


#### 17.2 Destruction de l'infrastructure après test

```bash
terraform destroy -auto-approve
```

cette commande supprime toutes les ressources Azure créées (VMs, réseaux, firewall, bastion, load balancer, IPs publiques). Aucune donnée Supabase n'est affectée (service externe).


---

### 18. Concepts

| Terme | Définition |
|---|---|
| **IaC (Infrastructure as Code)** | Pratique consistant à décrire une infrastructure sous forme de fichiers de code versionnés (ici, Terraform) plutôt que de la construire manuellement |
| **Module Terraform** | Unité réutilisable de code Terraform regroupant des ressources liées, avec des entrées (`variables`) et des sorties (`outputs`) définies |
| **NSG (Network Security Group)** | Pare-feu Azure appliqué au niveau d'un subnet ou d'une interface réseau, filtrant le trafic entrant/sortant par des règles |
| **UDR (User Defined Route)** | Table de routage personnalisée qui remplace le routage par défaut d'Azure, utilisée ici pour forcer le trafic inter-spoke via le Firewall |
| **Hub & Spoke** | Modèle d'architecture réseau où un VNet central ("hub", services partagés) est connecté à plusieurs VNets périphériques ("spokes", charges de travail) |
| **Cloud-init** | Standard de provisioning exécuté au premier démarrage d'une VM Linux, utilisé ici pour automatiser toute la configuration applicative |
| **Runner auto-hébergé** | Agent GitHub Actions installé sur une machine que l'on contrôle (ici, chaque VM applicative), qui va chercher son travail sur GitHub sans nécessiter de port entrant |
| **Rolling deploy** | Stratégie de déploiement qui met à jour les instances d'une application les unes après les autres plutôt que simultanément, pour garder le service disponible |
| **node_exporter** | Agent Prometheus qui expose les métriques systèmes (CPU, RAM, disque, réseau) d'une machine sur un port HTTP dédié |
| **PromQL** | Langage de requête utilisé par Prometheus pour interroger et agréger les métriques collectées |

---

>

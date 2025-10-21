Infrastructure IBM Cloud

Infrastructure as Code (IaC) pour IBM Cloud utilisant Terraform.

## 📋 Table des matières

- [Architecture](#architecture)
- [Prérequis](#prérequis)
- [Installation](#installation)
- [Utilisation](#utilisation)
- [Structure du projet](#structure-du-projet)
- [Bonnes pratiques](#bonnes-pratiques)

## 🏗️ Architecture

Ce projet gère l'infrastructure suivante sur IBM Cloud:

- **VPC**: Virtual Private Cloud avec subnets multi-AZ
- **Compute**: Instances VM et clusters Kubernetes
- **Databases**: PostgreSQL et MongoDB managés
- **Networking**: Load Balancers, DNS
- **Security**: Security Groups, Network ACLs

## 📦 Prérequis

- Terraform >= 1.5.0
- IBM Cloud CLI
- Accès IBM Cloud avec permissions appropriées
- API Key IBM Cloud

## 🚀 Installation

### 1. Cloner le repository

\`\`\`bash
git clone <repository-url>
cd $PROJECT_NAME
\`\`\`

### 2. Configurer les variables d'environnement

\`\`\`bash
cd environments/$ENVIRONMENT
cp terraform.tfvars.example terraform.tfvars
# Éditer terraform.tfvars avec vos valeurs
\`\`\`

### 3. Initialiser Terraform

\`\`\`bash
terraform init
\`\`\`

## 📝 Utilisation

### Déploiement complet

\`\`\`bash
# Planifier les changements
terraform plan

# Appliquer les changements
terraform apply

# Détruire l'infrastructure
terraform destroy
\`\`\`

### Import de ressources existantes

\`\`\`bash
# Utiliser le script d'import interactif
./scripts/import-resources.sh $ENVIRONMENT

# Ou importer manuellement
terraform import 'module.vpc.ibm_is_vpc.vpc' <vpc-id>
\`\`\`

### Validation

\`\`\`bash
# Valider la configuration
terraform validate

# Formater le code
terraform fmt -recursive

# Vérifier la sécurité (nécessite tfsec)
tfsec .
\`\`\`

## 📂 Structure du projet

\`\`\`
$PROJECT_NAME/
├── environments/           # Configurations par environnement
│   ├── dev/
│   ├── staging/
│   └── prod/
├── modules/               # Modules Terraform réutilisables
│   ├── vpc/
│   ├── compute/
│   │   ├── vm/
│   │   └── kubernetes/
│   ├── database/
│   │   ├── postgres/
│   │   └── mongodb/
│   ├── networking/
│   └── security/
├── scripts/               # Scripts utilitaires
│   └── import-resources.sh
└── docs/                  # Documentation
\`\`\`

## ✅ Bonnes pratiques

### État distant (Remote State)

**Obligatoire pour la production!** Configurer un backend S3:

\`\`\`hcl
terraform {
  backend "s3" {
    bucket = "terraform-state-bucket"
    key    = "ibm-cloud/\${var.environment}/terraform.tfstate"
    region = "eu-de"
  }
}
\`\`\`

### Gestion des secrets

- **Ne jamais** commiter de secrets dans Git
- Utiliser IBM Secrets Manager ou HashiCorp Vault
- Utiliser des variables d'environnement: \`export TF_VAR_ibmcloud_api_key=xxx\`

### Workspaces

\`\`\`bash
# Créer un workspace par environnement
terraform workspace new dev
terraform workspace new prod

# Lister les workspaces
terraform workspace list

# Sélectionner un workspace
terraform workspace select prod
\`\`\`

### Verrouillage des versions

- Toujours verrouiller les versions des providers
- Utiliser \`terraform.lock.hcl\` (commité dans Git)
- Tester les mises à jour dans un environnement de dev

### CI/CD

Exemple de pipeline GitLab CI:

\`\`\`yaml
stages:
  - validate
  - plan
  - apply

validate:
  script:
    - terraform init
    - terraform validate
    - terraform fmt -check

plan:
  script:
    - terraform init
    - terraform plan -out=tfplan

apply:
  script:
    - terraform apply tfplan
  when: manual
  only:
    - main
\`\`\`

## 🔒 Sécurité

- Activer le chiffrement au repos pour toutes les bases de données
- Utiliser des Security Groups restrictifs
- Activer les backups automatiques
- Utiliser des Private Endpoints quand possible
- Activer l'audit logging

## 📊 Monitoring

- Configurer IBM Cloud Monitoring
- Activer les alertes pour les métriques critiques
- Utiliser IBM Log Analysis pour les logs

## 🆘 Support

- Documentation IBM Cloud: https://cloud.ibm.com/docs
- Terraform IBM Provider: https://registry.terraform.io/providers/IBM-Cloud/ibm/latest/docs

## 📄 Licence

--
#!/bin/bash

###############################################################################
# Script de création et gestion de projet Terraform pour IBM Cloud
# Auteur: Infrastructure Team
# Description: Crée une structure de projet Terraform complète avec modules
#              pour IBM Cloud (Postgres, MongoDB, VMs, VPC, etc.)
###############################################################################

set -e  # Arrêt en cas d'erreur
set -u  # Erreur si variable non définie

# Couleurs pour l'output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Fonctions utilitaires
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Configuration par défaut
PROJECT_NAME="${PROJECT_NAME:-ibm-cloud-infra}"
ENVIRONMENT="${ENVIRONMENT:-dev}"
REGION="${REGION:-eu-de}"
TERRAFORM_VERSION="${TERRAFORM_VERSION:-1.5.0}"

###############################################################################
# Fonction: Afficher l'aide
###############################################################################
show_help() {
    cat << EOF
Usage: $0 [OPTIONS] COMMAND

Script de gestion de projet Terraform pour IBM Cloud

COMMANDS:
    init            Initialise la structure du projet
    import          Importe des ressources existantes
    validate        Valide la configuration Terraform
    plan            Exécute terraform plan
    apply           Applique la configuration
    destroy         Détruit l'infrastructure

OPTIONS:
    -n, --name NAME         Nom du projet (défaut: ibm-cloud-infra)
    -e, --env ENV          Environnement (dev/staging/prod)
    -r, --region REGION    Région IBM Cloud (défaut: eu-de)
    -h, --help             Affiche cette aide

EXAMPLES:
    $0 -n mon-projet -e prod init
    $0 -n mon-projet import
    $0 validate
    $0 plan
    $0 apply

EOF
}

###############################################################################
# Fonction: Créer la structure de base du projet
###############################################################################
create_project_structure() {
    log_info "Création de la structure du projet: $PROJECT_NAME"
    
    # Structure de répertoires
    mkdir -p "$PROJECT_NAME"/{environments/{dev,staging,prod},modules/{vpc,compute,database,networking,security},scripts,docs}
    mkdir -p "$PROJECT_NAME"/modules/database/{postgres,mongodb}
    mkdir -p "$PROJECT_NAME"/modules/compute/{vm,kubernetes}
    mkdir -p "$PROJECT_NAME"/modules/networking/{load_balancer,dns}
    
    cd "$PROJECT_NAME"
    
    log_success "Structure de répertoires créée"
}

###############################################################################
# Fonction: Créer le fichier provider principal
###############################################################################
create_provider_config() {
    log_info "Création de la configuration du provider IBM Cloud"
    
    cat > "environments/$ENVIRONMENT/provider.tf" << 'EOF'
###############################################################################
# Provider Configuration - IBM Cloud
###############################################################################

terraform {
  required_version = ">= 1.5.0"
  
  required_providers {
    ibm = {
      source  = "IBM-Cloud/ibm"
      version = "~> 1.60.0"
    }
  }
  
  # Backend pour le state distant (décommenter et configurer)
  # backend "s3" {
  #   bucket = "terraform-state-bucket"
  #   key    = "ibm-cloud/${var.environment}/terraform.tfstate"
  #   region = "eu-de"
  # }
}

provider "ibm" {
  ibmcloud_api_key = var.ibmcloud_api_key
  region           = var.region
  
  # Configuration du timeout
  ibmcloud_timeout = 300
}

EOF
    
    log_success "Fichier provider.tf créé"
}

###############################################################################
# Fonction: Créer les variables globales
###############################################################################
create_variables() {
    log_info "Création des fichiers de variables"
    
    # Variables principales
    cat > "environments/$ENVIRONMENT/variables.tf" << 'EOF'
###############################################################################
# Variables Globales
###############################################################################

variable "ibmcloud_api_key" {
  description = "IBM Cloud API Key"
  type        = string
  sensitive   = true
}

variable "region" {
  description = "IBM Cloud region"
  type        = string
  default     = "eu-de"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
}

variable "resource_group" {
  description = "IBM Cloud Resource Group"
  type        = string
  default     = "default"
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = list(string)
  default     = []
}

###############################################################################
# Network Variables
###############################################################################

variable "vpc_name" {
  description = "VPC name"
  type        = string
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnets" {
  description = "Subnet configuration"
  type = map(object({
    cidr_block        = string
    availability_zone = string
    public            = bool
  }))
  default = {}
}

###############################################################################
# Compute Variables
###############################################################################

variable "vm_instances" {
  description = "VM instances configuration"
  type = map(object({
    profile           = string
    image             = string
    subnet            = string
    security_groups   = list(string)
    user_data         = string
  }))
  default = {}
}

variable "kubernetes_cluster" {
  description = "Kubernetes cluster configuration"
  type = object({
    name              = string
    kube_version      = string
    worker_count      = number
    flavor            = string
    hardware          = string
  })
  default = null
}

###############################################################################
# Database Variables
###############################################################################

variable "postgres_instances" {
  description = "PostgreSQL database instances"
  type = map(object({
    name              = string
    plan              = string
    version           = string
    members_memory_mb = number
    members_disk_mb   = number
    members_cpu_count = number
    backup_enabled    = bool
  }))
  default = {}
}

variable "mongodb_instances" {
  description = "MongoDB database instances"
  type = map(object({
    name              = string
    plan              = string
    version           = string
    members_memory_mb = number
    members_disk_mb   = number
    backup_enabled    = bool
  }))
  default = {}
}

###############################################################################
# Load Balancer Variables
###############################################################################

variable "load_balancers" {
  description = "Load balancer configuration"
  type = map(object({
    type              = string  # public or private
    subnets           = list(string)
    listeners = list(object({
      protocol      = string
      port          = number
      default_pool  = string
    }))
  }))
  default = {}
}

EOF

    # Fichier terraform.tfvars pour l'environnement
    cat > "environments/$ENVIRONMENT/terraform.tfvars.example" << EOF
###############################################################################
# Variables d'environnement - ${ENVIRONMENT}
# Copier ce fichier vers terraform.tfvars et remplir les valeurs
###############################################################################

# IBM Cloud Configuration
ibmcloud_api_key = "YOUR_API_KEY_HERE"
region           = "${REGION}"
environment      = "${ENVIRONMENT}"
project_name     = "${PROJECT_NAME}"
resource_group   = "default"

tags = [
  "env:${ENVIRONMENT}",
  "managed-by:terraform",
  "project:${PROJECT_NAME}"
]

# VPC Configuration
vpc_name = "${PROJECT_NAME}-vpc-${ENVIRONMENT}"
vpc_cidr = "10.0.0.0/16"

subnets = {
  "subnet-1" = {
    cidr_block        = "10.0.1.0/24"
    availability_zone = "${REGION}-1"
    public            = true
  },
  "subnet-2" = {
    cidr_block        = "10.0.2.0/24"
    availability_zone = "${REGION}-2"
    public            = false
  },
  "subnet-3" = {
    cidr_block        = "10.0.3.0/24"
    availability_zone = "${REGION}-3"
    public            = false
  }
}

# VM Instances
vm_instances = {
  "web-server-1" = {
    profile         = "cx2-2x4"
    image           = "ibm-ubuntu-20-04-minimal-amd64-2"
    subnet          = "subnet-1"
    security_groups = ["web-sg"]
    user_data       = ""
  }
}

# PostgreSQL Databases
postgres_instances = {
  "main-db" = {
    name              = "${PROJECT_NAME}-postgres-${ENVIRONMENT}"
    plan              = "standard"
    version           = "14"
    members_memory_mb = 4096
    members_disk_mb   = 20480
    members_cpu_count = 2
    backup_enabled    = true
  }
}

# MongoDB Databases
mongodb_instances = {
  "cache-db" = {
    name              = "${PROJECT_NAME}-mongodb-${ENVIRONMENT}"
    plan              = "standard"
    version           = "5.0"
    members_memory_mb = 4096
    members_disk_mb   = 20480
    backup_enabled    = true
  }
}

# Load Balancers
load_balancers = {
  "public-lb" = {
    type    = "public"
    subnets = ["subnet-1", "subnet-2"]
    listeners = [
      {
        protocol     = "http"
        port         = 80
        default_pool = "web-pool"
      },
      {
        protocol     = "https"
        port         = 443
        default_pool = "web-pool"
      }
    ]
  }
}

EOF
    
    log_success "Fichiers de variables créés"
}

###############################################################################
# Fonction: Créer le module VPC
###############################################################################
create_vpc_module() {
    log_info "Création du module VPC"
    
    cat > "modules/vpc/main.tf" << 'EOF'
###############################################################################
# Module VPC - IBM Cloud
###############################################################################

resource "ibm_is_vpc" "vpc" {
  name                      = var.name
  resource_group            = var.resource_group
  address_prefix_management = "auto"
  tags                      = var.tags
}

resource "ibm_is_subnet" "subnet" {
  for_each = var.subnets

  name                     = "${var.name}-${each.key}"
  vpc                      = ibm_is_vpc.vpc.id
  zone                     = each.value.availability_zone
  total_ipv4_address_count = tonumber(split("/", each.value.cidr_block)[1]) == 24 ? 256 : 512
  resource_group           = var.resource_group
  
  public_gateway = each.value.public ? ibm_is_public_gateway.gateway[each.value.availability_zone].id : null
}

resource "ibm_is_public_gateway" "gateway" {
  for_each = toset([for k, v in var.subnets : v.availability_zone if v.public])
  
  name           = "${var.name}-pgw-${each.key}"
  vpc            = ibm_is_vpc.vpc.id
  zone           = each.key
  resource_group = var.resource_group
  tags           = var.tags
}

resource "ibm_is_security_group" "default" {
  name           = "${var.name}-default-sg"
  vpc            = ibm_is_vpc.vpc.id
  resource_group = var.resource_group
}

resource "ibm_is_security_group_rule" "allow_outbound" {
  group     = ibm_is_security_group.default.id
  direction = "outbound"
  remote    = "0.0.0.0/0"
}

EOF

    cat > "modules/vpc/variables.tf" << 'EOF'
variable "name" {
  description = "VPC name"
  type        = string
}

variable "resource_group" {
  description = "Resource group ID"
  type        = string
}

variable "subnets" {
  description = "Subnet configuration"
  type = map(object({
    cidr_block        = string
    availability_zone = string
    public            = bool
  }))
}

variable "tags" {
  description = "Tags to apply"
  type        = list(string)
  default     = []
}
EOF

    cat > "modules/vpc/outputs.tf" << 'EOF'
output "vpc_id" {
  description = "VPC ID"
  value       = ibm_is_vpc.vpc.id
}

output "vpc_crn" {
  description = "VPC CRN"
  value       = ibm_is_vpc.vpc.crn
}

output "subnet_ids" {
  description = "Map of subnet names to IDs"
  value       = { for k, v in ibm_is_subnet.subnet : k => v.id }
}

output "default_security_group_id" {
  description = "Default security group ID"
  value       = ibm_is_security_group.default.id
}
EOF

    log_success "Module VPC créé"
}

###############################################################################
# Fonction: Créer le module PostgreSQL
###############################################################################
create_postgres_module() {
    log_info "Création du module PostgreSQL"
    
    cat > "modules/database/postgres/main.tf" << 'EOF'
###############################################################################
# Module PostgreSQL Database - IBM Cloud Databases
###############################################################################

resource "ibm_database" "postgres" {
  name              = var.name
  plan              = var.plan
  location          = var.location
  service           = "databases-for-postgresql"
  version           = var.version
  resource_group_id = var.resource_group_id
  tags              = var.tags

  adminpassword = var.admin_password

  group {
    group_id = "member"
    
    memory {
      allocation_mb = var.members_memory_mb
    }
    
    disk {
      allocation_mb = var.members_disk_mb
    }
    
    cpu {
      allocation_count = var.members_cpu_count
    }
  }

  backup_id = var.backup_id

  configuration = jsonencode({
    max_connections            = var.max_connections
    max_prepared_transactions  = var.max_prepared_transactions
    shared_buffers             = var.shared_buffers
  })

  lifecycle {
    prevent_destroy = true
  }
}

resource "ibm_resource_key" "db_credentials" {
  name                 = "${var.name}-credentials"
  resource_instance_id = ibm_database.postgres.id
  role                 = "Manager"
}

EOF

    cat > "modules/database/postgres/variables.tf" << 'EOF'
variable "name" {
  description = "Database instance name"
  type        = string
}

variable "plan" {
  description = "Service plan (standard, enterprise)"
  type        = string
  default     = "standard"
}

variable "location" {
  description = "Location/Region"
  type        = string
}

variable "version" {
  description = "PostgreSQL version"
  type        = string
  default     = "14"
}

variable "resource_group_id" {
  description = "Resource group ID"
  type        = string
}

variable "admin_password" {
  description = "Admin password"
  type        = string
  sensitive   = true
}

variable "members_memory_mb" {
  description = "Memory allocation per member in MB"
  type        = number
  default     = 4096
}

variable "members_disk_mb" {
  description = "Disk allocation per member in MB"
  type        = number
  default     = 20480
}

variable "members_cpu_count" {
  description = "CPU allocation per member"
  type        = number
  default     = 2
}

variable "backup_id" {
  description = "Backup ID for restore"
  type        = string
  default     = null
}

variable "max_connections" {
  description = "Max connections"
  type        = number
  default     = 200
}

variable "max_prepared_transactions" {
  description = "Max prepared transactions"
  type        = number
  default     = 0
}

variable "shared_buffers" {
  description = "Shared buffers"
  type        = number
  default     = 16384
}

variable "tags" {
  description = "Tags"
  type        = list(string)
  default     = []
}
EOF

    cat > "modules/database/postgres/outputs.tf" << 'EOF'
output "database_id" {
  description = "Database instance ID"
  value       = ibm_database.postgres.id
}

output "database_crn" {
  description = "Database CRN"
  value       = ibm_database.postgres.resource_crn
}

output "connection_string" {
  description = "Database connection string"
  value       = ibm_database.postgres.connectionstrings
  sensitive   = true
}

output "credentials" {
  description = "Database credentials"
  value       = ibm_resource_key.db_credentials.credentials
  sensitive   = true
}
EOF

    log_success "Module PostgreSQL créé"
}

###############################################################################
# Fonction: Créer le module MongoDB
###############################################################################
create_mongodb_module() {
    log_info "Création du module MongoDB"
    
    cat > "modules/database/mongodb/main.tf" << 'EOF'
###############################################################################
# Module MongoDB Database - IBM Cloud Databases
###############################################################################

resource "ibm_database" "mongodb" {
  name              = var.name
  plan              = var.plan
  location          = var.location
  service           = "databases-for-mongodb"
  version           = var.version
  resource_group_id = var.resource_group_id
  tags              = var.tags

  adminpassword = var.admin_password

  group {
    group_id = "member"
    
    memory {
      allocation_mb = var.members_memory_mb
    }
    
    disk {
      allocation_mb = var.members_disk_mb
    }
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "ibm_resource_key" "db_credentials" {
  name                 = "${var.name}-credentials"
  resource_instance_id = ibm_database.mongodb.id
  role                 = "Manager"
}

EOF

    cat > "modules/database/mongodb/variables.tf" << 'EOF'
variable "name" {
  description = "Database instance name"
  type        = string
}

variable "plan" {
  description = "Service plan"
  type        = string
  default     = "standard"
}

variable "location" {
  description = "Location/Region"
  type        = string
}

variable "version" {
  description = "MongoDB version"
  type        = string
  default     = "5.0"
}

variable "resource_group_id" {
  description = "Resource group ID"
  type        = string
}

variable "admin_password" {
  description = "Admin password"
  type        = string
  sensitive   = true
}

variable "members_memory_mb" {
  description = "Memory allocation per member in MB"
  type        = number
  default     = 4096
}

variable "members_disk_mb" {
  description = "Disk allocation per member in MB"
  type        = number
  default     = 20480
}

variable "tags" {
  description = "Tags"
  type        = list(string)
  default     = []
}
EOF

    cat > "modules/database/mongodb/outputs.tf" << 'EOF'
output "database_id" {
  description = "Database instance ID"
  value       = ibm_database.mongodb.id
}

output "database_crn" {
  description = "Database CRN"
  value       = ibm_database.mongodb.resource_crn
}

output "connection_string" {
  description = "Database connection string"
  value       = ibm_database.mongodb.connectionstrings
  sensitive   = true
}

output "credentials" {
  description = "Database credentials"
  value       = ibm_resource_key.db_credentials.credentials
  sensitive   = true
}
EOF

    log_success "Module MongoDB créé"
}

###############################################################################
# Fonction: Créer le fichier main.tf principal
###############################################################################
create_main_config() {
    log_info "Création du fichier main.tf principal"
    
    cat > "environments/$ENVIRONMENT/main.tf" << 'EOF'
###############################################################################
# Configuration principale - Infrastructure IBM Cloud
###############################################################################

# Data sources
data "ibm_resource_group" "group" {
  name = var.resource_group
}

###############################################################################
# VPC et Réseau
###############################################################################

module "vpc" {
  source = "../../modules/vpc"
  
  name           = var.vpc_name
  resource_group = data.ibm_resource_group.group.id
  subnets        = var.subnets
  tags           = var.tags
}

###############################################################################
# Bases de données PostgreSQL
###############################################################################

module "postgres" {
  source   = "../../modules/database/postgres"
  for_each = var.postgres_instances
  
  name              = each.value.name
  plan              = each.value.plan
  location          = var.region
  version           = each.value.version
  resource_group_id = data.ibm_resource_group.group.id
  admin_password    = random_password.db_password[each.key].result
  members_memory_mb = each.value.members_memory_mb
  members_disk_mb   = each.value.members_disk_mb
  members_cpu_count = each.value.members_cpu_count
  tags              = concat(var.tags, ["database:postgres", "name:${each.key}"])
}

###############################################################################
# Bases de données MongoDB
###############################################################################

module "mongodb" {
  source   = "../../modules/database/mongodb"
  for_each = var.mongodb_instances
  
  name              = each.value.name
  plan              = each.value.plan
  location          = var.region
  version           = each.value.version
  resource_group_id = data.ibm_resource_group.group.id
  admin_password    = random_password.db_password["mongo-${each.key}"].result
  members_memory_mb = each.value.members_memory_mb
  members_disk_mb   = each.value.members_disk_mb
  tags              = concat(var.tags, ["database:mongodb", "name:${each.key}"])
}

###############################################################################
# Mots de passe aléatoires pour les bases de données
###############################################################################

resource "random_password" "db_password" {
  for_each = merge(
    var.postgres_instances,
    { for k, v in var.mongodb_instances : "mongo-${k}" => v }
  )
  
  length  = 32
  special = true
}

EOF

    log_success "Fichier main.tf principal créé"
}

###############################################################################
# Fonction: Créer les outputs
###############################################################################
create_outputs() {
    log_info "Création du fichier outputs.tf"
    
    cat > "environments/$ENVIRONMENT/outputs.tf" << 'EOF'
###############################################################################
# Outputs
###############################################################################

output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "subnet_ids" {
  description = "Subnet IDs"
  value       = module.vpc.subnet_ids
}

output "postgres_databases" {
  description = "PostgreSQL database information"
  value = {
    for k, v in module.postgres : k => {
      id  = v.database_id
      crn = v.database_crn
    }
  }
}

output "mongodb_databases" {
  description = "MongoDB database information"
  value = {
    for k, v in module.mongodb : k => {
      id  = v.database_id
      crn = v.database_crn
    }
  }
}

# Sensitive outputs (utiliser: terraform output -json <name>)
output "postgres_connection_strings" {
  description = "PostgreSQL connection strings"
  value       = { for k, v in module.postgres : k => v.connection_string }
  sensitive   = true
}

output "mongodb_connection_strings" {
  description = "MongoDB connection strings"
  value       = { for k, v in module.mongodb : k => v.connection_string }
  sensitive   = true
}

EOF

    log_success "Fichier outputs.tf créé"
}

###############################################################################
# Fonction: Créer le script d'import
###############################################################################
create_import_script() {
    log_info "Création du script d'import de ressources"
    
    cat > "scripts/import-resources.sh" << 'EOF'
#!/bin/bash

###############################################################################
# Script d'import de ressources existantes dans Terraform
###############################################################################

set -e

ENVIRONMENT="${1:-dev}"
cd "$(dirname "$0")/../environments/$ENVIRONMENT"

log_info() {
    echo "[INFO] $1"
}

log_success() {
    echo "[SUCCESS] $1"
}

###############################################################################
# Fonction: Importer un VPC existant
###############################################################################
import_vpc() {
    local vpc_id="$1"
    local vpc_name="$2"
    
    log_info "Import du VPC: $vpc_name (ID: $vpc_id)"
    
    terraform import 'module.vpc.ibm_is_vpc.vpc' "$vpc_id"
    
    log_success "VPC importé avec succès"
}

###############################################################################
# Fonction: Importer une base de données PostgreSQL
###############################################################################
import_postgres() {
    local db_crn="$1"
    local module_key="$2"
    
    log_info "Import de PostgreSQL: $module_key"
    
    terraform import "module.postgres[\"$module_key\"].ibm_database.postgres" "$db_crn"
    
    log_success "PostgreSQL importé avec succès"
}

###############################################################################
# Fonction: Importer une base de données MongoDB
###############################################################################
import_mongodb() {
    local db_crn="$1"
    local module_key="$2"
    
    log_info "Import de MongoDB: $module_key"
    
    terraform import "module.mongodb[\"$module_key\"].ibm_database.mongodb" "$db_crn"
    
    log_success "MongoDB importé avec succès"
}

###############################################################################
# Fonction: Importer un subnet
###############################################################################
import_subnet() {
    local subnet_id="$1"
    local subnet_key="$2"
    
    log_info "Import du subnet: $subnet_key (ID: $subnet_id)"
    
    terraform import "module.vpc.ibm_is_subnet.subnet[\"$subnet_key\"]" "$subnet_id"
    
    log_success "Subnet importé avec succès"
}

###############################################################################
# Menu interactif
###############################################################################

echo "====================================="
echo "Script d'import de ressources"
echo "Environnement: $ENVIRONMENT"
echo "====================================="
echo ""
echo "Que souhaitez-vous importer ?"
echo "1. VPC"
echo "2. PostgreSQL Database"
echo "3. MongoDB Database"
echo "4. Subnet"
echo "5. Import depuis fichier CSV"
echo "0. Quitter"
echo ""

read -p "Votre choix: " choice

case $choice in
    1)
        read -p "ID du VPC: " vpc_id
        read -p "Nom du VPC: " vpc_name
        import_vpc "$vpc_id" "$vpc_name"
        ;;
    2)
        read -p "CRN de la base PostgreSQL: " db_crn
        read -p "Clé du module (ex: main-db): " module_key
        import_postgres "$db_crn" "$module_key"
        ;;
    3)
        read -p "CRN de la base MongoDB: " db_crn
        read -p "Clé du module (ex: cache-db): " module_key
        import_mongodb "$db_crn" "$module_key"
        ;;
    4)
        read -p "ID du subnet: " subnet_id
        read -p "Clé du subnet (ex: subnet-1): " subnet_key
        import_subnet "$subnet_id" "$subnet_key"
        ;;
    5)
        log_info "Format CSV attendu: resource_type,resource_id,module_key"
        read -p "Chemin du fichier CSV: " csv_file
        
        if [ ! -f "$csv_file" ]; then
            echo "Fichier non trouvé: $csv_file"
            exit 1
        fi
        
        while IFS=',' read -r resource_type resource_id module_key; do
            case $resource_type in
                vpc)
                    import_vpc "$resource_id" "$module_key"
                    ;;
                postgres)
                    import_postgres "$resource_id" "$module_key"
                    ;;
                mongodb)
                    import_mongodb "$resource_id" "$module_key"
                    ;;
                subnet)
                    import_subnet "$resource_id" "$module_key"
                    ;;
            esac
        done < "$csv_file"
        ;;
    0)
        exit 0
        ;;
    *)
        echo "Choix invalide"
        exit 1
        ;;
esac

EOF

    chmod +x scripts/import-resources.sh
    log_success "Script d'import créé"
}

###############################################################################
# Fonction: Créer la documentation
###############################################################################
create_documentation() {
    log_info "Création de la documentation"
    
    cat > "README.md" << EOF
# $PROJECT_NAME - Infrastructure IBM Cloud

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

[Votre licence]

EOF

    # Créer un exemple de fichier CSV pour l'import
    cat > "docs/import-example.csv" << 'EOF'
resource_type,resource_id,module_key
vpc,r006-12345678-1234-1234-1234-123456789012,main-vpc
postgres,crn:v1:bluemix:public:databases-for-postgresql:eu-de:a/abc123::,main-db
mongodb,crn:v1:bluemix:public:databases-for-mongodb:eu-de:a/abc123::,cache-db
subnet,0717-12345678-1234-1234-1234-123456789012,subnet-1
EOF

    log_success "Documentation créée"
}

###############################################################################
# Fonction: Créer le fichier .gitignore
###############################################################################
create_gitignore() {
    cat > ".gitignore" << 'EOF'
# Terraform
*.tfstate
*.tfstate.*
*.tfvars
!*.tfvars.example
.terraform/
.terraform.lock.hcl
crash.log
override.tf
override.tf.json
*_override.tf
*_override.tf.json
tfplan

# IDE
.idea/
.vscode/
*.swp
*.swo
*~

# OS
.DS_Store
Thumbs.db

# Secrets
*.pem
*.key
secrets/

EOF
    
    log_success "Fichier .gitignore créé"
}

###############################################################################
# Fonction: Initialiser le projet
###############################################################################
init_project() {
    log_info "Initialisation du projet Terraform pour IBM Cloud"
    
    create_project_structure
    create_provider_config
    create_variables
    create_vpc_module
    create_postgres_module
    create_mongodb_module
    create_main_config
    create_outputs
    create_import_script
    create_documentation
    create_gitignore
    
    # Initialiser Terraform
    log_info "Initialisation de Terraform"
    cd "environments/$ENVIRONMENT"
    terraform init
    cd ../..
    
    log_success "✅ Projet initialisé avec succès!"
    echo ""
    echo "Prochaines étapes:"
    echo "1. cd $PROJECT_NAME/environments/$ENVIRONMENT"
    echo "2. cp terraform.tfvars.example terraform.tfvars"
    echo "3. Éditer terraform.tfvars avec vos valeurs"
    echo "4. terraform plan"
    echo "5. terraform apply"
}

###############################################################################
# Fonction: Valider la configuration
###############################################################################
validate_config() {
    log_info "Validation de la configuration Terraform"
    
    cd "environments/$ENVIRONMENT"
    terraform fmt -recursive -check
    terraform validate
    
    log_success "Configuration valide!"
}

###############################################################################
# MAIN
###############################################################################

# Parse des arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -n|--name)
            PROJECT_NAME="$2"
            shift 2
            ;;
        -e|--env)
            ENVIRONMENT="$2"
            shift 2
            ;;
        -r|--region)
            REGION="$2"
            shift 2
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        init|import|validate|plan|apply|destroy)
            COMMAND="$1"
            shift
            ;;
        *)
            log_error "Option inconnue: $1"
            show_help
            exit 1
            ;;
    esac
done

# Exécuter la commande
case ${COMMAND:-} in
    init)
        init_project
        ;;
    import)
        if [ ! -d "$PROJECT_NAME" ]; then
            log_error "Projet non trouvé. Exécutez d'abord: $0 init"
            exit 1
        fi
        cd "$PROJECT_NAME"
        ./scripts/import-resources.sh "$ENVIRONMENT"
        ;;
    validate)
        if [ ! -d "$PROJECT_NAME" ]; then
            log_error "Projet non trouvé. Exécutez d'abord: $0 init"
            exit 1
        fi
        cd "$PROJECT_NAME"
        validate_config
        ;;
    plan|apply|destroy)
        if [ ! -d "$PROJECT_NAME" ]; then
            log_error "Projet non trouvé. Exécutez d'abord: $0 init"
            exit 1
        fi
        cd "$PROJECT_NAME/environments/$ENVIRONMENT"
        terraform "$COMMAND"
        ;;
    *)
        log_error "Commande requise: init, import, validate, plan, apply, destroy"
        show_help
        exit 1
        ;;
esac
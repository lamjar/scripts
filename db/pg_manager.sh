#!/bin/bash

#############################################################################
# pg_manager.sh - OwnPgBox By LAMJAR (Refactored & Optimized)
# Description: Complete PostgreSQL database management tool
#############################################################################

set -euo pipefail

# ============================================================================
# CONFIGURATION & CONSTANTS
# ============================================================================

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"
readonly VERSION="2.0"

readonly CONFIG_DIR="${SCRIPT_DIR}/config"
readonly LOG_BASE_DIR="${SCRIPT_DIR}/logs"
readonly BACKUP_BASE_DIR="${SCRIPT_DIR}/backups"

ACTIVE_ENV_FILE=""
LOG_FILE=""
LOG_DIR=""
BACKUP_DIR=""

readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly MAGENTA='\033[0;35m'
readonly NC='\033[0m'

CURRENT_SCHEMA="public"
PGHOST="localhost"
PGPORT="5432"
PGDATABASE="postgres"
PGUSER="postgres"
PGPASSWORD=""

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================

init_dirs() {
    mkdir -p "$CONFIG_DIR" "$LOG_BASE_DIR" "$BACKUP_BASE_DIR"
}

log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $message" | tee -a "$LOG_FILE"
}

print_success() { 
    echo -e "${GREEN}✓ $*${NC}"
    [ -n "$LOG_FILE" ] && log "INFO" "$*"
}

print_error() { 
    echo -e "${RED}✗ $*${NC}"
    [ -n "$LOG_FILE" ] && log "ERROR" "$*"
}

print_warning() { 
    echo -e "${YELLOW}⚠ $*${NC}"
    [ -n "$LOG_FILE" ] && log "WARNING" "$*"
}

print_info() { 
    echo -e "${BLUE}ℹ $*${NC}"
    [ -n "$LOG_FILE" ] && log "INFO" "$*"
}

print_banner() {
    clear
    echo -e "${CYAN}"
    cat << 'EOF'
╔════════════════════════════════════════════════════════════════════╗
║                                                                    ║
║    ██████╗ ██╗    ██╗███╗   ██╗██████╗  ██████╗ ██████╗  ██████╗ ║
║   ██╔═══██╗██║    ██║████╗  ██║██╔══██╗██╔════╝ ██╔══██╗██╔═══██╗║
║   ██║   ██║██║ █╗ ██║██╔██╗ ██║██████╔╝██║  ███╗██████╔╝██║   ██║║
║   ██║   ██║██║███╗██║██║╚██╗██║██╔═══╝ ██║   ██║██╔══██╗██║   ██║║
║   ╚██████╔╝╚███╔███╔╝██║ ╚████║██║     ╚██████╔╝██████╔╝╚██████╔╝║
║    ╚═════╝  ╚══╝╚══╝ ╚═╝  ╚═══╝╚═╝      ╚═════╝ ╚═════╝  ╚═════╝ ║
║                                                                    ║
║                        By LAMJAR v${VERSION}                            ║
║              Gestionnaire PostgreSQL Complet                       ║
╚════════════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
}

print_header() {
    print_banner
    echo -e "${MAGENTA}┌────────────────────────────────────────────────────────────────┐${NC}"
    echo -e "${MAGENTA}│${NC} Base: ${GREEN}${PGDATABASE}${NC}@${GREEN}${PGHOST}:${PGPORT}${NC}"
    echo -e "${MAGENTA}│${NC} Schéma: ${YELLOW}${CURRENT_SCHEMA}${NC}"
    echo -e "${MAGENTA}│${NC} Utilisateur: ${CYAN}${PGUSER}${NC}"
    echo -e "${MAGENTA}│${NC} Config: ${CYAN}$(basename "$ACTIVE_ENV_FILE")${NC}"
    echo -e "${MAGENTA}└────────────────────────────────────────────────────────────────┘${NC}"
    echo ""
}

pause() {
    read -p "Appuyez sur ENTRÉE pour continuer..."
}

get_timestamp() {
    date +%Y%m%d_%H%M%S
}

format_size() {
    du -h "$1" 2>/dev/null | cut -f1 || echo "N/A"
}

# ============================================================================
# CONFIGURATION FILE MANAGEMENT
# ============================================================================

list_env_files() {
    local env_files=()
    while IFS= read -r file; do
        env_files+=("$file")
    done < <(find "$CONFIG_DIR" -maxdepth 1 -name ".env*" -type f 2>/dev/null | sort)

    if [ ${#env_files[@]} -eq 0 ]; then
        return 1
    fi
    
    echo "Configurations disponibles:"
    echo ""
    echo " 0) Créer une nouvelle configuration"
    for i in "${!env_files[@]}"; do
        local filename=$(basename "${env_files[$i]}")
        local size=$(du -h "${env_files[$i]}" | cut -f1)
        local modified=$(stat -c %y "${env_files[$i]}" 2>/dev/null | cut -d' ' -f1 || stat -f %Sm "${env_files[$i]}" 2>/dev/null)
        printf "%2d) %-20s %6s  %s\n" "$((i+1))" "$filename" "$size" "$modified"
    done
    echo ""
    echo "${#env_files[@]} configuration(s) disponible(s)"
    return 0
}

select_env_file() {
    local env_files=()
    while IFS= read -r file; do
        env_files+=("$file")
    done < <(find "$CONFIG_DIR" -maxdepth 1 -name ".env*" -type f 2>/dev/null | sort)

    if [ ${#env_files[@]} -eq 0 ]; then
        return 1
    fi

    if list_env_files; then
        read -p "Sélectionner une configuration (numéro ou ZERO pour créer une nouvelle configuration) : " choice

        if ! [[ "$choice" =~ ^[0-9]+$ ]] || [ "$choice" -lt 1 ] || [ "$choice" -gt ${#env_files[@]} ]; then
            print_error "Sélection invalide"
            return 1
        fi

        ACTIVE_ENV_FILE="${env_files[$((choice-1))]}"
        print_success "Configuration sélectionnée: $(basename "$ACTIVE_ENV_FILE")"
        return 0
    fi

    return 1
}

source_env_file() {
    if [ ! -f "$ACTIVE_ENV_FILE" ]; then
        print_error "Fichier non trouvé: $ACTIVE_ENV_FILE"
        return 1
    fi

    unset PGHOST PGPORT PGDATABASE PGUSER PGPASSWORD 2>/dev/null || true
    unset PSQL_PATH PG_DUMP_PATH PG_RESTORE_PATH PG_DUMPALL_PATH 2>/dev/null || true

    set -a
    source "$ACTIVE_ENV_FILE"
    set +a

    export PGHOST PGPORT PGDATABASE PGUSER PGPASSWORD

    LOG_DIR="${LOG_BASE_DIR}/$(basename "$ACTIVE_ENV_FILE" | sed 's/^\.env\.//')"
    BACKUP_DIR="${BACKUP_BASE_DIR}/$(basename "$ACTIVE_ENV_FILE" | sed 's/^\.env\.//')"
    
    mkdir -p "$LOG_DIR" "$BACKUP_DIR"

    LOG_FILE="${LOG_DIR}/pg_manager_$(date +%Y%m%d).log"

    return 0
}

create_new_env() {
    print_banner
    echo "Créer une nouvelle configuration"
    echo ""
    
    read -p "Nom de la configuration (ex: instanceX-prod, instance-dev, intanceZ-staging) : " config_name
    
    if [ -z "$config_name" ]; then
        print_error "Nom vide"
        return 1
    fi

    local new_env_file="${CONFIG_DIR}/.env-${config_name}"
    
    if [ -f "$new_env_file" ]; then
        print_warning "Configuration .env-$config_name existe déjà"
        read -p "Écraser ? (o/n) : " overwrite
        if [ "$overwrite" != "o" ]; then
            return 1
        fi
    fi

    print_info "Veuillez configurer les paramètres PostgreSQL"
    echo ""

    read -p "Hôte PostgreSQL (défaut: localhost) : " pg_host
    pg_host=${pg_host:-localhost}

    read -p "Port PostgreSQL (défaut: 5432) : " pg_port
    pg_port=${pg_port:-5432}

    read -p "Nom de la base (défaut: postgres) : " pg_database
    pg_database=${pg_database:-postgres}

    read -p "Utilisateur PostgreSQL (défaut: postgres) : " pg_user
    pg_user=${pg_user:-postgres}

    read -sp "Mot de passe PostgreSQL : " pg_password
    echo ""

    cat > "$new_env_file" << EOF_ENV
# Configuration PostgreSQL - OwnPgBox v${VERSION}
# Profil: $config_name
# Date de création: $(date)

PGHOST=${pg_host}
PGPORT=${pg_port}
PGDATABASE=${pg_database}
PGUSER=${pg_user}
PGPASSWORD=${pg_password}

# PostgreSQL tools paths
PSQL_PATH=$(command -v psql 2>/dev/null || echo "psql")
PG_DUMP_PATH=$(command -v pg_dump 2>/dev/null || echo "pg_dump")
PG_RESTORE_PATH=$(command -v pg_restore 2>/dev/null || echo "pg_restore")
PG_DUMPALL_PATH=$(command -v pg_dumpall 2>/dev/null || echo "pg_dumpall")

# Optional monitoring tools
PG_ACTIVITY_PATH=$(command -v pg_activity 2>/dev/null || echo "pg_activity")
PGBADGER_PATH=$(command -v pgbadger 2>/dev/null || echo "pgbadger")

# Backup options
BACKUP_FORMAT=custom
BACKUP_COMPRESSION=9
EOF_ENV

    chmod 600 "$new_env_file"
    print_success "Configuration créée: .env-$config_name"
    pause
}

delete_env_file() {
    print_banner
    echo "Supprimer une configuration"
    echo ""

    local env_files=()
    while IFS= read -r file; do
        env_files+=("$file")
    done < <(find "$CONFIG_DIR" -maxdepth 1 -name ".env*" -type f 2>/dev/null | sort)

    if [ ${#env_files[@]} -eq 0 ]; then
        print_warning "Aucune configuration"
        pause
        return 1
    fi

    list_env_files
    read -p "Sélectionner une configuration à supprimer (numéro, 0 pour annuler) : " choice

    if [ "$choice" = "0" ]; then
        return 1
    fi

    if ! [[ "$choice" =~ ^[0-9]+$ ]] || [ "$choice" -lt 1 ] || [ "$choice" -gt ${#env_files[@]} ]; then
        print_error "Sélection invalide"
        pause
        return 1
    fi

    local file_to_delete="${env_files[$((choice-1))]}"
    local filename=$(basename "$file_to_delete")

    if [ "$file_to_delete" = "$ACTIVE_ENV_FILE" ]; then
        print_error "Impossible de supprimer la configuration active"
        pause
        return 1
    fi

    print_warning "Fichier à supprimer: $filename"
    read -p "Confirmer la suppression ? (o/n) : " confirm

    if [ "$confirm" = "o" ]; then
        rm -f "$file_to_delete"
        print_success "Configuration supprimée: $filename"
    fi
    pause
}

show_config_details() {
    print_header
    echo "Détails de la configuration active"
    echo ""
    
    echo "Fichier: $ACTIVE_ENV_FILE"
    echo ""
    
    echo "Paramètres de connexion:"
    echo "  Host:     $PGHOST"
    echo "  Port:     $PGPORT"
    echo "  Database: $PGDATABASE"
    echo "  User:     $PGUSER"
    echo ""
    
    echo "Répertoires:"
    echo "  Backups: $BACKUP_DIR"
    echo "  Logs:    $LOG_DIR"
    echo ""
    pause
}

select_initial_config() {
    print_banner
    echo "Sélection de la configuration"
    echo ""

    if select_env_file; then
        if source_env_file; then
            print_success "Configuration chargée et activée"
            sleep 2
            return 0
        else
            print_error "Impossible de charger la configuration"
            pause
            return 1
        fi
    else
        print_warning "Aucune configuration existante"
        echo ""
        echo "1. Créer une nouvelle configuration"
        echo "2. Quitter"
        echo ""
        read -p "Choix : " choice

        case $choice in
            1)
                create_new_env
                if [ -f "${CONFIG_DIR}/.env-"* ]; then
                    if select_env_file; then
                        source_env_file
                        return 0
                    fi
                fi
                return 1
                ;;
            *)
                return 1
                ;;
        esac
    fi

    return 1
}

# ============================================================================
# DATABASE FUNCTIONS
# ============================================================================

test_connection() {
    print_info "Test de connexion PostgreSQL..."
    if $PSQL_PATH -c "SELECT version();" &>/dev/null; then
        print_success "Connexion réussie"
        return 0
    else
        print_error "Impossible de se connecter à PostgreSQL"
        return 1
    fi
}

select_schema() {
    print_header
    echo "Sélection du schéma de travail"
    echo ""

    print_info "Schémas disponibles :"
    $PSQL_PATH -c "\dn" 2>/dev/null || return 1

    echo ""
    read -p "Schéma à utiliser (défaut: public) : " schema_choice
    CURRENT_SCHEMA=${schema_choice:-public}

    if ! $PSQL_PATH -tAc "SELECT 1 FROM information_schema.schemata WHERE schema_name='${CURRENT_SCHEMA}';" &>/dev/null; then
        print_warning "Schéma '$CURRENT_SCHEMA' n'existe pas"
        read -p "Le créer ? (o/n) : " create_schema

        if [ "$create_schema" = "o" ]; then
            if $PSQL_PATH -c "CREATE SCHEMA $CURRENT_SCHEMA;" 2>/dev/null; then
                print_success "Schéma créé"
            else
                print_error "Création échouée"
                CURRENT_SCHEMA="public"
            fi
        else
            CURRENT_SCHEMA="public"
        fi
    fi

    export PGOPTIONS="-c search_path=${CURRENT_SCHEMA},public"
    pause
}

change_schema() {
    print_header
    echo "Changement de schéma"
    print_info "Schéma actuel: $CURRENT_SCHEMA"
    echo ""

    $PSQL_PATH -c "\dn+" 2>/dev/null || return 1

    echo ""
    read -p "Nouveau schéma : " new_schema

    if [ -z "$new_schema" ]; then
        print_warning "Aucun changement"
        pause
        return
    fi

    if $PSQL_PATH -tAc "SELECT 1 FROM information_schema.schemata WHERE schema_name='${new_schema}';" &>/dev/null; then
        CURRENT_SCHEMA="$new_schema"
        export PGOPTIONS="-c search_path=${CURRENT_SCHEMA},public"
        print_success "Schéma changé: $CURRENT_SCHEMA"
    else
        print_error "Schéma '$new_schema' n'existe pas"
    fi

    pause
}

# ============================================================================
# BACKUP FUNCTIONS
# ============================================================================

list_backups() {
    print_header
    echo "Sauvegardes disponibles"
    echo ""

    if [ ! "$(ls -A "$BACKUP_DIR" 2>/dev/null)" ]; then
        print_warning "Aucune sauvegarde dans: $BACKUP_DIR"
        pause
        return
    fi

    print_info "Répertoire: $BACKUP_DIR"
    echo ""

    find "$BACKUP_DIR" -maxdepth 1 \( -name "*.dump" -o -name "*.sql" -o -name "*.tar" \) -type f 2>/dev/null | while read -r file; do
        echo "----------------------------------------"
        echo "Fichier: $(basename "$file")"
        echo "Taille: $(format_size "$file")"
        echo "Date: $(stat -c %y "$file" 2>/dev/null | cut -d' ' -f1 || stat -f %Sm "$file" 2>/dev/null)"

        meta_file="${file}.meta"
        if [ -f "$meta_file" ]; then
            echo ""
            cat "$meta_file"
        fi
    done

    echo "----------------------------------------"
    echo ""
    print_info "Total: $(du -sh "$BACKUP_DIR" | cut -f1)"
    pause
}

create_backup() {
    print_header
    echo "Créer une sauvegarde"
    echo ""

    timestamp=$(get_timestamp)
    backup_name="${PGDATABASE}_backup_${timestamp}"

    echo "Type de sauvegarde :"
    echo "1. Complète (structure + données)"
    echo "2. Structure uniquement"
    echo "3. Données uniquement"
    echo ""
    read -p "Choix (1-3) : " backup_type

    backup_file="${BACKUP_DIR}/${backup_name}.dump"
    cmd="$PG_DUMP_PATH -Fc -d $PGDATABASE"

    case $backup_type in
        2) cmd="$cmd --schema-only" ;;
        3) cmd="$cmd --data-only" ;;
    esac

    cmd="$cmd -f $backup_file"

    print_info "Sauvegarde en cours..."

    if eval "$cmd"; then
        print_success "Sauvegarde créée: $backup_file"

        cat > "${backup_file}.meta" << EOF_META
Date: $(date)
Database: $PGDATABASE
Host: ${PGHOST}:${PGPORT}
Type: $backup_type
Size: $(format_size "$backup_file")
EOF_META

        ls -lh "$backup_file"
    else
        print_error "Sauvegarde échouée"
    fi

    pause
}

restore_backup() {
    print_header
    echo "Restaurer une sauvegarde"
    echo ""

    list_backups

    read -p "Fichier de sauvegarde (chemin ou nom) : " backup_file

    if [ ! -f "$backup_file" ]; then
        if [ -f "$BACKUP_DIR/$backup_file" ]; then
            backup_file="$BACKUP_DIR/$backup_file"
        else
            print_error "Fichier introuvable"
            pause
            return
        fi
    fi

    read -p "Base cible (défaut: $PGDATABASE) : " target_db
    target_db=${target_db:-$PGDATABASE}

    print_warning "Ceci peut écraser les données existantes!"
    read -p "Nettoyer avant restauration ? (o/n) : " clean
    read -p "Confirmer ? (o/n) : " confirm

    if [ "$confirm" != "o" ]; then
        print_info "Restauration annulée"
        pause
        return
    fi

    cmd="$PG_RESTORE_PATH -d $target_db --verbose"
    [ "$clean" = "o" ] && cmd="$cmd --clean"
    cmd="$cmd $backup_file"

    print_info "Restauration en cours..."

    if eval "$cmd"; then
        print_success "Restauration réussie"
    else
        print_error "Restauration échouée"
    fi

    pause
}

cleanup_backups() {
    print_header
    echo "Supprimer les anciennes sauvegardes"
    echo ""

    read -p "Supprimer les fichiers de plus de X jours : " days

    if ! [[ "$days" =~ ^[0-9]+$ ]]; then
        print_error "Nombre invalide"
        pause
        return
    fi

    print_info "Recherche des sauvegardes de plus de $days jours..."

    old_backups=$(find "$BACKUP_DIR" -type f \( -name "*.dump" -o -name "*.sql" -o -name "*.tar" \) -mtime "+$days" 2>/dev/null)

    if [ -z "$old_backups" ]; then
        print_info "Aucun fichier à supprimer"
        pause
        return
    fi

    count=$(echo "$old_backups" | wc -l)
    echo "$old_backups"
    echo ""
    print_warning "Fichiers à supprimer: $count"
    read -p "Confirmer ? (o/n) : " confirm

    if [ "$confirm" = "o" ]; then
        echo "$old_backups" | while read -r file; do
            rm -f "$file" "${file}.meta"
            print_info "Supprimé: $(basename "$file")"
        done
        print_success "Nettoyage terminé"
    fi

    pause
}

# ============================================================================
# MONITORING FUNCTIONS
# ============================================================================

show_db_stats() {
    print_header
    echo "Statistiques: $PGDATABASE"
    echo ""

    $PSQL_PATH << 'EOF'
SELECT 
    datname AS database,
    pg_size_pretty(pg_database_size(datname)) AS size,
    (SELECT count(*) FROM pg_stat_activity WHERE datname = d.datname) AS connections,
    age(datfrozenxid) AS transaction_age
FROM pg_database d
WHERE datname = current_database();
EOF

    pause
}

show_sizes() {
    print_header
    echo "Taille des bases et tables"
    echo ""

    print_info "Bases de données:"
    $PSQL_PATH -c "
    SELECT 
        datname,
        pg_size_pretty(pg_database_size(datname)) as size
    FROM pg_database
    ORDER BY pg_database_size(datname) DESC;"

    pause
}

show_connections() {
    print_header
    echo "Connexions actives"
    echo ""

    $PSQL_PATH -c "
    SELECT 
        pid,
        usename,
        application_name,
        client_addr,
        state,
        query_start,
        LEFT(query, 50) AS query
    FROM pg_stat_activity
    WHERE datname = current_database()
    ORDER BY query_start DESC;"

    pause
}

# ============================================================================
# EXPORT FUNCTIONS
# ============================================================================

export_database() {
    print_header
    echo "Exporter une base de données"
    echo ""

    read -p "Base à exporter (défaut: $PGDATABASE) : " db_name
    db_name=${db_name:-$PGDATABASE}

    timestamp=$(get_timestamp)
    output_file="${BACKUP_DIR}/${db_name}_export_${timestamp}.dump"

    cmd="$PG_DUMP_PATH -Fc -d $db_name -f $output_file"

    print_info "Export en cours..."

    if eval "$cmd"; then
        print_success "Export créé: $output_file"
        ls -lh "$output_file"
    else
        print_error "Export échoué"
    fi

    pause
}

# ============================================================================
# CONFIGURATION MANAGEMENT
# ============================================================================

manage_configuration() {
    while true; do
        print_header
        echo "Gestion des configurations"
        echo ""
        
        list_env_files || echo "Aucune configuration disponible"
        
        echo ""
        echo "1. Charger une autre configuration"
        echo "2. Créer une nouvelle configuration"
        echo "3. Supprimer une configuration"
        echo "4. Afficher la configuration active"
        echo "0. Retour"
        echo ""
        read -p "Choix : " config_choice

        case $config_choice in
            1)
                if select_env_file; then
                    if source_env_file; then
                        print_success "Configuration chargée"
                        CURRENT_SCHEMA="public"
                    else
                        print_error "Impossible de charger la configuration"
                    fi
                fi
                pause
                ;;
            2)
                create_new_env
                ;;
            3)
                delete_env_file
                ;;
            4)
                show_config_details
                ;;
            0)
                break
                ;;
        esac
    done
}

# ============================================================================
# MAIN MENU
# ============================================================================

show_main_menu() {
    print_header
    cat << 'EOF'
═══════════════════════════════════════════════════════════════════
                    MENU PRINCIPAL
═══════════════════════════════════════════════════════════════════
  1. Sauvegardes
  2. Export/Import
  3. Monitoring
  4. Gestion des configurations
  5. Logs
  S. Changer de schéma
  0. Quitter
═══════════════════════════════════════════════════════════════════
EOF
    read -p "Choix : " choice
    echo "$choice"
}

menu_backups() {
    while true; do
        print_header
        echo "Gestion des Sauvegardes"
        echo ""
        echo "1. Créer une sauvegarde"
        echo "2. Lister les sauvegardes"
        echo "3. Restaurer une sauvegarde"
        echo "4. Nettoyer les anciennes sauvegardes"
        echo "0. Retour"
        echo ""
        read -p "Choix : " choice

        case $choice in
            1) create_backup ;;
            2) list_backups ;;
            3) restore_backup ;;
            4) cleanup_backups ;;
            0) break ;;
            *) print_error "Choix invalide" ; pause ;;
        esac
    done
}

menu_export() {
    while true; do
        print_header
        echo "Export/Import de Données"
        echo ""
        echo "1. Exporter une base de données"
        echo "2. Exporter un schéma"
        echo "3. Exporter une table"
        echo "4. Importer depuis un fichier"
        echo "5. Exporter toutes les bases (pg_dumpall)"
        echo "0. Retour"
        echo ""
        read -p "Choix : " choice

        case $choice in
            1) export_database ;;
            2) export_schema ;;
            3) export_table ;;
            4) import_data ;;
            5) export_all_databases ;;
            0) break ;;
            *) print_error "Choix invalide" ; pause ;;
        esac
    done
}

export_schema() {
    print_header
    echo "Exporter un schéma"
    echo ""

    print_info "Schémas disponibles:"
    $PSQL_PATH -c "\dn" 2>/dev/null || { print_error "Aucun schéma"; pause; return; }
    echo ""

    read -p "Schéma à exporter (défaut: $CURRENT_SCHEMA) : " schema_name
    schema_name=${schema_name:-$CURRENT_SCHEMA}

    timestamp=$(get_timestamp)
    output_file="${BACKUP_DIR}/${PGDATABASE}_${schema_name}_${timestamp}.dump"

    print_info "Export en cours..."

    if $PG_DUMP_PATH -Fc -d "$PGDATABASE" -n "$schema_name" -f "$output_file"; then
        print_success "Schéma exporté: $output_file"
        ls -lh "$output_file"
    else
        print_error "Export échoué"
    fi
    pause
}

export_table() {
    print_header
    echo "Exporter une table"
    echo ""

    print_info "Schéma actuel: $CURRENT_SCHEMA"
    print_info "Tables disponibles:"
    $PSQL_PATH -c "\dt $CURRENT_SCHEMA.*" 2>/dev/null || { print_error "Aucune table"; pause; return; }
    echo ""

    read -p "Nom de la table : " table_name
    [ -z "$table_name" ] && { print_error "Table vide"; pause; return; }

    timestamp=$(get_timestamp)
    output_file="${BACKUP_DIR}/${table_name}_${timestamp}.dump"

    print_info "Export en cours..."

    if $PG_DUMP_PATH -Fc -d "$PGDATABASE" -t "${CURRENT_SCHEMA}.${table_name}" -f "$output_file"; then
        print_success "Table exportée: $output_file"
        ls -lh "$output_file"
    else
        print_error "Export échoué"
    fi
    pause
}

import_data() {
    print_header
    echo "Importer des données"
    echo ""

    read -p "Chemin du fichier : " import_file

    if [ ! -e "$import_file" ]; then
        print_error "Fichier introuvable: $import_file"
        pause
        return
    fi

    read -p "Base cible (défaut: $PGDATABASE) : " target_db
    target_db=${target_db:-$PGDATABASE}

    print_warning "Cela peut écraser les données existantes!"
    read -p "Nettoyer avant import (DROP) ? (o/n) : " clean
    read -p "Confirmer ? (o/n) : " confirm

    if [ "$confirm" != "o" ]; then
        print_info "Import annulé"
        pause
        return
    fi

    cmd="$PG_RESTORE_PATH -d $target_db"
    [ "$clean" = "o" ] && cmd="$cmd --clean"
    cmd="$cmd --verbose $import_file"

    print_info "Import en cours..."

    if eval "$cmd"; then
        print_success "Import réussi"
    else
        print_error "Import échoué"
    fi
    pause
}

export_all_databases() {
    print_header
    echo "Exporter toutes les bases (pg_dumpall)"
    echo ""

    timestamp=$(get_timestamp)
    output_file="${BACKUP_DIR}/all_databases_${timestamp}.sql"

    print_warning "Ceci exportera TOUTES les bases, rôles et tablespaces"
    read -p "Continuer ? (o/n) : " confirm

    if [ "$confirm" != "o" ]; then
        pause
        return
    fi

    print_info "Export en cours (cela peut prendre du temps)..."

    if $PG_DUMPALL_PATH -f "$output_file"; then
        print_success "Export créé: $output_file"
        ls -lh "$output_file"
    else
        print_error "Export échoué"
    fi
    pause
}

menu_monitoring() {
    while true; do
        print_header
        echo "Monitoring"
        echo ""
        echo "1. Statistiques de la base"
        echo "2. Tailles"
        echo "3. Connexions actives"
        echo "4. Requêtes lentes"
        echo "5. Verrouillages (locks)"
        echo "6. Statistiques des tables"
        echo "7. Index inutilisés"
        echo "8. Santé de la base (bloat, vacuum)"
        echo "0. Retour"
        echo ""
        read -p "Choix : " choice

        case $choice in
            1) show_db_stats ;;
            2) show_sizes ;;
            3) show_connections ;;
            4) show_slow_queries ;;
            5) show_locks ;;
            6) show_table_stats ;;
            7) show_unused_indexes ;;
            8) show_db_health ;;
            0) break ;;
            *) print_error "Choix invalide" ; pause ;;
        esac
    done
}

show_slow_queries() {
    print_header
    echo "Requêtes lentes"
    echo ""

    print_info "Requêtes en cours (triées par durée):"
    $PSQL_PATH -c "
    SELECT 
        pid,
        now() - query_start AS duration,
        usename,
        state,
        LEFT(query, 100) AS query
    FROM pg_stat_activity
    WHERE state != 'idle'
        AND datname = current_database()
        AND query NOT LIKE '%pg_stat_activity%'
    ORDER BY duration DESC;"

    pause
}

show_locks() {
    print_header
    echo "Verrouillages (LOCKS)"
    echo ""

    print_info "Verrous actifs:"
    $PSQL_PATH -c "
    SELECT 
        l.locktype,
        l.relation::regclass AS relation,
        l.mode,
        l.granted,
        a.pid,
        a.usename,
        a.state,
        LEFT(a.query, 50) AS query
    FROM pg_locks l
    LEFT JOIN pg_stat_activity a ON l.pid = a.pid
    WHERE l.database = (SELECT oid FROM pg_database WHERE datname = current_database())
    ORDER BY l.granted, l.pid;"

    pause
}

show_table_stats() {
    print_header
    echo "Statistiques des tables (Schéma: $CURRENT_SCHEMA)"
    echo ""

    print_info "Activité des tables:"
    $PSQL_PATH -c "
    SELECT 
        schemaname || '.' || relname AS table,
        seq_scan,
        seq_tup_read,
        idx_scan,
        idx_tup_fetch,
        n_tup_ins AS inserts,
        n_tup_upd AS updates,
        n_tup_del AS deletes,
        n_live_tup AS live_tuples,
        n_dead_tup AS dead_tuples,
        last_vacuum,
        last_autovacuum
    FROM pg_stat_user_tables
    WHERE schemaname = '$CURRENT_SCHEMA'
    ORDER BY seq_scan + idx_scan DESC
    LIMIT 20;"

    pause
}

show_unused_indexes() {
    print_header
    echo "Index inutilisés (Schéma: $CURRENT_SCHEMA)"
    echo ""

    print_info "Index potentiellement inutilisés:"
    $PSQL_PATH -c "
    SELECT 
        schemaname || '.' || tablename AS table,
        indexname,
        pg_size_pretty(pg_relation_size(indexrelid)) AS index_size,
        idx_scan AS number_of_scans,
        idx_tup_read,
        idx_tup_fetch
    FROM pg_stat_user_indexes
    WHERE idx_scan = 0
        AND indexrelname NOT LIKE '%pkey'
        AND schemaname = '$CURRENT_SCHEMA'
    ORDER BY pg_relation_size(indexrelid) DESC;"

    pause
}

show_db_health() {
    print_header
    echo "Santé de la base de données"
    echo ""

    print_info "Bloat des tables (Schéma: $CURRENT_SCHEMA):"
    $PSQL_PATH -c "
    SELECT 
        schemaname || '.' || tablename AS table,
        pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS total_size,
        ROUND(100 * n_dead_tup / NULLIF(n_live_tup + n_dead_tup, 0), 2) AS dead_tuples_pct,
        n_dead_tup AS dead_tuples,
        last_vacuum,
        last_autovacuum
    FROM pg_stat_user_tables
    WHERE n_dead_tup > 1000
        AND schemaname = '$CURRENT_SCHEMA'
    ORDER BY n_dead_tup DESC
    LIMIT 20;"

    echo ""
    print_info "Tables nécessitant VACUUM:"
    $PSQL_PATH -c "
    SELECT 
        schemaname || '.' || tablename AS table,
        n_dead_tup AS dead_tuples,
        ROUND(100 * n_dead_tup / NULLIF(n_live_tup + n_dead_tup, 0), 2) AS dead_pct,
        last_vacuum,
        last_autovacuum
    FROM pg_stat_user_tables
    WHERE n_dead_tup > 1000
        AND schemaname = '$CURRENT_SCHEMA'
        AND (last_vacuum IS NULL OR last_vacuum < NOW() - INTERVAL '7 days')
    ORDER BY n_dead_tup DESC;"

    echo ""
    read -p "Exécuter VACUUM ANALYZE ? (o/n) : " run_vacuum
    if [ "$run_vacuum" = "o" ]; then
        print_info "Exécution en cours..."
        if $PSQL_PATH -c "VACUUM ANALYZE;"; then
            print_success "VACUUM ANALYZE terminé"
        else
            print_error "VACUUM échoué"
        fi
    fi
    pause
}

view_logs() {
    print_header
    echo "Consulter les logs"
    echo ""

    if [ ! -d "$LOG_DIR" ] || [ -z "$(ls -A "$LOG_DIR" 2>/dev/null)" ]; then
        print_warning "Aucun fichier de logs"
        pause
        return
    fi

    print_info "Fichiers disponibles:"
    ls -lth "$LOG_DIR"/*.log 2>/dev/null | head -10

    echo ""
    echo "1. Afficher le log du jour"
    echo "2. Afficher un log spécifique"
    echo "3. Rechercher dans les logs"
    echo "4. Afficher les dernières lignes"
    echo "0. Retour"
    echo ""
    read -p "Choix : " choice

    case $choice in
        1)
            if [ -f "$LOG_FILE" ]; then
                less "$LOG_FILE"
            else
                print_error "Aucun log pour aujourd'hui"
            fi
            ;;
        2)
            read -p "Nom du fichier : " log_name
            if [ -f "$LOG_DIR/$log_name" ]; then
                less "$LOG_DIR/$log_name"
            else
                print_error "Fichier introuvable"
            fi
            ;;
        3)
            read -p "Terme à rechercher : " search_term
            grep -rn "$search_term" "$LOG_DIR"/*.log 2>/dev/null || print_warning "Aucun résultat"
            ;;
        4)
            read -p "Nombre de lignes (défaut: 50) : " lines
            lines=${lines:-50}
            if [ -f "$LOG_FILE" ]; then
                tail -n "$lines" "$LOG_FILE"
            fi
            ;;
    esac
    pause
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

main() {
    init_dirs

    if ! select_initial_config; then
        print_error "Impossible de démarrer sans configuration"
        exit 1
    fi

    if ! test_connection; then
        print_error "Connexion échouée avec la configuration sélectionnée"
        print_info "Vérifiez les paramètres: $ACTIVE_ENV_FILE"
        exit 1
    fi

    select_schema

    while true; do
        choice=$(show_main_menu)

        case $choice in
            1) menu_backups ;;
            2) menu_export ;;
            3) menu_monitoring ;;
            4) manage_configuration ;;
            5) view_logs ;;
            [Ss]) change_schema ;;
            0) 
                print_banner
                echo -e "${GREEN}Merci d'avoir utilisé OwnPgBox!${NC}"
                [ -n "$LOG_FILE" ] && log "INFO" "Script arrêté"
                exit 0
                ;;
            *) print_error "Choix invalide" ; pause ;;
        esac
    done
}

trap 'echo -e "\n${YELLOW}Interruption...${NC}"; [ -n "$LOG_FILE" ] && log "WARNING" "Interruption utilisateur"; exit 130' INT TERM

main "$@"
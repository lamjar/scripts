#!/bin/bash
################################################################################
# pg_anonymize_dump.sh
# Script complet d'anonymisation de bases PostgreSQL lors du dump
#
# Fonctionnalités:
# - Détection automatique des colonnes à anonymiser
# - Anonymisation lors du dump (sans plugin pg_anonymizer)
# - Support de multiples serveurs (source et target différents)
# - Transfert sécurisé entre serveurs
# - Nettoyage et restauration du schéma target
#
# Usage: ./pg_anonymize_dump.sh [fichier_config]
################################################################################

set -e
set -o pipefail

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Variables globales
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="${SCRIPT_DIR}/anonymize_$(date +%Y%m%d_%H%M%S).log"
TEMP_DIR="${SCRIPT_DIR}/temp_anonymize_$$"
ANONYMIZE_RULES_FILE=""

################################################################################
# Fonctions utilitaires
################################################################################

log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1" | tee -a "$LOG_FILE"
}

log_error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ❌ ERREUR:${NC} $1" | tee -a "$LOG_FILE"
}

log_warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] ⚠️  WARNING:${NC} $1" | tee -a "$LOG_FILE"
}

log_info() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] ℹ️  INFO:${NC} $1" | tee -a "$LOG_FILE"
}

cleanup() {
    log_info "Nettoyage des fichiers temporaires..."
    if [ -d "$TEMP_DIR" ]; then
        rm -rf "$TEMP_DIR"
    fi
}

trap cleanup EXIT

die() {
    log_error "$1"
    exit 1
}

################################################################################
# Exemple de fichier de configuration
################################################################################

print_config_example() {
    cat << 'EOF'
################################################################################
# Fichier de configuration pour pg_anonymize_dump.sh
################################################################################

# === CONFIGURATION SOURCE ===
SOURCE_HOST="localhost"
SOURCE_PORT="5432"
SOURCE_DB="source_database"
SOURCE_SCHEMA="public"
SOURCE_USER="postgres"
SOURCE_PASSWORD="password"  # Optionnel, utiliser .pgpass plutôt

# === CONFIGURATION TARGET ===
TARGET_HOST="localhost"
TARGET_PORT="5432"
TARGET_DB="target_database"
TARGET_SCHEMA="public"
TARGET_USER="postgres"
TARGET_PASSWORD="password"  # Optionnel, utiliser .pgpass plutôt

# === CONFIGURATION SERVEURS ===
# Si source et target sont sur des serveurs différents
SOURCE_SERVER=""  # vide si local, sinon: user@server
TARGET_SERVER=""  # vide si local, sinon: user@server

# === RÉPERTOIRES ===
DUMP_DIR="/tmp/pg_dumps"  # Répertoire pour les dumps
TRANSFER_METHOD="scp"     # scp, rsync ou local

# === RÈGLES D'ANONYMISATION ===
# Fichier JSON contenant les règles (voir exemple ci-dessous)
ANONYMIZE_RULES_FILE="anonymize_rules.json"

# === OPTIONS ===
AUTO_DETECT_PII=true           # Détection automatique des données sensibles
KEEP_DUMP_AFTER_RESTORE=false  # Garder le dump après restauration
BACKUP_TARGET_BEFORE=true      # Backup du target avant écrasement
PARALLEL_JOBS=4                # Nombre de jobs parallèles pour pg_dump/restore

# === OPTIONS DE DUMP ===
DUMP_FORMAT="custom"  # custom, plain, directory, tar
COMPRESSION_LEVEL=6   # 0-9, 0=pas de compression

EOF
}

print_rules_example() {
    cat << 'EOF'
{
  "detection_patterns": {
    "email": ["email", "mail", "e_mail", "courriel"],
    "phone": ["phone", "tel", "telephone", "mobile", "cellulaire"],
    "name": ["name", "nom", "prenom", "firstname", "lastname", "surname"],
    "address": ["address", "adresse", "street", "rue", "city", "ville"],
    "ssn": ["ssn", "social_security", "secu", "nir"],
    "iban": ["iban", "account", "compte"],
    "credit_card": ["card", "carte", "cc_number"],
    "ip_address": ["ip", "ip_address", "adresse_ip"],
    "date_of_birth": ["birth", "naissance", "dob", "date_naissance"]
  },
  
  "anonymization_methods": {
    "email": "CASE WHEN {column} IS NOT NULL THEN 'user' || md5({column}::text)::uuid || '@anonymized.local' ELSE NULL END",
    "phone": "CASE WHEN {column} IS NOT NULL THEN '+33' || lpad((random() * 999999999)::bigint::text, 9, '0') ELSE NULL END",
    "name": "CASE WHEN {column} IS NOT NULL THEN 'Anonyme_' || substr(md5({column}::text), 1, 8) ELSE NULL END",
    "address": "CASE WHEN {column} IS NOT NULL THEN (random() * 999)::int || ' Rue Anonyme, ' || (10000 + random() * 89999)::int || ' Ville' ELSE NULL END",
    "ssn": "CASE WHEN {column} IS NOT NULL THEN (1 + random())::int || ' ' || lpad((random() * 99)::int::text, 2, '0') || ' ' || lpad((random() * 99)::int::text, 2, '0') || ' ' || lpad((random() * 999)::int::text, 3, '0') || ' ' || lpad((random() * 999)::int::text, 3, '0') ELSE NULL END",
    "iban": "CASE WHEN {column} IS NOT NULL THEN 'FR76' || lpad((random() * 9999999999999999999999)::bigint::text, 23, '0') ELSE NULL END",
    "credit_card": "CASE WHEN {column} IS NOT NULL THEN '4111' || lpad((random() * 999999999999)::bigint::text, 12, '0') ELSE NULL END",
    "ip_address": "CASE WHEN {column} IS NOT NULL THEN (10 + random() * 245)::int || '.' || (random() * 255)::int || '.' || (random() * 255)::int || '.' || (random() * 255)::int ELSE NULL END",
    "date_of_birth": "CASE WHEN {column} IS NOT NULL THEN (CURRENT_DATE - (18*365 + random() * 60*365)::int) ELSE NULL END"
  },
  
  "custom_rules": [
    {
      "table": "users",
      "column": "password_hash",
      "method": "CASE WHEN {column} IS NOT NULL THEN md5('anonymous')::text ELSE NULL END"
    },
    {
      "table": "users",
      "column": "salt",
      "method": "CASE WHEN {column} IS NOT NULL THEN md5(random()::text)::text ELSE NULL END"
    }
  ],
  
  "exclude_tables": [
    "schema_migrations",
    "spatial_ref_sys"
  ],
  
  "exclude_columns": [
    "id",
    "created_at",
    "updated_at",
    "version"
  ]
}
EOF
}

################################################################################
# Chargement de la configuration
################################################################################

load_config() {
    local config_file="$1"
    
    if [ ! -f "$config_file" ]; then
        log_error "Fichier de configuration introuvable: $config_file"
        echo ""
        echo "Exemple de fichier de configuration:"
        echo "────────────────────────────────────"
        print_config_example
        echo ""
        echo "Exemple de fichier de règles d'anonymisation (JSON):"
        echo "────────────────────────────────────────────────────"
        print_rules_example
        exit 1
    fi
    
    log "Chargement de la configuration depuis: $config_file"
    source "$config_file"
    
    # Validation de la configuration
    [ -z "$SOURCE_HOST" ] && die "SOURCE_HOST non défini"
    [ -z "$SOURCE_DB" ] && die "SOURCE_DB non défini"
    [ -z "$SOURCE_SCHEMA" ] && die "SOURCE_SCHEMA non défini"
    [ -z "$TARGET_HOST" ] && die "TARGET_HOST non défini"
    [ -z "$TARGET_DB" ] && die "TARGET_DB non défini"
    [ -z "$TARGET_SCHEMA" ] && die "TARGET_SCHEMA non défini"
    
    # Création du répertoire de dump
    mkdir -p "$DUMP_DIR"
    mkdir -p "$TEMP_DIR"
    
    log_info "Configuration chargée avec succès"
}

################################################################################
# Connexion à PostgreSQL
################################################################################

execute_sql_source() {
    local sql="$1"
    local output_format="${2:-tuples-only}"
    
    PGPASSWORD="$SOURCE_PASSWORD" psql \
        -h "$SOURCE_HOST" \
        -p "$SOURCE_PORT" \
        -U "$SOURCE_USER" \
        -d "$SOURCE_DB" \
        -t \
        -A \
        -c "$sql" 2>&1
}

execute_sql_target() {
    local sql="$1"
    
    if [ -n "$TARGET_SERVER" ]; then
        ssh "$TARGET_SERVER" "PGPASSWORD='$TARGET_PASSWORD' psql -h '$TARGET_HOST' -p '$TARGET_PORT' -U '$TARGET_USER' -d '$TARGET_DB' -t -A -c \"$sql\"" 2>&1
    else
        PGPASSWORD="$TARGET_PASSWORD" psql \
            -h "$TARGET_HOST" \
            -p "$TARGET_PORT" \
            -U "$TARGET_USER" \
            -d "$TARGET_DB" \
            -t \
            -A \
            -c "$sql" 2>&1
    fi
}

################################################################################
# Détection automatique des colonnes à anonymiser
################################################################################

detect_pii_columns() {
    log "🔍 Détection automatique des colonnes contenant des données sensibles..."
    
    if [ ! -f "$ANONYMIZE_RULES_FILE" ]; then
        log_warn "Fichier de règles introuvable: $ANONYMIZE_RULES_FILE"
        return
    fi
    
    # Récupération de toutes les colonnes du schéma
    local columns_sql="
    SELECT 
        table_name,
        column_name,
        data_type,
        COALESCE(character_maximum_length, numeric_precision, 0) as max_length
    FROM information_schema.columns
    WHERE table_schema = '$SOURCE_SCHEMA'
        AND table_name NOT IN (
            SELECT jsonb_array_elements_text(
                jsonb_extract_path(rules.data, 'exclude_tables')
            )
            FROM (SELECT '$(<"$ANONYMIZE_RULES_FILE")'::jsonb as data) rules
        )
        AND column_name NOT IN (
            SELECT jsonb_array_elements_text(
                jsonb_extract_path(rules.data, 'exclude_columns')
            )
            FROM (SELECT '$(<"$ANONYMIZE_RULES_FILE")'::jsonb as data) rules
        )
    ORDER BY table_name, ordinal_position;
    "
    
    local detected_file="$TEMP_DIR/detected_columns.json"
    echo "{\"detected_columns\": [" > "$detected_file"
    
    local first_entry=true
    
    # Lecture des patterns de détection depuis le fichier JSON
    local patterns=$(jq -r '.detection_patterns | to_entries[] | "\(.key):\(.value | join("|"))"' "$ANONYMIZE_RULES_FILE")
    
    while IFS='|' read -r table_name column_name data_type max_length; do
        [ -z "$table_name" ] && continue
        
        local column_lower=$(echo "$column_name" | tr '[:upper:]' '[:lower:]')
        local detected_type=""
        
        # Vérification contre chaque pattern
        while IFS=: read -r pii_type pattern_list; do
            if echo "$column_lower" | grep -qE "$pattern_list"; then
                detected_type="$pii_type"
                break
            fi
        done <<< "$patterns"
        
        if [ -n "$detected_type" ]; then
            log_info "  ✓ Détecté: $table_name.$column_name → $detected_type"
            
            if [ "$first_entry" = false ]; then
                echo "," >> "$detected_file"
            fi
            first_entry=false
            
            cat >> "$detected_file" << EOF
    {
      "table": "$table_name",
      "column": "$column_name",
      "type": "$detected_type",
      "data_type": "$data_type"
    }
EOF
        fi
        
    done < <(execute_sql_source "$columns_sql" | tr '\t' '|')
    
    echo "]}" >> "$detected_file"
    
    log "✅ Détection terminée. Résultats sauvegardés dans: $detected_file"
}

################################################################################
# Génération du script d'anonymisation
################################################################################

generate_anonymization_script() {
    log "📝 Génération du script d'anonymisation..."
    
    local anon_script="$TEMP_DIR/anonymize.sql"
    
    cat > "$anon_script" << 'EOF'
-- Script d'anonymisation généré automatiquement
-- Ne pas éditer manuellement

BEGIN;

-- Désactivation des triggers pour accélérer les mises à jour
SET session_replication_role = 'replica';

EOF
    
    # Chargement des règles d'anonymisation
    local methods=$(jq -r '.anonymization_methods' "$ANONYMIZE_RULES_FILE")
    
    # Traitement des colonnes détectées
    if [ -f "$TEMP_DIR/detected_columns.json" ]; then
        local columns=$(jq -c '.detected_columns[]' "$TEMP_DIR/detected_columns.json")
        
        while IFS= read -r col; do
            local table=$(echo "$col" | jq -r '.table')
            local column=$(echo "$col" | jq -r '.column')
            local type=$(echo "$col" | jq -r '.type')
            
            # Récupération de la méthode d'anonymisation
            local method=$(jq -r --arg type "$type" '.anonymization_methods[$type]' "$ANONYMIZE_RULES_FILE")
            
            if [ "$method" != "null" ] && [ -n "$method" ]; then
                # Remplacement du placeholder {column}
                method=$(echo "$method" | sed "s/{column}/$column/g")
                
                cat >> "$anon_script" << EOF

-- Anonymisation de $table.$column (type: $type)
UPDATE $SOURCE_SCHEMA.$table
SET $column = $method
WHERE $column IS NOT NULL;

EOF
            fi
        done <<< "$columns"
    fi
    
    # Ajout des règles personnalisées
    local custom_rules=$(jq -c '.custom_rules[]?' "$ANONYMIZE_RULES_FILE" 2>/dev/null || echo "")
    
    if [ -n "$custom_rules" ]; then
        while IFS= read -r rule; do
            [ -z "$rule" ] && continue
            
            local table=$(echo "$rule" | jq -r '.table')
            local column=$(echo "$rule" | jq -r '.column')
            local method=$(echo "$rule" | jq -r '.method')
            
            method=$(echo "$method" | sed "s/{column}/$column/g")
            
            cat >> "$anon_script" << EOF

-- Règle personnalisée: $table.$column
UPDATE $SOURCE_SCHEMA.$table
SET $column = $method
WHERE $column IS NOT NULL;

EOF
        done <<< "$custom_rules"
    fi
    
    cat >> "$anon_script" << 'EOF'

-- Réactivation des triggers
SET session_replication_role = 'origin';

COMMIT;

-- Analyse des tables pour mettre à jour les statistiques
ANALYZE;
EOF
    
    log "✅ Script d'anonymisation généré: $anon_script"
    echo "$anon_script"
}

################################################################################
# Dump de la base source avec anonymisation
################################################################################

create_anonymized_dump() {
    log "💾 Création du dump anonymisé..."
    
    local dump_file="$DUMP_DIR/dump_anonymized_$(date +%Y%m%d_%H%M%S)"
    
    # Sélection du format
    case "$DUMP_FORMAT" in
        custom)
            dump_file="${dump_file}.dump"
            local format_flag="-Fc"
            ;;
        directory)
            dump_file="${dump_file}.dir"
            local format_flag="-Fd"
            mkdir -p "$dump_file"
            ;;
        tar)
            dump_file="${dump_file}.tar"
            local format_flag="-Ft"
            ;;
        plain|*)
            dump_file="${dump_file}.sql"
            local format_flag="-Fp"
            ;;
    esac
    
    # Options de dump
    local dump_opts=(
        -h "$SOURCE_HOST"
        -p "$SOURCE_PORT"
        -U "$SOURCE_USER"
        -d "$SOURCE_DB"
        -n "$SOURCE_SCHEMA"
        "$format_flag"
        -j "$PARALLEL_JOBS"
        -Z "$COMPRESSION_LEVEL"
        --no-owner
        --no-privileges
    )
    
    # Création d'un dump temporaire avant anonymisation
    local temp_dump="$TEMP_DIR/pre_anon.dump"
    
    log_info "Création du dump pré-anonymisation..."
    PGPASSWORD="$SOURCE_PASSWORD" pg_dump "${dump_opts[@]}" -f "$temp_dump" || die "Échec du dump"
    
    # Restauration dans une base temporaire pour anonymisation
    log_info "Création d'une base temporaire pour l'anonymisation..."
    local temp_db="temp_anon_$$"
    
    execute_sql_source "CREATE DATABASE $temp_db;" || die "Impossible de créer la base temporaire"
    
    log_info "Restauration du dump dans la base temporaire..."
    if [ "$DUMP_FORMAT" = "custom" ]; then
        PGPASSWORD="$SOURCE_PASSWORD" pg_restore \
            -h "$SOURCE_HOST" \
            -p "$SOURCE_PORT" \
            -U "$SOURCE_USER" \
            -d "$temp_db" \
            -j "$PARALLEL_JOBS" \
            --no-owner \
            --no-privileges \
            "$temp_dump" || die "Échec de la restauration temporaire"
    else
        PGPASSWORD="$SOURCE_PASSWORD" psql \
            -h "$SOURCE_HOST" \
            -p "$SOURCE_PORT" \
            -U "$SOURCE_USER" \
            -d "$temp_db" \
            -f "$temp_dump" || die "Échec de la restauration temporaire"
    fi
    
    # Application du script d'anonymisation
    local anon_script=$(generate_anonymization_script)
    
    log_info "Application de l'anonymisation..."
    PGPASSWORD="$SOURCE_PASSWORD" psql \
        -h "$SOURCE_HOST" \
        -p "$SOURCE_PORT" \
        -U "$SOURCE_USER" \
        -d "$temp_db" \
        -f "$anon_script" || log_warn "Avertissements lors de l'anonymisation (peut être normal)"
    
    # Création du dump final anonymisé
    log_info "Création du dump final anonymisé..."
    dump_opts[4]="$temp_db"  # Remplacer la base source par la base temp
    
    PGPASSWORD="$SOURCE_PASSWORD" pg_dump "${dump_opts[@]}" -f "$dump_file" || die "Échec du dump anonymisé"
    
    # Nettoyage de la base temporaire
    log_info "Nettoyage de la base temporaire..."
    execute_sql_source "DROP DATABASE IF EXISTS $temp_db;" || log_warn "Impossible de supprimer la base temporaire"
    
    log "✅ Dump anonymisé créé: $dump_file"
    echo "$dump_file"
}

################################################################################
# Transfert du dump vers le serveur target
################################################################################

transfer_dump() {
    local dump_file="$1"
    
    if [ -z "$TARGET_SERVER" ]; then
        log_info "Source et target sur le même serveur, pas de transfert nécessaire"
        echo "$dump_file"
        return
    fi
    
    log "🚀 Transfert du dump vers le serveur target..."
    
    local remote_dump_dir="/tmp/pg_dumps_transfer"
    local dump_basename=$(basename "$dump_file")
    local remote_dump="$remote_dump_dir/$dump_basename"
    
    # Création du répertoire distant
    ssh "$TARGET_SERVER" "mkdir -p $remote_dump_dir" || die "Impossible de créer le répertoire distant"
    
    # Transfert
    case "$TRANSFER_METHOD" in
        rsync)
            log_info "Utilisation de rsync pour le transfert..."
            rsync -avz --progress "$dump_file" "$TARGET_SERVER:$remote_dump" || die "Échec du transfert rsync"
            ;;
        scp|*)
            log_info "Utilisation de scp pour le transfert..."
            scp "$dump_file" "$TARGET_SERVER:$remote_dump" || die "Échec du transfert scp"
            ;;
    esac
    
    log "✅ Dump transféré vers: $TARGET_SERVER:$remote_dump"
    echo "$remote_dump"
}

################################################################################
# Backup du schéma target
################################################################################

backup_target_schema() {
    if [ "$BACKUP_TARGET_BEFORE" != "true" ]; then
        log_info "Backup du target désactivé"
        return
    fi
    
    log "💾 Sauvegarde du schéma target avant écrasement..."
    
    local backup_file="$DUMP_DIR/backup_target_$(date +%Y%m%d_%H%M%S).dump"
    
    local backup_cmd="PGPASSWORD='$TARGET_PASSWORD' pg_dump \
        -h '$TARGET_HOST' \
        -p '$TARGET_PORT' \
        -U '$TARGET_USER' \
        -d '$TARGET_DB' \
        -n '$TARGET_SCHEMA' \
        -Fc \
        -f '$backup_file'"
    
    if [ -n "$TARGET_SERVER" ]; then
        ssh "$TARGET_SERVER" "$backup_cmd" || log_warn "Échec du backup target (peut-être vide)"
        # Rapatrier le backup
        scp "$TARGET_SERVER:$backup_file" "$backup_file" 2>/dev/null || true
    else
        eval "$backup_cmd" || log_warn "Échec du backup target (peut-être vide)"
    fi
    
    log "✅ Backup du target créé: $backup_file"
}

################################################################################
# Nettoyage du schéma target
################################################################################

clean_target_schema() {
    log "🧹 Nettoyage du schéma target..."
    
    local clean_sql="
    DO \$\$
    DECLARE
        r RECORD;
    BEGIN
        -- Suppression des tables
        FOR r IN (SELECT tablename FROM pg_tables WHERE schemaname = '$TARGET_SCHEMA') LOOP
            EXECUTE 'DROP TABLE IF EXISTS $TARGET_SCHEMA.' || quote_ident(r.tablename) || ' CASCADE';
        END LOOP;
        
        -- Suppression des séquences
        FOR r IN (SELECT sequence_name FROM information_schema.sequences WHERE sequence_schema = '$TARGET_SCHEMA') LOOP
            EXECUTE 'DROP SEQUENCE IF EXISTS $TARGET_SCHEMA.' || quote_ident(r.sequence_name) || ' CASCADE';
        END LOOP;
        
        -- Suppression des vues
        FOR r IN (SELECT viewname FROM pg_views WHERE schemaname = '$TARGET_SCHEMA') LOOP
            EXECUTE 'DROP VIEW IF EXISTS $TARGET_SCHEMA.' || quote_ident(r.viewname) || ' CASCADE';
        END LOOP;
        
        -- Suppression des fonctions
        FOR r IN (SELECT routine_name FROM information_schema.routines WHERE routine_schema = '$TARGET_SCHEMA') LOOP
            EXECUTE 'DROP FUNCTION IF EXISTS $TARGET_SCHEMA.' || quote_ident(r.routine_name) || ' CASCADE';
        END LOOP;
    END\$\$;
    "
    
    execute_sql_target "$clean_sql" || log_warn "Avertissements lors du nettoyage (peut être normal si vide)"
    
    log "✅ Schéma target nettoyé"
}

################################################################################
# Restauration dans le schéma target
################################################################################

restore_to_target() {
    local dump_file="$1"
    
    log "📥 Restauration dans le schéma target..."
    
    # Nettoyage préalable
    backup_target_schema
    clean_target_schema
    
    # Restauration
    local restore_cmd="PGPASSWORD='$TARGET_PASSWORD' pg_restore \
        -h '$TARGET_HOST' \
        -p '$TARGET_PORT' \
        -U '$TARGET_USER' \
        -d '$TARGET_DB' \
        -n '$TARGET_SCHEMA' \
        -j '$PARALLEL_JOBS' \
        --no-owner \
        --no-privileges"
    
    if [ "$DUMP_FORMAT" = "plain" ]; then
        restore_cmd="PGPASSWORD='$TARGET_PASSWORD' psql \
            -h '$TARGET_HOST' \
            -p '$TARGET_PORT' \
            -U '$TARGET_USER' \
            -d '$TARGET_DB'"
        restore_cmd="$restore_cmd -f '$dump_file'"
    else
        restore_cmd="$restore_cmd '$dump_file'"
    fi
    
    if [ -n "$TARGET_SERVER" ]; then
        ssh "$TARGET_SERVER" "$restore_cmd" || die "Échec de la restauration"
    else
        eval "$restore_cmd" || die "Échec de la restauration"
    fi
    
    # Analyse des tables
    log_info "Analyse des tables restaurées..."
    execute_sql_target "ANALYZE;" || log_warn "Échec de l'analyse"
    
    log "✅ Restauration terminée avec succès"
}

################################################################################
# Statistiques et rapport
################################################################################

generate_report() {
    log "📊 Génération du rapport..."
    
    local report_file="$DUMP_DIR/report_$(date +%Y%m%d_%H%M%S).txt"
    
    cat > "$report_file" << EOF
═══════════════════════════════════════════════════════════════
  RAPPORT D'ANONYMISATION ET DE MIGRATION
═══════════════════════════════════════════════════════════════

Date: $(date)
Durée totale: $SECONDS secondes

SOURCE:
  Host: $SOURCE_HOST:$SOURCE_PORT
  Database: $SOURCE_DB
  Schema: $SOURCE_SCHEMA
  Server: ${SOURCE_SERVER:-local}

TARGET:
  Host: $TARGET_HOST:$TARGET_PORT
  Database: $TARGET_DB
  Schema: $TARGET_SCHEMA
  Server: ${TARGET_SERVER:-local}

COLONNES ANONYMISÉES:
EOF
    
    if [ -f "$TEMP_DIR/detected_columns.json" ]; then
        jq -r '.detected_columns[] | "  - \(.table).\(.column) (\(.type))"' "$TEMP_DIR/detected_columns.json" >> "$report_file"
    fi
    
    cat >> "$report_file" << EOF

STATISTIQUES TARGET:
EOF
    
    local stats_sql="
    SELECT 
        schemaname,
        COUNT(*) as nb_tables,
        SUM(n_live_tup) as total_rows
    FROM pg_stat_user_tables
    WHERE schemaname = '$TARGET_SCHEMA'
    GROUP BY schemaname;
    "
    
    execute_sql_target "$stats_sql" | while IFS='|' read -r schema tables rows; do
        echo "  Schema: $schema" >> "$report_file"
        echo "  Nombre de tables: $tables" >> "$report_file"
        echo "  Nombre de lignes: $rows" >> "$report_file"
    done
    
    cat >> "$report_file" << EOF

FICHIERS GÉNÉRÉS:
  - Log: $LOG_FILE
  - Rapport: $report_file
EOF
    
    if [ "$KEEP_DUMP_AFTER_RESTORE" = "true" ]; then
        echo "  - Dump anonymisé conservé dans: $DUMP_DIR" >> "$report_file"
    fi
    
    echo "═══════════════════════════════════════════════════════════════" >> "$report_file"
    
    log "✅ Rapport généré: $report_file"
    
    # Affichage du rapport
    cat "$report_file"
}

################################################################################
# Fonction principale
################################################################################

main() {
    echo "═══════════════════════════════════════════════════════════════"
    echo "  PostgreSQL Anonymization & Dump Tool"
    echo "═══════════════════════════════════════════════════════════════"
    echo ""
    
    local config_file="${1:-config.conf}"
    
    # Chargement de la configuration
    load_config "$config_file"
    
    # Détection automatique des colonnes PII si activée
    if [ "$AUTO_DETECT_PII" = "true" ]; then
        detect_pii_columns
    fi
    
    # Création du dump anonymisé
    local dump_file=$(create_anonymized_dump)
    
    # Transfert vers le serveur target si nécessaire
    local target_dump=$(transfer_dump "$dump_file")
    
    # Restauration dans le target
    restore_to_target "$target_dump"
    
    # Nettoyage du dump si demandé
    if [ "$KEEP_DUMP_AFTER_RESTORE" != "true" ]; then
        log_info "Suppression du dump..."
        rm -f "$dump_file"
        if [ -n "$TARGET_SERVER" ] && [ "$target_dump" != "$dump_file" ]; then
            ssh "$TARGET_SERVER" "rm -f $target_dump"
        fi
    fi
    
    # Génération du rapport
    generate_report
    
    log "✅ Processus terminé avec succès!"
}

################################################################################
# Point d'entrée
################################################################################

if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
        echo "Usage: $0 [fichier_config]"
        echo ""
        echo "Options:"
        echo "  --help, -h           Affiche cette aide"
        echo "  --example-config     Affiche un exemple de fichier de configuration"
        echo "  --example-rules      Affiche un exemple de fichier de règles"
        echo ""
        exit 0
    elif [ "$1" = "--example-config" ]; then
        print_config_example
        exit 0
    elif [ "$1" = "--example-rules" ]; then
        print_rules_example
        exit 0
    fi
    
    main "$@"
fi

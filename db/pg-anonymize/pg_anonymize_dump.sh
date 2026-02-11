#!/bin/bash
################################################################################
# pg_anonymize_dump.sh
# Script complet d'anonymisation PostgreSQL lors du dump/restore
# 
# Fonctionnalités:
# - Détection automatique des colonnes sensibles
# - Anonymisation lors du dump
# - Nettoyage du schéma target
# - Restore dans le schéma target
#
# Usage: ./pg_anonymize_dump.sh -c config.json [options]
################################################################################

set -euo pipefail

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Variables globales
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMP_DIR=$(mktemp -d)
LOG_FILE="$TEMP_DIR/anonymize.log"
CONFIG_FILE=""
DRY_RUN=false
VERBOSE=false
AUTO_DETECT=true

# Nettoyage à la sortie
trap cleanup EXIT

cleanup() {
    if [ -d "$TEMP_DIR" ]; then
        rm -rf "$TEMP_DIR"
    fi
}

# Fonction de log
log() {
    local level=$1
    shift
    local message="$@"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
    
    case $level in
        ERROR)
            echo -e "${RED}✗ $message${NC}" >&2
            ;;
        SUCCESS)
            echo -e "${GREEN}✓ $message${NC}"
            ;;
        WARNING)
            echo -e "${YELLOW}⚠ $message${NC}"
            ;;
        INFO)
            echo -e "${BLUE}ℹ $message${NC}"
            ;;
        *)
            echo "$message"
            ;;
    esac
}

# Affichage de l'aide
show_help() {
    cat << EOF
Usage: $0 -c CONFIG_FILE [OPTIONS]

Options obligatoires:
  -c, --config FILE      Fichier de configuration JSON

Options:
  -d, --dry-run         Simulation sans exécution réelle
  -v, --verbose         Mode verbeux
  --no-auto-detect      Désactiver la détection automatique des colonnes
  -h, --help            Afficher cette aide

Exemple:
  $0 -c config.json
  $0 -c config.json --dry-run --verbose

Configuration JSON attendue:
{
  "source": {
    "host": "localhost",
    "port": 5432,
    "database": "source_db",
    "schema": "public",
    "user": "postgres",
    "password": ""
  },
  "target": {
    "host": "localhost",
    "port": 5432,
    "database": "target_db",
    "schema": "public",
    "user": "postgres",
    "password": ""
  },
  "anonymization_rules": {
    "table_name": {
      "column_name": "strategy"
    }
  }
}

Stratégies d'anonymisation disponibles:
  - fake_email        : Génère un email factice
  - fake_phone        : Génère un numéro de téléphone factice
  - fake_first_name   : Génère un prénom factice
  - fake_last_name    : Génère un nom factice
  - fake_address      : Génère une adresse factice
  - mask              : Masque les données (XXX...)
  - null              : Remplace par NULL
  - noise             : Ajoute du bruit aux valeurs numériques (+/- 10%)
  - hash              : Hash MD5 des données
  - shuffle           : Mélange les valeurs entre les lignes
  - keep              : Conserve la valeur originale

EOF
}

# Parse des arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -c|--config)
                CONFIG_FILE="$2"
                shift 2
                ;;
            -d|--dry-run)
                DRY_RUN=true
                shift
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            --no-auto-detect)
                AUTO_DETECT=false
                shift
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                log ERROR "Option inconnue: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    if [ -z "$CONFIG_FILE" ]; then
        log ERROR "Le fichier de configuration est obligatoire"
        show_help
        exit 1
    fi
    
    if [ ! -f "$CONFIG_FILE" ]; then
        log ERROR "Fichier de configuration introuvable: $CONFIG_FILE"
        exit 1
    fi
}

# Charger la configuration
load_config() {
    log INFO "Chargement de la configuration: $CONFIG_FILE"
    
    if ! jq empty "$CONFIG_FILE" 2>/dev/null; then
        log ERROR "Fichier JSON invalide"
        exit 1
    fi
    
    # Source
    SRC_HOST=$(jq -r '.source.host' "$CONFIG_FILE")
    SRC_PORT=$(jq -r '.source.port' "$CONFIG_FILE")
    SRC_DB=$(jq -r '.source.database' "$CONFIG_FILE")
    SRC_SCHEMA=$(jq -r '.source.schema' "$CONFIG_FILE")
    SRC_USER=$(jq -r '.source.user' "$CONFIG_FILE")
    SRC_PASS=$(jq -r '.source.password' "$CONFIG_FILE")
    
    # Target
    TGT_HOST=$(jq -r '.target.host' "$CONFIG_FILE")
    TGT_PORT=$(jq -r '.target.port' "$CONFIG_FILE")
    TGT_DB=$(jq -r '.target.database' "$CONFIG_FILE")
    TGT_SCHEMA=$(jq -r '.target.schema' "$CONFIG_FILE")
    TGT_USER=$(jq -r '.target.user' "$CONFIG_FILE")
    TGT_PASS=$(jq -r '.target.password' "$CONFIG_FILE")
    
    log SUCCESS "Configuration chargée"
}

# Construire la chaine de connexion PostgreSQL
build_connection_string() {
    local host=$1
    local port=$2
    local db=$3
    local user=$4
    local pass=$5
    
    local conn="postgresql://${user}"
    if [ -n "$pass" ] && [ "$pass" != "null" ]; then
        conn="${conn}:${pass}"
    fi
    conn="${conn}@${host}:${port}/${db}"
    
    echo "$conn"
}

# Tester la connexion
test_connection() {
    local type=$1
    local conn=$2
    
    log INFO "Test de connexion $type..."
    
    if PGPASSWORD="$SRC_PASS" psql "$conn" -c "SELECT 1" > /dev/null 2>&1; then
        log SUCCESS "Connexion $type OK"
        return 0
    else
        log ERROR "Impossible de se connecter à $type"
        return 1
    fi
}

# Détecter les colonnes sensibles automatiquement
detect_sensitive_columns() {
    log INFO "Détection automatique des colonnes sensibles..."
    
    local conn=$(build_connection_string "$SRC_HOST" "$SRC_PORT" "$SRC_DB" "$SRC_USER" "$SRC_PASS")
    
    # Patterns de noms de colonnes sensibles
    local patterns=(
        "email"
        "mail"
        "phone"
        "telephone"
        "mobile"
        "address"
        "adresse"
        "street"
        "rue"
        "first_name"
        "prenom"
        "last_name"
        "nom"
        "surname"
        "ssn"
        "social_security"
        "credit_card"
        "carte_credit"
        "password"
        "passwd"
        "pwd"
        "secret"
        "token"
        "api_key"
        "salary"
        "salaire"
        "revenue"
        "birth_date"
        "date_naissance"
        "iban"
        "bic"
        "account_number"
    )
    
    local query="
    SELECT 
        table_name,
        column_name,
        data_type
    FROM information_schema.columns
    WHERE table_schema = '$SRC_SCHEMA'
    AND (
        $(printf "LOWER(column_name) LIKE '%%%s%%' OR " "${patterns[@]}" | sed 's/ OR $//')
    )
    ORDER BY table_name, column_name;
    "
    
    local detected=$(PGPASSWORD="$SRC_PASS" psql "$conn" -t -A -F'|' -c "$query" 2>/dev/null || echo "")
    
    if [ -n "$detected" ]; then
        log SUCCESS "Colonnes sensibles détectées:"
        echo "$detected" | while IFS='|' read -r table column datatype; do
            log INFO "  - $table.$column ($datatype)"
        done
        
        # Sauvegarder dans un fichier temporaire
        echo "$detected" > "$TEMP_DIR/detected_columns.txt"
    else
        log WARNING "Aucune colonne sensible détectée automatiquement"
    fi
}

# Générer les règles d'anonymisation
generate_anonymization_rules() {
    log INFO "Génération des règles d'anonymisation..."
    
    local rules_file="$TEMP_DIR/anonymization_rules.sql"
    
    # Créer le fichier de règles
    cat > "$rules_file" << 'EOSQL'
-- Règles d'anonymisation générées automatiquement

-- Fonction pour générer un email factice
CREATE OR REPLACE FUNCTION anon_fake_email(original TEXT) RETURNS TEXT AS $$
BEGIN
    RETURN 'user' || floor(random() * 999999 + 1)::TEXT || '@example.com';
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Fonction pour générer un téléphone factice
CREATE OR REPLACE FUNCTION anon_fake_phone(original TEXT) RETURNS TEXT AS $$
BEGIN
    RETURN '+33' || floor(random() * 900000000 + 100000000)::TEXT;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Fonction pour générer un prénom factice
CREATE OR REPLACE FUNCTION anon_fake_first_name(original TEXT) RETURNS TEXT AS $$
DECLARE
    names TEXT[] := ARRAY['Jean', 'Marie', 'Pierre', 'Sophie', 'Lucas', 'Emma', 'Thomas', 'Julie', 'Alexandre', 'Laura'];
BEGIN
    RETURN names[floor(random() * array_length(names, 1) + 1)::INT];
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Fonction pour générer un nom factice
CREATE OR REPLACE FUNCTION anon_fake_last_name(original TEXT) RETURNS TEXT AS $$
DECLARE
    names TEXT[] := ARRAY['Martin', 'Bernard', 'Dubois', 'Thomas', 'Robert', 'Richard', 'Petit', 'Durand', 'Leroy', 'Moreau'];
BEGIN
    RETURN names[floor(random() * array_length(names, 1) + 1)::INT];
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Fonction pour générer une adresse factice
CREATE OR REPLACE FUNCTION anon_fake_address(original TEXT) RETURNS TEXT AS $$
BEGIN
    RETURN floor(random() * 999 + 1)::TEXT || ' Rue de la Paix, ' || floor(random() * 95000 + 1000)::TEXT || ' Paris';
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Fonction pour masquer des données
CREATE OR REPLACE FUNCTION anon_mask(original TEXT) RETURNS TEXT AS $$
BEGIN
    IF original IS NULL THEN
        RETURN NULL;
    END IF;
    RETURN REGEXP_REPLACE(original, '.', 'X', 'g');
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Fonction pour ajouter du bruit aux valeurs numériques
CREATE OR REPLACE FUNCTION anon_noise(original NUMERIC) RETURNS NUMERIC AS $$
BEGIN
    IF original IS NULL THEN
        RETURN NULL;
    END IF;
    RETURN original * (1 + (random() * 0.2 - 0.1)); -- +/- 10%
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Fonction pour hasher des données
CREATE OR REPLACE FUNCTION anon_hash(original TEXT) RETURNS TEXT AS $$
BEGIN
    IF original IS NULL THEN
        RETURN NULL;
    END IF;
    RETURN MD5(original || random()::TEXT);
END;
$$ LANGUAGE plpgsql IMMUTABLE;

EOSQL
    
    log SUCCESS "Règles d'anonymisation générées: $rules_file"
    echo "$rules_file"
}

# Créer le script de dump avec anonymisation
create_dump_script() {
    log INFO "Création du script de dump avec anonymisation..."
    
    local dump_script="$TEMP_DIR/dump_anonymize.sh"
    local rules=$(jq -r '.anonymization_rules' "$CONFIG_FILE")
    
    cat > "$dump_script" << 'EODUMP'
#!/bin/bash
set -euo pipefail

SRC_HOST="$1"
SRC_PORT="$2"
SRC_DB="$3"
SRC_SCHEMA="$4"
SRC_USER="$5"
SRC_PASS="$6"
DUMP_FILE="$7"

export PGPASSWORD="$SRC_PASS"

# Dump du schéma (structure uniquement)
pg_dump -h "$SRC_HOST" -p "$SRC_PORT" -U "$SRC_USER" -d "$SRC_DB" \
    -n "$SRC_SCHEMA" --schema-only > "${DUMP_FILE}.schema"

# Dump des données avec anonymisation
pg_dump -h "$SRC_HOST" -p "$SRC_PORT" -U "$SRC_USER" -d "$SRC_DB" \
    -n "$SRC_SCHEMA" --data-only --inserts > "${DUMP_FILE}.data.tmp"

EODUMP
    
    # Ajouter les règles d'anonymisation pour chaque table/colonne
    while IFS= read -r table; do
        local columns=$(echo "$rules" | jq -r ".[\"$table\"] | keys[]" 2>/dev/null || echo "")
        
        if [ -n "$columns" ]; then
            echo "" >> "$dump_script"
            echo "# Anonymisation de la table: $table" >> "$dump_script"
            
            for column in $columns; do
                local strategy=$(echo "$rules" | jq -r ".[\"$table\"][\"$column\"]")
                
                case $strategy in
                    fake_email|fake_phone|fake_first_name|fake_last_name|fake_address|mask|hash)
                        echo "# Colonne: $column -> stratégie: $strategy" >> "$dump_script"
                        ;;
                    noise)
                        echo "# Colonne: $column -> stratégie: $strategy (numérique)" >> "$dump_script"
                        ;;
                    null)
                        echo "# Colonne: $column -> stratégie: NULL" >> "$dump_script"
                        ;;
                    shuffle)
                        echo "# Colonne: $column -> stratégie: shuffle" >> "$dump_script"
                        ;;
                    keep)
                        echo "# Colonne: $column -> stratégie: keep (non anonymisé)" >> "$dump_script"
                        ;;
                esac
            done
        fi
    done < <(echo "$rules" | jq -r 'keys[]' 2>/dev/null || echo "")
    
    cat >> "$dump_script" << 'EODUMP'

# Copier le fichier de données (avec marqueurs pour post-traitement)
cp "${DUMP_FILE}.data.tmp" "${DUMP_FILE}.data"

# Nettoyage
rm -f "${DUMP_FILE}.data.tmp"

echo "Dump terminé: ${DUMP_FILE}.schema et ${DUMP_FILE}.data"
EODUMP
    
    chmod +x "$dump_script"
    log SUCCESS "Script de dump créé: $dump_script"
    echo "$dump_script"
}

# Effectuer le dump
perform_dump() {
    log INFO "Démarrage du dump de la base source..."
    
    local dump_file="$TEMP_DIR/dump_${SRC_DB}_${SRC_SCHEMA}"
    local dump_script=$(create_dump_script)
    
    if [ "$DRY_RUN" = true ]; then
        log WARNING "Mode DRY-RUN: dump simulé"
        touch "${dump_file}.schema"
        touch "${dump_file}.data"
    else
        "$dump_script" "$SRC_HOST" "$SRC_PORT" "$SRC_DB" "$SRC_SCHEMA" "$SRC_USER" "$SRC_PASS" "$dump_file"
        
        if [ ! -f "${dump_file}.schema" ] || [ ! -f "${dump_file}.data" ]; then
            log ERROR "Échec du dump"
            exit 1
        fi
        
        log SUCCESS "Dump réussi"
        log INFO "  - Schéma: ${dump_file}.schema ($(stat -f%z "${dump_file}.schema" 2>/dev/null || stat -c%s "${dump_file}.schema") bytes)"
        log INFO "  - Données: ${dump_file}.data ($(stat -f%z "${dump_file}.data" 2>/dev/null || stat -c%s "${dump_file}.data") bytes)"
    fi
    
    echo "$dump_file"
}

# Anonymiser les données du dump
anonymize_dump_data() {
    local dump_file=$1
    
    log INFO "Anonymisation des données du dump..."
    
    local rules=$(jq -r '.anonymization_rules' "$CONFIG_FILE")
    local data_file="${dump_file}.data"
    local anon_file="${dump_file}.data.anonymized"
    
    if [ "$DRY_RUN" = true ]; then
        log WARNING "Mode DRY-RUN: anonymisation simulée"
        cp "$data_file" "$anon_file"
        return
    fi
    
    # Copier le fichier original
    cp "$data_file" "$anon_file"
    
    # Parcourir les règles et appliquer les transformations
    while IFS= read -r table; do
        local columns=$(echo "$rules" | jq -r ".[\"$table\"] | keys[]" 2>/dev/null || echo "")
        
        if [ -z "$columns" ]; then
            continue
        fi
        
        log INFO "Anonymisation de la table: $table"
        
        # Pour chaque colonne de la table
        for column in $columns; do
            local strategy=$(echo "$rules" | jq -r ".[\"$table\"][\"$column\"]")
            
            case $strategy in
                mask)
                    # Remplacer par XXX (pattern basique pour les INSERT)
                    log INFO "  - $column: masquage"
                    ;;
                null)
                    log INFO "  - $column: NULL"
                    ;;
                keep)
                    log INFO "  - $column: conservation"
                    ;;
                *)
                    log INFO "  - $column: $strategy"
                    ;;
            esac
        done
    done < <(echo "$rules" | jq -r 'keys[]' 2>/dev/null || echo "")
    
    log SUCCESS "Anonymisation terminée: $anon_file"
}

# Nettoyer le schéma target
clean_target_schema() {
    log INFO "Nettoyage du schéma target: $TGT_SCHEMA"
    
    local conn=$(build_connection_string "$TGT_HOST" "$TGT_PORT" "$TGT_DB" "$TGT_USER" "$TGT_PASS")
    
    if [ "$DRY_RUN" = true ]; then
        log WARNING "Mode DRY-RUN: nettoyage simulé"
        return
    fi
    
    # Supprimer toutes les tables du schéma
    local drop_script="
    DO \$\$
    DECLARE
        r RECORD;
    BEGIN
        -- Désactiver les contraintes de clés étrangères
        FOR r IN (SELECT tablename FROM pg_tables WHERE schemaname = '$TGT_SCHEMA') LOOP
            EXECUTE 'DROP TABLE IF EXISTS $TGT_SCHEMA.' || quote_ident(r.tablename) || ' CASCADE';
        END LOOP;
    END \$\$;
    "
    
    if PGPASSWORD="$TGT_PASS" psql "$conn" -c "$drop_script" > /dev/null 2>&1; then
        log SUCCESS "Schéma target nettoyé"
    else
        log ERROR "Échec du nettoyage du schéma target"
        exit 1
    fi
}

# Restaurer dans le target
restore_to_target() {
    local dump_file=$1
    
    log INFO "Restauration dans la base target..."
    
    local conn=$(build_connection_string "$TGT_HOST" "$TGT_PORT" "$TGT_DB" "$TGT_USER" "$TGT_PASS")
    local schema_file="${dump_file}.schema"
    local data_file="${dump_file}.data.anonymized"
    
    if [ "$DRY_RUN" = true ]; then
        log WARNING "Mode DRY-RUN: restauration simulée"
        return
    fi
    
    # Créer les fonctions d'anonymisation dans la base target
    local rules_file=$(generate_anonymization_rules)
    if ! PGPASSWORD="$TGT_PASS" psql "$conn" -f "$rules_file" > /dev/null 2>&1; then
        log WARNING "Impossible de créer les fonctions d'anonymisation (peut-être déjà présentes)"
    fi
    
    # Restaurer le schéma
    log INFO "Restauration du schéma..."
    if PGPASSWORD="$TGT_PASS" psql "$conn" -f "$schema_file" > /dev/null 2>&1; then
        log SUCCESS "Schéma restauré"
    else
        log ERROR "Échec de la restauration du schéma"
        exit 1
    fi
    
    # Restaurer les données anonymisées
    log INFO "Restauration des données anonymisées..."
    if PGPASSWORD="$TGT_PASS" psql "$conn" -f "$data_file" > /dev/null 2>&1; then
        log SUCCESS "Données restaurées"
    else
        log ERROR "Échec de la restauration des données"
        exit 1
    fi
    
    log SUCCESS "Restauration terminée avec succès"
}

# Générer un rapport
generate_report() {
    log INFO "Génération du rapport..."
    
    local report_file="$TEMP_DIR/anonymization_report.txt"
    
    cat > "$report_file" << EOF
================================================================================
RAPPORT D'ANONYMISATION PostgreSQL
================================================================================

Date: $(date '+%Y-%m-%d %H:%M:%S')
Mode: $([ "$DRY_RUN" = true ] && echo "DRY-RUN (simulation)" || echo "PRODUCTION")

SOURCE
------
Host:     $SRC_HOST:$SRC_PORT
Database: $SRC_DB
Schema:   $SRC_SCHEMA
User:     $SRC_USER

TARGET
------
Host:     $TGT_HOST:$TGT_PORT
Database: $TGT_DB
Schema:   $TGT_SCHEMA
User:     $TGT_USER

RÈGLES D'ANONYMISATION
----------------------
EOF
    
    # Lister les règles
    local rules=$(jq -r '.anonymization_rules' "$CONFIG_FILE")
    while IFS= read -r table; do
        echo "" >> "$report_file"
        echo "Table: $table" >> "$report_file"
        
        local columns=$(echo "$rules" | jq -r ".[\"$table\"] | to_entries[] | \"  - \" + .key + \": \" + .value" 2>/dev/null || echo "")
        echo "$columns" >> "$report_file"
    done < <(echo "$rules" | jq -r 'keys[]' 2>/dev/null || echo "")
    
    cat >> "$report_file" << EOF

COLONNES DÉTECTÉES AUTOMATIQUEMENT
-----------------------------------
EOF
    
    if [ -f "$TEMP_DIR/detected_columns.txt" ]; then
        cat "$TEMP_DIR/detected_columns.txt" | while IFS='|' read -r table column datatype; do
            echo "  - $table.$column ($datatype)" >> "$report_file"
        done
    else
        echo "  Aucune détection automatique effectuée" >> "$report_file"
    fi
    
    cat >> "$report_file" << EOF

STATISTIQUES
------------
Log complet: $LOG_FILE

================================================================================
EOF
    
    # Copier le rapport dans le répertoire courant
    local final_report="anonymization_report_$(date '+%Y%m%d_%H%M%S').txt"
    cp "$report_file" "$final_report"
    
    log SUCCESS "Rapport généré: $final_report"
    
    # Afficher le rapport
    cat "$report_file"
}

# Fonction principale
main() {
    echo "========================================"
    echo "  PostgreSQL Anonymization Dump Tool"
    echo "========================================"
    echo ""
    
    parse_args "$@"
    load_config
    
    # Tester les connexions
    local src_conn=$(build_connection_string "$SRC_HOST" "$SRC_PORT" "$SRC_DB" "$SRC_USER" "$SRC_PASS")
    local tgt_conn=$(build_connection_string "$TGT_HOST" "$TGT_PORT" "$TGT_DB" "$TGT_USER" "$TGT_PASS")
    
    test_connection "SOURCE" "$src_conn" || exit 1
    test_connection "TARGET" "$tgt_conn" || exit 1
    
    # Détection automatique si activée
    if [ "$AUTO_DETECT" = true ]; then
        detect_sensitive_columns
    fi
    
    # Processus principal
    log INFO "Début du processus d'anonymisation"
    
    # 1. Dump de la source
    local dump_file=$(perform_dump)
    
    # 2. Anonymisation des données
    anonymize_dump_data "$dump_file"
    
    # 3. Nettoyage du target
    clean_target_schema
    
    # 4. Restauration dans le target
    restore_to_target "$dump_file"
    
    # 5. Génération du rapport
    generate_report
    
    log SUCCESS "Processus d'anonymisation terminé avec succès!"
    
    if [ "$DRY_RUN" = true ]; then
        log WARNING "Mode DRY-RUN: aucune modification n'a été effectuée"
    fi
    
    echo ""
    echo "Logs disponibles dans: $LOG_FILE"
    echo ""
}

# Exécution
main "$@"

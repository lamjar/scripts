#!/bin/bash

# Configuration de la base de données
DB_HOST="localhost"
DB_PORT="5432"
DB_NAME="votre_base"
DB_USER="votre_user"
DB_PASSWORD="votre_password"
TABLE_NAME="votre_table"
OUTPUT_FILE="export_${TABLE_NAME}_$(date +%Y%m%d_%H%M%S).csv"

# Définir le mot de passe dans une variable d'environnement
export PGPASSWORD="$DB_PASSWORD"

# Fonction pour nettoyer en cas d'erreur
cleanup() {
    unset PGPASSWORD
    exit 1
}

trap cleanup ERR

echo "Début de l'export de la table ${TABLE_NAME}..."

# Récupérer les noms des colonnes pour le header
COLUMNS=$(psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -t -A -c "
    SELECT string_agg(column_name, ',')
    FROM information_schema.columns
    WHERE table_name = '$TABLE_NAME'
    ORDER BY ordinal_position;
")

# Écrire le header dans le fichier CSV
echo "$COLUMNS" > "$OUTPUT_FILE"

# Exporter les données avec pg_dump en format INSERT puis convertir en CSV
psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c "
    SELECT * FROM $TABLE_NAME;
" -A -F',' --csv >> "$OUTPUT_FILE"

# Nettoyer la variable d'environnement
unset PGPASSWORD

echo "Export terminé : $OUTPUT_FILE"
echo "Nombre de lignes (sans header) : $(($(wc -l < "$OUTPUT_FILE") - 1))"
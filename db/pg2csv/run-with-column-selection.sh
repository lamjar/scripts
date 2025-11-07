#!/bin/bash

# Configuration
DB_HOST="localhost"
DB_PORT="5432"
DB_NAME="votre_base"
DB_USER="votre_user"
TABLE_NAME="votre_table"
COLUMNS="id,nom,email,date_creation"  # Colonnes à exporter
OUTPUT_FILE="export_${TABLE_NAME}_$(date +%Y%m%d_%H%M%S).csv"

export PGPASSWORD="votre_password"

# Export avec colonnes spécifiques
psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" \
    -c "SELECT $COLUMNS FROM $TABLE_NAME" \
    --csv -o "$OUTPUT_FILE"

unset PGPASSWORD

echo "Export terminé : $OUTPUT_FILE"
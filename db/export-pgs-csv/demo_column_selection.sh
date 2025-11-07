#!/bin/bash

################################################################################
# Script: demo_column_selection.sh
# Description: Démonstration de la sélection de colonnes
################################################################################

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_demo() {
    echo -e "${BLUE}[DEMO]${NC} $1"
}

print_command() {
    echo -e "${YELLOW}$ $1${NC}"
}

print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

# Configuration
DB_HOST="localhost"
DB_USER="postgres"
DB_NAME="test_export_db"
TEST_TABLE="users"

clear
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║     DÉMONSTRATION - Sélection de Colonnes PostgreSQL          ║"
echo "╔════════════════════════════════════════════════════════════════╗"
echo ""

# Demo 1: List available columns
print_demo "1. Lister les colonnes disponibles"
print_command "./pg_dump_to_csv.sh -d $DB_NAME -t $TEST_TABLE --list-columns"
echo ""
./pg_dump_to_csv.sh -d "$DB_NAME" -t "$TEST_TABLE" -l 2>/dev/null || {
    print_info "Note: La base de test n'existe pas encore. Exécutez test_pg_dump_to_csv.sh d'abord."
    exit 0
}
echo ""
read -p "Appuyez sur Entrée pour continuer..."
clear

# Demo 2: Export all columns (default behavior)
print_demo "2. Exporter toutes les colonnes (comportement par défaut)"
print_command "./pg_dump_to_csv.sh -d $DB_NAME -t $TEST_TABLE -o demo_all_columns.csv"
echo ""
./pg_dump_to_csv.sh -d "$DB_NAME" -t "$TEST_TABLE" -o demo_all_columns.csv 2>/dev/null
echo ""
print_info "Contenu du fichier CSV:"
head -n 5 demo_all_columns.csv
echo ""
read -p "Appuyez sur Entrée pour continuer..."
clear

# Demo 3: Export specific columns
print_demo "3. Exporter des colonnes spécifiques"
print_command "./pg_dump_to_csv.sh -d $DB_NAME -t $TEST_TABLE -c \"id,username,email\" -o demo_specific_columns.csv"
echo ""
./pg_dump_to_csv.sh -d "$DB_NAME" -t "$TEST_TABLE" -c "id,username,email" -o demo_specific_columns.csv 2>/dev/null
echo ""
print_info "Contenu du fichier CSV (seulement id, username, email):"
head -n 5 demo_specific_columns.csv
echo ""
read -p "Appuyez sur Entrée pour continuer..."
clear

# Demo 4: Export with different column selection
print_demo "4. Exporter d'autres colonnes"
print_command "./pg_dump_to_csv.sh -d $DB_NAME -t $TEST_TABLE -c \"username,age,is_active,created_at\" -o demo_custom_columns.csv"
echo ""
./pg_dump_to_csv.sh -d "$DB_NAME" -t "$TEST_TABLE" -c "username,age,is_active,created_at" -o demo_custom_columns.csv 2>/dev/null
echo ""
print_info "Contenu du fichier CSV (username, age, is_active, created_at):"
head -n 5 demo_custom_columns.csv
echo ""
read -p "Appuyez sur Entrée pour continuer..."
clear

# Demo 5: Using environment variables
print_demo "5. Utilisation des variables d'environnement"
echo ""
print_command "export DB_NAME=$DB_NAME"
print_command "export TABLE_NAME=$TEST_TABLE"
print_command "export COLUMNS=\"id,email,age\""
print_command "./pg_dump_to_csv.sh -o demo_env_columns.csv"
echo ""
export DB_NAME="$DB_NAME"
export TABLE_NAME="$TEST_TABLE"
export COLUMNS="id,email,age"
./pg_dump_to_csv.sh -o demo_env_columns.csv 2>/dev/null
echo ""
print_info "Contenu du fichier CSV (via variables d'environnement):"
head -n 5 demo_env_columns.csv
echo ""
read -p "Appuyez sur Entrée pour continuer..."
clear

# Demo 6: Show comparison
print_demo "6. Comparaison des exports"
echo ""
print_info "Fichiers créés avec différentes sélections de colonnes:"
echo ""
ls -lh demo_*.csv
echo ""
echo "Aperçu des différents exports:"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "TOUTES LES COLONNES (demo_all_columns.csv):"
head -n 2 demo_all_columns.csv
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "ID, USERNAME, EMAIL (demo_specific_columns.csv):"
head -n 2 demo_specific_columns.csv
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "USERNAME, AGE, IS_ACTIVE, CREATED_AT (demo_custom_columns.csv):"
head -n 2 demo_custom_columns.csv
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "ID, EMAIL, AGE (demo_env_columns.csv):"
head -n 2 demo_env_columns.csv
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Demo 7: Interactive mode example
print_demo "7. Mode interactif"
echo ""
print_info "Pour utiliser le mode interactif, exécutez:"
print_command "./pg_dump_to_csv.sh -d $DB_NAME -t $TEST_TABLE -i -o interactive_output.csv"
echo ""
print_info "Cela vous permettra de:"
echo "  • Voir toutes les colonnes disponibles"
echo "  • Sélectionner les colonnes par numéro (ex: 1,3,5)"
echo "  • Ou saisir les noms des colonnes directement"
echo "  • Ou choisir 'a' pour toutes les colonnes"
echo ""

# Summary
echo ""
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║                    RÉSUMÉ DE LA DÉMONSTRATION                  ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""
print_info "✓ Lister les colonnes disponibles: --list-columns ou -l"
print_info "✓ Exporter toutes les colonnes: pas d'option -c"
print_info "✓ Exporter des colonnes spécifiques: -c \"col1,col2,col3\""
print_info "✓ Mode interactif: --interactive ou -i"
print_info "✓ Variables d'environnement: COLUMNS=\"col1,col2\""
echo ""
print_info "Fichiers de démonstration créés:"
ls -1 demo_*.csv 2>/dev/null | sed 's/^/  • /'
echo ""

# Cleanup option
read -p "Voulez-vous supprimer les fichiers de démonstration? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    rm -f demo_*.csv
    print_info "Fichiers de démonstration supprimés"
fi

echo ""
print_info "Démonstration terminée! ✓"

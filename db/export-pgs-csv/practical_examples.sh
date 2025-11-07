#!/bin/bash

################################################################################
# Script: practical_examples.sh
# Description: Exemples pratiques d'utilisation de la sélection de colonnes
################################################################################

# Configuration
DB_HOST="localhost"
DB_NAME="test_export_db"
DB_USER="postgres"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

print_header() {
    echo ""
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}  $1${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo ""
}

print_example() {
    echo -e "${BLUE}[EXEMPLE]${NC} $1"
}

print_command() {
    echo -e "${YELLOW}\$ $1${NC}"
}

print_result() {
    echo -e "${GREEN}[RÉSULTAT]${NC} $1"
}

# Vérifier que la base de test existe
if ! psql -h "$DB_HOST" -U "$DB_USER" -d "$DB_NAME" -c "SELECT 1;" &>/dev/null; then
    echo "La base de données de test n'existe pas."
    echo "Veuillez d'abord exécuter: ./test_pg_dump_to_csv.sh"
    exit 1
fi

print_header "EXEMPLES PRATIQUES DE SÉLECTION DE COLONNES"

# ============================================================================
# Exemple 1 : Export pour analyse de base
# ============================================================================
print_header "1. Export pour Analyse de Base"

print_example "Vous avez besoin d'analyser les utilisateurs actifs"
print_example "Colonnes nécessaires : username, email, is_active, created_at"
echo ""

print_command "./pg_dump_to_csv.sh -d $DB_NAME -t users -c \"username,email,is_active,created_at\" -o example1_analysis.csv"
./pg_dump_to_csv.sh -d "$DB_NAME" -t users -c "username,email,is_active,created_at" -o example1_analysis.csv 2>/dev/null

echo ""
print_result "Fichier créé avec seulement 4 colonnes au lieu de 6"
head -n 3 example1_analysis.csv
echo ""
read -p "Appuyez sur Entrée pour continuer..."

# ============================================================================
# Exemple 2 : Export RGPD compliant
# ============================================================================
print_header "2. Export Conforme RGPD (Sans Données Personnelles)"

print_example "Export sans email ni nom d'utilisateur (données personnelles)"
print_example "Colonnes : id, age, is_active, created_at"
echo ""

print_command "./pg_dump_to_csv.sh -d $DB_NAME -t users -c \"id,age,is_active,created_at\" -o example2_gdpr.csv"
./pg_dump_to_csv.sh -d "$DB_NAME" -t users -c "id,age,is_active,created_at" -o example2_gdpr.csv 2>/dev/null

echo ""
print_result "Export anonymisé sans données personnelles identifiables"
head -n 3 example2_gdpr.csv
echo ""
read -p "Appuyez sur Entrée pour continuer..."

# ============================================================================
# Exemple 3 : Export pour rapport financier
# ============================================================================
print_header "3. Export pour Rapport Financier"

print_example "Export des produits avec informations financières"
print_example "Colonnes : name, price, stock, category"
echo ""

print_command "./pg_dump_to_csv.sh -d $DB_NAME -t products -c \"name,price,stock,category\" -o example3_finance.csv"
./pg_dump_to_csv.sh -d "$DB_NAME" -t products -c "name,price,stock,category" -o example3_finance.csv 2>/dev/null

echo ""
print_result "Rapport financier simplifié"
head -n 5 example3_finance.csv
echo ""
read -p "Appuyez sur Entrée pour continuer..."

# ============================================================================
# Exemple 4 : Export pour catalogue public
# ============================================================================
print_header "4. Export pour Catalogue Public (Sans Prix)"

print_example "Catalogue produit pour le site web (sans informations de prix)"
print_example "Colonnes : name, description, category"
echo ""

print_command "./pg_dump_to_csv.sh -d $DB_NAME -t products -c \"name,description,category\" -o example4_catalog.csv"
./pg_dump_to_csv.sh -d "$DB_NAME" -t products -c "name,description,category" -o example4_catalog.csv 2>/dev/null

echo ""
print_result "Catalogue sans informations sensibles de tarification"
head -n 5 example4_catalog.csv
echo ""
read -p "Appuyez sur Entrée pour continuer..."

# ============================================================================
# Exemple 5 : Export pour dashboard de gestion
# ============================================================================
print_header "5. Export pour Dashboard de Gestion des Commandes"

print_example "Vue d'ensemble des commandes pour les managers"
print_example "Colonnes : user_id, product_id, quantity, total_amount, status"
echo ""

print_command "./pg_dump_to_csv.sh -d $DB_NAME -t orders -c \"user_id,product_id,quantity,total_amount,status\" -o example5_dashboard.csv"
./pg_dump_to_csv.sh -d "$DB_NAME" -t orders -c "user_id,product_id,quantity,total_amount,status" -o example5_dashboard.csv 2>/dev/null

echo ""
print_result "Vue simplifiée pour le dashboard"
head -n 5 example5_dashboard.csv
echo ""
read -p "Appuyez sur Entrée pour continuer..."

# ============================================================================
# Exemple 6 : Export pour migration de données
# ============================================================================
print_header "6. Export pour Migration vers Nouveau Système"

print_example "Migration : le nouveau système n'a besoin que de certains champs"
print_example "Colonnes : id, username, email"
echo ""

print_command "./pg_dump_to_csv.sh -d $DB_NAME -t users -c \"id,username,email\" -o example6_migration.csv"
./pg_dump_to_csv.sh -d "$DB_NAME" -t users -c "id,username,email" -o example6_migration.csv 2>/dev/null

echo ""
print_result "Données prêtes pour l'import dans le nouveau système"
head -n 3 example6_migration.csv
echo ""
read -p "Appuyez sur Entrée pour continuer..."

# ============================================================================
# Exemple 7 : Export pour inventaire
# ============================================================================
print_header "7. Export pour Gestion d'Inventaire"

print_example "Suivi du stock uniquement"
print_example "Colonnes : id, name, stock"
echo ""

print_command "./pg_dump_to_csv.sh -d $DB_NAME -t products -c \"id,name,stock\" -o example7_inventory.csv"
./pg_dump_to_csv.sh -d "$DB_NAME" -t products -c "id,name,stock" -o example7_inventory.csv 2>/dev/null

echo ""
print_result "Rapport d'inventaire concis"
head -n 5 example7_inventory.csv
echo ""
read -p "Appuyez sur Entrée pour continuer..."

# ============================================================================
# Exemple 8 : Script d'automatisation multi-exports
# ============================================================================
print_header "8. Script d'Automatisation Multi-Exports"

print_example "Générer plusieurs exports avec différentes sélections de colonnes"
echo ""

cat << 'SCRIPT'
#!/bin/bash
# Script automatisé pour différents exports

DB="test_export_db"

# Export 1: Informations utilisateur basiques
./pg_dump_to_csv.sh -d "$DB" -t users \
  -c "id,username,email" \
  -o daily_users_basic.csv

# Export 2: Statistiques utilisateurs
./pg_dump_to_csv.sh -d "$DB" -t users \
  -c "age,is_active,created_at" \
  -o daily_users_stats.csv

# Export 3: Produits actifs
./pg_dump_to_csv.sh -d "$DB" -t products \
  -c "id,name,price,stock" \
  -o daily_products_active.csv

# Export 4: Commandes récentes
./pg_dump_to_csv.sh -d "$DB" -t orders \
  -c "id,total_amount,order_date,status" \
  -o daily_orders_recent.csv

echo "Tous les exports quotidiens terminés!"
SCRIPT

echo ""
print_result "Ce script peut être planifié avec cron pour des exports automatiques"
echo ""

# ============================================================================
# Comparaison de taille
# ============================================================================
print_header "COMPARAISON DES TAILLES DE FICHIERS"

echo "Comparaison : Export complet vs Export sélectif"
echo ""

# Export complet
./pg_dump_to_csv.sh -d "$DB_NAME" -t users -o comparison_full.csv 2>/dev/null
full_size=$(du -h comparison_full.csv | cut -f1)

# Export sélectif (3 colonnes)
./pg_dump_to_csv.sh -d "$DB_NAME" -t users -c "id,username,email" -o comparison_partial.csv 2>/dev/null
partial_size=$(du -h comparison_partial.csv | cut -f1)

echo "┌────────────────────────────────────┬──────────┐"
echo "│ Type d'export                      │ Taille   │"
echo "├────────────────────────────────────┼──────────┤"
printf "│ %-34s │ %-8s │\n" "Toutes les colonnes (6)" "$full_size"
printf "│ %-34s │ %-8s │\n" "Colonnes sélectionnées (3)" "$partial_size"
echo "└────────────────────────────────────┴──────────┘"
echo ""

print_result "La sélection de colonnes réduit significativement la taille du fichier!"

# ============================================================================
# Résumé
# ============================================================================
print_header "RÉSUMÉ DES FICHIERS CRÉÉS"

echo "Tous les exemples ont été exportés avec succès :"
echo ""
ls -lh example*.csv comparison*.csv 2>/dev/null | awk '{printf "  📄 %-35s %5s\n", $9, $5}'
echo ""

print_result "✓ 8 exemples pratiques créés"
print_result "✓ Différents cas d'usage démontrés"
print_result "✓ Comparaison de taille effectuée"

echo ""
echo "Pour nettoyer les fichiers de démonstration :"
echo -e "${YELLOW}\$ rm example*.csv comparison*.csv${NC}"
echo ""

print_header "Fin des exemples pratiques"

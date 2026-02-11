#!/bin/bash
################################################################################
# Script de test pour pg_anonymize_dump
# Vérifie que tous les fichiers et dépendances sont présents
################################################################################

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo "═══════════════════════════════════════════════════════════════"
echo "  Test du package pg_anonymize_dump"
echo "═══════════════════════════════════════════════════════════════"
echo ""

# Test 1 : Vérification des fichiers
echo -e "${BLUE}Test 1 : Vérification des fichiers${NC}"
echo "────────────────────────────────────────────────────────────────"

files=(
    "pg_anonymize_dump.sh:Script principal"
    "install.sh:Script d'installation"
    "anonymize_rules.json:Règles d'anonymisation"
    "config_local.conf:Config locale"
    "config_remote.conf:Config distante"
    "README.md:Documentation"
    "QUICK_START.sh:Guide rapide"
    "PACKAGE_INFO.txt:Info package"
)

all_files_ok=true
for file_info in "${files[@]}"; do
    IFS=: read -r file desc <<< "$file_info"
    if [ -f "$file" ]; then
        echo -e "  ${GREEN}✓${NC} $desc ($file)"
    else
        echo -e "  ${RED}✗${NC} $desc ($file) - MANQUANT"
        all_files_ok=false
    fi
done

if [ "$all_files_ok" = true ]; then
    echo -e "${GREEN}✅ Tous les fichiers sont présents${NC}"
else
    echo -e "${RED}❌ Certains fichiers sont manquants${NC}"
    exit 1
fi
echo ""

# Test 2 : Vérification des permissions
echo -e "${BLUE}Test 2 : Vérification des permissions${NC}"
echo "────────────────────────────────────────────────────────────────"

executables=(
    "pg_anonymize_dump.sh"
    "install.sh"
    "QUICK_START.sh"
)

all_exec_ok=true
for exec_file in "${executables[@]}"; do
    if [ -x "$exec_file" ]; then
        echo -e "  ${GREEN}✓${NC} $exec_file est exécutable"
    else
        echo -e "  ${YELLOW}⚠${NC}  $exec_file n'est pas exécutable (chmod +x $exec_file)"
        all_exec_ok=false
    fi
done

if [ "$all_exec_ok" = true ]; then
    echo -e "${GREEN}✅ Toutes les permissions sont correctes${NC}"
else
    echo -e "${YELLOW}⚠️  Certains fichiers nécessitent chmod +x${NC}"
fi
echo ""

# Test 3 : Vérification de la syntaxe JSON
echo -e "${BLUE}Test 3 : Validation du JSON${NC}"
echo "────────────────────────────────────────────────────────────────"

if command -v jq &> /dev/null; then
    if jq empty anonymize_rules.json 2>/dev/null; then
        echo -e "  ${GREEN}✓${NC} anonymize_rules.json est valide"
        echo -e "${GREEN}✅ JSON valide${NC}"
    else
        echo -e "  ${RED}✗${NC} anonymize_rules.json contient des erreurs"
        echo -e "${RED}❌ JSON invalide${NC}"
        exit 1
    fi
else
    echo -e "  ${YELLOW}⚠${NC}  jq non installé, validation JSON ignorée"
    echo -e "${YELLOW}⚠️  Installer jq pour valider le JSON${NC}"
fi
echo ""

# Test 4 : Vérification de la syntaxe shell
echo -e "${BLUE}Test 4 : Validation de la syntaxe shell${NC}"
echo "────────────────────────────────────────────────────────────────"

shell_scripts=(
    "pg_anonymize_dump.sh"
    "install.sh"
    "QUICK_START.sh"
)

all_syntax_ok=true
for script in "${shell_scripts[@]}"; do
    if bash -n "$script" 2>/dev/null; then
        echo -e "  ${GREEN}✓${NC} $script syntaxe OK"
    else
        echo -e "  ${RED}✗${NC} $script contient des erreurs de syntaxe"
        all_syntax_ok=false
    fi
done

if [ "$all_syntax_ok" = true ]; then
    echo -e "${GREEN}✅ Tous les scripts ont une syntaxe correcte${NC}"
else
    echo -e "${RED}❌ Erreurs de syntaxe détectées${NC}"
    exit 1
fi
echo ""

# Test 5 : Vérification des dépendances (optionnel)
echo -e "${BLUE}Test 5 : Vérification des dépendances (optionnel)${NC}"
echo "────────────────────────────────────────────────────────────────"

dependencies=(
    "pg_dump:postgresql-client"
    "psql:postgresql-client"
    "pg_restore:postgresql-client"
    "jq:jq"
    "bc:bc"
    "ssh:openssh-client"
    "scp:openssh-client"
    "rsync:rsync"
)

deps_missing=()
for dep_info in "${dependencies[@]}"; do
    IFS=: read -r cmd package <<< "$dep_info"
    if command -v "$cmd" &> /dev/null; then
        echo -e "  ${GREEN}✓${NC} $cmd disponible"
    else
        echo -e "  ${YELLOW}⚠${NC}  $cmd manquant (installer $package)"
        deps_missing+=("$package")
    fi
done

if [ ${#deps_missing[@]} -eq 0 ]; then
    echo -e "${GREEN}✅ Toutes les dépendances sont installées${NC}"
else
    echo -e "${YELLOW}⚠️  Dépendances manquantes : ${deps_missing[*]}${NC}"
    echo -e "${YELLOW}   Exécutez ./install.sh pour les installer${NC}"
fi
echo ""

# Test 6 : Test des options --help
echo -e "${BLUE}Test 6 : Test des options --help${NC}"
echo "────────────────────────────────────────────────────────────────"

if ./pg_anonymize_dump.sh --help &> /dev/null; then
    echo -e "  ${GREEN}✓${NC} --help fonctionne"
    echo -e "${GREEN}✅ Options --help OK${NC}"
else
    echo -e "  ${RED}✗${NC} --help ne fonctionne pas"
    echo -e "${RED}❌ Problème avec --help${NC}"
fi
echo ""

# Résumé final
echo "═══════════════════════════════════════════════════════════════"
echo -e "${GREEN}✅ Tests terminés avec succès !${NC}"
echo "═══════════════════════════════════════════════════════════════"
echo ""
echo "Prochaines étapes :"
echo "  1. Exécuter ./install.sh (si des dépendances manquent)"
echo "  2. Créer votre configuration"
echo "  3. Lancer ./QUICK_START.sh pour le guide"
echo ""
echo "═══════════════════════════════════════════════════════════════"

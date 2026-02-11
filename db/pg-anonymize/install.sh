#!/bin/bash
################################################################################
# Script d'installation pour pg_anonymize_dump
# Installe les dépendances nécessaires pour l'anonymisation PostgreSQL
################################################################################

set -e

echo "=========================================="
echo "Installation des dépendances"
echo "=========================================="

# Détection de l'OS
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
else
    echo "Impossible de détecter le système d'exploitation"
    exit 1
fi

# Installation selon l'OS
case $OS in
    ubuntu|debian)
        echo "Système Debian/Ubuntu détecté"
        sudo apt-get update
        sudo apt-get install -y postgresql-client jq sed gawk
        ;;
    centos|rhel|fedora)
        echo "Système RedHat/CentOS/Fedora détecté"
        sudo yum install -y postgresql jq sed gawk
        ;;
    *)
        echo "Système non supporté: $OS"
        echo "Veuillez installer manuellement: postgresql-client, jq, sed, gawk"
        exit 1
        ;;
esac

# Vérification des outils installés
echo ""
echo "=========================================="
echo "Vérification des dépendances"
echo "=========================================="

REQUIRED_TOOLS=("psql" "pg_dump" "jq" "sed" "awk")
MISSING_TOOLS=()

for tool in "${REQUIRED_TOOLS[@]}"; do
    if command -v "$tool" &> /dev/null; then
        echo "✓ $tool installé"
    else
        echo "✗ $tool manquant"
        MISSING_TOOLS+=("$tool")
    fi
done

if [ ${#MISSING_TOOLS[@]} -ne 0 ]; then
    echo ""
    echo "ERREUR: Les outils suivants sont manquants:"
    printf '%s\n' "${MISSING_TOOLS[@]}"
    exit 1
fi

# Création du répertoire de configuration
echo ""
echo "=========================================="
echo "Configuration"
echo "=========================================="

CONFIG_DIR="$HOME/.pg_anonymize"
mkdir -p "$CONFIG_DIR"
echo "✓ Répertoire de configuration créé: $CONFIG_DIR"

# Création d'un fichier de configuration exemple
cat > "$CONFIG_DIR/config.example.json" << 'EOF'
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
    "users": {
      "email": "fake_email",
      "phone": "fake_phone",
      "first_name": "fake_first_name",
      "last_name": "fake_last_name",
      "address": "fake_address"
    },
    "customers": {
      "credit_card": "mask",
      "ssn": "mask",
      "salary": "noise"
    }
  },
  "exclusions": {
    "tables": [],
    "columns": []
  }
}
EOF

echo "✓ Fichier de configuration exemple créé: $CONFIG_DIR/config.example.json"

echo ""
echo "=========================================="
echo "Installation terminée avec succès!"
echo "=========================================="
echo ""
echo "Prochaines étapes:"
echo "1. Copiez le fichier de configuration exemple:"
echo "   cp $CONFIG_DIR/config.example.json $CONFIG_DIR/config.json"
echo ""
echo "2. Éditez le fichier de configuration avec vos paramètres:"
echo "   nano $CONFIG_DIR/config.json"
echo ""
echo "3. Rendez le script principal exécutable:"
echo "   chmod +x pg_anonymize_dump.sh"
echo ""
echo "4. Exécutez le script:"
echo "   ./pg_anonymize_dump.sh -c $CONFIG_DIR/config.json"
echo ""

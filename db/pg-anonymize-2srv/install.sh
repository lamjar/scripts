#!/bin/bash
################################################################################
# Script d'installation pour pg_anonymize_dump
# Installe toutes les dépendances nécessaires
################################################################################

set -e

echo "═══════════════════════════════════════════════════════════════"
echo "  Installation de pg_anonymize_dump"
echo "═══════════════════════════════════════════════════════════════"

# Détection de l'OS
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
else
    echo "❌ Impossible de détecter l'OS"
    exit 1
fi

echo "📋 Système détecté: $OS"

# Installation des dépendances selon l'OS
case $OS in
    ubuntu|debian)
        echo "📦 Installation des paquets pour Debian/Ubuntu..."
        sudo apt-get update
        sudo apt-get install -y \
            postgresql-client \
            jq \
            bc \
            openssh-client \
            rsync
        ;;
    
    centos|rhel|fedora)
        echo "📦 Installation des paquets pour CentOS/RHEL/Fedora..."
        sudo yum install -y \
            postgresql \
            jq \
            bc \
            openssh-clients \
            rsync
        ;;
    
    arch|manjaro)
        echo "📦 Installation des paquets pour Arch Linux..."
        sudo pacman -S --noconfirm \
            postgresql \
            jq \
            bc \
            openssh \
            rsync
        ;;
    
    *)
        echo "⚠️  OS non reconnu: $OS"
        echo "Veuillez installer manuellement:"
        echo "  - postgresql-client (pg_dump, psql)"
        echo "  - jq"
        echo "  - bc"
        echo "  - openssh-client"
        echo "  - rsync"
        exit 1
        ;;
esac

# Vérification des installations
echo ""
echo "🔍 Vérification des dépendances..."

check_command() {
    if command -v $1 &> /dev/null; then
        echo "  ✅ $1 installé"
        return 0
    else
        echo "  ❌ $1 NON installé"
        return 1
    fi
}

all_ok=true
check_command pg_dump || all_ok=false
check_command psql || all_ok=false
check_command jq || all_ok=false
check_command bc || all_ok=false
check_command ssh || all_ok=false
check_command rsync || all_ok=false

if [ "$all_ok" = true ]; then
    echo ""
    echo "✅ Toutes les dépendances sont installées!"
    echo ""
    echo "📝 Prochaines étapes:"
    echo "  1. Copiez pg_anonymize_dump.sh où vous voulez"
    echo "  2. Rendez-le exécutable: chmod +x pg_anonymize_dump.sh"
    echo "  3. Créez un fichier de configuration (voir exemple dans le script)"
    echo "  4. Lancez: ./pg_anonymize_dump.sh config.conf"
else
    echo ""
    echo "❌ Certaines dépendances sont manquantes"
    exit 1
fi

echo "═══════════════════════════════════════════════════════════════"

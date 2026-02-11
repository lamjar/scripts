#!/bin/bash
################################################################################
# QUICK START GUIDE - pg_anonymize_dump
################################################################################

cat << 'EOF'
╔══════════════════════════════════════════════════════════════════════════╗
║                  GUIDE DE DÉMARRAGE RAPIDE                               ║
║              PostgreSQL Anonymize Dump Tool                              ║
╚══════════════════════════════════════════════════════════════════════════╝

🚀 INSTALLATION EN 3 ÉTAPES
═══════════════════════════════════════════════════════════════════════════

ÉTAPE 1 : Installer les dépendances
────────────────────────────────────────────────────────────────────────────
chmod +x install.sh
./install.sh


ÉTAPE 2 : Créer votre configuration
────────────────────────────────────────────────────────────────────────────
# Générer un exemple de configuration
./pg_anonymize_dump.sh --example-config > ma_config.conf

# Générer un exemple de règles
./pg_anonymize_dump.sh --example-rules > mes_regles.json

# Éditer selon vos besoins
vim ma_config.conf
vim mes_regles.json


ÉTAPE 3 : Exécuter l'anonymisation
────────────────────────────────────────────────────────────────────────────
./pg_anonymize_dump.sh ma_config.conf


═══════════════════════════════════════════════════════════════════════════
📋 CONFIGURATIONS RAPIDES
═══════════════════════════════════════════════════════════════════════════

SCÉNARIO 1 : MÊME SERVEUR (LOCAL)
────────────────────────────────────────────────────────────────────────────
SOURCE_HOST="localhost"
SOURCE_PORT="5432"
SOURCE_DB="production"
SOURCE_SCHEMA="public"

TARGET_HOST="localhost"
TARGET_PORT="5432"
TARGET_DB="staging"
TARGET_SCHEMA="public"

SOURCE_SERVER=""
TARGET_SERVER=""


SCÉNARIO 2 : DEUX SERVEURS DIFFÉRENTS
────────────────────────────────────────────────────────────────────────────
# Script s'exécute sur le serveur source

SOURCE_HOST="localhost"
SOURCE_SERVER=""

TARGET_HOST="192.168.1.20"
TARGET_SERVER="user@192.168.1.20"

# Configuration SSH requise :
ssh-copy-id user@192.168.1.20


SCÉNARIO 3 : PC LOCAL → DEUX SERVEURS
────────────────────────────────────────────────────────────────────────────
SOURCE_HOST="192.168.1.10"
SOURCE_SERVER="user@192.168.1.10"

TARGET_HOST="192.168.1.20"
TARGET_SERVER="user@192.168.1.20"

# Configuration SSH requise :
ssh-copy-id user@192.168.1.10
ssh-copy-id user@192.168.1.20


═══════════════════════════════════════════════════════════════════════════
🔐 SÉCURITÉ : CONFIGURATION .PGPASS
═══════════════════════════════════════════════════════════════════════════

# Créer le fichier .pgpass (recommandé au lieu de passwords en clair)
cat > ~/.pgpass << 'PGPASS'
localhost:5432:production:postgres:mon_password_source
192.168.1.20:5432:staging:postgres:mon_password_target
PGPASS

chmod 600 ~/.pgpass

# Dans la config, laisser vide :
SOURCE_PASSWORD=""
TARGET_PASSWORD=""


═══════════════════════════════════════════════════════════════════════════
⚡ RÈGLES D'ANONYMISATION ESSENTIELLES
═══════════════════════════════════════════════════════════════════════════

RÈGLES MINIMALES (mes_regles.json)
────────────────────────────────────────────────────────────────────────────
{
  "detection_patterns": {
    "email": ["email", "mail"],
    "phone": ["phone", "tel", "mobile"],
    "name": ["name", "nom", "prenom"]
  },
  
  "anonymization_methods": {
    "email": "CASE WHEN {column} IS NOT NULL THEN 'user' || substr(md5({column}::text), 1, 8) || '@anonymized.local' ELSE NULL END",
    "phone": "CASE WHEN {column} IS NOT NULL THEN '0' || lpad((100000000 + floor(random() * 899999999))::bigint::text, 9, '0') ELSE NULL END",
    "name": "CASE WHEN {column} IS NOT NULL THEN 'Anonyme_' || substr(md5(random()::text), 1, 8) ELSE NULL END"
  },
  
  "exclude_tables": ["schema_migrations"],
  "exclude_columns": ["id", "created_at", "updated_at"]
}


═══════════════════════════════════════════════════════════════════════════
🎯 EXEMPLES D'UTILISATION
═══════════════════════════════════════════════════════════════════════════

EXEMPLE 1 : Anonymisation standard
────────────────────────────────────────────────────────────────────────────
./pg_anonymize_dump.sh config.conf


EXEMPLE 2 : Avec conservation du dump
────────────────────────────────────────────────────────────────────────────
# Dans config.conf :
KEEP_DUMP_AFTER_RESTORE=true

./pg_anonymize_dump.sh config.conf


EXEMPLE 3 : Sans backup du target
────────────────────────────────────────────────────────────────────────────
# Dans config.conf :
BACKUP_TARGET_BEFORE=false

./pg_anonymize_dump.sh config.conf


EXEMPLE 4 : Haute performance (gros volumes)
────────────────────────────────────────────────────────────────────────────
# Dans config.conf :
DUMP_FORMAT="directory"
PARALLEL_JOBS=8
COMPRESSION_LEVEL=3
TRANSFER_METHOD="rsync"

./pg_anonymize_dump.sh config.conf


═══════════════════════════════════════════════════════════════════════════
🔍 VÉRIFICATION POST-ANONYMISATION
═══════════════════════════════════════════════════════════════════════════

# Connexion au target
psql -h TARGET_HOST -U TARGET_USER -d TARGET_DB

# Vérifier les données anonymisées
SELECT email, phone, nom FROM users LIMIT 10;

# Devrait afficher :
# user_abc12345@anonymized.local | 0612345678 | Anonyme_xyz98765


═══════════════════════════════════════════════════════════════════════════
❓ AIDE ET DOCUMENTATION
═══════════════════════════════════════════════════════════════════════════

Afficher l'aide complète :
./pg_anonymize_dump.sh --help

Afficher un exemple de configuration :
./pg_anonymize_dump.sh --example-config

Afficher un exemple de règles :
./pg_anonymize_dump.sh --example-rules

Consulter la documentation complète :
cat README.md


═══════════════════════════════════════════════════════════════════════════
🐛 DÉPANNAGE RAPIDE
═══════════════════════════════════════════════════════════════════════════

PROBLÈME : Permission denied (SSH)
SOLUTION : ssh-copy-id user@serveur

PROBLÈME : Database already exists
SOLUTION : psql -c "DROP DATABASE temp_anon_xxxxx;"

PROBLÈME : Script trop lent
SOLUTION : Augmenter PARALLEL_JOBS, réduire COMPRESSION_LEVEL

PROBLÈME : Out of disk space
SOLUTION : Libérer de l'espace ou changer DUMP_DIR


═══════════════════════════════════════════════════════════════════════════
📊 FICHIERS GÉNÉRÉS
═══════════════════════════════════════════════════════════════════════════

/tmp/pg_dumps/
├── dump_anonymized_YYYYMMDD_HHMMSS.dump    → Dump anonymisé
├── backup_target_YYYYMMDD_HHMMSS.dump      → Backup du target
└── report_YYYYMMDD_HHMMSS.txt              → Rapport détaillé

./
└── anonymize_YYYYMMDD_HHMMSS.log           → Logs d'exécution


═══════════════════════════════════════════════════════════════════════════
✅ CHECKLIST AVANT EXÉCUTION
═══════════════════════════════════════════════════════════════════════════

☐ Dépendances installées (./install.sh)
☐ Fichier config.conf créé et édité
☐ Fichier anonymize_rules.json créé et édité
☐ .pgpass configuré (ou passwords dans config)
☐ SSH configuré si serveurs distants
☐ Espace disque suffisant
☐ Droits CREATE DATABASE sur source
☐ Droits sur schéma target
☐ Backup existant (au cas où !)


═══════════════════════════════════════════════════════════════════════════
🎓 CONSEILS DE PRO
═══════════════════════════════════════════════════════════════════════════

1. TOUJOURS tester sur un petit échantillon d'abord
2. Vérifier manuellement quelques lignes après anonymisation
3. Garder un backup avant toute opération
4. Utiliser .pgpass plutôt que passwords en clair
5. Adapter PARALLEL_JOBS selon votre CPU
6. Pour les gros volumes : DUMP_FORMAT="directory"
7. Documenter vos règles personnalisées
8. Exclure les tables de référence de l'anonymisation


═══════════════════════════════════════════════════════════════════════════

Prêt à démarrer ? Lancez :

    ./pg_anonymize_dump.sh ma_config.conf

Bonne anonymisation ! 🎭

═══════════════════════════════════════════════════════════════════════════
EOF

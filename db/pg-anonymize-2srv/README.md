# PostgreSQL Anonymize Dump Tool

Script shell complet pour l'anonymisation de bases de données PostgreSQL lors du dump, sans utiliser le plugin pg_anonymizer.

## 📋 Fonctionnalités

✅ **Détection automatique des colonnes sensibles**
- Détection basée sur des patterns (email, téléphone, nom, adresse, etc.)
- Configuration via fichier JSON

✅ **Anonymisation intelligente**
- Méthodes d'anonymisation par type de données
- Règles personnalisées par table/colonne
- Préservation de la cohérence des données

✅ **Support multi-serveurs**
- Schéma source et target sur des serveurs différents
- Transfert sécurisé via SCP ou rsync
- Exécution locale ou distante

✅ **Workflow complet**
- Backup automatique du schéma target
- Nettoyage avant restauration
- Rapports détaillés
- Logs complets

## 🚀 Installation

### 1. Exécuter le script d'installation

```bash
chmod +x install.sh
./install.sh
```

Le script installe automatiquement :
- `postgresql-client` (pg_dump, psql, pg_restore)
- `jq` (parsing JSON)
- `bc` (calculs)
- `openssh-client` (transferts SSH)
- `rsync` (transferts optimisés)

### 2. Rendre le script principal exécutable

```bash
chmod +x pg_anonymize_dump.sh
```

## ⚙️ Configuration

### Fichier de configuration principal

Créez un fichier `config.conf` :

```bash
# === CONFIGURATION SOURCE ===
SOURCE_HOST="localhost"
SOURCE_PORT="5432"
SOURCE_DB="production_db"
SOURCE_SCHEMA="public"
SOURCE_USER="postgres"
SOURCE_PASSWORD=""  # Utiliser .pgpass recommandé

# === CONFIGURATION TARGET ===
TARGET_HOST="localhost"
TARGET_PORT="5432"
TARGET_DB="staging_db"
TARGET_SCHEMA="public"
TARGET_USER="postgres"
TARGET_PASSWORD=""

# === CONFIGURATION SERVEURS ===
SOURCE_SERVER=""              # vide si local, sinon: user@server
TARGET_SERVER=""              # vide si local, sinon: user@server

# === RÉPERTOIRES ===
DUMP_DIR="/tmp/pg_dumps"
TRANSFER_METHOD="scp"         # scp, rsync ou local

# === RÈGLES D'ANONYMISATION ===
ANONYMIZE_RULES_FILE="anonymize_rules.json"

# === OPTIONS ===
AUTO_DETECT_PII=true
KEEP_DUMP_AFTER_RESTORE=false
BACKUP_TARGET_BEFORE=true
PARALLEL_JOBS=4

# === OPTIONS DE DUMP ===
DUMP_FORMAT="custom"          # custom, plain, directory, tar
COMPRESSION_LEVEL=6           # 0-9
```

### Fichier de règles d'anonymisation (JSON)

Le fichier `anonymize_rules.json` définit :

1. **Patterns de détection** : comment identifier les colonnes sensibles
2. **Méthodes d'anonymisation** : comment anonymiser chaque type
3. **Règles personnalisées** : règles spécifiques par table/colonne
4. **Exclusions** : tables et colonnes à ignorer

Exemple minimal :

```json
{
  "detection_patterns": {
    "email": ["email", "mail", "courriel"],
    "phone": ["phone", "tel", "mobile"],
    "name": ["name", "nom", "prenom"]
  },
  
  "anonymization_methods": {
    "email": "CASE WHEN {column} IS NOT NULL THEN 'user' || md5({column}::text)::uuid || '@anonymized.local' ELSE NULL END",
    "phone": "CASE WHEN {column} IS NOT NULL THEN '+33' || lpad((random() * 999999999)::bigint::text, 9, '0') ELSE NULL END",
    "name": "CASE WHEN {column} IS NOT NULL THEN 'Anonyme_' || substr(md5({column}::text), 1, 8) ELSE NULL END"
  },
  
  "custom_rules": [
    {
      "table": "users",
      "column": "password_hash",
      "method": "md5('anonymous')"
    }
  ],
  
  "exclude_tables": ["schema_migrations"],
  "exclude_columns": ["id", "created_at", "updated_at"]
}
```

## 📖 Utilisation

### Scénario 1 : Exécution locale (même serveur)

```bash
# Configuration
vim config_local.conf

# Exécution
./pg_anonymize_dump.sh config_local.conf
```

### Scénario 2 : Deux serveurs différents

**Option A : Script sur serveur source**

```bash
# Sur serveur1 (source)
SOURCE_HOST="localhost"
SOURCE_SERVER=""

TARGET_HOST="192.168.1.20"
TARGET_SERVER="user@192.168.1.20"

./pg_anonymize_dump.sh config.conf
```

**Option B : Script sur PC local**

```bash
# Sur PC local
SOURCE_HOST="192.168.1.10"
SOURCE_SERVER="user@192.168.1.10"

TARGET_HOST="192.168.1.20"
TARGET_SERVER="user@192.168.1.20"

./pg_anonymize_dump.sh config.conf
```

### Scénario 3 : Source accessible depuis serveur1, target depuis serveur2

```bash
# Exécuter le script sur serveur1
ssh user@serveur1

# Configuration
SOURCE_HOST="localhost"
SOURCE_SERVER=""

TARGET_HOST="192.168.1.20"
TARGET_SERVER="user@192.168.1.20"

./pg_anonymize_dump.sh config.conf
```

## 🔐 Sécurité des mots de passe

**Méthode recommandée : fichier .pgpass**

```bash
# Créer ~/.pgpass
cat > ~/.pgpass << EOF
localhost:5432:production_db:postgres:mot_de_passe_source
192.168.1.20:5432:staging_db:postgres:mot_de_passe_target
EOF

# Sécuriser le fichier
chmod 600 ~/.pgpass

# Laisser vide dans config.conf
SOURCE_PASSWORD=""
TARGET_PASSWORD=""
```

## 📊 Workflow détaillé

Le script exécute les étapes suivantes :

```
1. 📝 Chargement de la configuration
2. 🔍 Détection automatique des colonnes PII
3. 📝 Génération du script d'anonymisation SQL
4. 💾 Dump de la base source
5. 🔄 Restauration dans une base temporaire
6. 🎭 Application de l'anonymisation
7. 💾 Dump final anonymisé
8. 🗑️ Suppression de la base temporaire
9. 🚀 Transfert vers le serveur target (si applicable)
10. 💾 Backup du schéma target (si activé)
11. 🧹 Nettoyage du schéma target
12. 📥 Restauration dans le schéma target
13. 📊 Génération du rapport
14. ✅ Terminé !
```

## 📁 Structure des fichiers générés

```
/tmp/pg_dumps/
├── dump_anonymized_20260212_143022.dump    # Dump anonymisé
├── backup_target_20260212_143022.dump      # Backup du target
└── report_20260212_143022.txt              # Rapport détaillé

./
├── anonymize_20260212_143022.log           # Logs d'exécution
└── temp_anonymize_12345/                   # Temporaire (auto-nettoyé)
    ├── detected_columns.json
    └── anonymize.sql
```

## 🎯 Exemples d'utilisation

### Exemple 1 : Anonymiser une base complète

```bash
./pg_anonymize_dump.sh config.conf
```

### Exemple 2 : Voir les exemples de configuration

```bash
# Exemple de config
./pg_anonymize_dump.sh --example-config > ma_config.conf

# Exemple de règles
./pg_anonymize_dump.sh --example-rules > mes_regles.json
```

### Exemple 3 : Désactiver la détection automatique

```bash
# Dans config.conf
AUTO_DETECT_PII=false

# Le script utilisera uniquement les custom_rules
```

### Exemple 4 : Conserver les dumps

```bash
# Dans config.conf
KEEP_DUMP_AFTER_RESTORE=true

# Les dumps seront conservés dans DUMP_DIR
```

## 🔧 Personnalisation avancée

### Ajouter une nouvelle méthode d'anonymisation

```json
{
  "detection_patterns": {
    "siret": ["siret", "numero_siret"]
  },
  
  "anonymization_methods": {
    "siret": "CASE WHEN {column} IS NOT NULL THEN lpad((floor(random() * 99999999999999))::bigint::text, 14, '0') ELSE NULL END"
  }
}
```

### Anonymiser une colonne spécifique uniquement

```json
{
  "custom_rules": [
    {
      "table": "commandes",
      "column": "notes_client",
      "method": "'[ANONYMISÉ]'"
    }
  ]
}
```

### Exclure certaines tables de l'anonymisation

```json
{
  "exclude_tables": [
    "parametres_systeme",
    "logs_application",
    "reference_data"
  ]
}
```

## 📈 Performance

### Optimisation pour grandes bases

```bash
# Dans config.conf
DUMP_FORMAT="directory"      # Meilleur pour gros volumes
PARALLEL_JOBS=8              # Augmenter selon CPU disponible
COMPRESSION_LEVEL=3          # Réduire pour plus de vitesse
```

### Transfert optimisé

```bash
TRANSFER_METHOD="rsync"      # Plus rapide que scp pour gros fichiers
```

## ⚠️ Limitations et notes

1. **Base temporaire** : Le script crée une base temporaire pour l'anonymisation
   - Nécessite de l'espace disque (taille ≈ base source)
   - Nécessite les droits CREATE DATABASE

2. **Performances** : L'anonymisation prend du temps
   - Proportionnel au nombre de lignes à anonymiser
   - Utiliser PARALLEL_JOBS pour accélérer

3. **Cohérence** : L'anonymisation ne préserve pas les relations
   - Les clés étrangères peuvent devenir invalides
   - À gérer manuellement si nécessaire

4. **SSH** : Pour les transferts entre serveurs
   - Clés SSH configurées et autorisées
   - Ou utiliser ssh-agent

## 🐛 Dépannage

### Erreur : "PGPASSWORD: command not found"

**Solution** : Utiliser .pgpass au lieu de passwords dans la config

### Erreur : "Permission denied" lors du transfert SSH

**Solution** : Configurer les clés SSH
```bash
ssh-keygen -t rsa
ssh-copy-id user@serveur
```

### Erreur : "Database already exists"

**Solution** : Une base temporaire existe déjà
```bash
# Se connecter et supprimer manuellement
psql -U postgres -c "DROP DATABASE temp_anon_12345;"
```

### Le script est lent

**Solutions** :
- Augmenter PARALLEL_JOBS
- Réduire COMPRESSION_LEVEL
- Utiliser DUMP_FORMAT="directory"

## 📝 Logs et rapports

### Fichier de log

Chaque exécution génère un log détaillé :
```bash
tail -f anonymize_20260212_143022.log
```

### Rapport final

Le rapport contient :
- Résumé de la configuration
- Liste des colonnes anonymisées
- Statistiques du target
- Fichiers générés
- Durée totale

## 🤝 Support des types PostgreSQL

Le script supporte tous les types PostgreSQL standards :
- `text`, `varchar`, `char`
- `integer`, `bigint`, `numeric`
- `date`, `timestamp`, `timestamptz`
- `boolean`
- `json`, `jsonb`
- `uuid`
- `inet`, `cidr` (pour IP)

## 📄 Licence

Ce script est fourni "tel quel" sans garantie.
Libre d'utilisation et de modification.

## 👤 Auteur

Script créé pour l'anonymisation sécurisée de bases PostgreSQL.

## 🔄 Changelog

### Version 1.0.0 (2026-02-12)
- Version initiale
- Détection automatique PII
- Support multi-serveurs
- Anonymisation complète
- Transfert sécurisé
- Rapports détaillés

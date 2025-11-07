# Configuration Examples for pg_dump_to_csv

## 1. Variables d'environnement (.env)

Créez un fichier `.env` avec vos paramètres de connexion :

```bash
# Database connection settings
DB_HOST=localhost
DB_PORT=5432
DB_NAME=mydb
DB_USER=postgres
DB_PASSWORD=mysecretpassword

# Export settings
TABLE_NAME=users
OUTPUT_FILE=users.csv
```

Chargez les variables :

```bash
# Charger les variables d'environnement
source .env

# Exécuter le script
./pg_dump_to_csv.sh
```

## 2. Fichier de configuration PostgreSQL (.pgpass)

Pour éviter de taper le mot de passe à chaque fois :

```bash
# Créer le fichier .pgpass dans votre home directory
echo "localhost:5432:mydb:postgres:mysecretpassword" >> ~/.pgpass

# Donner les permissions appropriées (IMPORTANT!)
chmod 600 ~/.pgpass
```

Format du fichier `.pgpass` :
```
hostname:port:database:username:password
```

Exemples :
```
localhost:5432:*:postgres:mypassword
192.168.1.100:5432:production:admin:prod_password
*:*:test_db:test_user:test_password
```

## 3. Script de configuration de projet

```bash
#!/bin/bash
# config.sh - Configuration pour exports PostgreSQL

# Paramètres de connexion
export DB_HOST="localhost"
export DB_PORT="5432"
export DB_NAME="myprojectdb"
export DB_USER="projectuser"

# Méthode d'export (psql ou dump)
export EXPORT_METHOD="psql"

# Répertoire de sortie
export OUTPUT_DIR="./exports/$(date +%Y%m%d)"

# Créer le répertoire de sortie
mkdir -p "$OUTPUT_DIR"

echo "Configuration chargée :"
echo "  Database: $DB_NAME @ $DB_HOST:$DB_PORT"
echo "  User: $DB_USER"
echo "  Output: $OUTPUT_DIR"
```

Utilisation :
```bash
source config.sh
./pg_dump_to_csv.sh -t users -o "$OUTPUT_DIR/users.csv"
```

## 4. Export planifié (Cron)

### Export quotidien à minuit

```bash
# Ouvrir crontab
crontab -e

# Ajouter cette ligne pour export quotidien
0 0 * * * /path/to/pg_dump_to_csv.sh -d mydb -t users -o /backup/users_$(date +\%Y\%m\%d).csv 2>&1 | logger -t pg_export
```

### Export hebdomadaire le dimanche à 2h du matin

```bash
0 2 * * 0 /path/to/batch_export.sh -d mydb --all -o /backup/weekly/$(date +\%Y\%m\%d)
```

### Export mensuel le 1er de chaque mois

```bash
0 3 1 * * /path/to/batch_export.sh -d mydb --all -o /backup/monthly/$(date +\%Y\%m)
```

## 5. Script de rotation des backups

```bash
#!/bin/bash
# rotate_exports.sh - Rotation automatique des exports

BACKUP_DIR="/backup/exports"
RETENTION_DAYS=30

# Exporter les données
./batch_export.sh -d mydb --all -o "$BACKUP_DIR/$(date +%Y%m%d)"

# Supprimer les exports plus vieux que RETENTION_DAYS
find "$BACKUP_DIR" -type f -name "*.csv" -mtime +$RETENTION_DAYS -delete

echo "Backup completed and old files cleaned up"
```

## 6. Configuration Docker

Si PostgreSQL est dans Docker :

```bash
# Variables pour conteneur Docker
export DB_HOST="localhost"  # ou l'IP du conteneur
export DB_PORT="5432"       # port exposé
export DB_NAME="mydb"
export DB_USER="postgres"

# Si PostgreSQL écoute sur un port custom
export DB_PORT="5433"

# Export
./pg_dump_to_csv.sh -t users -o users.csv
```

## 7. Configuration pour environnements multiples

```bash
#!/bin/bash
# multi_env_config.sh

case "$1" in
    dev)
        export DB_HOST="localhost"
        export DB_NAME="dev_db"
        export DB_USER="dev_user"
        export OUTPUT_DIR="./exports/dev"
        ;;
    staging)
        export DB_HOST="staging.example.com"
        export DB_NAME="staging_db"
        export DB_USER="staging_user"
        export OUTPUT_DIR="./exports/staging"
        ;;
    prod)
        export DB_HOST="prod.example.com"
        export DB_NAME="production_db"
        export DB_USER="prod_user"
        export OUTPUT_DIR="./exports/prod"
        ;;
    *)
        echo "Usage: $0 {dev|staging|prod}"
        exit 1
        ;;
esac

echo "Environment: $1"
echo "Database: $DB_NAME @ $DB_HOST"
```

Utilisation :
```bash
source multi_env_config.sh dev
./pg_dump_to_csv.sh -t users -o users.csv
```

## 8. Wrapper avec logging

```bash
#!/bin/bash
# export_with_log.sh

LOG_FILE="./logs/export_$(date +%Y%m%d_%H%M%S).log"
mkdir -p ./logs

{
    echo "=== Export started at $(date) ==="
    
    ./pg_dump_to_csv.sh \
        -d "$DB_NAME" \
        -t "$TABLE_NAME" \
        -o "$OUTPUT_FILE"
    
    EXIT_CODE=$?
    
    echo "=== Export finished at $(date) with exit code $EXIT_CODE ==="
} 2>&1 | tee -a "$LOG_FILE"

exit $EXIT_CODE
```

## 9. Configuration avec sécurité renforcée

```bash
#!/bin/bash
# secure_config.sh

# Lire le mot de passe de manière sécurisée
read -sp "Enter database password: " DB_PASSWORD
echo
export DB_PASSWORD

# Ou utiliser un gestionnaire de secrets
# export DB_PASSWORD=$(secret-tool lookup postgres mydb)

# Ou Azure Key Vault
# export DB_PASSWORD=$(az keyvault secret show --name db-password --vault-name myvault --query value -o tsv)

# Ou AWS Secrets Manager
# export DB_PASSWORD=$(aws secretsmanager get-secret-value --secret-id db-password --query SecretString --output text)
```

## 10. Export parallèle

```bash
#!/bin/bash
# parallel_export.sh - Export multiple tables in parallel

TABLES=("users" "products" "orders" "customers" "transactions")

# Export en parallèle (max 3 processus simultanés)
for table in "${TABLES[@]}"; do
    (
        ./pg_dump_to_csv.sh -d mydb -t "$table" -o "${table}.csv"
    ) &
    
    # Limiter à 3 processus simultanés
    if [[ $(jobs -r -p | wc -l) -ge 3 ]]; then
        wait -n
    fi
done

# Attendre que tous les exports se terminent
wait

echo "All exports completed!"
```

## 11. Configuration avec validation

```bash
#!/bin/bash
# validated_export.sh

# Fonction de validation
validate_export() {
    local csv_file=$1
    local table=$2
    
    # Vérifier que le fichier existe
    if [ ! -f "$csv_file" ]; then
        echo "ERROR: File $csv_file not found"
        return 1
    fi
    
    # Vérifier le nombre de lignes
    local csv_lines=$(wc -l < "$csv_file")
    local db_lines=$(psql -h "$DB_HOST" -U "$DB_USER" -d "$DB_NAME" -t -c "SELECT COUNT(*) + 1 FROM $table;")
    
    if [ "$csv_lines" -eq "$db_lines" ]; then
        echo "✓ Validation successful: $csv_lines lines"
        return 0
    else
        echo "✗ Validation failed: CSV has $csv_lines lines, DB has $((db_lines - 1)) rows"
        return 1
    fi
}

# Export et validation
./pg_dump_to_csv.sh -d mydb -t users -o users.csv
validate_export "users.csv" "users"
```

## 12. Notification par email

```bash
#!/bin/bash
# export_with_notification.sh

RECIPIENT="admin@example.com"

# Exécuter l'export
if ./batch_export.sh -d mydb --all -o ./exports; then
    STATUS="SUCCESS"
    MESSAGE="PostgreSQL export completed successfully"
else
    STATUS="FAILED"
    MESSAGE="PostgreSQL export failed"
fi

# Envoyer notification
echo "$MESSAGE at $(date)" | mail -s "DB Export: $STATUS" "$RECIPIENT"
```

Ces configurations couvrent la plupart des cas d'usage courants pour l'export PostgreSQL vers CSV.

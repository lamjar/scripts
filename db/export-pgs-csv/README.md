# Script PostgreSQL Export vers CSV

Ce script permet d'exporter des données PostgreSQL vers un fichier CSV avec headers **SANS utiliser la commande COPY**.

## 📋 Fonctionnalités

- ✅ Export de tables PostgreSQL vers CSV
- ✅ Génération automatique des headers (noms des colonnes)
- ✅ **Sélection de colonnes spécifiques** (nouveau !)
- ✅ **Mode interactif pour choisir les colonnes** (nouveau !)
- ✅ **Lister les colonnes disponibles** (nouveau !)
- ✅ Deux méthodes d'export : `pg_dump` et `psql`
- ✅ Support des variables d'environnement
- ✅ Connexion sécurisée avec mot de passe
- ✅ Messages colorés et informatifs
- ✅ Validation de la connexion avant export

## 🔧 Prérequis

- PostgreSQL client tools installés (`psql`, `pg_dump`)
- Accès à une base de données PostgreSQL
- Bash shell

## 📦 Installation

```bash
# Donner les droits d'exécution
chmod +x pg_dump_to_csv.sh
```

## 🚀 Utilisation

### Syntaxe de base

```bash
./pg_dump_to_csv.sh -d DATABASE -t TABLE -o output.csv
```

### Options disponibles

| Option | Description | Défaut |
|--------|-------------|--------|
| `-h, --host` | Hôte de la base de données | localhost |
| `-p, --port` | Port de la base de données | 5432 |
| `-d, --database` | Nom de la base de données | **(requis)** |
| `-u, --user` | Utilisateur PostgreSQL | postgres |
| `-w, --password` | Mot de passe | *(vide)* |
| `-t, --table` | Nom de la table à exporter | **(requis)** |
| `-c, --columns` | Colonnes à exporter (séparées par virgules) | *(toutes)* |
| `-o, --output` | Fichier CSV de sortie | output.csv |
| `-m, --method` | Méthode d'export: `dump` ou `psql` | psql |
| `-i, --interactive` | Mode interactif pour sélectionner les colonnes | - |
| `-l, --list-columns` | Lister les colonnes disponibles et quitter | - |
| `--help` | Afficher l'aide | - |

## 📝 Exemples

### Exemple 1 : Export simple (toutes les colonnes)

```bash
./pg_dump_to_csv.sh -d mydb -t users -o users.csv
```

### Exemple 2 : Lister les colonnes disponibles

```bash
./pg_dump_to_csv.sh -d mydb -t users --list-columns
```

### Exemple 3 : Exporter des colonnes spécifiques

```bash
./pg_dump_to_csv.sh -d mydb -t users -c "id,username,email" -o users.csv
```

### Exemple 4 : Mode interactif

```bash
./pg_dump_to_csv.sh -d mydb -t users --interactive -o users.csv
```

### Exemple 5 : Avec authentification

```bash
./pg_dump_to_csv.sh \
  -h localhost \
  -p 5432 \
  -d mydb \
  -u postgres \
  -w mypassword \
  -t customers \
  -c "customer_id,name,email,country" \
  -o customers.csv
```

### Exemple 6 : Utilisation de pg_dump

```bash
./pg_dump_to_csv.sh \
  -d mydb \
  -t products \
  -c "id,name,price" \
  -o products.csv \
  -m dump
```

### Exemple 7 : Avec variables d'environnement

```bash
export DB_HOST=localhost
export DB_PORT=5432
export DB_NAME=mydb
export DB_USER=postgres
export DB_PASSWORD=mypassword
export TABLE_NAME=orders
export COLUMNS="order_id,customer_id,total_amount,order_date"
export OUTPUT_FILE=orders.csv

./pg_dump_to_csv.sh
```

### Exemple 8 : Export depuis un serveur distant

```bash
./pg_dump_to_csv.sh \
  -h db.example.com \
  -p 5432 \
  -d production_db \
  -u readonly_user \
  -w secretpass \
  -t transactions \
  -c "id,date,amount,status" \
  -o transactions_export.csv
```

## 🔍 Sélection de colonnes

### Pourquoi sélectionner des colonnes ?

- 📉 Réduire la taille des fichiers CSV
- 🔒 Exporter sans données sensibles (RGPD)
- 🎯 Exporter uniquement les données nécessaires
- ⚡ Accélérer les exports de grandes tables

### Méthodes disponibles

#### 1. Toutes les colonnes (défaut)

```bash
./pg_dump_to_csv.sh -d mydb -t users -o users.csv
```

#### 2. Colonnes spécifiques

```bash
./pg_dump_to_csv.sh -d mydb -t users -c "id,username,email" -o users.csv
```

#### 3. Mode interactif

```bash
./pg_dump_to_csv.sh -d mydb -t users -i -o users.csv
```

L'interface interactive vous permet de :
- Voir toutes les colonnes disponibles avec leur type
- Sélectionner par numéro (ex: `1,3,5`)
- Sélectionner par nom (ex: `username,email`)
- Choisir toutes les colonnes avec `a`

#### 4. Lister les colonnes

```bash
./pg_dump_to_csv.sh -d mydb -t users -l
```

Affiche :
```
 # | Column Name  | Type                        | Nullable
---+--------------+-----------------------------+----------
 1 | id           | integer                     | NOT NULL
 2 | username     | character varying(50)       | NOT NULL
 3 | email        | character varying(100)      | NOT NULL
 4 | age          | integer                     | NULL
 5 | is_active    | boolean                     | NULL
 6 | created_at   | timestamp without time zone | NULL
```

### Cas d'usage pratiques

**Export anonymisé (sans données personnelles)**
```bash
./pg_dump_to_csv.sh -d mydb -t users -c "id,country,signup_date,purchase_count" -o users_anonymous.csv
```

**Export léger (réduction de taille)**
```bash
./pg_dump_to_csv.sh -d mydb -t logs -c "id,timestamp,level,message" -o logs_light.csv
```

**Export pour rapport**
```bash
./pg_dump_to_csv.sh -d mydb -t sales -c "date,product,revenue,region" -o sales_report.csv
```

📖 **Guide complet** : Consultez [COLUMN_SELECTION_GUIDE.md](COLUMN_SELECTION_GUIDE.md) pour plus d'exemples.

## 🔍 Méthodes d'export

### Méthode 1 : `psql` (Recommandée)

La méthode par défaut utilise `psql` avec des options de formatage :

```bash
./pg_dump_to_csv.sh -d mydb -t users -m psql
```

**Avantages :**
- Plus rapide pour les grandes tables
- Format CSV natif
- Meilleure gestion des types de données

### Méthode 2 : `pg_dump`

Utilise `pg_dump` avec l'option `--column-inserts` :

```bash
./pg_dump_to_csv.sh -d mydb -t users -m dump
```

**Avantages :**
- Utilise l'outil officiel pg_dump
- Peut être plus fiable pour certaines structures de données

## 📊 Format du fichier CSV

Le fichier CSV généré contient :

1. **Première ligne** : Header avec les noms des colonnes séparés par des virgules
2. **Lignes suivantes** : Données de la table

Exemple de sortie :

```csv
id,name,email,created_at
1,John Doe,john@example.com,2024-01-15
2,Jane Smith,jane@example.com,2024-01-16
3,Bob Johnson,bob@example.com,2024-01-17
```

## 🔐 Sécurité

### Mot de passe

Le script utilise la variable d'environnement `PGPASSWORD` pour éviter d'exposer le mot de passe dans l'historique des commandes.

### Méthode recommandée : `.pgpass`

Créez un fichier `~/.pgpass` avec le format :

```
hostname:port:database:username:password
```

Exemple :

```bash
echo "localhost:5432:mydb:postgres:mypassword" >> ~/.pgpass
chmod 600 ~/.pgpass
```

Puis utilisez le script sans l'option `-w` :

```bash
./pg_dump_to_csv.sh -d mydb -t users -o users.csv
```

## ⚠️ Gestion des erreurs

Le script vérifie automatiquement :

- ✅ Installation des outils PostgreSQL
- ✅ Connexion à la base de données
- ✅ Existence de la table
- ✅ Récupération des colonnes
- ✅ Succès de l'export

Messages d'erreur typiques :

```
[ERROR] psql is not installed. Please install PostgreSQL client tools.
[ERROR] Cannot connect to database
[ERROR] Could not retrieve column names. Check if table exists.
[ERROR] Export failed
```

## 📈 Performance

Pour optimiser les performances sur de grandes tables :

```bash
# Utiliser la méthode psql (plus rapide)
./pg_dump_to_csv.sh -d mydb -t big_table -m psql -o big_table.csv

# Si la table est très grande, considérez d'exporter par lots
# ou d'utiliser une requête avec WHERE clause (modification du script nécessaire)
```

## 🔄 Automatisation

### Cron Job

Ajoutez une tâche cron pour des exports automatiques :

```bash
# Editer crontab
crontab -e

# Export quotidien à minuit
0 0 * * * /path/to/pg_dump_to_csv.sh -d mydb -t users -o /backup/users_$(date +\%Y\%m\%d).csv
```

### Script Batch

Créez un script pour exporter plusieurs tables :

```bash
#!/bin/bash

TABLES=("users" "products" "orders" "customers")

for table in "${TABLES[@]}"; do
    ./pg_dump_to_csv.sh -d mydb -t "$table" -o "${table}.csv"
done
```

## 🐛 Dépannage

### Problème : "psql is not installed"

**Solution :** Installer les outils client PostgreSQL

```bash
# Ubuntu/Debian
sudo apt-get install postgresql-client

# CentOS/RHEL
sudo yum install postgresql

# macOS
brew install postgresql
```

### Problème : "Cannot connect to database"

**Solutions possibles :**
1. Vérifier que PostgreSQL est en cours d'exécution
2. Vérifier les credentials (host, port, user, password)
3. Vérifier les règles de pare-feu
4. Vérifier `pg_hba.conf` pour les permissions

### Problème : "Could not retrieve column names"

**Solution :** Vérifier que la table existe

```bash
psql -h localhost -U postgres -d mydb -c "\dt"
```

## 📄 License

Ce script est fourni tel quel, sans garantie.

## 🤝 Contribution

N'hésitez pas à améliorer ce script selon vos besoins !

## 📞 Support

Pour toute question ou problème, vérifiez :
- La connexion à la base de données
- Les permissions utilisateur
- Les logs PostgreSQL

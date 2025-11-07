# Guide de Sélection de Colonnes

Ce guide explique comment utiliser la fonctionnalité de sélection de colonnes pour exporter uniquement les colonnes dont vous avez besoin.

## 📋 Table des Matières

1. [Vue d'ensemble](#vue-densemble)
2. [Lister les colonnes disponibles](#lister-les-colonnes-disponibles)
3. [Exporter toutes les colonnes](#exporter-toutes-les-colonnes)
4. [Exporter des colonnes spécifiques](#exporter-des-colonnes-spécifiques)
5. [Mode interactif](#mode-interactif)
6. [Utilisation avancée](#utilisation-avancée)
7. [Cas d'usage](#cas-dusage)

---

## 📖 Vue d'ensemble

Le script `pg_dump_to_csv.sh` permet maintenant de sélectionner précisément les colonnes à exporter :

✅ **Exporter toutes les colonnes** (comportement par défaut)  
✅ **Exporter des colonnes spécifiques** (en paramètre ou variable d'environnement)  
✅ **Sélection interactive** (choisir les colonnes de manière guidée)  
✅ **Lister les colonnes disponibles** (pour voir la structure de la table)

---

## 🔍 Lister les colonnes disponibles

Avant d'exporter, vous pouvez voir quelles colonnes sont disponibles dans une table.

### Commande

```bash
./pg_dump_to_csv.sh -d mydb -t users --list-columns
```

### Sortie exemple

```
[INFO] Available columns in table 'users':
 # | Column Name  | Type                        | Nullable
---+--------------+-----------------------------+----------
 1 | id           | integer                     | NOT NULL
 2 | username     | character varying(50)       | NOT NULL
 3 | email        | character varying(100)      | NOT NULL
 4 | age          | integer                     | NULL
 5 | is_active    | boolean                     | NULL
 6 | created_at   | timestamp without time zone | NULL
```

### Alias court

```bash
./pg_dump_to_csv.sh -d mydb -t users -l
```

---

## 📦 Exporter toutes les colonnes

Par défaut, si vous ne spécifiez pas de colonnes, toutes les colonnes sont exportées.

### Commande

```bash
./pg_dump_to_csv.sh -d mydb -t users -o users.csv
```

### Résultat

```csv
id,username,email,age,is_active,created_at
1,john_doe,john@example.com,30,t,2024-01-15 10:30:00
2,jane_smith,jane@example.com,25,t,2024-01-16 11:45:00
```

---

## 🎯 Exporter des colonnes spécifiques

### Méthode 1 : Option `-c` ou `--columns`

Spécifiez les colonnes séparées par des virgules (sans espaces) :

```bash
./pg_dump_to_csv.sh -d mydb -t users -c "id,username,email" -o users.csv
```

**Résultat :**
```csv
id,username,email
1,john_doe,john@example.com
2,jane_smith,jane@example.com
```

### Méthode 2 : Variable d'environnement

```bash
export DB_NAME=mydb
export TABLE_NAME=users
export COLUMNS="id,username,email"
export OUTPUT_FILE=users.csv

./pg_dump_to_csv.sh
```

### Méthode 3 : Avec espaces (entourés de guillemets)

```bash
./pg_dump_to_csv.sh -d mydb -t users -c "username, email, created_at" -o users_info.csv
```

**Note :** Les espaces autour des virgules sont automatiquement supprimés.

---

## 🎨 Mode interactif

Le mode interactif vous permet de sélectionner les colonnes de manière guidée.

### Commande

```bash
./pg_dump_to_csv.sh -d mydb -t users --interactive -o users.csv
```

ou

```bash
./pg_dump_to_csv.sh -d mydb -t users -i -o users.csv
```

### Exemple d'interaction

```
[INFO] Interactive column selection for table 'users'

Available columns:
  1) id
  2) username
  3) email
  4) age
  5) is_active
  6) created_at
  a) All columns

Select columns (comma-separated numbers, 'a' for all, or column names): 1,2,3

[INFO] Selected columns: id,username,email
```

### Options de sélection

1. **Par numéros** : `1,3,5` → Sélectionne les colonnes 1, 3 et 5
2. **Tous** : `a` ou `A` → Sélectionne toutes les colonnes
3. **Par noms** : `username,email` → Sélectionne directement par nom

---

## 🚀 Utilisation avancée

### Exemple 1 : Export partiel pour analyse

Exporter uniquement les colonnes nécessaires pour une analyse :

```bash
./pg_dump_to_csv.sh \
  -d analytics_db \
  -t transactions \
  -c "transaction_id,amount,date,status" \
  -o transactions_summary.csv
```

### Exemple 2 : Export pour rapport

Créer un rapport avec colonnes sélectionnées :

```bash
./pg_dump_to_csv.sh \
  -d production_db \
  -t employees \
  -c "employee_id,first_name,last_name,department,salary" \
  -o employee_report.csv
```

### Exemple 3 : Export sans données sensibles

Exporter une table en excluant les colonnes sensibles :

```bash
# Exporter users sans password et email
./pg_dump_to_csv.sh \
  -d mydb \
  -t users \
  -c "id,username,first_name,last_name,created_at" \
  -o users_public.csv
```

### Exemple 4 : Export multi-colonnes complexe

```bash
./pg_dump_to_csv.sh \
  -d ecommerce_db \
  -t orders \
  -c "order_id,customer_name,product_name,quantity,unit_price,total_amount,order_date,status" \
  -o orders_detailed.csv
```

### Exemple 5 : Script automatisé avec différentes sélections

```bash
#!/bin/bash

DB="mydb"
TABLE="products"

# Export complet
./pg_dump_to_csv.sh -d "$DB" -t "$TABLE" -o products_full.csv

# Export pour catalogue (sans prix)
./pg_dump_to_csv.sh -d "$DB" -t "$TABLE" \
  -c "id,name,description,category" \
  -o products_catalog.csv

# Export pour finance (avec prix uniquement)
./pg_dump_to_csv.sh -d "$DB" -t "$TABLE" \
  -c "id,name,price,cost,margin" \
  -o products_finance.csv

# Export pour stock
./pg_dump_to_csv.sh -d "$DB" -t "$TABLE" \
  -c "id,name,stock_quantity,reorder_level" \
  -o products_inventory.csv
```

---

## 💡 Cas d'usage

### Cas 1 : Anonymisation de données

**Problème :** Vous devez partager une table mais sans les données personnelles.

**Solution :**
```bash
./pg_dump_to_csv.sh \
  -d user_db \
  -t customers \
  -c "customer_id,purchase_count,total_spent,signup_date,country" \
  -o customers_anonymous.csv
```

### Cas 2 : Réduction de la taille du fichier

**Problème :** La table contient beaucoup de colonnes inutiles pour votre analyse.

**Solution :**
```bash
# Au lieu d'exporter 30 colonnes, n'exporter que 5
./pg_dump_to_csv.sh \
  -d big_data_db \
  -t events \
  -c "event_id,event_type,timestamp,user_id,value" \
  -o events_light.csv
```

### Cas 3 : Export pour migration

**Problème :** Vous migrez vers un nouveau système qui n'a pas toutes les colonnes.

**Solution :**
```bash
./pg_dump_to_csv.sh \
  -d old_system \
  -t products \
  -c "sku,name,price,category" \
  -o products_migration.csv
```

### Cas 4 : Rapport pour les managers

**Problème :** Les managers ont besoin d'un rapport simple sans détails techniques.

**Solution :**
```bash
./pg_dump_to_csv.sh \
  -d sales_db \
  -t sales_report \
  -c "date,product,revenue,profit,region" \
  -o management_report.csv
```

### Cas 5 : Conformité RGPD

**Problème :** Vous devez exporter des données sans informations personnelles identifiables.

**Solution :**
```bash
# Exporter sans email, téléphone, adresse
./pg_dump_to_csv.sh \
  -d customer_db \
  -t customers \
  -c "customer_id,country,purchase_history,preferences" \
  -o customers_gdpr_compliant.csv
```

---

## 🔧 Validation et Erreurs

### Validation automatique

Le script valide automatiquement que les colonnes spécifiées existent :

```bash
$ ./pg_dump_to_csv.sh -d mydb -t users -c "id,invalid_column,email" -o test.csv

[ERROR] Column 'invalid_column' does not exist in table 'users'
```

### Colonnes avec espaces

Si vos colonnes contiennent des espaces, entourez-les de guillemets :

```bash
./pg_dump_to_csv.sh -d mydb -t mytable -c "\"First Name\",\"Last Name\",Email" -o output.csv
```

---

## 📊 Comparaison des méthodes

| Méthode | Avantages | Inconvénients | Cas d'usage |
|---------|-----------|---------------|-------------|
| **Toutes les colonnes** | Simple, rapide | Fichier plus lourd | Backup complet |
| **Colonnes spécifiques** | Précis, léger | Nécessite de connaître les colonnes | Export ciblé |
| **Mode interactif** | Facile, guidé | Moins adapté aux scripts | Exploration |
| **Variables d'env** | Réutilisable | Configuration supplémentaire | Automatisation |

---

## ✅ Bonnes pratiques

1. **Toujours lister d'abord** : Utilisez `-l` pour voir les colonnes disponibles
2. **Exporter uniquement nécessaire** : Réduisez la taille des fichiers et le temps d'export
3. **Documenter vos exports** : Notez quelles colonnes vous avez exportées et pourquoi
4. **Valider les noms** : Vérifiez l'orthographe des noms de colonnes
5. **Automatiser** : Utilisez des variables d'environnement pour les exports répétitifs

---

## 🎬 Démonstration

Pour voir toutes ces fonctionnalités en action, exécutez le script de démonstration :

```bash
./demo_column_selection.sh
```

---

## 📞 Support

Si vous rencontrez des problèmes :

1. Vérifiez que la table existe : `\dt` dans psql
2. Listez les colonnes : `./pg_dump_to_csv.sh -d mydb -t table -l`
3. Vérifiez l'orthographe des noms de colonnes
4. Assurez-vous que les colonnes sont séparées par des virgules sans espaces superflus

---

**Prêt à exporter ? Commencez par lister vos colonnes disponibles !** 🚀

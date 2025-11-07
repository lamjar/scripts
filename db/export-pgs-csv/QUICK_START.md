# 🚀 Quick Start - Sélection de Colonnes

Guide ultra-rapide pour commencer à utiliser la sélection de colonnes.

## ⚡ En 30 secondes

### 1️⃣ Voir les colonnes disponibles

```bash
./pg_dump_to_csv.sh -d mydb -t users -l
```

### 2️⃣ Exporter des colonnes spécifiques

```bash
./pg_dump_to_csv.sh -d mydb -t users -c "id,name,email" -o users.csv
```

### 3️⃣ Mode interactif (le plus facile)

```bash
./pg_dump_to_csv.sh -d mydb -t users -i -o users.csv
```

**C'est tout ! Vous êtes prêt ! 🎉**

---

## 📖 Commandes essentielles

| Que voulez-vous faire ? | Commande |
|------------------------|----------|
| **Voir les colonnes** | `-l` ou `--list-columns` |
| **Choisir interactivement** | `-i` ou `--interactive` |
| **Spécifier les colonnes** | `-c "col1,col2,col3"` |
| **Exporter tout** | *(pas d'option -c)* |

---

## 💡 Exemples rapides

### Export basique (toutes colonnes)
```bash
./pg_dump_to_csv.sh -d mydb -t users -o users.csv
```

### Export de 3 colonnes
```bash
./pg_dump_to_csv.sh -d mydb -t users -c "id,username,email" -o users.csv
```

### Export sans données sensibles
```bash
./pg_dump_to_csv.sh -d mydb -t users -c "id,age,country" -o users_anonymous.csv
```

### Avec authentification
```bash
./pg_dump_to_csv.sh -h localhost -u postgres -w password -d mydb -t users -c "id,name" -o users.csv
```

---

## 🎯 Cas d'usage en 1 ligne

**RGPD / Anonymisation**
```bash
./pg_dump_to_csv.sh -d mydb -t customers -c "customer_id,country,purchase_count" -o customers_anon.csv
```

**Rapport financier**
```bash
./pg_dump_to_csv.sh -d mydb -t sales -c "date,product,revenue,profit" -o sales_report.csv
```

**Migration de données**
```bash
./pg_dump_to_csv.sh -d olddb -t users -c "id,username,email" -o migration.csv
```

**Catalogue produits**
```bash
./pg_dump_to_csv.sh -d mydb -t products -c "name,description,category" -o catalog.csv
```

---

## 🔥 Mode interactif (recommandé pour débuter)

```bash
./pg_dump_to_csv.sh -d mydb -t users -i -o users.csv
```

Vous verrez :
```
Available columns:
  1) id
  2) username
  3) email
  4) age
  5) created_at
  a) All columns

Select columns: 1,2,3     ← Tapez les numéros ou les noms
```

Options de sélection :
- `1,3,5` → Colonnes par numéro
- `a` → Toutes les colonnes
- `username,email` → Par nom

---

## 📊 Résultat

### Avant (sans sélection)
```csv
id,username,email,age,phone,address,created_at,updated_at
1,john,john@mail.com,30,555-0100,123 Main St,2024-01-01,2024-01-15
```

### Après (avec sélection)
```csv
id,username,email
1,john,john@mail.com
```

✅ **Plus petit, plus rapide, plus propre !**

---

## 🛠️ Tester avec la base d'exemple

### 1. Créer la base de test
```bash
./test_pg_dump_to_csv.sh
```

### 2. Lancer les exemples
```bash
./practical_examples.sh
```

### 3. Démonstration interactive
```bash
./demo_column_selection.sh
```

---

## 🤔 Besoin d'aide ?

### Lister les colonnes
```bash
./pg_dump_to_csv.sh -d mydb -t mytable -l
```

### Aide complète
```bash
./pg_dump_to_csv.sh --help
```

### Documentation détaillée
- [README.md](README.md) - Documentation complète
- [COLUMN_SELECTION_GUIDE.md](COLUMN_SELECTION_GUIDE.md) - Guide détaillé
- [CONFIGURATION_EXAMPLES.md](CONFIGURATION_EXAMPLES.md) - Exemples de config

---

## ⚠️ Erreurs courantes

### Erreur : "Column does not exist"
```bash
# Solution : Vérifier l'orthographe
./pg_dump_to_csv.sh -d mydb -t users -l
```

### Erreur : "Cannot connect"
```bash
# Vérifier les paramètres de connexion
./pg_dump_to_csv.sh -h localhost -p 5432 -u postgres -w password -d mydb -t users -l
```

### Oublié le nom des colonnes ?
```bash
# Lister d'abord !
./pg_dump_to_csv.sh -d mydb -t users -l
```

---

## 🎓 Prochaines étapes

1. ✅ Vous savez lister les colonnes
2. ✅ Vous savez exporter des colonnes spécifiques
3. ✅ Vous connaissez le mode interactif

**Maintenant, essayez :**
- Automatiser avec des scripts
- Planifier avec cron
- Intégrer dans vos workflows

---

## 📞 Support rapide

| Problème | Solution |
|----------|----------|
| Colonne introuvable | Utiliser `-l` pour lister |
| Syntaxe incorrecte | `"col1,col2,col3"` (virgules, sans espaces) |
| Mot de passe | Utiliser `.pgpass` ou variable `PGPASSWORD` |
| Table inconnue | Vérifier avec `\dt` dans psql |

---

**Prêt ? Commencez maintenant ! 🚀**

```bash
./pg_dump_to_csv.sh -d YOUR_DB -t YOUR_TABLE -i -o output.csv
```

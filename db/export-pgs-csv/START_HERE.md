# 🎯 COMMENCEZ ICI !

Bienvenue dans le **package complet d'export PostgreSQL vers CSV** avec sélection de colonnes !

## ⚡ Démarrage ultra-rapide (30 secondes)

```bash
# 1. Rendre les scripts exécutables
chmod +x *.sh

# 2. Lister les colonnes disponibles
./pg_dump_to_csv.sh -d mydb -t users --list-columns

# 3. Exporter avec sélection de colonnes
./pg_dump_to_csv.sh -d mydb -t users -c "id,name,email" -o users.csv
```

**C'est tout ! Vous venez d'exporter des données PostgreSQL avec sélection de colonnes ! 🎉**

---

## 📦 Contenu du package

### 🔧 Scripts (5)

| Script | Description | Utilisation |
|--------|-------------|-------------|
| **pg_dump_to_csv.sh** | ⭐ Script principal | Export avec sélection de colonnes |
| **batch_export.sh** | Export multiple | Exporter plusieurs tables |
| **test_pg_dump_to_csv.sh** | Base de test | Créer des données d'exemple |
| **demo_column_selection.sh** | Démonstration | Voir les fonctionnalités en action |
| **practical_examples.sh** | 8 exemples | Cas d'usage pratiques |

### 📚 Documentation (6)

| Document | Pour qui ? | Contenu |
|----------|-----------|---------|
| **[INDEX.md](INDEX.md)** | 🗺️ Tous | Navigation complète |
| **[QUICK_START.md](QUICK_START.md)** | 🚀 Débutants | Démarrage en 30s |
| **[README.md](README.md)** | 📖 Utilisateurs | Doc complète |
| **[COLUMN_SELECTION_GUIDE.md](COLUMN_SELECTION_GUIDE.md)** | 🎯 Avancés | Guide détaillé |
| **[CONFIGURATION_EXAMPLES.md](CONFIGURATION_EXAMPLES.md)** | ⚙️ Experts | Configs avancées |
| **[CHANGELOG.md](CHANGELOG.md)** | 📝 Tous | Historique des versions |

---

## 🎬 Premiers pas recommandés

### Pour les débutants (5 minutes)

```bash
# 1. Lire le Quick Start
cat QUICK_START.md

# 2. Tester avec la base d'exemple
./test_pg_dump_to_csv.sh

# 3. Voir la démo
./demo_column_selection.sh
```

### Pour les utilisateurs expérimentés (2 minutes)

```bash
# Export direct avec colonnes
./pg_dump_to_csv.sh -d mydb -t users -c "id,username,email" -o users.csv

# Ou mode interactif
./pg_dump_to_csv.sh -d mydb -t users -i -o users.csv
```

---

## ✨ Fonctionnalités principales

### 🎯 Sélection de colonnes (NOUVEAU !)

✅ **Exporter des colonnes spécifiques**
```bash
./pg_dump_to_csv.sh -d mydb -t users -c "id,name,email" -o users.csv
```

✅ **Mode interactif**
```bash
./pg_dump_to_csv.sh -d mydb -t users -i -o users.csv
```

✅ **Lister les colonnes disponibles**
```bash
./pg_dump_to_csv.sh -d mydb -t users -l
```

### 📊 Export de base

✅ Export avec headers automatiques  
✅ Deux méthodes : `pg_dump` et `psql`  
✅ Validation automatique  
✅ Messages colorés  

---

## 🚀 Cas d'usage rapides

### 1. Anonymisation RGPD
```bash
./pg_dump_to_csv.sh -d mydb -t customers \
  -c "customer_id,country,purchase_count" \
  -o customers_anonymous.csv
```

### 2. Rapport financier
```bash
./pg_dump_to_csv.sh -d mydb -t sales \
  -c "date,product,revenue,profit" \
  -o sales_report.csv
```

### 3. Migration de données
```bash
./pg_dump_to_csv.sh -d olddb -t users \
  -c "id,username,email" \
  -o migration.csv
```

### 4. Export léger
```bash
./pg_dump_to_csv.sh -d mydb -t logs \
  -c "timestamp,level,message" \
  -o logs_light.csv
```

---

## 📖 Quelle documentation lire ?

### Je débute → [QUICK_START.md](QUICK_START.md)
- Commandes essentielles
- Exemples immédiats
- 5 minutes de lecture

### Je veux tout comprendre → [README.md](README.md)
- Documentation complète
- Installation détaillée
- Tous les exemples
- Dépannage

### J'ai un cas spécifique → [COLUMN_SELECTION_GUIDE.md](COLUMN_SELECTION_GUIDE.md)
- 12 cas d'usage détaillés
- Bonnes pratiques
- Comparaison des méthodes

### Je veux automatiser → [CONFIGURATION_EXAMPLES.md](CONFIGURATION_EXAMPLES.md)
- Cron jobs
- Scripts avancés
- Variables d'environnement
- Sécurité

### Je ne sais pas où aller → [INDEX.md](INDEX.md)
- Navigation complète
- Par profil utilisateur
- Par fonctionnalité

---

## 🎯 Par profil

| Profil | Documentation | Exemple |
|--------|--------------|---------|
| 👨‍💼 Business Analyst | [QUICK_START.md](QUICK_START.md) | Rapports simples |
| 👨‍💻 Développeur | [README.md](README.md) | Migration, intégration |
| 🔒 DPO | [COLUMN_SELECTION_GUIDE.md](COLUMN_SELECTION_GUIDE.md) | Conformité RGPD |
| 👨‍🔧 DevOps | [CONFIGURATION_EXAMPLES.md](CONFIGURATION_EXAMPLES.md) | Automatisation |
| 🎓 Data Scientist | [COLUMN_SELECTION_GUIDE.md](COLUMN_SELECTION_GUIDE.md) | Extraction datasets |

---

## ⚡ Commandes les plus utilisées

```bash
# Lister les colonnes
./pg_dump_to_csv.sh -d mydb -t users -l

# Export simple
./pg_dump_to_csv.sh -d mydb -t users -o users.csv

# Export avec colonnes
./pg_dump_to_csv.sh -d mydb -t users -c "id,name,email" -o users.csv

# Mode interactif
./pg_dump_to_csv.sh -d mydb -t users -i -o users.csv

# Export multiple
./batch_export.sh -d mydb --all

# Aide
./pg_dump_to_csv.sh --help
```

---

## 🛠️ Installation et test

```bash
# 1. Télécharger et extraire le package
# (déjà fait si vous lisez ceci !)

# 2. Rendre exécutables
chmod +x *.sh

# 3. Tester la connexion
./pg_dump_to_csv.sh -d mydb -t mytable -l

# 4. Premier export
./pg_dump_to_csv.sh -d mydb -t mytable -i -o output.csv
```

---

## ❓ FAQ Rapide

**Q: Comment lister les colonnes d'une table ?**  
R: `./pg_dump_to_csv.sh -d mydb -t mytable -l`

**Q: Comment exporter uniquement certaines colonnes ?**  
R: `./pg_dump_to_csv.sh -d mydb -t mytable -c "col1,col2" -o output.csv`

**Q: Comment utiliser le mode interactif ?**  
R: `./pg_dump_to_csv.sh -d mydb -t mytable -i -o output.csv`

**Q: Quelle documentation lire en premier ?**  
R: [QUICK_START.md](QUICK_START.md) pour débuter, puis [INDEX.md](INDEX.md) pour naviguer

**Q: Comment tester sans ma vraie base ?**  
R: `./test_pg_dump_to_csv.sh` crée une base de test

---

## 📞 Besoin d'aide ?

1. **Problème de base ?** → [QUICK_START.md](QUICK_START.md)
2. **Erreur technique ?** → [README.md](README.md) section Dépannage
3. **Cas spécifique ?** → [COLUMN_SELECTION_GUIDE.md](COLUMN_SELECTION_GUIDE.md)
4. **Navigation ?** → [INDEX.md](INDEX.md)

---

## 🎉 Prêt à commencer !

### Option 1 : Mode guidé (recommandé)
```bash
./test_pg_dump_to_csv.sh    # Créer base de test
./demo_column_selection.sh   # Voir les démos
./practical_examples.sh      # Voir 8 exemples
```

### Option 2 : Mode direct
```bash
# Remplacez mydb et users par vos valeurs
./pg_dump_to_csv.sh -d mydb -t users -i -o users.csv
```

### Option 3 : Mode lecture
```bash
# Lire d'abord
cat QUICK_START.md
cat INDEX.md
```

---

## 📊 Statistiques du package

- ✅ **5 scripts** prêts à l'emploi
- ✅ **6 documents** de documentation (60+ pages)
- ✅ **30+ exemples** pratiques
- ✅ **12 cas d'usage** détaillés
- ✅ **100% compatible** avec version précédente
- ✅ **0 dépendance** supplémentaire

---

## 🚀 Commencez maintenant !

**Le moyen le plus rapide de démarrer :**

```bash
./pg_dump_to_csv.sh -d YOUR_DATABASE -t YOUR_TABLE -i -o output.csv
```

Remplacez `YOUR_DATABASE` et `YOUR_TABLE` par vos valeurs et suivez les instructions !

---

**Bon export ! 🎯**

*Pour toute question, commencez par [INDEX.md](INDEX.md) qui vous guidera vers la bonne documentation.*

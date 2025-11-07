# 📝 Changelog

Toutes les modifications notables de ce projet sont documentées dans ce fichier.

## [2.0.0] - 2024-11-06

### ✨ Nouvelles fonctionnalités majeures

#### Sélection de colonnes
- **Ajout** : Option `-c, --columns` pour spécifier les colonnes à exporter
- **Ajout** : Mode interactif `-i, --interactive` pour sélectionner les colonnes de façon guidée
- **Ajout** : Option `-l, --list-columns` pour lister les colonnes disponibles d'une table
- **Ajout** : Support de la variable d'environnement `COLUMNS`
- **Ajout** : Validation automatique des colonnes sélectionnées

#### Scripts additionnels
- **Ajout** : `demo_column_selection.sh` - Démonstration des fonctionnalités de sélection
- **Ajout** : `practical_examples.sh` - 8 exemples pratiques d'utilisation

#### Documentation
- **Ajout** : `QUICK_START.md` - Guide de démarrage rapide
- **Ajout** : `COLUMN_SELECTION_GUIDE.md` - Guide complet de sélection de colonnes
- **Ajout** : `INDEX.md` - Index de navigation de la documentation
- **Ajout** : `CHANGELOG.md` - Ce fichier
- **Mise à jour** : `README.md` avec les nouvelles fonctionnalités

### 🔧 Améliorations

- **Amélioration** : Fonction `get_column_names()` étendue pour supporter la sélection
- **Amélioration** : Fonction `export_with_psql()` optimisée pour les colonnes spécifiques
- **Amélioration** : Messages d'information plus détaillés sur les colonnes exportées
- **Amélioration** : Gestion d'erreurs plus robuste pour les colonnes invalides

### 📖 Documentation

- Guide complet de 60+ pages incluant :
  - Quick Start (démarrage en 30 secondes)
  - Guide de sélection de colonnes avec 12 cas d'usage
  - 12 exemples de configuration avancée
  - Index de navigation structuré par profil utilisateur

### 🎯 Cas d'usage ajoutés

1. Anonymisation de données (RGPD)
2. Réduction de taille de fichiers
3. Export pour migration
4. Rapports pour managers
5. Export sans données sensibles
6. Conformité réglementaire
7. Analyse de données ciblée
8. Catalogues produits

---

## [1.0.0] - Version initiale

### ✨ Fonctionnalités

- Export PostgreSQL vers CSV avec headers
- Deux méthodes d'export : `pg_dump` et `psql`
- Support des variables d'environnement
- Gestion des connexions sécurisées
- Messages colorés et informatifs
- Validation de connexion

### 📜 Scripts

- `pg_dump_to_csv.sh` - Script principal
- `batch_export.sh` - Export multiple de tables
- `test_pg_dump_to_csv.sh` - Script de test

### 📖 Documentation

- `README.md` - Documentation de base
- `CONFIGURATION_EXAMPLES.md` - Exemples de configuration

---

## 🔮 Roadmap / Fonctionnalités futures

### Version 2.1.0 (Prévu)
- [ ] Support des filtres WHERE dans la sélection
- [ ] Export avec tri personnalisé (ORDER BY)
- [ ] Limite de lignes (LIMIT)
- [ ] Support des jointures simples
- [ ] Format de sortie alternatif (TSV, JSON)

### Version 2.2.0 (Prévu)
- [ ] Interface graphique web simple
- [ ] API REST pour exports automatisés
- [ ] Compression automatique des exports
- [ ] Chiffrement des fichiers CSV
- [ ] Support de templates d'export

### Version 3.0.0 (Vision)
- [ ] Support multi-SGBD (MySQL, MariaDB, SQLite)
- [ ] Export incrémental (delta)
- [ ] Streaming pour très grandes tables
- [ ] Format Parquet pour big data
- [ ] Intégration avec cloud storage (S3, GCS, Azure)

---

## 📊 Statistiques

### Version 2.0.0
- **Scripts** : 5 scripts principaux + 2 scripts de démo
- **Documentation** : 5 fichiers (60+ pages)
- **Fonctionnalités** : 15+ fonctionnalités
- **Exemples** : 30+ exemples pratiques
- **Lignes de code** : ~1500 lignes de bash
- **Lignes de doc** : ~2000 lignes de markdown

---

## 🙏 Contributeurs

Merci à tous ceux qui ont contribué à ce projet !

---

## 📝 Notes de migration

### De v1.0 à v2.0

**Compatibilité arrière** : Complète ✅

Tous les scripts v1.0 fonctionnent sans modification. Les nouvelles fonctionnalités sont optionnelles.

**Nouvelles dépendances** : Aucune

**Changements de comportement** :
- Aucun changement dans le comportement par défaut
- Nouvelles options `-c`, `-i`, `-l` sont optionnelles
- Export de toutes les colonnes par défaut (inchangé)

**Migration recommandée** :
```bash
# Aucune action requise pour les scripts existants
# Pour utiliser les nouvelles fonctionnalités :

# Avant (v1.0) - fonctionne toujours
./pg_dump_to_csv.sh -d mydb -t users -o users.csv

# Maintenant (v2.0) - avec sélection de colonnes
./pg_dump_to_csv.sh -d mydb -t users -c "id,name,email" -o users.csv
```

---

## 🐛 Corrections de bugs

### Version 2.0.0
- **Fix** : Gestion améliorée des colonnes avec espaces dans les noms
- **Fix** : Validation plus robuste des noms de colonnes
- **Fix** : Messages d'erreur plus explicites

---

## 🔒 Sécurité

### Version 2.0.0
- Validation des entrées utilisateur pour les noms de colonnes
- Protection contre l'injection SQL dans les sélections de colonnes
- Documentation renforcée sur les bonnes pratiques de sécurité

---

## 📞 Support

Pour signaler un bug ou demander une fonctionnalité :
1. Vérifier la documentation existante
2. Consulter les exemples
3. Tester avec le script de démonstration

---

**Dernière mise à jour** : 6 novembre 2024

# 🔍 Elasticsearch Manager

Script shell interactif pour manipuler une base Elasticsearch depuis Linux avec gestion des fichiers de configuration `.env`.

## 📋 Table des matières

- [Fonctionnalités principales](#fonctionnalités-principales)
- [Prérequis](#prérequis)
- [Installation](#installation)
- [Configuration](#configuration)
- [Utilisation](#utilisation)
- [Exemples](#exemples)
- [Opérations disponibles](#opérations-disponibles)
- [Expressions régulières](#expressions-régulières)
- [Sécurité](#sécurité)

## ✨ Fonctionnalités principales

### 1. Gestion des fichiers .env

- ✅ Liste automatiquement tous les fichiers `.env*` disponibles
- ✅ Permet de choisir parmi les fichiers existants
- ✅ Propose de créer un nouveau fichier si aucun n'existe
- ✅ Sauvegarde les configurations (hôte, port, authentification, HTTPS)

### 2. Opérations disponibles

- 📊 **Lister les indices** Elasticsearch
- 🔍 **Rechercher** des documents (simple ou avec regex)
- 🗑️ **Supprimer** des documents (avec confirmation)
- ✏️ **Mettre à jour** des documents en masse
- 🔄 **Changer de configuration** à la volée
- ⚙️ **Afficher la configuration** actuelle

### 3. Expressions régulières

Le script supporte les regex pour :

- Filtrer les recherches
- Sélectionner les documents à supprimer
- Cibler les documents à mettre à jour

## 🔧 Prérequis

Le script nécessite les outils suivants :

- `bash` (version 4.0+)
- `curl` (pour les requêtes HTTP)
- `jq` (pour le parsing JSON)

## 📦 Installation

### 1. Télécharger le script

```bash
# Télécharger ou copier le script
wget https://github.com/lamjar/scripts/blob/main/db/elasticsearch_manager.sh
# ou
curl -O https://github.com/lamjar/scripts/blob/main/db/elasticsearch_manager.sh
```

### 2. Rendre le script exécutable

```bash
chmod +x elasticsearch_manager.sh
```

### 3. Installer les dépendances

**Debian/Ubuntu :**

```bash
sudo apt-get update
sudo apt-get install curl jq
```

**RedHat/CentOS/Fedora :**

```bash
sudo yum install curl jq
# ou
sudo dnf install curl jq
```

**Arch Linux :**

```bash
sudo pacman -S curl jq
```

**macOS :**

```bash
brew install curl jq
```

## ⚙️ Configuration

### Exemple de fichier .env

Créez un fichier `.env` dans le même répertoire que le script :

```env
# Configuration Elasticsearch
ES_HOST=localhost
ES_PORT=9200
ES_PROTOCOL=http
ES_USER=elastic
ES_PASSWORD=votre_mot_de_passe
```

### Configuration sans authentification

```env
ES_HOST=localhost
ES_PORT=9200
ES_PROTOCOL=http
```

### Configuration avec HTTPS

```env
ES_HOST=mon-serveur-es.com
ES_PORT=9200
ES_PROTOCOL=https
ES_USER=elastic
ES_PASSWORD=mot_de_passe_securise
```

### Configurations multiples

Vous pouvez créer plusieurs fichiers de configuration :

```bash
.env              # Configuration locale
.env.dev          # Configuration développement
.env.prod         # Configuration production
.env.staging      # Configuration staging
```

## 🚀 Utilisation

### Lancer le script

```bash
./elasticsearch_manager.sh
```

Le script vous guidera à travers les étapes suivantes :

1. **Sélection du fichier de configuration**
   - Liste tous les fichiers `.env*` disponibles
   - Permet d'en créer un nouveau si nécessaire

2. **Menu principal**
   - Choisissez l'opération à effectuer
   - Suivez les instructions interactives

## 📖 Exemples

### Exemple 1 : Recherche simple

```
Choisissez une option: 2
Nom de l'index: users
Utiliser une expression régulière? (o/n): n
Recherche simple (ex: status:active): status:active
```

### Exemple 2 : Recherche avec regex

```
Choisissez une option: 2
Nom de l'index: logs
Utiliser une expression régulière? (o/n): o
Champ à rechercher: email
Expression régulière: .*@gmail\.com
```

### Exemple 3 : Mise à jour en masse

```
Choisissez une option: 4
Nom de l'index: products
Utiliser une expression régulière pour filtrer? (o/n): o
Champ à filtrer: category
Expression régulière: electronics.*
Champ à mettre à jour: status
Nouvelle valeur: available
```

### Exemple 4 : Suppression avec confirmation

```
Choisissez une option: 3
Nom de l'index: old_data
Utiliser une expression régulière pour la suppression? (o/n): o
Champ à rechercher: date
Expression régulière: 2020-.*
Êtes-vous sûr de vouloir supprimer? (oui/non): oui
```

## 🛠️ Opérations disponibles

### 1️⃣ Lister les indices

Affiche tous les indices Elasticsearch avec leurs statistiques :

- Nom de l'index
- Santé (health)
- Statut
- Nombre de documents
- Taille du stockage

### 2️⃣ Rechercher des documents

**Recherche simple :**
- Recherche par paire clé:valeur
- Match query Elasticsearch
- Support de `match_all` pour tout afficher

**Recherche avec regex :**
- Utilise l'API `regexp` d'Elasticsearch
- Supporte les patterns complexes
- Affiche le nombre de résultats

### 3️⃣ Supprimer des documents

- Suppression par requête
- Support des expressions régulières
- Confirmation obligatoire avant suppression
- Affiche le nombre de documents supprimés

### 4️⃣ Mettre à jour des documents

- Mise à jour en masse via `_update_by_query`
- Support des filtres avec regex
- Détection automatique du type de valeur (string, number, boolean)
- Aperçu de la requête avant exécution
- Confirmation obligatoire

### 5️⃣ Changer de configuration

- Permet de basculer entre différents fichiers `.env`
- Utile pour gérer plusieurs environnements
- Rechargement à chaud sans redémarrage

### 6️⃣ Afficher la configuration

Affiche les paramètres actuels :
- Fichier `.env` utilisé
- URL de connexion
- Nom d'utilisateur (si configuré)

## 🔤 Expressions régulières

### Syntaxe supportée

Le script utilise les expressions régulières Lucene/Elasticsearch :

| Pattern | Description | Exemple |
|---------|-------------|---------|
| `.` | N'importe quel caractère | `a.c` → abc, adc |
| `*` | Zéro ou plus | `ab*` → a, ab, abb |
| `+` | Un ou plus | `ab+` → ab, abb |
| `?` | Zéro ou un | `ab?` → a, ab |
| `\|` | OU logique | `a\|b` → a ou b |
| `()` | Groupement | `(ab)+` → ab, abab |
| `[]` | Classe de caractères | `[abc]` → a, b ou c |
| `[^]` | Négation | `[^abc]` → tout sauf a, b, c |

### Exemples de regex

```bash
# Emails Gmail
.*@gmail\.com

# Dates de 2023
2023-[0-9]{2}-[0-9]{2}

# Codes postaux français
[0-9]{5}

# Numéros de téléphone
0[1-9][0-9]{8}

# URLs
https?://.*
```

## 🔒 Sécurité

### Bonnes pratiques

1. **Ne jamais commiter les fichiers .env**
   ```bash
   # Ajouter à .gitignore
   .env*
   !.env.example
   ```

2. **Permissions des fichiers**
   ```bash
   chmod 600 .env*
   ```

3. **Confirmations obligatoires**
   - Le script demande confirmation pour les suppressions
   - Aperçu des requêtes de mise à jour avant exécution

4. **Variables d'environnement**
   - Les mots de passe ne sont pas affichés dans les logs
   - Utilisation de `-s` pour la saisie des mots de passe

### Recommandations

- ✅ Utilisez HTTPS en production
- ✅ Utilisez des mots de passe forts
- ✅ Limitez les privilèges des utilisateurs Elasticsearch
- ✅ Testez sur un environnement de développement d'abord
- ✅ Faites des sauvegardes avant les suppressions massives

## 🎨 Interface

Le script utilise des couleurs pour une meilleure lisibilité :

- 🔵 **Bleu** : Informations
- ✅ **Vert** : Succès
- ⚠️ **Jaune** : Avertissements
- ❌ **Rouge** : Erreurs

## 📝 Licence

Ce script est fourni tel quel, sans garantie. Utilisez-le à vos propres risques.

## 🤝 Contribution

Les contributions sont les bienvenues ! N'hésitez pas à :

- Signaler des bugs
- Proposer des améliorations
- Soumettre des pull requests

## 📞 Support

Pour toute question ou problème :

1. Vérifiez que toutes les dépendances sont installées
2. Vérifiez votre fichier `.env`
3. Vérifiez la connectivité avec Elasticsearch
4. Consultez les logs d'erreur Elasticsearch

---

**Fait avec ❤️ pour faciliter la gestion d'Elasticsearch**
# PostgreSQL Anonymization Dump Tool

Script shell complet pour l'anonymisation de données PostgreSQL lors du dump/restore entre deux bases de données.

## 📋 Fonctionnalités

- ✅ Détection automatique des colonnes sensibles
- ✅ Anonymisation lors du dump
- ✅ Multiples stratégies d'anonymisation
- ✅ Nettoyage automatique du schéma target
- ✅ Restore dans le schéma target
- ✅ Support de deux bases de données différentes
- ✅ Mode dry-run pour simulation
- ✅ Rapports détaillés
- ✅ Gestion complète des erreurs

## 🚀 Installation

### 1. Installer les dépendances

```bash
chmod +x install.sh
./install.sh
```

Le script d'installation va installer automatiquement:
- `postgresql-client` (psql, pg_dump)
- `jq` (manipulation JSON)
- `sed` et `awk` (traitement de texte)

### 2. Configuration

Copier le fichier de configuration exemple:

```bash
cp ~/.pg_anonymize/config.example.json ~/.pg_anonymize/config.json
```

Éditer la configuration avec vos paramètres:

```bash
nano ~/.pg_anonymize/config.json
```

## 📝 Configuration

### Structure du fichier JSON

```json
{
  "source": {
    "host": "localhost",
    "port": 5432,
    "database": "production_db",
    "schema": "public",
    "user": "postgres",
    "password": "your_password"
  },
  "target": {
    "host": "localhost",
    "port": 5432,
    "database": "staging_db",
    "schema": "public",
    "user": "postgres",
    "password": "your_password"
  },
  "anonymization_rules": {
    "users": {
      "email": "fake_email",
      "phone": "fake_phone",
      "first_name": "fake_first_name",
      "last_name": "fake_last_name",
      "address": "fake_address",
      "password": "hash"
    },
    "customers": {
      "credit_card": "mask",
      "ssn": "mask",
      "salary": "noise",
      "notes": "null"
    },
    "orders": {
      "ip_address": "hash",
      "user_agent": "mask"
    }
  },
  "exclusions": {
    "tables": ["audit_logs", "system_config"],
    "columns": ["id", "created_at", "updated_at"]
  }
}
```

### Stratégies d'anonymisation disponibles

| Stratégie | Description | Exemple |
|-----------|-------------|---------|
| `fake_email` | Génère un email factice | user123456@example.com |
| `fake_phone` | Génère un numéro de téléphone | +33612345678 |
| `fake_first_name` | Génère un prénom factice | Jean, Marie, Pierre |
| `fake_last_name` | Génère un nom factice | Martin, Dubois, Bernard |
| `fake_address` | Génère une adresse factice | 42 Rue de la Paix, 75001 Paris |
| `mask` | Masque les données | XXX-XX-1234 |
| `null` | Remplace par NULL | NULL |
| `noise` | Ajoute du bruit (+/- 10%) | 45000 → 46789 |
| `hash` | Hash MD5 | abc123 → 5f4dcc3b5aa765d61d8327deb882cf99 |
| `shuffle` | Mélange les valeurs | Redistribue les valeurs entre lignes |
| `keep` | Conserve la valeur | Données non anonymisées |

## 🎯 Utilisation

### Commande de base

```bash
chmod +x pg_anonymize_dump.sh
./pg_anonymize_dump.sh -c config.json
```

### Options disponibles

```bash
./pg_anonymize_dump.sh [OPTIONS]

Options obligatoires:
  -c, --config FILE      Fichier de configuration JSON

Options:
  -d, --dry-run         Simulation sans exécution réelle
  -v, --verbose         Mode verbeux
  --no-auto-detect      Désactiver la détection automatique
  -h, --help            Afficher l'aide
```

### Exemples d'utilisation

#### 1. Simulation (dry-run)

Tester la configuration sans modifier les bases:

```bash
./pg_anonymize_dump.sh -c config.json --dry-run
```

#### 2. Mode verbeux

Afficher tous les détails de l'exécution:

```bash
./pg_anonymize_dump.sh -c config.json --verbose
```

#### 3. Sans détection automatique

Utiliser uniquement les règles définies manuellement:

```bash
./pg_anonymize_dump.sh -c config.json --no-auto-detect
```

#### 4. Configuration complète

```bash
./pg_anonymize_dump.sh -c config.json --dry-run --verbose
```

## 📊 Processus d'anonymisation

Le script effectue les étapes suivantes:

```
1. Chargement de la configuration
   ↓
2. Test des connexions (source et target)
   ↓
3. Détection automatique des colonnes sensibles
   ↓
4. Dump du schéma source (structure)
   ↓
5. Dump des données source
   ↓
6. Anonymisation des données
   ↓
7. Nettoyage du schéma target (DROP CASCADE)
   ↓
8. Restauration du schéma dans target
   ↓
9. Restauration des données anonymisées
   ↓
10. Génération du rapport
```

## 🔍 Détection automatique

Le script détecte automatiquement les colonnes sensibles basées sur des patterns de noms:

**Colonnes détectées automatiquement:**
- Email: `email`, `mail`, `e_mail`
- Téléphone: `phone`, `telephone`, `mobile`
- Nom/Prénom: `first_name`, `last_name`, `prenom`, `nom`, `surname`
- Adresse: `address`, `adresse`, `street`, `rue`
- Données sensibles: `ssn`, `social_security`, `credit_card`, `password`, `token`, `api_key`
- Données financières: `salary`, `salaire`, `revenue`, `iban`, `bic`
- Données personnelles: `birth_date`, `date_naissance`

## 📈 Rapport d'anonymisation

Après chaque exécution, un rapport est généré:

```
anonymization_report_YYYYMMDD_HHMMSS.txt
```

Le rapport contient:
- Configuration source et target
- Liste des règles d'anonymisation appliquées
- Colonnes détectées automatiquement
- Statistiques d'exécution
- Chemin vers les logs complets

## 🛡️ Sécurité

### Bonnes pratiques

1. **Mots de passe**: Ne jamais commiter le fichier de configuration avec les mots de passe
2. **Permissions**: Limiter les permissions sur les fichiers de configuration
   ```bash
   chmod 600 ~/.pg_anonymize/config.json
   ```
3. **Backups**: Toujours faire un backup avant d'exécuter en production
4. **Test**: Utiliser le mode `--dry-run` pour tester
5. **Logs**: Vérifier les logs pour détecter les erreurs

### Variables d'environnement

Alternative aux mots de passe dans le fichier JSON:

```bash
export PGPASSWORD_SOURCE="source_password"
export PGPASSWORD_TARGET="target_password"
```

Puis dans le JSON:
```json
{
  "source": {
    "password": ""
  },
  "target": {
    "password": ""
  }
}
```

## 🔧 Dépannage

### Problème de connexion

```
ERROR: Impossible de se connecter à SOURCE
```

**Solutions:**
- Vérifier que PostgreSQL est accessible
- Vérifier les credentials (host, port, user, password)
- Vérifier que l'utilisateur a les permissions nécessaires
- Vérifier le pg_hba.conf pour autoriser la connexion

### Erreur de permissions

```
ERROR: permission denied for schema
```

**Solutions:**
- L'utilisateur doit avoir les permissions suivantes:
  ```sql
  GRANT USAGE ON SCHEMA public TO user;
  GRANT SELECT ON ALL TABLES IN SCHEMA public TO user;
  GRANT CREATE ON SCHEMA public TO user;
  ```

### Dump échoue

```
ERROR: Échec du dump
```

**Solutions:**
- Vérifier l'espace disque disponible
- Vérifier que pg_dump est installé
- Augmenter les timeouts PostgreSQL si nécessaire

### Restauration échoue

```
ERROR: Échec de la restauration du schéma
```

**Solutions:**
- Vérifier que le schéma target existe
- Vérifier les permissions de création d'objets
- Vérifier les contraintes de clés étrangères

## 📚 Cas d'usage

### Cas 1: Production vers Staging

Copier les données de production vers staging avec anonymisation:

```json
{
  "source": {
    "host": "prod-db.example.com",
    "database": "production",
    "schema": "public"
  },
  "target": {
    "host": "staging-db.example.com",
    "database": "staging",
    "schema": "public"
  }
}
```

### Cas 2: Migration entre serveurs

Migrer un schéma complet entre deux serveurs:

```json
{
  "source": {
    "host": "old-server.com",
    "database": "app_db",
    "schema": "production"
  },
  "target": {
    "host": "new-server.com",
    "database": "app_db",
    "schema": "production"
  }
}
```

### Cas 3: Environnement de développement

Créer un environnement de dev avec données réalistes mais anonymisées:

```json
{
  "source": {
    "host": "localhost",
    "database": "prod_backup"
  },
  "target": {
    "host": "localhost",
    "database": "dev_env"
  },
  "anonymization_rules": {
    "users": {
      "email": "fake_email",
      "password": "hash",
      "first_name": "fake_first_name",
      "last_name": "fake_last_name"
    }
  }
}
```

## 🔄 Automatisation

### Cron job quotidien

Ajouter dans crontab pour une exécution quotidienne à 2h du matin:

```bash
crontab -e
```

```cron
0 2 * * * /path/to/pg_anonymize_dump.sh -c /path/to/config.json >> /var/log/anonymize.log 2>&1
```

### Script de rotation

```bash
#!/bin/bash
# Garder seulement les 7 derniers rapports
find . -name "anonymization_report_*.txt" -mtime +7 -delete
```

## 📄 Structure des fichiers

```
.
├── install.sh                      # Script d'installation
├── pg_anonymize_dump.sh           # Script principal
└── ~/.pg_anonymize/
    ├── config.json                # Configuration utilisateur
    └── config.example.json        # Exemple de configuration
```

## 🤝 Support

En cas de problème:

1. Vérifier les logs: Les logs détaillés sont dans `/tmp/anonymize.log`
2. Utiliser le mode `--dry-run` pour diagnostiquer
3. Utiliser le mode `--verbose` pour plus d'informations
4. Vérifier la configuration JSON avec `jq`

```bash
# Valider le JSON
jq empty config.json
```

## 📜 Licence

Ce script est fourni "tel quel" sans garantie. Utilisez-le à vos propres risques.

## ⚠️ Avertissements

- **TOUJOURS** tester avec `--dry-run` avant l'exécution réelle
- **TOUJOURS** faire un backup complet avant d'exécuter en production
- Vérifier que l'anonymisation est conforme au RGPD
- Vérifier que les données anonymisées ne peuvent pas être désanonymisées
- Ne pas utiliser en production sans tests approfondis

## 🎓 Exemples avancés

### Configuration multi-schémas

Pour traiter plusieurs schémas, créer plusieurs fichiers de configuration:

```bash
./pg_anonymize_dump.sh -c config_schema1.json
./pg_anonymize_dump.sh -c config_schema2.json
```

### Stratégies personnalisées

Pour des stratégies plus avancées, modifier les fonctions PL/pgSQL dans le script principal.

### Intégration CI/CD

```yaml
# .gitlab-ci.yml
anonymize_staging:
  stage: deploy
  script:
    - ./pg_anonymize_dump.sh -c config.staging.json
  only:
    - master
```

## 📞 Contact

Pour toute question ou suggestion d'amélioration, créer une issue ou soumettre une pull request.

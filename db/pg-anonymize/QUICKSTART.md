# Guide de Démarrage Rapide - PostgreSQL Anonymization Tool

## 🚀 Installation en 5 minutes

### Étape 1: Télécharger les fichiers

```bash
# Créer un répertoire de travail
mkdir pg_anonymize && cd pg_anonymize

# Les fichiers nécessaires:
# - install.sh
# - pg_anonymize_dump.sh
# - config.example.json
```

### Étape 2: Installation des dépendances

```bash
# Rendre le script d'installation exécutable
chmod +x install.sh

# Exécuter l'installation
./install.sh
```

**Ce que fait le script:**
- Installe PostgreSQL client tools
- Installe jq (parser JSON)
- Crée le répertoire ~/.pg_anonymize
- Crée un fichier de configuration exemple

### Étape 3: Configuration

```bash
# Copier la configuration exemple
cp config.example.json ~/.pg_anonymize/config.json

# Éditer la configuration
nano ~/.pg_anonymize/config.json
```

**Configuration minimale à modifier:**

```json
{
  "source": {
    "host": "votre_serveur_source",
    "database": "votre_db_source",
    "user": "votre_user",
    "password": "votre_password"
  },
  "target": {
    "host": "votre_serveur_target",
    "database": "votre_db_target",
    "user": "votre_user",
    "password": "votre_password"
  },
  "anonymization_rules": {
    "users": {
      "email": "fake_email",
      "phone": "fake_phone"
    }
  }
}
```

### Étape 4: Premier test (simulation)

```bash
# Rendre le script principal exécutable
chmod +x pg_anonymize_dump.sh

# Test en mode dry-run (aucune modification)
./pg_anonymize_dump.sh -c ~/.pg_anonymize/config.json --dry-run
```

**Sortie attendue:**
```
==========================================
  PostgreSQL Anonymization Dump Tool
==========================================

✓ Configuration chargée
ℹ Test de connexion SOURCE...
✓ Connexion SOURCE OK
ℹ Test de connexion TARGET...
✓ Connexion TARGET OK
ℹ Détection automatique des colonnes sensibles...
✓ Colonnes sensibles détectées:
  - users.email (varchar)
  - users.phone (varchar)
⚠ Mode DRY-RUN: dump simulé
⚠ Mode DRY-RUN: anonymisation simulée
⚠ Mode DRY-RUN: nettoyage simulé
⚠ Mode DRY-RUN: restauration simulée
✓ Processus d'anonymisation terminé avec succès!
⚠ Mode DRY-RUN: aucune modification n'a été effectuée
```

### Étape 5: Exécution réelle

```bash
# Exécution en production
./pg_anonymize_dump.sh -c ~/.pg_anonymize/config.json
```

**⚠️ ATTENTION:** Cette commande va:
1. Dumper les données de la source
2. Les anonymiser
3. **SUPPRIMER** toutes les tables du schéma target
4. Restaurer les données anonymisées

## 📋 Checklist avant la première exécution

- [ ] Backup de la base target effectué
- [ ] Test en mode `--dry-run` réussi
- [ ] Connexions source et target vérifiées
- [ ] Règles d'anonymisation définies
- [ ] Permissions PostgreSQL correctes
- [ ] Espace disque suffisant

## 🎯 Exemples de configuration par cas d'usage

### Cas 1: Dev local depuis Production

```json
{
  "source": {
    "host": "prod.example.com",
    "port": 5432,
    "database": "app_production",
    "schema": "public",
    "user": "readonly_user",
    "password": "xxx"
  },
  "target": {
    "host": "localhost",
    "port": 5432,
    "database": "app_dev",
    "schema": "public",
    "user": "postgres",
    "password": "dev"
  },
  "anonymization_rules": {
    "users": {
      "email": "fake_email",
      "password": "hash",
      "phone": "fake_phone"
    }
  }
}
```

### Cas 2: Staging depuis Production

```json
{
  "source": {
    "host": "prod-db.internal",
    "database": "production"
  },
  "target": {
    "host": "staging-db.internal",
    "database": "staging"
  },
  "anonymization_rules": {
    "customers": {
      "credit_card": "mask",
      "ssn": "mask"
    },
    "orders": {
      "ip_address": "hash"
    }
  }
}
```

### Cas 3: Migration entre serveurs

```json
{
  "source": {
    "host": "old-server.com",
    "database": "app_db",
    "schema": "v1"
  },
  "target": {
    "host": "new-server.com",
    "database": "app_db",
    "schema": "v1"
  }
}
```

## 🔧 Commandes utiles

### Vérifier la configuration JSON

```bash
jq empty config.json && echo "JSON valide" || echo "JSON invalide"
```

### Voir les règles définies

```bash
jq '.anonymization_rules' config.json
```

### Tester la connexion manuellement

```bash
# Source
psql -h localhost -p 5432 -U postgres -d source_db -c "SELECT 1"

# Target
psql -h localhost -p 5432 -U postgres -d target_db -c "SELECT 1"
```

### Vérifier l'espace disque

```bash
df -h /tmp
```

### Voir les logs en temps réel

```bash
tail -f /tmp/anonymize_*/anonymize.log
```

## ❗ Résolution des problèmes courants

### Problème: "jq: command not found"

```bash
# Ubuntu/Debian
sudo apt-get install jq

# CentOS/RHEL
sudo yum install jq

# MacOS
brew install jq
```

### Problème: "psql: command not found"

```bash
# Ubuntu/Debian
sudo apt-get install postgresql-client

# CentOS/RHEL
sudo yum install postgresql

# MacOS
brew install postgresql
```

### Problème: "permission denied for schema"

```sql
-- Se connecter en tant que superuser et exécuter:
GRANT ALL PRIVILEGES ON SCHEMA public TO votre_user;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO votre_user;
```

### Problème: "too many connections"

Modifier postgresql.conf:
```
max_connections = 200
```

Puis redémarrer PostgreSQL:
```bash
sudo systemctl restart postgresql
```

## 📊 Vérification post-anonymisation

### Compter les lignes

```sql
-- Source
SELECT 
    schemaname,
    tablename,
    n_live_tup as row_count
FROM pg_stat_user_tables
WHERE schemaname = 'public'
ORDER BY n_live_tup DESC;

-- Target (devrait être identique)
```

### Vérifier l'anonymisation

```sql
-- Vérifier qu'il n'y a pas d'emails réels
SELECT email FROM users WHERE email LIKE '%@example.com' LIMIT 10;

-- Vérifier les données masquées
SELECT credit_card FROM customers WHERE credit_card LIKE 'X%' LIMIT 10;
```

### Vérifier l'intégrité référentielle

```sql
-- Vérifier les clés étrangères
SELECT 
    tc.table_name, 
    kcu.column_name, 
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name 
FROM information_schema.table_constraints AS tc 
JOIN information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name
    AND tc.table_schema = kcu.table_schema
JOIN information_schema.constraint_column_usage AS ccu
    ON ccu.constraint_name = tc.constraint_name
    AND ccu.table_schema = tc.table_schema
WHERE tc.constraint_type = 'FOREIGN KEY';
```

## 🔄 Automatisation

### Cron quotidien (2h du matin)

```bash
# Éditer crontab
crontab -e

# Ajouter:
0 2 * * * /path/to/pg_anonymize_dump.sh -c /path/to/config.json >> /var/log/anonymize.log 2>&1
```

### Script wrapper avec notification

```bash
#!/bin/bash
# anonymize_wrapper.sh

LOG_FILE="/var/log/anonymize_$(date +%Y%m%d).log"
ERROR_LOG="/var/log/anonymize_error.log"

if /path/to/pg_anonymize_dump.sh -c /path/to/config.json >> "$LOG_FILE" 2>&1; then
    echo "Anonymisation réussie $(date)" >> "$LOG_FILE"
    # Envoyer notification de succès
    echo "Anonymisation réussie" | mail -s "Anonymisation OK" admin@example.com
else
    echo "Anonymisation échouée $(date)" >> "$ERROR_LOG"
    # Envoyer alerte
    echo "ERREUR lors de l'anonymisation. Voir $ERROR_LOG" | mail -s "ALERTE: Anonymisation" admin@example.com
fi
```

## 📈 Monitoring

### Temps d'exécution

```bash
time ./pg_anonymize_dump.sh -c config.json
```

### Taille des dumps

```bash
# Avant compression
ls -lh /tmp/dump_*

# Surveiller l'espace disque
watch -n 5 'df -h /tmp'
```

## 🎓 Prochaines étapes

1. **Tester avec des données réelles** en mode dry-run
2. **Définir toutes les règles** d'anonymisation nécessaires
3. **Documenter le processus** pour votre équipe
4. **Automatiser** l'exécution avec cron
5. **Monitorer** les exécutions régulières
6. **Auditer** régulièrement les données anonymisées

## 📚 Ressources

- README complet: `README.md`
- Configuration exemple: `config.example.json`
- Logs: `/tmp/anonymize_*/anonymize.log`
- Rapports: `anonymization_report_*.txt`

## ⚠️ Rappels importants

1. **Toujours** tester en dry-run d'abord
2. **Toujours** faire un backup avant
3. **Jamais** commiter les mots de passe dans Git
4. **Vérifier** l'anonymisation est conforme RGPD
5. **Documenter** les règles d'anonymisation

---

**Besoin d'aide?** Vérifiez les logs et utilisez `--verbose` pour plus de détails.

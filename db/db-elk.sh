#!/bin/bash

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Fonction pour afficher les messages
print_info() { echo -e "${BLUE}ℹ ${NC}$1"; }
print_success() { echo -e "${GREEN}✓${NC} $1"; }
print_warning() { echo -e "${YELLOW}⚠${NC} $1"; }
print_error() { echo -e "${RED}✗${NC} $1"; }

# Fonction pour charger le fichier .env
load_env() {
    if [ -f "$1" ]; then
        export $(cat "$1" | grep -v '^#' | xargs)
        print_success "Fichier $1 chargé avec succès"
        return 0
    else
        print_error "Fichier $1 introuvable"
        return 1
    fi
}

# Fonction pour créer un fichier .env
create_env_file() {
    local filename="$1"
    
    echo -e "\n${BLUE}Création du fichier $filename${NC}"
    echo "=================================="
    
    read -p "Hôte Elasticsearch (ex: localhost): " es_host
    read -p "Port (défaut: 9200): " es_port
    es_port=${es_port:-9200}
    
    read -p "Utiliser HTTPS? (o/n, défaut: n): " use_https
    if [[ "$use_https" == "o" || "$use_https" == "O" ]]; then
        es_protocol="https"
    else
        es_protocol="http"
    fi
    
    read -p "Nom d'utilisateur (laisser vide si pas d'auth): " es_user
    if [ -n "$es_user" ]; then
        read -sp "Mot de passe: " es_password
        echo
        auth_line="ES_USER=$es_user\nES_PASSWORD=$es_password"
    else
        auth_line=""
    fi
    
    # Création du fichier
    cat > "$filename" << EOF
# Configuration Elasticsearch
ES_HOST=$es_host
ES_PORT=$es_port
ES_PROTOCOL=$es_protocol
$auth_line
EOF
    
    print_success "Fichier $filename créé avec succès"
}

# Fonction pour sélectionner un fichier .env
select_env_file() {
    echo -e "\n${BLUE}Sélection du fichier de configuration${NC}"
    echo "========================================"
    
    # Rechercher tous les fichiers .env*
    mapfile -t env_files < <(ls -1 .env* 2>/dev/null)
    
    if [ ${#env_files[@]} -eq 0 ]; then
        print_warning "Aucun fichier .env trouvé"
        read -p "Nom du fichier à créer (défaut: .env): " new_file
        new_file=${new_file:-.env}
        create_env_file "$new_file"
        ENV_FILE="$new_file"
    else
        echo "Fichiers disponibles:"
        for i in "${!env_files[@]}"; do
            echo "  $((i+1))) ${env_files[$i]}"
        done
        echo "  $((${#env_files[@]}+1))) Créer un nouveau fichier"
        
        read -p "Choisissez une option: " choice
        
        if [ "$choice" -eq "$((${#env_files[@]}+1))" ]; then
            read -p "Nom du nouveau fichier (ex: .env.prod): " new_file
            create_env_file "$new_file"
            ENV_FILE="$new_file"
        elif [ "$choice" -ge 1 ] && [ "$choice" -le "${#env_files[@]}" ]; then
            ENV_FILE="${env_files[$((choice-1))]}"
        else
            print_error "Choix invalide"
            exit 1
        fi
    fi
    
    load_env "$ENV_FILE"
}

# Fonction pour construire l'URL de base
build_base_url() {
    if [ -n "$ES_USER" ] && [ -n "$ES_PASSWORD" ]; then
        ES_AUTH="-u $ES_USER:$ES_PASSWORD"
    else
        ES_AUTH=""
    fi
    ES_BASE_URL="${ES_PROTOCOL}://${ES_HOST}:${ES_PORT}"
}

# Fonction pour lister les indices
list_indices() {
    print_info "Liste des indices Elasticsearch:"
    curl -s $ES_AUTH "$ES_BASE_URL/_cat/indices?v"
}

# Fonction pour rechercher des documents
search_documents() {
    read -p "Nom de l'index: " index_name
    read -p "Utiliser une expression régulière? (o/n): " use_regex
    
    if [[ "$use_regex" == "o" || "$use_regex" == "O" ]]; then
        read -p "Champ à rechercher: " field_name
        read -p "Expression régulière: " regex_pattern
        
        query=$(cat <<EOF
{
  "query": {
    "regexp": {
      "$field_name": "$regex_pattern"
    }
  }
}
EOF
)
    else
        read -p "Recherche simple (ex: status:active): " simple_query
        if [ -z "$simple_query" ]; then
            query='{"query": {"match_all": {}}}'
        else
            IFS=':' read -r field value <<< "$simple_query"
            query=$(cat <<EOF
{
  "query": {
    "match": {
      "$field": "$value"
    }
  }
}
EOF
)
        fi
    fi
    
    print_info "Recherche en cours..."
    result=$(curl -s $ES_AUTH -H "Content-Type: application/json" \
        -X GET "$ES_BASE_URL/$index_name/_search" -d "$query")
    
    echo "$result" | jq '.'
    
    # Afficher le nombre de résultats
    hits=$(echo "$result" | jq '.hits.total.value // .hits.total')
    print_success "Nombre de résultats: $hits"
}

# Fonction pour supprimer des documents
delete_documents() {
    read -p "Nom de l'index: " index_name
    print_warning "Attention: Cette opération est irréversible!"
    read -p "Utiliser une expression régulière pour la suppression? (o/n): " use_regex
    
    if [[ "$use_regex" == "o" || "$use_regex" == "O" ]]; then
        read -p "Champ à rechercher: " field_name
        read -p "Expression régulière: " regex_pattern
        
        query=$(cat <<EOF
{
  "query": {
    "regexp": {
      "$field_name": "$regex_pattern"
    }
  }
}
EOF
)
    else
        read -p "Champ: " field_name
        read -p "Valeur: " field_value
        
        query=$(cat <<EOF
{
  "query": {
    "match": {
      "$field_name": "$field_value"
    }
  }
}
EOF
)
    fi
    
    read -p "Êtes-vous sûr de vouloir supprimer? (oui/non): " confirm
    if [ "$confirm" == "oui" ]; then
        result=$(curl -s $ES_AUTH -H "Content-Type: application/json" \
            -X POST "$ES_BASE_URL/$index_name/_delete_by_query" -d "$query")
        echo "$result" | jq '.'
        deleted=$(echo "$result" | jq '.deleted')
        print_success "Documents supprimés: $deleted"
    else
        print_info "Suppression annulée"
    fi
}

# Fonction pour mettre à jour des documents
update_documents() {
    read -p "Nom de l'index: " index_name
    read -p "Utiliser une expression régulière pour filtrer? (o/n): " use_regex
    
    if [[ "$use_regex" == "o" || "$use_regex" == "O" ]]; then
        read -p "Champ à filtrer: " filter_field
        read -p "Expression régulière: " regex_pattern
        
        query_part=$(cat <<EOF
"regexp": {
  "$filter_field": "$regex_pattern"
}
EOF
)
    else
        read -p "Champ à filtrer: " filter_field
        read -p "Valeur à filtrer: " filter_value
        
        query_part=$(cat <<EOF
"match": {
  "$filter_field": "$filter_value"
}
EOF
)
    fi
    
    read -p "Champ à mettre à jour: " update_field
    read -p "Nouvelle valeur: " new_value
    
    # Déterminer le type de valeur
    if [[ "$new_value" =~ ^[0-9]+$ ]]; then
        value_formatted="$new_value"
    elif [[ "$new_value" =~ ^(true|false)$ ]]; then
        value_formatted="$new_value"
    else
        value_formatted="\"$new_value\""
    fi
    
    query=$(cat <<EOF
{
  "query": {
    $query_part
  },
  "script": {
    "source": "ctx._source.$update_field = params.new_value",
    "params": {
      "new_value": $value_formatted
    }
  }
}
EOF
)
    
    print_info "Aperçu de la requête:"
    echo "$query" | jq '.'
    
    read -p "Confirmer la mise à jour? (oui/non): " confirm
    if [ "$confirm" == "oui" ]; then
        result=$(curl -s $ES_AUTH -H "Content-Type: application/json" \
            -X POST "$ES_BASE_URL/$index_name/_update_by_query" -d "$query")
        echo "$result" | jq '.'
        updated=$(echo "$result" | jq '.updated')
        print_success "Documents mis à jour: $updated"
    else
        print_info "Mise à jour annulée"
    fi
}

# Menu principal
show_menu() {
    echo -e "\n${GREEN}=== Menu Elasticsearch ===${NC}"
    echo "1) Lister les indices"
    echo "2) Rechercher des documents"
    echo "3) Supprimer des documents"
    echo "4) Mettre à jour des documents"
    echo "5) Changer de fichier .env"
    echo "6) Afficher la configuration actuelle"
    echo "0) Quitter"
    echo "=========================="
}

# Fonction pour afficher la configuration
show_config() {
    echo -e "\n${BLUE}Configuration actuelle:${NC}"
    echo "Fichier: $ENV_FILE"
    echo "URL: $ES_BASE_URL"
    echo "Utilisateur: ${ES_USER:-'(aucun)'}"
}

# Programme principal
main() {
    echo -e "${GREEN}"
    echo "╔═══════════════════════════════════════╗"
    echo "║  Elasticsearch Interactif ToolBox     ║"
    echo "║  _________   By LAMJAR __________     ║"
    echo "╚═══════════════════════════════════════╝"
    echo -e "${NC}"
    
    # Vérifier si curl et jq sont installés
    command -v curl >/dev/null 2>&1 || { print_error "curl n'est pas installé. Veuillez l'installer."; exit 1; }
    command -v jq >/dev/null 2>&1 || { print_error "jq n'est pas installé. Veuillez l'installer."; exit 1; }
    
    # Sélectionner le fichier .env
    select_env_file
    build_base_url
    
    # Boucle du menu
    while true; do
        show_menu
        read -p "Choisissez une option: " choice
        
        case $choice in
            1) list_indices ;;
            2) search_documents ;;
            3) delete_documents ;;
            4) update_documents ;;
            5) select_env_file; build_base_url ;;
            6) show_config ;;
            0) print_info "Au revoir!"; exit 0 ;;
            *) print_error "Option invalide" ;;
        esac
        
        read -p "Appuyez sur Entrée pour continuer..."
    done
}

# Lancer le programme
main
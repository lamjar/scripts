#!/bin/bash

# ===========================================
# OwnKube - Minikube Docker Compose Optimisé
# Version: 3.5 Ultimate Edition avec Auto-Fix
# Author: LAMJAR
# ===========================================

set -euo pipefail  # Mode strict avec gestion des pipes
trap 'echo -e "${RED}❌ Erreur détectée. Ligne $LINENO${NC}"' ERR

# Couleurs optimisées
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly MAGENTA='\033[0;35m'
readonly WHITE='\033[1;37m'
readonly NC='\033[0m'

# Configuration des ressources minimales
readonly MIN_MEMORY_MB=2048
readonly MIN_CPU=1
readonly DEFAULT_MEMORY_MB=2048
readonly DEFAULT_CPU=1
readonly CACHE_DIR="${HOME}/.ownkube/cache"

# Ports par défaut (seront vérifiés et ajustés si nécessaire)
DEFAULT_API_PORT=18443
DEFAULT_HTTP_PORT=18080
DEFAULT_HTTPS_PORT=18443

# Bannière OwnKube
show_banner() {
    clear
    echo -e "${CYAN}"
    cat << 'BANNER'
    ╔══════════════════════════════════════════════════════════════╗
    ║                                                              ║
    ║     ██████╗ ██╗    ██╗███╗   ██╗██╗  ██╗██╗   ██╗██████╗   ║
    ║    ██╔═══██╗██║    ██║████╗  ██║██║ ██╔╝██║   ██║██╔══██╗  ║
    ║    ██║   ██║██║ █╗ ██║██╔██╗ ██║█████╔╝ ██║   ██║██████╔╝  ║
    ║    ██║   ██║██║███╗██║██║╚██╗██║██╔═██╗ ██║   ██║██╔══██╗  ║
    ║    ╚██████╔╝╚███╔███╔╝██║ ╚████║██║  ██╗╚██████╔╝██████╔╝  ║
    ║     ╚═════╝  ╚══╝╚══╝ ╚═╝  ╚═══╝╚═╝  ╚═╝ ╚═════╝ ╚═════╝   ║
    ║                                                              ║
    ║                       by LAMJAR                              ║
    ║                                                              ║
    ║         🚀 Kubernetes Léger & Optimisé pour Tous 🚀         ║
    ║                                                              ║
    ╚══════════════════════════════════════════════════════════════╝
BANNER
    echo -e "${NC}"
    echo -e "${GREEN}    Version 3.5 - Ultimate Edition avec Auto-Fix${NC}"
    echo -e "${YELLOW}    Optimisé pour: 2GB RAM / 1 CPU${NC}\n"
    sleep 2
}

# Cache pour les opérations répétées
init_cache() {
    mkdir -p "$CACHE_DIR"
}

# Fonctions utilitaires optimisées
print_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
print_success() { echo -e "${GREEN}✅ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
print_error() { echo -e "${RED}❌ $1${NC}"; }

print_header() {
    echo -e "\n${CYAN}═══════════════════════════════════════${NC}"
    echo -e "${CYAN}  $1${NC}"
    echo -e "${CYAN}═══════════════════════════════════════${NC}\n"
}

print_step() {
    echo -e "\n${MAGENTA}▶ $1${NC}\n"
}

# Fonction améliorée pour trouver un port libre
find_free_port() {
    local start_port=$1
    local max_attempts=100
    
    for ((i=0; i<$max_attempts; i++)); do
        local test_port=$((start_port + i))
        
        # Vérifier avec plusieurs méthodes
        if ! lsof -Pi :$test_port -sTCP:LISTEN -t >/dev/null 2>&1 && \
           ! ss -tuln 2>/dev/null | grep -q ":$test_port " && \
           ! netstat -tuln 2>/dev/null | grep -q ":$test_port " && \
           ! docker ps 2>/dev/null | grep -q ":$test_port"; then
            echo $test_port
            return 0
        fi
    done
    
    # Si aucun port trouvé, utiliser un port aléatoire élevé
    echo $((30000 + RANDOM % 2000))
}

# Fonction pour vérifier et corriger les conflits de ports
check_and_fix_ports() {
    print_header "Détection Intelligente des Ports"
    
    local ports_changed=false
    
    # Vérifier le port API
    print_info "Vérification du port API ($DEFAULT_API_PORT)..."
    if lsof -Pi :$DEFAULT_API_PORT -sTCP:LISTEN -t >/dev/null 2>&1 || \
       ss -tuln 2>/dev/null | grep -q ":$DEFAULT_API_PORT "; then
        print_warning "Port API $DEFAULT_API_PORT occupé"
        DEFAULT_API_PORT=$(find_free_port 18443)
        print_success "Nouveau port API: $DEFAULT_API_PORT"
        ports_changed=true
    else
        print_success "Port API $DEFAULT_API_PORT disponible"
    fi
    
    # Vérifier le port HTTP
    print_info "Vérification du port HTTP ($DEFAULT_HTTP_PORT)..."
    if lsof -Pi :$DEFAULT_HTTP_PORT -sTCP:LISTEN -t >/dev/null 2>&1 || \
       ss -tuln 2>/dev/null | grep -q ":$DEFAULT_HTTP_PORT "; then
        print_warning "Port HTTP $DEFAULT_HTTP_PORT occupé"
        DEFAULT_HTTP_PORT=$(find_free_port 18080)
        print_success "Nouveau port HTTP: $DEFAULT_HTTP_PORT"
        ports_changed=true
    else
        print_success "Port HTTP $DEFAULT_HTTP_PORT disponible"
    fi
    
    # Vérifier le port HTTPS  
    print_info "Vérification du port HTTPS ($DEFAULT_HTTPS_PORT)..."
    if lsof -Pi :$DEFAULT_HTTPS_PORT -sTCP:LISTEN -t >/dev/null 2>&1 || \
       ss -tuln 2>/dev/null | grep -q ":$DEFAULT_HTTPS_PORT "; then
        print_warning "Port HTTPS $DEFAULT_HTTPS_PORT occupé"
        DEFAULT_HTTPS_PORT=$(find_free_port 18443)
        print_success "Nouveau port HTTPS: $DEFAULT_HTTPS_PORT"
        ports_changed=true
    else
        print_success "Port HTTPS $DEFAULT_HTTPS_PORT disponible"
    fi
    
    if [ "$ports_changed" = true ]; then
        echo ""
        print_warning "Les ports ont été ajustés pour éviter les conflits"
        echo -e "${YELLOW}Nouveaux ports:${NC}"
        echo -e "  API:   ${GREEN}$DEFAULT_API_PORT${NC}"
        echo -e "  HTTP:  ${GREEN}$DEFAULT_HTTP_PORT${NC}"
        echo -e "  HTTPS: ${GREEN}$DEFAULT_HTTPS_PORT${NC}"
        echo ""
        sleep 2
    fi
}

# Nettoyage des conteneurs existants
cleanup_existing_containers() {
    print_info "Vérification des conteneurs existants..."
    
    local existing_containers=$(docker ps -aq -f name=ownkube 2>/dev/null)
    existing_containers+=" $(docker ps -aq -f name=minikube 2>/dev/null)"
    
    if [ ! -z "$(echo $existing_containers | tr -d ' ')" ]; then
        print_warning "Conteneurs OwnKube/Minikube trouvés"
        echo "Arrêt et suppression des conteneurs existants..."
        
        for container in $existing_containers; do
            docker stop $container 2>/dev/null || true
            docker rm $container 2>/dev/null || true
        done
        
        print_success "Conteneurs nettoyés"
    fi
}

# Détection optimisée du système
detect_system() {
    local os_type=$(uname -s)
    local arch=$(uname -m)
    local total_mem_mb=0
    local cpu_count=0
    
    case "$os_type" in
        Linux*)
            total_mem_mb=$(free -m | awk '/^Mem:/{print $2}')
            cpu_count=$(nproc)
            ;;
        Darwin*)
            total_mem_mb=$(($(sysctl -n hw.memsize) / 1048576))
            cpu_count=$(sysctl -n hw.ncpu)
            ;;
        *)
            print_error "Système non supporté: $os_type"
            exit 1
            ;;
    esac
    
    echo "$total_mem_mb|$cpu_count"
}

# Vérification des prérequis optimisée
check_prerequisites() {
    print_header "Vérification Rapide des Prérequis"
    
    local errors=0
    
    # Vérifications parallèles avec timeout
    {
        command -v docker &>/dev/null || { print_error "Docker non trouvé"; ((errors++)); }
    } &
    
    {
        command -v docker-compose &>/dev/null || docker compose version &>/dev/null || { print_error "Docker Compose non trouvé"; ((errors++)); }
    } &
    
    wait
    
    if [ $errors -gt 0 ]; then
        print_error "Installez les dépendances manquantes"
        echo "Docker: https://docs.docker.com/engine/install/"
        echo "Docker Compose: https://docs.docker.com/compose/install/"
        exit 1
    fi
    
    # Vérification Docker daemon avec timeout
    if ! timeout 5 docker info &>/dev/null; then
        print_error "Docker daemon non accessible"
        echo "Démarrez Docker: sudo systemctl start docker"
        exit 1
    fi
    
    print_success "Docker: $(docker --version 2>/dev/null | cut -d' ' -f3 | cut -d',' -f1)"
    
    # Détection des ressources
    local system_info=$(detect_system)
    local total_mem_mb=${system_info%|*}
    local cpu_count=${system_info#*|}
    
    # Avertissements pour ressources faibles
    if [ "$total_mem_mb" -lt 2048 ]; then
        print_warning "RAM: ${total_mem_mb}MB (2GB minimum requis)"
        print_info "Mode ultra-léger activé"
    else
        print_success "RAM: ${total_mem_mb}MB"
    fi
    
    if [ "$cpu_count" -lt 2 ]; then
        print_warning "CPU: ${cpu_count} cores (performance limitée)"
    else
        print_success "CPU: ${cpu_count} cores"
    fi
    
    # Vérification espace disque optimisée
    local available_gb=$(df -BG . 2>/dev/null | awk 'NR==2 {gsub(/[^0-9]/,"",$4); print $4}')
    if [ "$available_gb" -lt 10 ]; then
        print_warning "Espace disque: ${available_gb}GB (10GB minimum)"
    else
        print_success "Espace disque: ${available_gb}GB"
    fi
}

# Recherche de subnet optimisée avec cache
find_available_subnet_cached() {
    local cache_file="$CACHE_DIR/subnet_cache"
    
    # Vérifier le cache (5 minutes)
    if [ -f "$cache_file" ] && [ $(($(date +%s) - $(stat -c %Y "$cache_file" 2>/dev/null || echo 0))) -lt 300 ]; then
        cat "$cache_file"
        return 0
    fi
    
    # Recherche optimisée de subnet
    local used_subnets=$(docker network ls --format "{{.Name}}" 2>/dev/null | \
        xargs -P4 -I{} docker network inspect {} 2>/dev/null | \
        grep -oP '"Subnet":\s*"\K[^"]+' 2>/dev/null | sort -u)
    
    local subnet=""
    for i in {20..30}; do
        local test="172.${i}.0.0/16"
        if ! echo "$used_subnets" | grep -qF "$test"; then
            subnet="$test|172.${i}.0.1"
            echo "$subnet" > "$cache_file"
            echo "$subnet"
            return 0
        fi
    done
    
    # Fallback
    subnet="10.99.0.0/16|10.99.0.1"
    echo "$subnet" > "$cache_file"
    echo "$subnet"
}

# Configuration rapide avec valeurs par défaut
configure_quick() {
    print_header "Configuration Rapide OwnKube"
    
    # Vérifier et ajuster les ports avant configuration
    check_and_fix_ports
    
    PROJECT_NAME="${1:-ownkube}"
    MEMORY="${2:-$DEFAULT_MEMORY_MB}"
    CPUS="${3:-$DEFAULT_CPU}"
    API_PORT="$DEFAULT_API_PORT"
    HTTP_PORT="$DEFAULT_HTTP_PORT"
    HTTPS_PORT="$DEFAULT_HTTPS_PORT"
    INSTALL_DASHBOARD="${7:-n}"
    INSTALL_INGRESS="${8:-n}"
    
    # Configuration réseau automatique
    print_info "Configuration réseau automatique..."
    local subnet_info=$(find_available_subnet_cached)
    NETWORK_SUBNET="${subnet_info%|*}"
    NETWORK_GATEWAY="${subnet_info#*|}"
    NETWORK_NAME="${PROJECT_NAME}-net"
    NETWORK_EXTERNAL="false"
    
    print_success "Configuration optimale définie"
}

# Configuration interactive optimisée
configure_interactive() {
    print_header "Configuration Interactive OwnKube"
    
    # Vérifier et ajuster les ports avant configuration
    check_and_fix_ports
    
    echo -e "${CYAN}Appuyez sur Entrée pour les valeurs par défaut${NC}\n"
    
    read -rp "Nom du projet [ownkube]: " PROJECT_NAME
    PROJECT_NAME=${PROJECT_NAME:-ownkube}
    
    read -rp "RAM en MB [2048]: " MEMORY
    MEMORY=${MEMORY:-2048}
    
    read -rp "Nombre de CPUs [1]: " CPUS
    CPUS=${CPUS:-1}
    
    # Proposer les ports détectés automatiquement
    read -rp "Port API [$DEFAULT_API_PORT]: " API_PORT
    API_PORT=${API_PORT:-$DEFAULT_API_PORT}
    
    read -rp "Port HTTP [$DEFAULT_HTTP_PORT]: " HTTP_PORT
    HTTP_PORT=${HTTP_PORT:-$DEFAULT_HTTP_PORT}
    
    read -rp "Port HTTPS [$DEFAULT_HTTPS_PORT]: " HTTPS_PORT
    HTTPS_PORT=${HTTPS_PORT:-$DEFAULT_HTTPS_PORT}
    
    # Réseau automatique pour simplicité
    print_info "Configuration réseau automatique..."
    local subnet_info=$(find_available_subnet_cached)
    NETWORK_SUBNET="${subnet_info%|*}"
    NETWORK_GATEWAY="${subnet_info#*|}"
    NETWORK_NAME="${PROJECT_NAME}-net"
    NETWORK_EXTERNAL="false"
    
    read -rp "Dashboard Kubernetes? (o/n) [n]: " INSTALL_DASHBOARD
    INSTALL_DASHBOARD=${INSTALL_DASHBOARD:-n}
    
    read -rp "Ingress Controller? (o/n) [n]: " INSTALL_INGRESS
    INSTALL_INGRESS=${INSTALL_INGRESS:-n}
    
    print_success "Configuration enregistrée"
}

# Création de structure optimisée
create_directory_structure() {
    print_header "Création Structure OwnKube"
    
    mkdir -p "$PROJECT_NAME"/{projects,manifests/examples,scripts,kube-config,data/{minikube,docker}} 2>/dev/null || true
    cd "$PROJECT_NAME"
    
    print_success "Structure créée: $(pwd)"
}

# Docker Compose optimisé SANS l'attribut version
create_docker_compose() {
    print_header "Création Docker Compose Optimisé"
    
    # IMPORTANT: Pas d'attribut "version" pour éviter le warning
    cat > docker-compose.yml << 'EOF'
services:
  ownkube:
    image: ${MINIKUBE_IMAGE:-kicbase/stable:v0.0.42}
    container_name: ${CONTAINER_NAME:-ownkube}
    hostname: ownkube
    privileged: true
    restart: unless-stopped
    
    environment:
      - MINIKUBE_IN_STYLE=false
      - CHANGE_MINIKUBE_NONE_USER=true
      - KUBECONFIG=/etc/kubernetes/admin.conf
    
    ports:
      - "${K8S_API_PORT:-18443}:8443"
      - "${HTTP_PORT:-18080}:80"
      - "${HTTPS_PORT:-18443}:443"
      - "${NODEPORT_START:-30000}-${NODEPORT_END:-30010}:30000-30010"
    
    volumes:
      - minikube-data:/var
      - docker-data:/var/lib/docker
      - ./manifests:/manifests:ro
      - ./kube-config:/root/.kube
    
    networks:
      - ownkube-net
    
    deploy:
      resources:
        limits:
          cpus: '${CPU_LIMIT:-1}'
          memory: ${MEMORY_LIMIT:-2048M}
        reservations:
          cpus: '${CPU_RESERVATION:-0.5}'
          memory: ${MEMORY_RESERVATION:-1024M}
    
    command: >
      sh -c "
      dockerd-entrypoint.sh &
      sleep 5 &&
      minikube start 
        --driver=docker 
        --container-runtime=docker
        --cpus=${MINIKUBE_CPUS:-1}
        --memory=${MINIKUBE_MEMORY:-1800}
        --disk-size=${DISK_SIZE:-10g}
        --cache-images=false
        --preload=false
        --apiserver-ips=0.0.0.0
        --listen-address=0.0.0.0
        --extra-config=kubelet.max-pods=30
        --extra-config=kubelet.pods-per-core=5
        --extra-config=apiserver.service-node-port-range=30000-30010 &&
      tail -f /dev/null
      "
    
    healthcheck:
      test: ["CMD", "minikube", "status", "--format", "{{.Host}}"]
      interval: 60s
      timeout: 10s
      retries: 3
      start_period: 90s

networks:
  ownkube-net:
    driver: bridge
    driver_opts:
      com.docker.network.bridge.enable_icc: "true"
      com.docker.network.bridge.enable_ip_masquerade: "true"
    ipam:
      config:
        - subnet: ${NETWORK_SUBNET:-172.20.0.0/16}

volumes:
  minikube-data:
    driver: local
  docker-data:
    driver: local
EOF
    
    print_success "Docker Compose optimisé créé (sans attribut version)"
}

# Fichier .env optimisé
create_env_file() {
    print_header "Création Configuration Environnement"
    
    cat > .env << EOF
# OwnKube Configuration - by LAMJAR
CONTAINER_NAME=ownkube
MINIKUBE_IMAGE=kicbase/stable:v0.0.42

# Ressources Optimisées
MINIKUBE_CPUS=$CPUS
MINIKUBE_MEMORY=$((MEMORY * 9 / 10))
DISK_SIZE=10g
CPU_LIMIT=${CPUS}
CPU_RESERVATION=0.5
MEMORY_LIMIT=${MEMORY}M
MEMORY_RESERVATION=$((MEMORY / 2))M

# Ports (Auto-détectés pour éviter les conflits)
K8S_API_PORT=$API_PORT
HTTP_PORT=$HTTP_PORT
HTTPS_PORT=$HTTPS_PORT
NODEPORT_START=30000
NODEPORT_END=30010

# Réseau
NETWORK_SUBNET=$NETWORK_SUBNET
NETWORK_GATEWAY=$NETWORK_GATEWAY
EOF
    
    print_success "Configuration environnement créée"
}

# Scripts de gestion optimisés avec gestion des erreurs
create_utility_scripts() {
    print_header "Création Scripts de Gestion"
    
    # Script principal de gestion avec fix intégré
    cat > ownkube.sh << 'SCRIPT'
#!/bin/bash
# OwnKube Management Script with Auto-Fix

GREEN='\033[0;32m'
RED='\033[0;31m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
NC='\033[0m'

show_logo() {
    echo -e "${CYAN}"
    echo "  ___                 _  __      _          "
    echo " / _ \__      ___ __ | |/ /   _ | |__   ___ "
    echo "| | | \ \ /\ / / '_ \| ' / | | | '_ \ / _ \\"
    echo "| |_| |\ V  V /| | | | . \ |_| | |_) |  __/"
    echo " \___/  \_/\_/ |_| |_|_|\_\__,_|_.__/ \___|"
    echo "                              by LAMJAR"
    echo -e "${NC}\n"
}

# Fonction pour vérifier et corriger les problèmes
fix_issues() {
    # Supprimer l'attribut version si présent
    if [ -f "docker-compose.yml" ] && grep -q "^version:" docker-compose.yml; then
        echo -e "${YELLOW}Correction: Suppression de l'attribut version obsolète${NC}"
        sed -i '/^version:/d' docker-compose.yml
    fi
    
    # Vérifier les conflits de ports
    if [ -f ".env" ]; then
        source .env
        for port in $K8S_API_PORT $HTTP_PORT $HTTPS_PORT; do
            if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1; then
                echo -e "${YELLOW}⚠️  Port $port en conflit, arrêt des conteneurs existants...${NC}"
                docker stop ownkube 2>/dev/null || true
                docker rm ownkube 2>/dev/null || true
                break
            fi
        done
    fi
}

case "$1" in
    start)
        show_logo
        fix_issues  # Auto-fix avant démarrage
        echo -e "${GREEN}🚀 Démarrage OwnKube...${NC}"
        docker-compose up -d
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✅ OwnKube démarré avec succès${NC}"
            echo -e "${CYAN}Accès: https://localhost:$(grep K8S_API_PORT .env | cut -d= -f2)${NC}"
        else
            echo -e "${RED}❌ Erreur au démarrage. Vérifiez: docker-compose logs${NC}"
        fi
        ;;
    stop)
        echo -e "${RED}⏹️  Arrêt OwnKube...${NC}"
        docker-compose down
        ;;
    restart)
        $0 stop
        sleep 2
        $0 start
        ;;
    status)
        docker exec ownkube minikube status 2>/dev/null || echo "OwnKube arrêté"
        ;;
    logs)
        docker-compose logs -f --tail=100
        ;;
    shell)
        docker exec -it ownkube /bin/bash
        ;;
    kubectl|k)
        shift
        docker exec -it ownkube kubectl "$@"
        ;;
    deploy)
        [ -z "$2" ] && { echo "Usage: $0 deploy <file.yaml>"; exit 1; }
        docker exec ownkube kubectl apply -f "/manifests/$2"
        ;;
    fix)
        echo -e "${YELLOW}🔧 Correction des problèmes...${NC}"
        fix_issues
        # Redémarrer si nécessaire
        if docker ps | grep -q ownkube; then
            $0 restart
        fi
        echo -e "${GREEN}✅ Corrections appliquées${NC}"
        ;;
    clean)
        echo -e "${RED}🧹 Nettoyage complet...${NC}"
        docker-compose down -v
        rm -rf data/*
        ;;
    info)
        show_logo
        echo -e "${CYAN}État:${NC}"
        $0 status
        echo -e "\n${CYAN}Ports configurés:${NC}"
        grep -E "K8S_API_PORT|HTTP_PORT|HTTPS_PORT" .env 2>/dev/null || echo "Config non trouvée"
        echo -e "\n${CYAN}Ressources:${NC}"
        docker stats --no-stream ownkube 2>/dev/null || echo "Conteneur arrêté"
        echo -e "\n${CYAN}Pods:${NC}"
        docker exec ownkube kubectl get pods -A 2>/dev/null || echo "Kubernetes non disponible"
        ;;
    *)
        show_logo
        echo "Usage: $0 {start|stop|restart|status|logs|shell|kubectl|deploy|fix|clean|info}"
        echo ""
        echo "  start   - Démarrer OwnKube (avec auto-fix)"
        echo "  stop    - Arrêter OwnKube"
        echo "  restart - Redémarrer OwnKube"
        echo "  status  - État du cluster"
        echo "  logs    - Afficher les logs"
        echo "  shell   - Shell dans le conteneur"
        echo "  kubectl - Exécuter kubectl (alias: k)"
        echo "  deploy  - Déployer un manifest"
        echo "  fix     - Corriger les problèmes"
        echo "  clean   - Nettoyer tout"
        echo "  info    - Informations complètes"
        ;;
esac
SCRIPT
    
    chmod +x ownkube.sh
    
    # Script de monitoring léger
    cat > monitor.sh << 'MONITOR'
#!/bin/bash
# OwnKube Monitor

while true; do
    clear
    echo "=== OwnKube Monitor ==="
    echo "$(date)"
    echo ""
    echo "CPU & Memory:"
    docker stats --no-stream ownkube 2>/dev/null | tail -n +2
    echo ""
    echo "Cluster Status:"
    docker exec ownkube minikube status 2>/dev/null || echo "Offline"
    echo ""
    echo "Pods Running:"
    docker exec ownkube kubectl get pods -A 2>/dev/null | grep Running | wc -l
    echo ""
    echo "Press Ctrl+C to exit"
    sleep 5
done
MONITOR
    
    chmod +x monitor.sh
    
    # Script de diagnostic des ports
    cat > check-ports.sh << 'PORTCHECK'
#!/bin/bash
# Script de vérification des ports OwnKube

source .env 2>/dev/null

echo "=== Vérification des Ports OwnKube ==="
echo ""

check_port() {
    local port=$1
    local name=$2
    echo -n "$name (Port $port): "
    if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1; then
        echo "❌ OCCUPÉ"
        lsof -i :$port | grep LISTEN
        return 1
    else
        echo "✅ Disponible"
        return 0
    fi
}

check_port ${K8S_API_PORT:-18443} "API Kubernetes"
check_port ${HTTP_PORT:-18080} "HTTP"
check_port ${HTTPS_PORT:-18443} "HTTPS"

echo ""
echo "Si des ports sont occupés, utilisez: ./ownkube.sh fix"
PORTCHECK
    
    chmod +x check-ports.sh
    
    print_success "Scripts de gestion créés avec auto-fix intégré"
}

# Manifest exemple optimisé
create_example_manifest() {
    print_header "Création Exemples Kubernetes"
    
    cat > manifests/examples/hello-world.yaml << 'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: hello-ownkube
  labels:
    app: hello
spec:
  containers:
  - name: hello
    image: busybox:latest
    command: ['sh', '-c', 'echo "OwnKube by LAMJAR is running!" && sleep 3600']
    resources:
      requests:
        memory: "32Mi"
        cpu: "50m"
      limits:
        memory: "64Mi"
        cpu: "100m"
---
apiVersion: v1
kind: Service
metadata:
  name: hello-service
spec:
  type: NodePort
  ports:
    - port: 80
      targetPort: 80
      nodePort: 30001
  selector:
    app: hello
EOF
    
    print_success "Exemples créés"
}

# README optimisé
create_readme() {
    cat > README.md << 'README'
# 🚀 OwnKube by LAMJAR

## Installation Kubernetes Ultra-Légère avec Auto-Fix

### ⚡ Démarrage Rapide
```bash
./ownkube.sh start     # Démarrer OwnKube (auto-fix inclus)
./ownkube.sh info      # Voir l'état complet
./ownkube.sh k get pods -A  # Lister les pods
```

### 🔧 Résolution Automatique des Problèmes
OwnKube détecte et corrige automatiquement:
- Conflits de ports
- Attribut version obsolète dans docker-compose
- Conteneurs en conflit

### 🎯 Commandes Essentielles
| Commande | Description |
|----------|-------------|
| `./ownkube.sh start` | Démarrer le cluster (avec auto-fix) |
| `./ownkube.sh stop` | Arrêter le cluster |
| `./ownkube.sh restart` | Redémarrer le cluster |
| `./ownkube.sh status` | État du cluster |
| `./ownkube.sh shell` | Shell dans le conteneur |
| `./ownkube.sh k <cmd>` | Exécuter kubectl |
| `./ownkube.sh deploy <file>` | Déployer un manifest |
| `./ownkube.sh fix` | Corriger les problèmes manuellement |
| `./check-ports.sh` | Vérifier les ports |

### 💡 Optimisé Pour
- **RAM**: 2GB minimum
- **CPU**: 1 core minimum  
- **Disque**: 10GB minimum
- **Ports**: Détection automatique des ports libres

### 📊 Monitoring
```bash
./monitor.sh    # Surveillance en temps réel
```

### 🚀 Exemple de Déploiement
```bash
./ownkube.sh deploy examples/hello-world.yaml
./ownkube.sh k get pods
```

### 🌐 Accès Services
Les ports sont automatiquement configurés pour éviter les conflits.
Vérifiez vos ports avec: `./ownkube.sh info`

### 🛠️ Dépannage
Si vous rencontrez des problèmes:
```bash
./check-ports.sh    # Vérifier les ports
./ownkube.sh fix    # Appliquer les corrections
./ownkube.sh logs   # Voir les logs
```

---
*OwnKube - Kubernetes intelligent et auto-réparant*
README
    
    print_success "Documentation créée"
}

# Téléchargement optimisé des images
pull_docker_images() {
    print_header "Préparation des Images Docker"
    
    print_info "Téléchargement image Minikube optimisée..."
    docker pull kicbase/stable:v0.0.42 --quiet &
    
    local pull_pid=$!
    local spinner=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')
    
    while kill -0 $pull_pid 2>/dev/null; do
        for s in "${spinner[@]}"; do
            printf "\r${CYAN}%s${NC} Téléchargement en cours..." "$s"
            sleep 0.1
        done
    done
    
    wait $pull_pid
    printf "\r"
    print_success "Images Docker prêtes"
}

# Démarrage optimisé avec gestion d'erreurs
start_ownkube() {
    print_header "Lancement OwnKube"
    
    # Nettoyer les conteneurs existants si nécessaire
    cleanup_existing_containers
    
    # Démarrer avec docker-compose
    docker-compose up -d 2>/dev/null
    
    if [ $? -ne 0 ]; then
        print_warning "Premier démarrage échoué, tentative de correction..."
        
        # Essayer de trouver de nouveaux ports
        check_and_fix_ports
        
        # Recréer le fichier .env avec les nouveaux ports
        create_env_file
        
        # Réessayer
        docker-compose up -d
        
        if [ $? -ne 0 ]; then
            print_error "Impossible de démarrer OwnKube"
            docker-compose logs --tail=20
            return 1
        fi
    fi
    
    print_info "Initialisation du cluster (60-90 secondes)..."
    
    local max_attempts=30
    local attempt=0
    
    while [ $attempt -lt $max_attempts ]; do
        if docker exec ownkube minikube status --format "{{.Host}}" 2>/dev/null | grep -q "Running"; then
            print_success "OwnKube opérationnel!"
            return 0
        fi
        printf "\r${CYAN}⏳${NC} Attente... %d/%d" $((attempt+1)) $max_attempts
        sleep 3
        ((attempt++))
    done
    
    print_warning "Démarrage plus long que prévu"
    docker-compose logs --tail=20
}

# Informations finales
display_final_info() {
    print_header "✨ OwnKube Installé avec Succès!"
    
    echo -e "${GREEN}╔════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║     OwnKube by LAMJAR - Prêt à l'emploi     ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════╝${NC}\n"
    
    echo -e "${CYAN}📍 Répertoire:${NC} $(pwd)"
    echo -e "${CYAN}🔗 API Kubernetes:${NC} https://localhost:$API_PORT"
    echo -e "${CYAN}🌐 HTTP/HTTPS:${NC} localhost:$HTTP_PORT / localhost:$HTTPS_PORT"
    
    echo -e "\n${YELLOW}Commandes rapides:${NC}"
    echo -e "  ${WHITE}./ownkube.sh start${NC}   - Démarrer"
    echo -e "  ${WHITE}./ownkube.sh info${NC}    - Informations"
    echo -e "  ${WHITE}./ownkube.sh k get pods -A${NC} - Voir les pods"
    echo -e "  ${WHITE}./monitor.sh${NC}         - Monitoring"
    echo -e "  ${WHITE}./check-ports.sh${NC}     - Vérifier les ports"
    
    echo -e "\n${GREEN}🎯 Test rapide:${NC}"
    echo -e "  ${WHITE}./ownkube.sh deploy examples/hello-world.yaml${NC}"
    
    echo -e "\n${MAGENTA}💡 Astuce:${NC} Ajoutez un alias dans ~/.bashrc:"
    echo -e "  ${WHITE}alias ok='$(pwd)/ownkube.sh'${NC}"
    
    if [ "$API_PORT" != "18443" ] || [ "$HTTP_PORT" != "18080" ]; then
        echo -e "\n${YELLOW}📝 Note:${NC} Les ports ont été ajustés automatiquement pour éviter les conflits"
    fi
    
    echo -e "\n${GREEN}🚀 OwnKube est prêt! Auto-Fix intégré pour une expérience sans souci.${NC}\n"
}

# Fonction principale
main() {
    show_banner
    init_cache
    
    # Vérifications
    check_prerequisites
    
    # Menu simplifié
    print_header "Mode d'Installation"
    echo "1) Installation Express (Recommandé)"
    echo "2) Installation Personnalisée"
    echo "3) Quitter"
    echo ""
    read -rp "Choix [1]: " choice
    choice=${choice:-1}
    
    case $choice in
        1) configure_quick ;;
        2) configure_interactive ;;
        3) exit 0 ;;
        *) print_error "Choix invalide"; exit 1 ;;
    esac
    
    # Installation
    create_directory_structure
    create_docker_compose
    create_env_file
    create_utility_scripts
    create_example_manifest
    create_readme
    
    # Préparation et démarrage
    pull_docker_images
    start_ownkube
    
    # Affichage final
    display_final_info
}

# Exécution avec gestion d'erreur globale
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@" || {
        print_error "Installation échouée. Vérifiez les logs ci-dessus."
        print_info "Essayez: docker-compose logs pour plus de détails"
        exit 1
    }
fi
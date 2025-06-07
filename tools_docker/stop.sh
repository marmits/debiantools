#!/bin/bash

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
NC='\033[0m'

# Fonction d'aide
usage() {
    echo -e "\n${BLUE}Usage: ${YELLOW}$0 [all|NOM_CONTAINER|--help]${NC}"
    echo -e "${GREEN}  all          ${NC}- Supprime containers, volumes et réseaux (sans images)"
    echo -e "${GREEN}  NOM_CONTAINER${NC}- Supprime un container avec ses dépendances"
    echo -e "${GREEN}  --help       ${NC}- Affiche cette aide"
    echo -e "\n${CYAN}Mode interactif si aucun argument.${NC}"
    exit 0
}

# Suppression sécurisée
delete_container() {
    local target=$1
    local networks=$(docker inspect "$target" --format '{{range .NetworkSettings.Networks}}{{.NetworkID}} {{end}}' 2>/dev/null)

    if docker inspect "$target" &>/dev/null; then
        echo -e "${YELLOW}Arrêt de ${CYAN}$target${NC}"
        docker stop "$target" >/dev/null 2>&1

        echo -e "${YELLOW}Suppression du container et volumes...${NC}"
        docker rm -vf "$target" >/dev/null 2>&1

        for net in $networks; do
            if docker network inspect "$net" >/dev/null 2>&1; then
                echo -e "${YELLOW}Suppression du réseau ${CYAN}$net${NC}"
                docker network rm "$net" >/dev/null 2>&1
            fi
        done

        echo -e "${GREEN}✅ $target et dépendances supprimés${NC}"
    else
        echo -e "${RED}❌ Container introuvable: ${CYAN}$target${NC}" >&2
        return 1
    fi
}

# Nettoyage des volumes orphelins
clean_unused_volumes() {
    echo -e "${YELLOW}Recherche de volumes inutilisés...${NC}"
    local unused_volumes=($(docker volume ls -qf dangling=true))
    
    if [ ${#unused_volumes[@]} -eq 0 ]; then
        echo -e "${GREEN}Aucun volume inutilisé trouvé.${NC}"
        return 1
    else
        echo -e "${CYAN}Volumes inutilisés trouvés :${NC}"
        printf '  - %s\n' "${unused_volumes[@]}"
        read -p "Voulez-vous les supprimer ? (y/N) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            docker volume rm "${unused_volumes[@]}" 2>/dev/null
            echo -e "${GREEN}✅ Volumes supprimés avec succès${NC}"
        else
            echo -e "${YELLOW}❌ Annulé${NC}"
        fi
        return 0
    fi
}

# Mode interactif
interactive_mode() {
    while true; do
        clear
        echo -e "${BLUE}Containers disponibles:${NC}"
        docker ps -a --format "table {{.ID}}\t{{.Names}}\t{{.Status}}\t{{.Networks}}"

        # Vérifier s'il y a des volumes orphelins
        local has_unused_volumes=$(docker volume ls -qf dangling=true | wc -l)
        
        echo -e "\n${BLUE}Options:${NC}"
        options=(
            "Supprimer un container spécifique"
            "Tout supprimer (containers/volumes/réseaux)"
        )
        
        # Ajouter l'option de nettoyage des volumes si nécessaire
        if [ $has_unused_volumes -gt 0 ]; then
            options+=("Nettoyer les volumes inutilisés")
        fi
        
        options+=(
            "Aide"
            "Quitter"
        )
        
        select opt in "${options[@]}"; do
            case $opt in
                "Supprimer un container spécifique")
                    read -p "Nom/ID du container: " container
                    delete_container "$container"
                    break
                    ;;
                "Tout supprimer (containers/volumes/réseaux)")
                    echo -e "\n${RED}⚠️ ATTENTION : Cette action va supprimer :"
                    echo -e "  - Tous les containers arrêtés/en cours"
                    echo -e "  - Tous les volumes non utilisés"
                    echo -e "  - Tous les réseaux non utilisés${NC}"
                    read -p "Confirmez-vous ? (y/N) " -n 1 -r
                    echo
                    if [[ $REPLY =~ ^[Yy]$ ]]; then
                        echo -e "${YELLOW}Nettoyage en cours...${NC}"
                        docker stop $(docker ps -q) 2>/dev/null
                        docker rm -vf $(docker ps -a -q) 2>/dev/null
                        docker network prune -f
                        docker volume prune -f
                        echo -e "${GREEN}✅ Nettoyage complet effectué (images conservées)${NC}"
                    else
                        echo -e "${GREEN}❌ Annulé${NC}"
                    fi
                    break
                    ;;
                "Nettoyer les volumes inutilisés")
                    clean_unused_volumes
                    break
                    ;;
                "Aide")
                    usage
                    ;;
                "Quitter")
                    exit 0
                    ;;
                *) 
                    echo -e "${RED}Option invalide${NC}"
                    break
                    ;;
            esac
        done
        read -p $'\n'"Appuyez sur Entrée pour continuer..."
    done
}

# Gestion des arguments
case "$1" in
    all)
        echo -e "${YELLOW}Nettoyage complet...${NC}"
        docker stop $(docker ps -q) 2>/dev/null
        docker rm -vf $(docker ps -a -q) 2>/dev/null
        docker network prune -f
        docker volume prune -f
        echo -e "${GREEN}✅ Tous les éléments supprimés (sauf images)${NC}"
        ;;
    --help|-h)
        usage
        ;;
    "")
        interactive_mode
        ;;
    *)
        delete_container "$1"
        ;;
esac
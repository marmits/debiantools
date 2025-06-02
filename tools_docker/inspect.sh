#!/bin/bash

# Fonction pour coloriser l'image
highlight_image() {
    echo -e "\033[1;38;5;51m$1\033[0m"  # Cyan vif
}

# Fonction pour afficher les détails d'un container
show_container_details() {
    clear
    local id=$1
    local name=$(docker inspect --format '{{.Name}}' $id | sed 's/^\///')
    local status=$(docker inspect --format '{{.State.Status}}' $id)
    local image=$(highlight_image "$(docker inspect --format '{{.Config.Image}}' $id)")
    
    echo -e "\n\033[1;36m🔍 Détails du container: $name ($id)\033[0m"
    echo "=========================================="
    echo -e "\033[1;34m🔄 Status:\033[0m $status"
    echo -e "\033[1;34m🐳 Image:\033[0m $image"
    
    # Inspection détaillée
    echo -e "\n\033[1;34m📝 Configuration:\033[0m"
    docker inspect $id | grep -E '(Image|Volumes|Network|"Path"|Status|tmp|HostPort|HostIp|IPAddress|Type|Source|Destination|com.docker.compose.project.working_dir)' | sed 's/^/    /'
    
    # Ports exposés
    echo -e "\n\033[1;34m🔌 Ports exposés:\033[0m"
    docker inspect --format='{{range $p, $conf := .NetworkSettings.Ports}}{{$p}} -> {{(index $conf 0).HostPort}} ({{(index $conf 0).HostIp}})
{{end}}' $id | sed 's/^/    /' | grep -v '^$' || echo "    Aucun port exposé"
    
    # Volumes
    echo -e "\n\033[1;34m💾 Volumes:\033[0m"
    docker inspect --format='{{range .Mounts}}{{.Source}} -> {{.Destination}} ({{.Type}})
{{end}}' $id | sed 's/^/    /' | grep -v '^$' || echo "    Aucun volume"
    
    # Derniers logs
    echo -e "\n\033[1;34m📜 Logs (20 dernières lignes):\033[0m"
    docker logs --tail=20 $id 2>&1 | sed 's/^/    /'
    
    read -p $'\n\033[1;33mAppuyez sur Entrée pour continuer...\033[0m'
}

# Menu principal
while true; do
    clear
    echo -e "\033[1;35m🐳 Gestionnaire Docker - Sélection de container\033[0m"
    echo "=========================================="
    echo
    
    # Liste des containers
    containers=($(docker ps -a --format "{{.ID}}"))
    if [ ${#containers[@]} -eq 0 ]; then
        echo "Aucun container Docker trouvé."
        exit 0
    fi
    
    # Affichage de la liste numérotée
    echo -e "\033[1;33mContainers disponibles:\033[0m"
    i=1
    for id in "${containers[@]}"; do
        name=$(docker inspect --format '{{.Name}}' $id | sed 's/^\///')
        status=$(docker inspect --format '{{.State.Status}}' $id)
        image=$(highlight_image "$(docker inspect --format '{{.Config.Image}}' $id)")
        printf " \033[1;32m%2d\033[0m | %-12s | %-10s | %-30s | %s\n" $i "${id:0:12}" "$status" "$name" "$image"
        ((i++))
    done
    
    echo -e "\n \033[1;32m 0\033[0m | Quitter"
    echo
    
    # Sélection
    read -p "Sélectionnez un numéro de container (1-$((i-1))) ou 0 pour quitter: " choice
    
    # Validation
    if [[ $choice -eq 0 ]]; then
        clear
        exit 0
    elif [[ $choice -ge 1 && $choice -le $((i-1)) ]]; then
        selected_id=${containers[$((choice-1))]}
        show_container_details $selected_id
    else
        read -p $'\033[1;31mSélection invalide. Appuyez sur Entrée pour continuer...\033[0m'
    fi
done
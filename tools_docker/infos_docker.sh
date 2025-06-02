#!/bin/bash

# Fonction pour coloriser le nom du container
highlight_name() {
    echo -e "\033[1;38;5;214m$1\033[0m"  # Orange vif
}

# Fonction pour afficher les informations Docker complètes
show_docker_info() {
    echo "🐳 Docker System Information"
    echo "=========================="
    echo

    # 1. Afficher l'état du système
    echo "📊 System Status:"
    docker system df
    echo
    echo "----------------------------------------"
    echo

    # 2. Afficher tous les containers avec détails complets
    echo "📦 Containers (Detailed View):"
    local containers=$(docker ps -a --format '{{.ID}}|{{.Names}}|{{.Status}}|{{.State}}')

    if [ -z "$containers" ]; then
        echo "No containers found"
    else
        echo "🔵 Running   🔴 Exited    ⚪ Other states"
        echo

        while IFS='|' read -r id name status state; do
            local display_name=$(highlight_name "${name:-<no-name>}")
            local state_icon=""
            local status_details=""
            
            if [[ "$state" == "running" ]]; then
                state_icon="🔵"
                status_details=""
            elif [[ "$state" == "exited" ]]; then
                state_icon="🔴"
                local exit_code=$(docker inspect -f '{{.State.ExitCode}}' "$id" 2>/dev/null)
                status_details=" (Exit Code: ${exit_code})"
            else
                state_icon="⚪"
                status_details=" (Status: ${state})"
            fi

            echo "${state_icon} Container: $display_name (${id:0:12}) - ${status}${status_details}"
            
            # Image info
            local image=$(docker inspect -f '{{.Config.Image}}' "$id" 2>/dev/null || echo "<unknown>")
            echo "   🏷️ Image: $image"
            
            # Network info
            echo "   🌐 Networks:"
            docker inspect -f '{{range $k, $v := .NetworkSettings.Networks}}      - {{$k}} (IP: {{$v.IPAddress}}){{"\n"}}{{end}}' "$id" 2>/dev/null || echo "      <no network>"
            
            # Volumes info
            echo "   💾 Mounts:"
            docker inspect --format $'{{range .Mounts}}\n      - {{if eq .Type "volume"}}Volume{{else if eq .Type "bind"}}Bind{{else}}{{.Type}}{{end}}: {{if .Name}}{{.Name}}{{else}}{{.Source}}{{end}} \u2192 {{.Destination}} ({{.Type}}){{end}}' "$id" 2>/dev/null || echo "      <no mounts>"
            
            # Ports info
            if [[ "$state" == "running" ]]; then
                echo "   🔌 Ports:"
                docker inspect -f '{{range $p, $conf := .NetworkSettings.Ports}}{{if $conf}}      - {{$p}} → {{(index $conf 0).HostPort}}{{end}}{{end}}' "$id" 2>/dev/null | grep -v '^      - $' || echo "      <no ports exposed>"
            else
                echo "   🔌 Ports: (container not running)"
            fi
            
            echo
            echo "----------------------------------------"
            echo
        done <<< "$containers"
    fi

    # 3. Afficher toutes les images (vue globale)
    echo "🖼️ All Images (Global View):"
    docker images --format "table {{.Repository}}:{{.Tag}}\t{{.ID}}\t{{.Size}}" | while read -r line; do
        echo "   - $line"
    done

    echo
    echo "----------------------------------------"
    echo

    # 4. Afficher les réseaux Docker
    echo "📡 Docker Networks:"
    docker network ls --format "table {{.ID}}\t{{.Name}}\t{{.Driver}}\t{{.Scope}}" | while read -r line; do
        echo "   - $line"
    done

    echo
    echo "----------------------------------------"
    echo

    # 5. Afficher les volumes non utilisés
    show_unused_volumes
}

# Fonction pour afficher les volumes non utilisés
show_unused_volumes() {
    local unused_volumes=$(docker volume ls -q --filter dangling=true)
    
    if [ -n "$unused_volumes" ]; then
        echo "📦 Unattached Volumes:"
        echo "$unused_volumes" | while read -r volume; do
            echo "   - $volume (not used by any container)"
        done
        echo
        echo "💡 Tip: Clean unused volumes with 'docker volume prune'"
    else
        echo "No unattached volumes found"
    fi
    echo "----------------------------------------"
}

# Exécuter la fonction principale
show_docker_info
#!/bin/sh
# pour entrypoint.sh
# donne le temps écoulé depuis que le container est actif

CONTAINER_START_FILE="/var/container_start_time"
OUTPUT_FILE="/tmp/container_uptime"

get_uptime() {
    [ ! -f "$CONTAINER_START_FILE" ] && echo $(date +%s) > "$CONTAINER_START_FILE"
    
    start=$(cat "$CONTAINER_START_FILE")
    now=$(date +%s)
    uptime_seconds=$((now - start))
    
    echo "$((uptime_seconds/3600))h $(( (uptime_seconds%3600)/60 ))m" > "$OUTPUT_FILE"
}

# Exécuter en continu
while true; do
    get_uptime
    sleep 60  # Actualiser toutes les minutes
done

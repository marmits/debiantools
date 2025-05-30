#!/bin/bash

# Arrêter tous les conteneurs en cours d'exécution
docker stop $(docker ps -q)

# Supprimer tous les conteneurs
docker rm $(docker ps -a -q)

docker system prune -f
echo "Tous les conteneurs ont été supprimés."


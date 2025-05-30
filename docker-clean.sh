#!/bin/bash

# Arrêter tous les conteneurs en cours d'exécution
docker stop $(docker ps -q)

# Supprimer tous les conteneurs
docker rm $(docker ps -a -q)

# Supprimer toutes les images
docker rmi $(docker images -q)

# Supprimer tous les volumes
docker volume rm $(docker volume ls -q)

echo "Tous les conteneurs, images et volumes Docker ont été supprimés."

docker system prune -f
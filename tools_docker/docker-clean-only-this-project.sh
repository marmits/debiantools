#!/bin/bash
# Nettoyer sélectivement les ressources Docker (conteneurs, images, volumes, réseaux) 
# associées à un ou plusieurs préfixes fournis en argument.

# Vérifie si des préfixes ont été fournis
if [ "$#" -eq 0 ]; then
  echo "❌ Aucun préfixe fourni. Utilisation : $0 <prefix1> <prefix2> ..."
  exit 1
fi
PREFIXES=("$@")

echo "🔁 Nettoyage Docker pour les préfixes: ${PREFIXES[*]}"

for PREFIX in "${PREFIXES[@]}"; do
  echo -e "\n🧹 Nettoyage pour le préfixe: $PREFIX"

  containers=$(docker ps -a --format "{{.ID}} {{.Names}}" | grep "$PREFIX" | awk '{print $1}')
  if [ -n "$containers" ]; then
    echo "🗑️ Suppression des containers:"
    echo "$containers"
    docker rm -f $containers
  else
    echo "✅ Aucun container à supprimer"
  fi

  image_ids=$(docker images --format "{{.Repository}} {{.ID}}" | grep "$PREFIX" | awk '{print $2}')
  if [ -n "$image_ids" ]; then
    echo "🗑️ Suppression des images:"
    echo "$image_ids"
    docker rmi -f $image_ids
  else
    echo "✅ Aucune image à supprimer"
  fi

  volumes=$(docker volume ls --format "{{.Name}}" | grep "^$PREFIX")
  if [ -n "$volumes" ]; then
    echo "🗑️ Suppression des volumes:"
    echo "$volumes"
    docker volume rm $volumes
  else
    echo "✅ Aucun volume à supprimer"
  fi

  networks=$(docker network ls --format "{{.Name}}" | grep "$PREFIX")
  if [ -n "$networks" ]; then
    echo "🗑️ Suppression des réseaux:"
    echo "$networks"
    docker network rm $networks
  else
    echo "✅ Aucun réseau à supprimer"
  fi

  echo "✅ Nettoyage terminé pour '$PREFIX'"
done

docker image prune -f
docker buildx prune -af
echo -e "\n🎉 Nettoyage global terminé. 🎉"

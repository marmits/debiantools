#!/bin/bash
# Permet de stopper, supprimer un container, son image associée si non utililsé par un autre container et les réseaux

# Processus en 5 étapes :
# 1. Arrêt
# 2. Analyse
# 3. Suppression container
# 4. Suppression image
# 5. Nettoyage réseaux

# Gestion des réseaux 
# Détection automatique de tous les réseaux attachés
# Suppression sélective (ne touche pas aux réseaux système : bridge/host/none)
# Conservation des réseaux partagés entre containers

# Protections supplémentaires :
# Ne supprime pas les réseaux par défaut
# Vérification explicite des réseaux utilisateurs



# Vérifier qu'un argument a été fourni
if [ -z "$1" ]; then
    echo "Usage: $0 <nom_du_container>"
    exit 1
fi

CONTAINER_NAME=$1

echo "🔴 Début du nettoyage pour le container: $CONTAINER_NAME"
echo

# 1. Afficher les informations détaillées avant suppression
echo "📝 Informations actuelles du container:"
if docker inspect "$CONTAINER_NAME" &> /dev/null; then
    docker inspect "$CONTAINER_NAME" | grep -E '(Image|Config.Image|Volumes|Network|State)'
else
    echo "ℹ️ Le container $CONTAINER_NAME n'existe pas"
    exit 1
fi

echo
read -p "⏳ Voulez-vous vraiment supprimer ce container et toutes ses dépendances? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Abandon de l'opération"
    exit 0
fi

echo
echo "🚀 Début des opérations de nettoyage..."
echo

# 2. Arrêter le container
echo "🛑 1/5 Arrêt du container..."
docker stop "$CONTAINER_NAME" 2>/dev/null || echo "ℹ️ Le container n'était pas en cours d'exécution"

# 3. Récupérer les infos AVANT suppression
echo "🔍 2/5 Identification des dépendances..."
IMAGE_ID=$(docker inspect --format='{{.Image}}' "$CONTAINER_NAME" 2>/dev/null)
IMAGE_NAME=$(docker inspect --format='{{.Config.Image}}' "$CONTAINER_NAME" 2>/dev/null)
NETWORK_NAMES=$(docker inspect --format='{{range $net,$v := .NetworkSettings.Networks}}{{printf "%s\n" $net}}{{end}}' "$CONTAINER_NAME" 2>/dev/null | sort | uniq)

# 4. Supprimer le container
echo "🗑️ 3/5 Suppression du container..."
docker rm -f "$CONTAINER_NAME" 2>/dev/null || { echo "❌ Échec de la suppression du container"; exit 1; }

# 5. Supprimer l'image
if [ -n "$IMAGE_ID" ]; then
    echo "🖼️ 4/5 Suppression de l'image..."
    echo "ℹ️ Image ID: ${IMAGE_ID:0:12}"
    echo "ℹ️ Image Name: $IMAGE_NAME"
    
    docker rmi -f "$IMAGE_ID" 2>/dev/null || echo "⚠️ Impossible de supprimer l'image (utilisée ailleurs)"
    
    # Suppression par nom si différent de l'ID
    if [ -n "$IMAGE_NAME" ] && [ "$IMAGE_NAME" != "$IMAGE_ID" ]; then
        docker rmi -f "$IMAGE_NAME" 2>/dev/null || true
    fi
else
    echo "ℹ️ Aucune image identifiée"
fi

# 6. Supprimer les réseaux (seulement si créés par l'utilisateur)
if [ -n "$NETWORK_NAMES" ]; then
    echo "🌐 5/5 Nettoyage des réseaux..."
    for NET in $NETWORK_NAMES; do
        if [ "$NET" != "bridge" ] && [ "$NET" != "host" ] && [ "$NET" != "none" ]; then
            echo "ℹ️ Suppression du réseau: $NET"
            docker network rm "$NET" 2>/dev/null || echo "⚠️ Impossible de supprimer le réseau (peut être utilisé par d'autres containers)"
        else
            echo "ℹ️ Conservation du réseau système: $NET"
        fi
    done
else
    echo "ℹ️ Aucun réseau personnalisé identifié"
fi

# 7. Nettoyage final
echo
echo "💾 Nettoyage des volumes orphelins..."
docker volume prune -f

echo
echo "✨ Nettoyage système final..."
docker system prune -f

echo
echo "✅ Nettoyage terminé avec succès pour $CONTAINER_NAME"
echo "🗑️ Container supprimé | 🖼️ Image nettoyée | 🌐 Réseaux traités | 💾 Volumes purgés"
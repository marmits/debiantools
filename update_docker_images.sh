#!/bin/bash
set -e

# =============================================
# CHARGEMENT DES VARIABLES D'ENVIRONNEMENT
# =============================================
if [ -f .env ]; then
    set -a
    . ./.env
    set +a
fi

# Valeurs par défaut (cohérentes avec run.sh)
IMAGE_NAME_DEBIAN=${IMAGE_NAME_DEBIAN:-"debian_tools"}
BASE_IMAGE=${BASE_IMAGE:-"local/debian:latest"}
SOURCE_IMAGE="debian:latest"
TARGET_SSH_DEV=${TARGET_SSH_DEV:-"ssh"}
TZ=${TZ:-"Europe/Paris"}
SSH_USER=${SSH_USER:-"debian"}
CONTAINER_NAME_TOOLS=${CONTAINER_NAME_TOOLS:-"debian_tools"}

# Chemins des clés SSH (tels que définis dans run.sh)
KEY_DIR=${KEY_DIR:-"ssh_keys"}
KEY_PREFIX=${KEY_PREFIX:-"debiantools_id_rsa"}
PUBLIC_KEY="$KEY_DIR/$KEY_PREFIX.pub"
PRIVATE_KEY="$KEY_DIR/$KEY_PREFIX"

# Vérification de la présence des clés
if [ ! -f "$PUBLIC_KEY" ]; then
    echo "❌ Clé publique introuvable : $PUBLIC_KEY"
    echo "Veuillez d'abord exécuter ./run.sh pour générer les clés."
    exit 1
fi

# =============================================
# MISE À JOUR DE L'IMAGE DE BASE
# =============================================
echo "=== 1. Mise à jour de l'image de base $SOURCE_IMAGE ==="
docker pull "$SOURCE_IMAGE"

# Mise à jour du tag local (optionnel, pour compatibilité)
if ! docker image inspect "$BASE_IMAGE" &>/dev/null; then
    docker tag "$SOURCE_IMAGE" "$BASE_IMAGE"
else
    # On force le retag pour pointer vers la nouvelle image
    docker tag "$SOURCE_IMAGE" "$BASE_IMAGE"
fi

# =============================================
# RECONSTRUCTION DE L'IMAGE AVEC LE SECRET SSH
# =============================================
echo "=== 2. Reconstruction de l'image $IMAGE_NAME_DEBIAN (sans cache) ==="
DOCKER_BUILDKIT=1 docker build \
    --no-cache \
    --target "$TARGET_SSH_DEV" \
    --build-arg BASE_IMAGE="$BASE_IMAGE" \
    --build-arg TZ="$TZ" \
    --build-arg SSH_USER="$SSH_USER" \
    --secret id=ssh_pub,src="$PUBLIC_KEY" \
    -t "$IMAGE_NAME_DEBIAN" .

# =============================================
# REDÉMARRAGE DU CONTENEUR AVEC LA NOUVELLE IMAGE
# =============================================
echo "=== 3. Redémarrage du conteneur $CONTAINER_NAME_TOOLS ==="
# On force la recréation du conteneur avec la nouvelle image
docker compose -f compose.yml up -d --force-recreate --no-build

# =============================================
# NETTOYAGE DES ANCIENNES IMAGES (optionnel)
# =============================================
echo "=== 4. Nettoyage des images orphelines ==="
docker image prune -f

echo "=== Mise à jour des images terminée ==="
docker images | head -n 1
docker images | grep -E "debian|$IMAGE_NAME_DEBIAN" || true



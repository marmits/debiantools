#!/bin/bash

# =============================================
# PARTIE 1 : GESTION DES IMAGES DOCKER
# =============================================

# Charge les variables depuis .env si le fichier existe
if [ -f .env ]; then
    export $(grep -v '^#' .env | xargs)
fi

# Définit les valeurs par défaut
IMAGE_NAME_DEBIAN=${IMAGE_NAME_DEBIAN:-"debian_tools"}
BASE_IMAGE=${BASE_IMAGE:-"local/debian:latest"}
SOURCE_IMAGE="debian:latest"

# Vérifie si l'image source existe localement
if ! docker image inspect "$SOURCE_IMAGE" &>/dev/null; then
    echo "Téléchargement de l'image $SOURCE_IMAGE..."
    docker pull "$SOURCE_IMAGE" || { echo "Échec du téléchargement"; exit 1; }
fi

# Vérifie si l'image taggée existe déjà
if ! docker image inspect "$BASE_IMAGE" &>/dev/null; then
    echo "Création du tag $BASE_IMAGE..."
    docker tag "$SOURCE_IMAGE" "$BASE_IMAGE" || { echo "Échec du tagging"; exit 1; }
else
    # Vérifie si le conteneur est actif
        if ! docker ps --filter "name=$CONTAINER_NAME_TOOLS" --format '{{.Status}}' | grep -q "Up"; then
            echo "L'image $BASE_IMAGE présente pour build du container ${CONTAINER_NAME_TOOLS}."
        fi
fi

# =============================================
# PARTIE 2 : GÉNÉRATION DES CLÉS SSH
# =============================================
KEY_DIR=${KEY_DIR:-"ssh_keys"}
KEY_PREFIX=${KEY_PREFIX:-"debiantools_id_rsa"}
PRIVATE_KEY="$KEY_DIR/$KEY_PREFIX"
PUBLIC_KEY="$KEY_DIR/$KEY_PREFIX.pub"

mkdir -p "$KEY_DIR"
if [ ! -f "$PRIVATE_KEY" ] || [ ! -f "$PUBLIC_KEY" ]; then
    ssh-keygen -t rsa -b 4096 -f "$PRIVATE_KEY" -N "" -q
    echo "Clés SSH générées dans : $PRIVATE_KEY"
fi

chmod 600 ${PRIVATE_KEY}
chmod 644 ${PUBLIC_KEY}

# =============================================
# PARTIE 3 : GESTION DU CONTENEUR + SSH
# =============================================
CONTAINER_NAME_TOOLS=${CONTAINER_NAME_TOOLS:-"debian_tools"}
SSH_USER=${SSH_USER:-"debian"}
SSH_PORT=${SSH_PORT:-2222}
SSH_HOST=${SSH_HOST:-"localhost"}

# Fonction d'aide
usage() {
    echo "Usage: $0 [--ssh-key PATH_TO_KEY]"
    echo "Options:"
    echo "  --ssh-key    Utiliser une clé SSH personnalisée (par défaut: $PRIVATE_KEY)"
    exit 0
}

# Traitement des arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --ssh-key)
            if [ ! -f "$2" ]; then
                echo "Erreur: Clé SSH introuvable à $2"
                exit 1
            fi
            PRIVATE_KEY="$2"
            shift 2
            ;;
        -h|--help)
            usage
            ;;
        *)
            echo "Option non reconnue: $1"
            usage
            ;;
    esac
done


# Vérification du conteneur Docker
if ! docker ps --filter "name=$CONTAINER_NAME_TOOLS" --format '{{.Status}}' | grep -q "Up"; then
    echo "Démarrage du conteneur $CONTAINER_NAME_TOOLS..."

    DOCKER_BUILDKIT=1 docker build \
      --target "$TARGET_SSH_DEV" \
    	--build-arg BASE_IMAGE="$BASE_IMAGE" \
    	--build-arg TZ="$TZ" \
    	--build-arg SSH_USER="$SSH_USER" \
    	--secret id=ssh_pub,src=./${PUBLIC_KEY} \
    	-t "$IMAGE_NAME_DEBIAN" .

    # => voir Dockerfile => RUN --mount=type=secret,id=ssh_pub
    docker compose up -d --wait
fi


# Nettoyage de known_hosts si nécessaire
if ssh -o StrictHostKeyChecking=no -o PasswordAuthentication=no \
   -p "$SSH_PORT" -i "$PRIVATE_KEY" "$SSH_USER@$SSH_HOST" true 2>&1 | grep -q "WARNING: REMOTE HOST IDENTIFICATION HAS CHANGED"; then
    echo "Nettoyage de l'entrée known_hosts pour [$SSH_HOST]:$SSH_PORT..."
    ssh-keygen -R "[$SSH_HOST]:$SSH_PORT" 2>/dev/null || true
fi

# Connexion SSH
echo "Connexion à $SSH_USER@$SSH_HOST (port $SSH_PORT) avec la clé : $PRIVATE_KEY"
ssh -p "$SSH_PORT" -i "$PRIVATE_KEY" "$SSH_USER@$SSH_HOST"
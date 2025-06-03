#!/bin/bash



# Paramètres configurables avec valeurs par défaut
CONTAINER_NAME=${CONTAINER_NAME:-"debian_tools"}
SSH_USER=${SSH_USER:-"debian"}
SSH_PORT=${SSH_PORT:-2222}
SSH_HOST=${SSH_HOST:-"localhost"}
SSH_KEY=${SSH_KEY:-"SSH_KEY"}

# Nettoyage des clés SSH connues


# Fonction d'aide
usage() {
    echo "Usage: $0 --ssh-key PATH_TO_KEY"
    echo "Les options suivantes sont obligatoires : --ssh-key"
    echo "Variables d'environnement alternatives (non obligatoires) :"
    echo "  CONTAINER_NAME, SSH_USER, SSH_PORT"
    exit 1
}

# Traitement des arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --ssh-key)
            SSH_KEY="$2"
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

# Vérifier si SSH_KEY a été définie
if [ -z "$SSH_KEY" ]; then
    echo "Erreur: L'option --ssh-key est obligatoire."
    usage
fi

# Vérifier si le container est déjà en cours d'exécution
if ! docker ps --filter "name=$CONTAINER_NAME" --format '{{.Status}}' | grep -q "Up"; then
    echo "Démarrage des containers..."
    docker compose up -d --wait
else
    echo "Le container $CONTAINER_NAME est déjà en cours d'exécution"
fi

# Vérification de la clé SSH
if [ ! -f "$SSH_KEY" ]; then
    echo "Erreur: Clé SSH introuvable à $SSH_KEY"
    exit 1
fi

# Vérification de la clé SSH
if [ ! -f "$SSH_KEY" ]; then
echo "Erreur: Clé SSH introuvable à $SSH_KEY"
exit 1
fi

# Vérifier si la clé du serveur a changé (sans supprimer si première connexion)
if ssh -o StrictHostKeyChecking=no -o PasswordAuthentication=no -p $SSH_PORT -i "$SSH_KEY" $SSH_USER@$SSH_HOST true 2>&1 | grep -q "WARNING: REMOTE HOST IDENTIFICATION HAS CHANGED"; then
echo "La clé du serveur a changé, nettoyage de l'entrée known_hosts..."
ssh-keygen -R "[$SSH_HOST]:$SSH_PORT" 2>/dev/null || true
fi

# Connexion SSH
echo "Connexion avec la clé: $SSH_KEY"
ssh -p $SSH_PORT -i "$SSH_KEY" $SSH_USER@$SSH_HOST


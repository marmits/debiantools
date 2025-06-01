#!/bin/bash

# Paramètres configurables avec valeurs par défaut
CONTAINER_NAME=${CONTAINER_NAME:-"debian_tools"}
SSH_USER=${SSH_USER:-"debian"}
SSH_PORT=${SSH_PORT:-2222}
SSH_KEY="" # Initialiser à vide pour s'assurer qu'elle doit être définie

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

# Connexion SSH
echo "Connexion avec la clé: $SSH_KEY"
ssh -p $SSH_PORT -i "$SSH_KEY" $SSH_USER@localhost

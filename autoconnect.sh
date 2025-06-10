# Vérifier que .env existe
if [ ! -f ".env" ]; then
echo "Erreur: le fichier .env est manquant."
exit 1
fi

# Charger les variables
set -a
source .env
set +a

# Vérifier que la clé existe
if [ ! -f "${KEY_DIR}/${KEY_PREFIX}" ]; then
echo "Erreur: la clé SSH ${KEY_DIR}/${KEY_PREFIX} est introuvable."
exit 1
fi

# Lancer la connexion SSH
echo "Connexion à $SSH_USER@$SSH_HOST sur le port $SSH_PORT..."
ssh -p "$SSH_PORT" -i "${KEY_DIR}/${KEY_PREFIX}" "$SSH_USER"@"$SSH_HOST"

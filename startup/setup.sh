#!/bin/sh

SSH_USER=${SSH_USER:-"debian"}
HOME_DIR="/home/$SSH_USER"

# Vérifier que l'utilisateur existe
if ! id -u "$SSH_USER" >/dev/null 2>&1; then
    echo "Erreur: L'utilisateur $SSH_USER n'existe pas" >&2
    exit 1
fi

# Créer le fichier test.txt
if ! echo "un contenu généré au démarrage" > "$HOME_DIR/test.txt"; then
    echo "Erreur: Impossible de créer test.txt" >&2
    exit 1
fi
chmod 644 "$HOME_DIR/test.txt"

# Créer le répertoire datas
if ! mkdir -p "$HOME_DIR/datas"; then
    echo "Erreur: Impossible de créer le répertoire datas" >&2
    exit 1
fi
chown "$SSH_USER:$SSH_USER" "$HOME_DIR/datas"
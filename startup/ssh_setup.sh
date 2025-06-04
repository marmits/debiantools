#!/bin/bash
# Configuration complète du serveur SSH


set -e  # Arrêt en cas d'erreur
echo "=== Début de la configuration SSH ==="

# 1. Préparation des répertoires
mkdir -p /run/sshd
echo "Répertoire /run/sshd créé"

# 2. Génération des clés SSH si manquantes
declare -A KEY_TYPES=(
    ["rsa"]=""
    ["ecdsa"]=""
    ["ed25519"]=""
)

for type in "${!KEY_TYPES[@]}"; do
    key_file="/etc/ssh/ssh_host_${type}_key"
    if [ ! -f "$key_file" ]; then
        echo "Génération de la clé $type..."
        ssh-keygen -t "$type" -f "$key_file" -N ""
    else
        echo "Clé $type existe déjà"
    fi
done

# 3. Configuration des permissions
echo "Configuration des permissions..."
chmod 600 /etc/ssh/ssh_host_*
chown root:root /etc/ssh/ssh_host_*

# 4. Vérifications
echo "=== Vérification finale ==="
echo "Permissions :"
ls -la /etc/ssh/ssh_host_*

echo "Empreintes des clés :"
for type in "${!KEY_TYPES[@]}"; do
    echo -n "$type : "
    ssh-keygen -lf "/etc/ssh/ssh_host_${type}_key"
done

# 1. Vérification/Création de l'utilisateur syslog
if ! id -u syslog >/dev/null 2>&1; then
    echo "Création de l'utilisateur syslog..."
    addgroup --system adm 2>/dev/null || true
    adduser \
        --system \
        --no-create-home \
        --ingroup adm \
        --disabled-password \
        --quiet \
        syslog
fi

touch /var/log/sshd.log
chmod 640 /var/log/sshd.log
chown syslog:adm /var/log/sshd.log

echo "=== Configuration SSH terminée avec succès ==="
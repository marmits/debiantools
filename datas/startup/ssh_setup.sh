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



echo "=== Configuration SSH terminée avec succès ==="
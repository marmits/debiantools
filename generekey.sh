#!/bin/bash

# Définir le dossier de destination
KEY_DIR="ssh_keys"
KEY_PREFIX="debiantools_id_rsa"

# Créer le dossier s'il n'existe pas
mkdir -p "$KEY_DIR"

# Générer la clé SSH
ssh-keygen -t rsa -b 4096 -f "$KEY_DIR/$KEY_PREFIX" -N ""

echo "Clé SSH générée dans le dossier '$KEY_DIR' avec le préfixe '$KEY_PREFIX'"

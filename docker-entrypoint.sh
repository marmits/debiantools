#!/bin/sh
set -e
echo "TZ=${TZ}" > /startup/config.env

# Sous Windows, les fichiers texte utilisent par défaut les fins de ligne CRLF (\r\n), tandis que sous Linux, c’est LF (\n)
# Convertir les fins de ligne du fichier ssh_setup.sh en LF
find /datas -type f -name "*.sh" -exec dos2unix {} \;
find /startup -type f -name "*.sh" -exec dos2unix {} \;
sudo chmod -R +x /datas/*
sudo chmod -R +x /startup/*

# Configuration SSH
if [ -f "/startup/ssh_setup.sh" ]; then
    chmod +x /startup/ssh_setup.sh
    /startup/ssh_setup.sh
else
    echo "Warning: Script ssh_setup.sh introuvable - configuration SSH par défaut" >&2
    
    # Fallback minimal
    mkdir -p /run/sshd
    ssh-keygen -A  # Génère toutes les clés manquantes
    chmod 600 /etc/ssh/ssh_host_*
    chown root:root /etc/ssh/ssh_host_*
fi


############## UPTIME CONATAINER #########################
# Initialiser l'uptime via le script externe
if [ -f "/startup/uptime.sh" ]; then
    chmod +x /startup/uptime.sh
    /startup/uptime.sh &
else
    echo "Warning: Script test.sh introuvable dans /startup/" >&2
fi


############ BANNIERE #################################
# Initialiser la bannière via le script externe
if [ -f "/startup/banner.sh" ]; then
    chmod +x /startup/banner.sh
    /startup/banner.sh
else
    echo "Warning: Script banner.sh introuvable dans /startup/" >&2
fi
########################################


############# setup ######################
# Initialiser la configuration des fichiers et répertoires via le script externe
if [ -f "/startup/setup.sh" ]; then
    chmod +x /startup/setup.sh
    /startup/setup.sh
else
    echo "Warning: Script setup.sh introuvable dans /startup/" >&2
fi


################### server ssh ##########################
rsyslogd &
exec /usr/sbin/sshd -D
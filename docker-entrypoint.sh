#!/bin/sh
set -e
echo "TZ=${TZ}" > /datas/startup/config.env

# Sous Windows, les fichiers texte utilisent par défaut les fins de ligne CRLF (\r\n), tandis que sous Linux, c’est LF (\n)
# Convertir les fins de ligne du fichier ssh_setup.sh en LF
find /datas -type f -name "*.sh" -exec dos2unix {} \;

# Configuration SSH
if [ -f "/datas/startup/ssh_setup.sh" ]; then
    chmod +x /datas/startup/ssh_setup.sh
    /datas/startup/ssh_setup.sh
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
if [ -f "/datas/startup/uptime.sh" ]; then
    chmod +x /datas/startup/uptime.sh
    /datas/startup/uptime.sh &
else
    echo "Warning: Script test.sh introuvable dans /datas/startup/" >&2
fi


############ BANNIERE #################################
# Initialiser la bannière via le script externe
if [ -f "/datas/startup/banner.sh" ]; then
    chmod +x /datas/startup/banner.sh
    /datas/startup/banner.sh
else
    echo "Warning: Script banner.sh introuvable dans /datas/startup/" >&2
fi
########################################


############# setup ######################
# Initialiser la configuration des fichiers et répertoires via le script externe
if [ -f "/datas/startup/setup.sh" ]; then
    chmod +x /datas/startup/setup.sh
    /datas/startup/setup.sh
else
    echo "Warning: Script setup.sh introuvable dans /datas/startup/" >&2
fi


################### server ssh ##########################
rsyslogd &
exec /usr/sbin/sshd -D
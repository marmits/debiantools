#!/bin/sh
set -e



echo "TZ=${TZ}" > /startup/config.env

# Sous Windows, les fichiers texte utilisent par défaut les fins de ligne CRLF (\r\n), tandis que sous Linux, c’est LF (\n)
# Convertir les fins de ligne du fichier ssh_setup.sh en LF
find /datas -type f -name "*.sh" -exec dos2unix {} \;
find /startup -type f -name "*.sh" -exec dos2unix {} \;
sudo chown -R ${SSH_USER}:${SSH_USER} /datas
sudo chmod -R 755 /datas
sudo chmod 644 /datas/bash/*.sh
sudo chmod +x /datas/bash/*.sh
sudo chmod -R +x /startup/*.sh


# Configuration SSH
if [ -f "/startup/ssh_setup.sh" ]; then
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
    /startup/uptime.sh &
else
    echo "Warning: Script test.sh introuvable dans /startup/" >&2
fi


############ BANNIERE #################################
# Initialiser la bannière via le script externe
if [ -f "/startup/banner.sh" ]; then
    /startup/banner.sh
else
    echo "Warning: Script banner.sh introuvable dans /startup/" >&2
fi
########################################


############# github ######################
# authentification github
if [ -f "/startup/github.sh" ]; then
    /startup/github.sh
else
    echo "Warning: Script github.sh introuvable dans /startup/" >&2
fi

############# pass ######################
# Unix pass
if [ -f "/startup/pass.sh" ]; then
    /startup/pass.sh
else
    echo "Warning: Script pass.sh introuvable dans /startup/" >&2
fi

############# setup ######################
# Initialiser la configuration des fichiers et répertoires via le script externe
if [ -f "/startup/setup.sh" ]; then
    /startup/setup.sh
else
    echo "Warning: Script setup.sh introuvable dans /startup/" >&2
fi


# Nettoyage des scripts startup après utilisation
rm -rf /startup


################### server ssh ##########################
rsyslogd &
exec /usr/sbin/sshd -D
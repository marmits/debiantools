#!/bin/sh
set -e



# Créer le répertoire pour la séparation des privilèges
mkdir -p /run/sshd

# Vérification et configuration des permissions des clés SSH
chmod 600 /etc/ssh/ssh_host_*
chown root:root /etc/ssh/ssh_host_*

#Vérification des Clés d'Hôte :
#Assurez-vous que les clés d'hôte sont bien générées et présentes dans le conteneur. 
if [ ! -f /etc/ssh/ssh_host_rsa_key ]; then
    ssh-keygen -t rsa -f /etc/ssh/ssh_host_rsa_key -N ''
fi
if [ ! -f /etc/ssh/ssh_host_ecdsa_key ]; then
    ssh-keygen -t ecdsa -f /etc/ssh/ssh_host_ecdsa_key -N ''
fi
if [ ! -f /etc/ssh/ssh_host_ed25519_key ]; then
    ssh-keygen -t ed25519 -f /etc/ssh/ssh_host_ed25519_key -N ''
fi


# Vérification finale des clés
echo "=== Vérification finale ==="
sudo ls -la /etc/ssh/ssh_host_*
sudo ssh-keygen -lf /etc/ssh/ssh_host_rsa_key
sudo ssh-keygen -lf /etc/ssh/ssh_host_ecdsa_key
sudo ssh-keygen -lf /etc/ssh/ssh_host_ed25519_key


# Vérification des permissions (exécuté en tant que debian)
echo "Vérification des permissions..."
sudo ls -la /etc/ssh/ || echo "Échec de la vérification"


# Vérification des clés (debug avancé)
echo "=== Contenu de /etc/ssh ==="
ls -la /etc/ssh/
echo "=== Clés SSH disponibles ==="
ls -la /etc/ssh/ssh_host_* || echo "Aucune clé trouvée"


#############  DIVERS ######################""
touch /home/debian/test.txt
chmod 755 /home/debian/test.txt
echo "un contenu généré au démarrage" > /home/debian/test.txt

mkdir -p /home/debian/datas
chown debian:debian /home/debian/datas


exec /usr/sbin/sshd -D -e
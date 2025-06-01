#!/bin/sh

# Créer un fichier test.txt avec un contenu et définir les permissions
touch /home/debian/test.txt
chmod 755 /home/debian/test.txt
echo "un contenu généré au démarrage" > /home/debian/test.txt

# Créer un répertoire datas et définir le propriétaire
mkdir -p /home/debian/datas
chown debian:debian /home/debian/datas
#!/bin/bash

# Liste des paquets en phased updates
PACKAGES=$(apt list --upgradable | grep -E "*" | cut -d'/' -f1)
echo "Checking phased updates"
# Parcourir chaque paquet et extraire le pourcentage de phased updates
for PACKAGE in $PACKAGES; do
    echo $PACKAGE
    apt-cache policy $PACKAGE | grep "phased"
done



# gist.sh
#!/bin/bash

# Script pour publier un fichier en gist public ou secret avec GitHub CLI
# Usage: ./gist.sh <fichier> [public]
#        ./gist.sh -h

show_help() {
    echo "Usage: $(basename "$0") <fichier> [public]"
    echo "       $(basename "$0") -h"
    echo
    echo "Publie <fichier> en gist via GitHub CLI."
    echo "  - Sans paramètre supplémentaire : gist secret (par défaut)"
    echo "  - Avec 'public' : gist public"
    echo
    echo "Options:"
    echo "  -h, --help    Affiche ce message d'aide"
    echo
    echo "Exemples:"
    echo "  $(basename "$0") /datas/volumes.md          # Gist secret"
    echo "  $(basename "$0") /datas/volumes.md public   # Gist public"
    echo "  $(basename "$0") -h                         # Affiche l'aide"
}

# Vérifier l'option -h ou --help
if [ $# -eq 1 ] && { [ "$1" = "-h" ] || [ "$1" = "--help" ]; }; then
    show_help
    exit 0
fi

if [ $# -lt 1 ]; then
    echo "Erreur : nom de fichier requis."
    show_help
    exit 1
fi

FILE="$1"
PUBLIC=false

# Vérifier si le deuxième paramètre est "public"
if [ $# -ge 2 ] && [ "$2" = "public" ]; then
    PUBLIC=true
fi

if [ ! -f "$FILE" ]; then
    echo "Erreur : le fichier '$FILE' n'existe pas."
    exit 2
fi

if [ "$PUBLIC" = true ]; then
    sudo gh gist create --public "$FILE"
else
    sudo gh gist create "$FILE"  # Par défaut: secret
fi

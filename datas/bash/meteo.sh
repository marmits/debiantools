#!/bin/bash


# Couleurs pour le terminal
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Message d'aide
show_help() {
    echo -e "${GREEN}Usage: $0 [option] <lieu>${NC}"
    echo "Options (défaut: 1 - mode tableau):"
    echo "  1 : Mode tableau (format par défaut)"
    echo "  2 : Mode graphique (format v2)"
    echo ""
    echo -e "${YELLOW}Exemples:${NC}"
    echo "  $0 \"Paris\"               # Météo en tableau (défaut)"
    echo "  $0 2 \"New York\"         # Météo en mode graphique"    
    echo "  $0 2 48.8566,2.3522    # Météo graphique par coordonnées"
    echo ""
    echo -e "${RED}Remarque:${NC} Pour les lieux avec espaces, utilisez des guillemets."
    exit 1
}

# Vérification des arguments
if [ "$#" -eq 0 ] || [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
    show_help
    exit 0
fi

# Détection option/lieu
if [[ "$1" =~ ^[12]$ ]]; then
    option="$1"
    shift
    lieu_raw="$1"
else
    option=1  # Valeur par défaut = tableau
    lieu_raw="$1"
fi

# Alias "marmits"
if [[ "$lieu_raw" == "marmits" ]]; then
    lieu_raw="49.417027,3.951417"
    echo -e "${GREEN}Info: Lieu 'marmits' remplacé par 49.417027,3.951417${NC}"
fi

# Encodage du lieu
lieu_encoded=$(echo "$lieu_raw" | tr ' ' '+' | sed 's/[éèêë]/e/g; s/[àâä]/a/g; s/,,*/,/g')

# Requête météo
get_weather() {
    local url="wttr.in/$1?p&lang=fr"
    if [[ "$2" == "v2" ]]; then
        url+="&format=v2"
    fi
    
    response=$(curl -s -w "\n%{http_code}" "$url")
    http_code=${response##*$'\n'}
    content=${response%$'\n'*}

    if [[ "$http_code" != "200" || "$content" =~ "Unknown location" ]]; then
        echo -e "${RED}Erreur: Lieu '${lieu_raw}' non trouvé${NC}"
        echo "Essayez:"
        echo "  - Un nom plus précis (ex: 'Condé-sur-Suippe')"
        echo "  - Des coordonnées GPS (ex: '48.8566,2.3522')"
        exit 1
    fi
    echo "$content"
}

# Exécution (options inversées)
case "$option" in
    1) get_weather "$lieu_encoded" ;;       # Mode tableau (défaut)
    2) get_weather "$lieu_encoded" "v2" ;;  # Mode graphique
    *) show_help ;;
esac

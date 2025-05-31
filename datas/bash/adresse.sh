#!/bin/bash
# Script pour extraire les informations d'adresses via BAN (fichiers CSV ou API)
# source https://adresse.data.gouv.fr/data/ban/adresses/latest/csv/
# source https://api-adresse.data.gouv.fr

# Aide d'utilisation
usage() {
    echo "Usage: $0 -d DEPARTEMENT -c CODE -m MODE [-C COMMUNE] [-v VILLE] [-h]"
    echo "Extrait les rues d'une ville selon différents critères"
    echo ""
    echo "Options:"
    echo "  -d DEPARTEMENT   Code du département (ex: 02, 75) - non requis en mode 'api'"
    echo "  -c CODE          Code INSEE, postal ou autre selon le mode"
    echo "  -m MODE          Mode de recherche : 'insee', 'postal' ou 'api'"
    echo "  -C COMMUNE       Filtre sur le nom exact de la commune (2ème colonne) - modes insee/postal"
    echo "  -v VILLE         Nom de la ville pour le mode 'api' (optionnel, utilise le code postal si non fourni)"
    echo "  -h               Affiche cette aide"
    echo ""
    echo "Exemples:"
    echo "  $0 -d 02 -c 02011 -m insee #(affiche toutes les rues)" 
    echo "  $0 -d 02 -c 02290 -m postal -C \"Ambleny\" #(affiche toutes les rues)"
    echo "  $0 -m api -c 02190 -v \"Conde sur Suippe\" #(trouve les codes insee)"
    echo "  $0 -m api -c 02190 #(trouve les codes insee)"
    exit 1
}

# Variables par défaut
departement=""
code=""
mode=""
commune=""
ville=""

# Traitement des arguments
while getopts ":d:c:m:C:v:h" opt; do
    case $opt in
        d) departement="$OPTARG" ;;
        c) code="$OPTARG" ;;
        m) mode="$OPTARG" ;;
        C) commune="$OPTARG" ;;
        v) ville="$OPTARG" ;;
        h) usage ;;
        \?) echo "Option invalide: -$OPTARG" >&2; usage ;;
        :) echo "Option -$OPTARG nécessite un argument." >&2; usage ;;
    esac
done

# Vérification des paramètres obligatoires
if [ -z "$mode" ]; then
    echo "Erreur: Le paramètre -m est obligatoire"
    usage
fi

# Vérification du mode
if [ "$mode" != "insee" ] && [ "$mode" != "postal" ] && [ "$mode" != "api" ]; then
    echo "Erreur: Le mode doit être 'insee', 'postal' ou 'api'"
    usage
fi

# Traitement spécifique au mode API
if [ "$mode" = "api" ]; then
    if [ -z "$code" ]; then
        echo "Erreur: En mode 'api', le paramètre -c (code postal) est obligatoire"
        usage
    fi

    # Utilisation du code postal comme valeur par défaut pour q si ville n'est pas spécifiée
    if [ -z "$ville" ]; then
        echo "Interrogation de l'API pour le code postal ${code}..."
        curl -s "https://api-adresse.data.gouv.fr/search/?q=${code}&postcode=${code}&type=municipality" | \
        jq '.features[] | {citycode: .properties.citycode, commune: .properties.city}'
    else
        # Encodage de la ville pour URL
        encoded_ville=$(echo "$ville" | sed 's/ /+/g')

        echo "Interrogation de l'API pour la ville '${ville}' (code postal: ${code})..."
        curl -s "https://api-adresse.data.gouv.fr/search/?q=${encoded_ville}&postcode=${code}&type=municipality" | \
        jq '.features[] | {citycode: .properties.citycode, commune: .properties.city}'
    fi

    exit 0
fi

# Vérification des autres paramètres obligatoires pour modes CSV
if [ -z "$departement" ] || [ -z "$code" ]; then
    echo "Erreur: Les paramètres -d et -c sont obligatoires en modes 'insee' et 'postal'"
    usage
fi

# Suite du traitement pour les modes CSV (identique à l'original)
filename="adresses-${departement}.csv"
gzfile="${filename}.gz"
url="https://adresse.data.gouv.fr/data/ban/adresses/latest/csv/${gzfile}"

echo "Téléchargement du fichier pour le département ${departement}..."
wget -q "$url"

echo "Décompression..."
gunzip -f "$gzfile"

# Fonction pour filtrer par commune si spécifiée
filter_by_commune() {
    if [ -z "$commune" ]; then
        cat  # Pas de filtre, on affiche tout
    else
        awk -F' *\\| *' -v commune="$commune" 'tolower($2) == tolower(commune)'
    fi
}

# Traitement selon le mode
echo "Extraction des rues pour le code ${code} en mode ${mode}..."

if [ "$mode" = "insee" ]; then
    awk -F';' -v code="$code" '$7 == code {print $5 " | " $8 " | " $6}' "$filename" | awk '{$1=$1};1' | sort -u | filter_by_commune
elif [ "$mode" = "postal" ]; then
    awk -F';' -v code="$code" '$6 == code {print $5 " | " $8 " | " $7}' "$filename" | awk '{$1=$1};1' | sort -t '|' -u -k2,2 -k1,1 | filter_by_commune
fi

# Nettoyage (optionnel)
rm "$filename"

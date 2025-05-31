#!/bin/bash

# Aide d'utilisation
usage() {
    echo "Usage: $0 -c COMMUNE [-t TYPE_ETABLISSEMENT] [-f more|all] [-o OFFSET] [-l LIMIT]"
    echo "Recherche des établissements scolaires via l'API de l'Éducation Nationale"
    echo ""
    echo "Options:"
    echo "  -c COMMUNE           Nom de la commune (obligatoire)"
    echo "  -t TYPE_ETABLISSEMENT Type d'établissement (optionnel)"
    echo "  -f more              Affiche les champs de contact (mail,telephone,web) en JSON"
    echo "  -f all               Affiche TOUS les champs disponibles en JSON"
    echo "  -o OFFSET            Décalage pour la pagination (défaut: 0)"
    echo "  -l LIMIT             Nombre de résultats par requête (défaut: 100, max: 100)"
    echo "  -h                   Affiche cette aide"
    echo ""
    echo "Exemples:"
    echo "  $0 -c Paris -t lycee -l 50"
    echo "  $0 -c Reims -f more -o 100 -l 20"
    exit 1
}

# Variables par défaut
commune=""
type_etablissement=""
output_mode="table"
offset=0
limit=100

# Traitement des arguments
while getopts ":c:t:f:o:l:h" opt; do
    case $opt in
        c) commune="$OPTARG" ;;
        t) type_etablissement="$OPTARG" ;;
        f) case "$OPTARG" in
              more) output_mode="more" ;;
              all) output_mode="all" ;;
              *) echo "Option -f invalide: $OPTARG (utilisez 'more' ou 'all')" >&2; usage ;;
           esac ;;
        o) offset="$OPTARG"
           [[ "$offset" =~ ^[0-9]+$ ]] || { echo "Offset doit être un nombre positif" >&2; exit 1; } ;;
        l) limit="$OPTARG"
           [[ "$limit" =~ ^[0-9]+$ ]] && [ "$limit" -le 100 ] || { 
               echo "Limit doit être un nombre entre 1 et 100" >&2; exit 1; } ;;
        h) usage ;;
        \?) echo "Option invalide: -$OPTARG" >&2; usage ;;
        :) echo "Option -$OPTARG nécessite un argument." >&2; usage ;;
    esac
done

[ -z "$commune" ] && { echo "Erreur: Le paramètre -c est obligatoire"; usage; }

# Encodage URL
encoded_commune=$(echo "$commune" | sed 's/ /%20/g')
#where_clause="nom_commune%20%3D%20%22${encoded_commune}%22%20" #strictement égale
where_clause="nom_commune%20like%20%27${encoded_commune}%27" # like 'paris'
#where_clause="nom_commune%20like%20%27%25${encoded_commune}%25%27" # like '%paris%'

[ -n "$type_etablissement" ] && {
    encoded_type=$(echo "$type_etablissement" | sed 's/ /%20/g')
    where_clause+="%20AND%20type_etablissement%20like%20%27%25${encoded_type}%25%27"
}

# Construction de la requête API
api_url="https://data.education.gouv.fr/api/explore/v2.1/catalog/datasets/fr-en-annuaire-education/records?&order_by=identifiant_de_l_etablissement&where=${where_clause}&limit=${limit}&offset=${offset}"

# Affichage des paramètres de recherche
echo "Recherche des établissements à '$commune'" >&2
[ -n "$type_etablissement" ] && echo "Filtre : type '$type_etablissement'" >&2
[ "$output_mode" = "more" ] && echo "Affichage des champs de contact" >&2
[ "$output_mode" = "all" ] && echo "Affichage de tous les champs disponibles" >&2
[ "$offset" -gt 0 ] && echo "Décalage des résultats : $offset" >&2
[ "$limit" -ne 100 ] && echo "Nombre de résultats par page : $limit" >&2
echo "" >&2

case "$output_mode" in
    "table")
        # Mode tableau standard
        echo "N° | Établissement | Type | Adresse | Coordonnées GPS" >&2
        echo "---------------------------------------------------------------" >&2
        
        curl -s "$api_url" | \
        jq -r --argjson offset "$offset" '.results | to_entries[] | 
        "\($offset + .key + 1)|\(.value.nom_etablissement)|\(.value.type_etablissement)|\(.value.adresse_1)|\(.value.position.lat),\(.value.position.lon)"' | \
        while IFS='|' read -r num etablissement type adresse coord; do
            printf "%3d | %-30s | %-15s | %-25s | %s\n" \
                   "$num" \
                   "$(echo "$etablissement" | cut -c -30)" \
                   "$(echo "$type" | cut -c -15)" \
                   "$(echo "$adresse" | cut -c -25)" \
                   "$coord"
        done
        ;;
    "more")
        # Mode JSON avec champs de contact
        curl -s "$api_url" | \
        jq --argjson offset "$offset" '
        .results | to_entries | map({
            numero: ($offset + .key + 1),
            nom_etablissement: .value.nom_etablissement,
            type_etablissement: .value.type_etablissement,
            adresse: .value.adresse_1,
            position: .value.position,
            telephone: .value.telephone,
            mail: .value.mail,
            web: .value.web
        } | with_entries(select(.value != null)))
        '
        ;;
    "all")
        # Mode JSON complet avec tous les champs
        curl -s "$api_url" | \
        jq --argjson offset "$offset" '
        .results | to_entries | map(
            .value | del(.datasetid, .recordid, .record_timestamp, .geometry) | 
            . + {numero: ($offset + .key + 1)} |
            with_entries(select(.value != null))
        )
        '
        ;;
esac

echo "" >&2
echo "Nombre de résultats affichés: $limit" >&2
[ "$offset" -gt 0 ] && echo "Prochain offset possible: $((offset + limit))" >&2
echo "Recherche terminée." >&2
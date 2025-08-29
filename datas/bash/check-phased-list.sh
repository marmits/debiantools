#!/bin/bash

: '
============================================================
 Script : rapport-phasage.sh
 Auteur : [Ton Nom]
 Objet  : Générer un rapport clair sur les mises à jour phasées
============================================================

DESCRIPTION :
Ce script analyse les paquets upgradables signalés par APT et
vérifie s’ils sont soumis au "phasage" (phased updates).

Le phasage est une fonctionnalité d’APT qui déploie certaines
mises à jour progressivement (ex: 10%, 20%, ... des machines)
afin de limiter l’impact d’éventuels bugs.

Le script :
  1. Récupère la liste des paquets upgradables via
     `apt list --upgradable`.
  2. Pour chaque paquet, interroge `apt-cache show` pour
     extraire le champ `Phased-Update-Percentage`.
  3. Construit une liste fusionnée des paquets concernés,
     en indiquant le pourcentage de phasage appliqué.
  4. Trie et affiche les résultats par ordre alphabétique.
  5. Résume le nombre total de paquets affectés par le phasage.

AFFICHAGE :
- Chaque paquet est listé avec son pourcentage de phasage.
- Un résumé final indique le total de paquets concernés.

UTILISATION :
  ./rapport-phasage.sh

PRÉREQUIS :
- Debian/Ubuntu (ou dérivés) avec apt >= 2.2
- Droits de lecture sur `apt list` et `apt-cache show`
============================================================
'

# --- Définition des couleurs pour l'affichage ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'   # Reset couleur (No Color)

# --- En-tête ---
echo "=============================================="
echo " 🔍 Rapport sur les mises à jour phasées"
echo "=============================================="
echo

# Étape 1 : récupération des paquets upgradables
UPGRADABLE_PKGS=$(apt list --upgradable 2>/dev/null | awk -F/ 'NR>1 {print $1}')

# Étape 2 : carte associative pour stocker les pourcentages
declare -A PHASE_MAP

for pkg in $UPGRADABLE_PKGS; do
    PERC=$(apt-cache show "$pkg" 2>/dev/null | awk '/^Phased-Update-Percentage:/ {print $2}')
    if [ -n "$PERC" ]; then
        PHASE_MAP["$pkg"]="$PERC"
    fi
done

# Étape 3 : affichage trié
if [ ${#PHASE_MAP[@]} -eq 0 ]; then
    echo -e " ${GREEN}→ Aucun paquet soumis au phasage${NC}"
else
    for pkg in $(printf "%s\n" "${!PHASE_MAP[@]}" | sort); do
        echo -e "  - ${YELLOW}$pkg${NC} → ${RED}${PHASE_MAP[$pkg]}% en phase${NC}"
    done
    echo
    echo "=============================================="
    echo -e " ✅ ${GREEN}Analyse terminée${NC}"
    echo "   Résumé : ${#PHASE_MAP[@]} paquets concernés par le phasage"
    echo "=============================================="
fi


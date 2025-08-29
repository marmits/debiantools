#!/bin/bash

# =====================================================
# 🔍 Rapport sur les mises à jour phasées - Fusionné
# =====================================================
# Ce script liste tous les paquets Ubuntu en phase de mise à jour (phased updates).
# Il fusionne les paquets "différés" et "upgradables phasés" pour éviter les doublons,
# et affiche l'état réel de chaque paquet.
# Il gère automatiquement les locales FR/EN pour parser la sortie d'APT.
# =====================================================

echo "=============================================="
echo " 🔍 Rapport sur les mises à jour phasées"
echo "=============================================="
echo

# ==========================
# Couleurs pour la sortie
# ==========================
RED='\033[0;31m'     # rouge pour pourcentage
GREEN='\033[0;32m'   # vert pour upgradable
YELLOW='\033[1;33m'  # jaune pour différé ou paquet
BLUE='\033[0;34m'    # bleu pour sections
NC='\033[0m'         # reset couleur

# ==========================
# Détection de la langue
# ==========================
# On détecte la locale pour adapter le parsing
LANGUAGE=$(echo $LANG | cut -d_ -f1)

if [ "$LANGUAGE" == "fr" ]; then
    REGEX_DEFERRED="Les mises à jour suivantes ont été différées"
    REGEX_END="0 mis à jour"
else
    REGEX_DEFERRED="The following packages have been kept back"
    REGEX_END="0 upgraded"
fi

# ==========================
# 1) Récupérer les paquets différés par phasage
# ==========================
# On simule un full-upgrade pour capturer les paquets différés
DEFERRED=$(apt full-upgrade -s 2>/dev/null | awk "/$REGEX_DEFERRED/{flag=1; next} /$REGEX_END/{flag=0} flag")

# Nettoyage de la sortie pour extraire les noms de paquets
PKGS_DEFERRED=$(echo "$DEFERRED" | tr -d '\n' | sed 's/  /\n/g' | sed 's/^ *//;s/ *$//' | tr '\n' ' ')

# ==========================
# 2) Récupérer les paquets upgradables phasés
# ==========================
UPGRADABLE=$(apt list --upgradable 2>/dev/null | awk -F/ 'NR>1 {print $1}')

# On ne garde que ceux qui ont un pourcentage de phasage
PHASED_UPGRADABLE=""
for PKG in $UPGRADABLE; do
    PERC=$(apt-cache show "$PKG" 2>/dev/null | awk '/^Phased-Update-Percentage:/ {print $2}')
    if [ -n "$PERC" ]; then
        PHASED_UPGRADABLE+="$PKG "
    fi
done

# ==========================
# 3) Fusionner les listes pour éviter les doublons
# ==========================
declare -A PACKAGES

# Ajouter les paquets différés dans le tableau associatif
for PKG in $PKGS_DEFERRED; do
    PERC=$(apt-cache show "$PKG" 2>/dev/null | awk '/^Phased-Update-Percentage:/ {print $2}')
    PACKAGES["$PKG"]="différé|$PERC"
done

# Ajouter les upgradables phasés seulement si non déjà présent
for PKG in $PHASED_UPGRADABLE; do
    PERC=$(apt-cache show "$PKG" 2>/dev/null | awk '/^Phased-Update-Percentage:/ {print $2}')
    if [ -z "${PACKAGES[$PKG]}" ]; then
        PACKAGES["$PKG"]="upgradable|$PERC"
    fi
done

# ==========================
# 4) Affichage des résultats
# ==========================
COUNT_DIFF=0
COUNT_UP=0

echo -e "${BLUE}📦 Paquets phasés fusionnés :${NC}"
for PKG in "${!PACKAGES[@]}"; do
    STATE=$(echo "${PACKAGES[$PKG]}" | cut -d'|' -f1)  # différé / upgradable
    PERC=$(echo "${PACKAGES[$PKG]}" | cut -d'|' -f2)   # Pourcentage de phasage
    
    # Déterminer la couleur et compter les totaux
    if [ "$STATE" == "différé" ]; then
        COLOR_STATE="${YELLOW}différé${NC}"
        COUNT_DIFF=$((COUNT_DIFF+1))
    else
        COLOR_STATE="${GREEN}upgradable${NC}"
        COUNT_UP=$((COUNT_UP+1))
    fi
    
    # Affichage du paquet avec son état et pourcentage
    if [ -n "$PERC" ]; then
        echo -e "  - ${YELLOW}$PKG${NC} → ${RED}$PERC% en phase${NC} (${COLOR_STATE})"
    else
        echo -e "  - ${YELLOW}$PKG${NC} → phasage actif (${COLOR_STATE})"
    fi
done

# Totaux
echo
echo "  🔢 Total différés : $COUNT_DIFF"
echo "  🔢 Total upgradables phasés : $COUNT_UP"
echo
echo "=============================================="
echo -e " ✅ ${GREEN}Analyse terminée${NC}"
echo "   Résumé : $COUNT_DIFF différés, $COUNT_UP upgradables phasés"
echo "=============================================="


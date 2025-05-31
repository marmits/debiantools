#!/bin/bash
# Permet de consulter l'historique APT sur le système
#Usage: ./apt_log_history0.sh [OPTIONS]
#Options:
#  -f, --upgrades    Affiche uniquement les mises à jour
#  -i, --installs    Affiche uniquement les installations
#  -u, --removals    Affiche uniquement les suppressions
#  -r, --reset       Affiche tout (réinitialise le filtre)
#  -h, --help        Affiche ce message d'aide


# Fonction pour traiter les fichiers
process_apt_history() {
    local file="$1"
    local filter="${2:-.*}"  # Filtre par défaut : tout afficher

    echo -e "\033[1;35m\nFichier: ${file##*/}\033[0m"

    if [[ "$file" == *.gz ]]; then
        zcat "$file"
    else
        cat "$file"
    fi | awk -v filter="$filter" '
        /Start-Date:/ {
            start_pos = index($0, "Start-Date:") + 11;
            date = substr($0, start_pos, 19);
            current_date = "\033[1;32m[" date "]\033[0m";
            has_matching_action = 0;
        }
        /Commandline:/ {
            cmd = substr($0, index($0, "Commandline:") + 12);
            current_cmd = cmd;
        }
        /Install:|Upgrade:|Remove:|Installation:|Mise à jour:|Suppression:/ {
            action = $1;
            details = substr($0, index($0, ": ") + 2);

            if (action ~ filter) {
                if (!has_matching_action) {
                    print current_date;
                    if (current_cmd != "") {
                        printf "  \033[33m● Commande: %s\033[0m\n", current_cmd;
                    }
                    has_matching_action = 1;
                }

                # Couleurs
                color = "\033[36m"; # Par défaut (bleu cyan)
                if (action ~ /Install|Installation/) color = "\033[32m"; # Vert
                if (action ~ /Remove|Suppression/) color = "\033[31m";   # Rouge

                printf "  %s%-12s\033[0m %s\n", color, action, details;
            }
        }
    '
}

# Affichage de l'aide
display_help() {
    echo "Usage: $0 [OPTIONS]"
    echo "Options:"
    echo "  -f, --upgrades    Affiche uniquement les mises à jour"
    echo "  -i, --installs    Affiche uniquement les installations"
    echo "  -u, --removals    Affiche uniquement les suppressions"
    echo "  -r, --reset       Affiche tout (réinitialise le filtre)"
    echo "  -h, --help        Affiche ce message d'aide"
    exit 0
}

# Paramètres
FILTER=".*"  # Affiche tout par défaut

# Traitement des options
while getopts "fiurh" opt; do
    case $opt in
        f) FILTER="Upgrade|Mise à jour";;
        i) FILTER="Install|Installation";;
        u) FILTER="Remove|Suppression";;
        r) FILTER=".*";;
        h) display_help;;
        *) display_help;;
    esac
done

# Affichage
echo -e "\033[1;34m=== HISTORIQUE APT (Filtre: ${FILTER}) ===\033[0m"

# D'abord les archives (.gz)
for f in $(ls -v /var/log/apt/history.log*.gz 2>/dev/null); do
    process_apt_history "$f" "$FILTER"
done

# Puis le fichier courant
[ -f "/var/log/apt/history.log" ] && process_apt_history "/var/log/apt/history.log" "$FILTER"

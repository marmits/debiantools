#!/bin/bash
# Affiche uniquement les commandes APT utilisées dans l'historique
FILTER=".*"  # Par défaut, tout afficher

# Traitement des options
while getopts "fiurh" opt; do
  case $opt in
    f) FILTER="Upgrade\nMise à jour";;
    i) FILTER="Install\nInstallation";;
    u) FILTER="Remove\nSuppression";;
    r) FILTER=".*";;
    h) echo "Usage: $0 [OPTIONS]"
       echo "Options:"
       echo "  -f  Mises à jour uniquement"
       echo "  -i  Installations uniquement"
       echo "  -u  Suppressions uniquement"
       echo "  -r  Réinitialiser le filtre"
       echo "  -h  Afficher l'aide"
       exit 0;;
    *) exit 1;;
  esac
done

# Fonction pour extraire uniquement les commandes
extract_commands_only() {
  local file="$1"
  local filter="${2:-.*}"

  if [[ "$file" == *.gz ]]; then
    zcat "$file"
  else
    cat "$file"
  fi | awk -v filter="$filter" '
    /Start-Date:/ {
      start_pos = index($0, "Start-Date:") + 11;
      date = substr($0, start_pos, 19);
      current_date = sprintf("\033[1;32m[%s]\033[0m", date);
      has_matching_action = 0;
    }
    /Commandline:/ {
      cmd = substr($0, index($0, "Commandline:") + 12);
      current_cmd = cmd;
    }
    /Install:|Upgrade:|Remove:|Installation:|Mise à jour:|Suppression:/ {
      action = $1;
      if (action ~ filter) {
        if (!has_matching_action) {
          print current_date;
          if (current_cmd != "") {
            printf " \033[33m● Commande: %s\033[0m\n", current_cmd;
          }
          has_matching_action = 1;
        }
      }
    }
  '
}

echo -e "\033[1;34m=== COMMANDES APT (Filtre: ${FILTER}) ===\033[0m"

# Fichiers .gz
for f in $(ls -v /var/log/apt/history.log*.gz 2>/dev/null); do
  extract_commands_only "$f" "$FILTER"
done

# Fichier courant
[ -f "/var/log/apt/history.log" ] && extract_commands_only "/var/log/apt/history.log" "$FILTER"

#!/usr/bin/env bash
set -euo pipefail
# ------------------------------------------------------------
# pass-ttl-check.sh
# - Sans option : montre l'état de gpg-agent + TTL effectifs.
# - --set-ttl <DEF> <MAX> : applique les TTL et recharge l'agent.
# ------------------------------------------------------------

# Couleurs (facultatif)
BOLD="\033[1m"; DIM="\033[2m"; RED="\033[31m"; GREEN="\033[32m"; YELLOW="\033[33m"; NC="\033[0m"
info()  { echo -e "${BOLD}$*${NC}"; }
warn()  { echo -e "${YELLOW}[!]${NC} $*"; }
err()   { echo -e "${RED}[x]${NC} $*" 1>&2; }
ok()    { echo -e "${GREEN}[ok]${NC} $*"; }

need_bin() {
  command -v "$1" >/dev/null 2>&1 || { err "Commande requise non trouvée: $1"; exit 1; }
}

usage() {
  cat <<'USAGE'
Usage:
  pass-ttl-check.sh                 # Affiche uniquement les infos (gpg-agent + TTL)
  pass-ttl-check.sh --set-ttl <DEF> <MAX>
                                    # Définit les TTL (secondes) puis reload gpg-agent
  pass-ttl-check.sh -h | --help     # Aide

Exemples :
  pass-ttl-check.sh
  pass-ttl-check.sh --set-ttl 3600 7200
USAGE
}

conf_file_path() { echo "${HOME}/.gnupg/gpg-agent.conf"; }

ensure_gnupg_perms() {
  [[ -d "${HOME}/.gnupg" ]] || mkdir -p "${HOME}/.gnupg"
  chmod 700 "${HOME}/.gnupg" || true
}

launch_agent() { gpgconf --launch gpg-agent >/dev/null 2>&1 || true; }
agent_socket() { gpgconf --list-dirs agent-socket 2>/dev/null || true; }

check_agent() {
  launch_agent
  local sock; sock="$(agent_socket)"
  if [[ -n "${sock}" && -S "${sock}" ]]; then
    ok "gpg-agent dispo (socket: ${sock})"
  else
    warn "Socket gpg-agent introuvable (l'agent peut être auto-spawn via le socket)."
  fi
  if gpg-connect-agent 'GETINFO version' /bye >/dev/null 2>&1; then
    local ver
    ver="$(gpg-connect-agent 'GETINFO version' /bye 2>/dev/null | awk '{print $2}')"
    ok "Communication gpg-agent OK (version: ${ver})"
  else
    err "Impossible de communiquer avec gpg-agent."
    exit 1
  fi
}

show_ttls() {
  info "\n--- TTL vus par gpg-agent ---"
  # gpgconf --list-options gpg-agent : colonnes séparées par ':'.
  # Nous affichons colonnes 7 (default) et 10 (current) pour les deux paramètres intéressants.
  if ! gpgconf --list-options gpg-agent \
      | awk -F: '/^(default-cache-ttl|max-cache-ttl)/{
          name=$1; def=$7; cur=$10; if(cur=="") cur="(defaut)";
          printf "%-20s default=%-6s current=%s\n", name, def, cur
        }'; then
    warn "Impossible de lire les options via gpgconf."
  fi

  # Montre ce qui est explicitement posé dans le fichier de conf (si présent)
  local conf; conf="$(conf_file_path)"
  echo
  info "--- Contenu TTL dans ${conf} (si existant) ---"
  if [[ -f "$conf" ]]; then
    grep -E '^(default|max)-cache-ttl' "$conf" || echo "(aucune ligne TTL explicite)"
  else
    echo "(fichier absent)"
  fi
}

apply_ttls() {
  local DEF_TTL="$1" MAX_TTL="$2"
  [[ "$DEF_TTL" =~ ^[0-9]+$ && "$MAX_TTL" =~ ^[0-9]+$ ]] || { err "TTL non numériques."; exit 1; }

  ensure_gnupg_perms
  local conf; conf="$(conf_file_path)"
  [[ -f "$conf" ]] && cp -a "$conf" "${conf}.bak.$(date +%Y%m%d-%H%M%S)" && ok "Backup: ${conf}.bak.*"

  # Réécrit (ou crée) en supprimant d'éventuelles anciennes lignes TTL
  { [[ -f "$conf" ]] && grep -Ev '^(default|max)-cache-ttl' "$conf" || true; } > "${conf}.tmp"
  {
    echo "default-cache-ttl ${DEF_TTL}"
    echo "max-cache-ttl ${MAX_TTL}"
    # Optionnel si tu utilises --pinentry-mode loopback :
    # echo "allow-loopback-pinentry"
  } >> "${conf}.tmp"

  mv "${conf}.tmp" "$conf"
  chmod 600 "$conf"
  ok "TTL écrits dans ${conf} (default=${DEF_TTL}s, max=${MAX_TTL}s)"

  # Recharge l'agent pour prise en compte immédiate
  if gpgconf --reload gpg-agent; then
    ok "gpg-agent rechargé"
  else
    warn "Reload gpg-agent non concluant (l'agent se relancera au prochain usage)."
  fi
}

main() {
  # Dépendances minimales
  need_bin gpgconf
  need_bin gpg-connect-agent
  need_bin awk

  case "${1:-}" in
    -h|--help) usage; exit 0 ;;
    --set-ttl)
      [[ $# -eq 3 ]] || { err "Arguments manquants pour --set-ttl"; usage; exit 1; }
      info "=== Application des TTL demandés ==="
      check_agent
      apply_ttls "$2" "$3"
      show_ttls
      ;;
    "")
      info "=== Informations gpg-agent & TTL ==="
      check_agent
      show_ttls
      ;;
    *)
      err "Option inconnue: $1"; usage; exit 1 ;;
  esac
}

main "$@"

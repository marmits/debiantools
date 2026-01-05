
#!/bin/sh
# ============================================================
# GitHub CLI bootstrap: auth via Docker secrets only
# Priority: personal secret -> team secret
# ============================================================

set -e

echo "====================== GITHUB ======================"
export TERM=dumb
gh config set prompt disabled >/dev/null 2>&1 || true

# Reset any previous auth
gh auth logout >/dev/null 2>&1 || true
unset GITHUB_TOKEN

# ---- Helpers ------------------------------------------------

# mask_token: print token with middle masked (ghp_abc***xyz)
mask_token() {
  token="$1"
  case "$token" in
    ghp_*)
      prefix="ghp_"
      rest="${token#ghp_}"
      first="$(printf '%s' "$rest" | cut -c1-6)"
      last="$(printf '%s' "$rest" | awk '{print substr($0, length($0)-3)}')"
      printf '%s%s***%s' "$prefix" "$first" "$last"
      ;;
    *)
      first="$(printf '%s' "$token" | cut -c1-6)"
      last="$(printf '%s' "$token" | awk '{print substr($0, length($0)-3)}')"
      printf '%s***%s' "$first" "$last"
      ;;
  esac
}

# validate_github_token: returns 0 if API /user answers with "login"
validate_github_token() {
  token="$1"
  [ -z "$token" ] && return 1
  if curl -s -m 5 -H "Authorization: token $token" https://api.github.com/user | grep -q '"login"'; then
    return 0
  else
    return 1
  fi
}

# login_with_token: feed token to gh and log masked token & source
login_with_token() {
  token="$1"
  note="$2"
  masked="$(mask_token "$token")"
  echo ">>> Using token source: $note"
  echo ">>> Token (masked): $masked"
  printf '%s' "$token" | gh auth login --with-token
}

# (optional) ensure gh config dir ownership for $SSH_USER
write_hosts_yml() {
  [ -z "$SSH_USER" ] && return 0
  cfg_dir="/home/$SSH_USER/.config/gh"
  mkdir -p "$cfg_dir"
  chown -R "$SSH_USER:$SSH_USER" "/home/$SSH_USER/.config" 2>/dev/null || true
}

# ---- Sources in priority order ------------------------------

authenticated=0

# 1) Personal secret (highest priority)
if [ "$authenticated" -eq 0 ] && [ -f "/run/secrets/github_token_perso" ]; then
  token="$(tr -d '\r\n' < /run/secrets/github_token_perso)"
  if validate_github_token "$token"; then
    login_with_token "$token" "Docker Secret: personal (/run/secrets/github_token_perso)"
    authenticated=1
  else
    echo "WARN: Personal secret invalid or unreachable."
  fi
fi

# 2) Team/generic secret
if [ "$authenticated" -eq 0 ] && [ -f "/run/secrets/github_token" ]; then
  token="$(tr -d '\r\n' < /run/secrets/github_token)"
  if validate_github_token "$token"; then
    login_with_token "$token" "Docker Secret: team (/run/secrets/github_token)"
    authenticated=1
  else
    echo "WARN: Team secret invalid or unreachable."
  fi
fi

# ---- Final state & hints ------------------------------------

if [ "$authenticated" -eq 0 ]; then
  echo "WARNING: GitHub CLI not authenticated — features requiring auth will be limited."
  echo "Provide a token (scope 'gist' at minimum) in one of:"
  echo "  - secrets/github_token_perso.txt (personal, highest priority)"
  echo "  - secrets/github_token.txt       (team/generic)"
  exit 0
fi

write_hosts_yml

echo "GitHub CLI status:"
gh auth status || true
echo "===================================================="

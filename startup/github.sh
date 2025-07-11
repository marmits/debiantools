#!/bin/sh
set -e
echo "*********************** GITHUB ********************"


# Désactive les séquences d'échappement ANSI qui peuvent polluer les logs
export TERM=dumb
gh config set prompt disabled

# -------------------------------------------------------------------
# Nettoyage initial
# -------------------------------------------------------------------
gh auth logout >/dev/null 2>&1 || true
unset GITHUB_TOKEN

# -------------------------------------------------------------------
# Fonction de validation
# -------------------------------------------------------------------
validate_github_token() {
  local token=$1
  [ -z "$token" ] && return 1
  
  # Test avec timeout et vérification du user
  if curl -s -m 5 -H "Authorization: token $token" https://api.github.com/user | grep -q '"login"'; then
    return 0
  else
    echo "Token invalide ou erreur de connexion à GitHub" >&2
    return 1
  fi
}

# -------------------------------------------------------------------
# Stratégie d'authentification
# -------------------------------------------------------------------
authenticated=0

# 1. Essai avec Docker Secret (priorité absolue)
if [ -f "/run/secrets/github_token" ]; then
  token=$(cat /run/secrets/github_token | tr -d '\r\n')
  if validate_github_token "$token"; then
    echo "*********** GITHUB (Docker Secret) *************"
    echo "$token" | gh auth login --with-token
    authenticated=1
  fi
fi

# 2. Fallback avec .env.local (développement)
if [ "$authenticated" -eq 0 ] && [ -f "/app/.env.local" ]; then
  token=$(grep '^GITHUB_TOKEN=' /app/.env.local | cut -d= -f2- | tr -d '\r\n" ')
  if validate_github_token "$token"; then
    echo "*********** GITHUB (.env.local) *************"
    echo "$token" | gh auth login --with-token
    authenticated=1
  fi
fi

# 3. Échec contrôlé
if [ "$authenticated" -eq 0 ]; then
  echo "WARNING: GitHub CLI non authentifié - certaines fonctionnalités seront désactivées" >&2
  echo "Pour activer gh gist:" >&2
  echo "1. Créez un token avec permission 'gist' sur https://github.com/settings/tokens" >&2
  echo "2. Stockez-le dans :" >&2
  echo "   - ./github_token.txt (pour Docker Secret)" >&2
  echo "   - OU /app/.env.local (GITHUB_TOKEN=ghp_...)" >&2
  exit 0  # Ne pas bloquer le container
fi

# Vérification finale
echo "GitHub CLI status:"
gh auth status
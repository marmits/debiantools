# --- PASS/GPG: prepare persistent homes ---
GPG_HOME="/home/${SSH_USER}/.gnupg"
PASS_HOME="/home/${SSH_USER}/.password-store"

mkdir -p "$GPG_HOME" "$PASS_HOME"
chown -R "${SSH_USER}:${SSH_USER}" "$GPG_HOME" "$PASS_HOME"

# Droits stricts attendus par GnuPG
chmod 700 "$GPG_HOME"
find "$GPG_HOME" -type f -exec chmod 600 {} \;

# (optionnel) Paramétrage agent + gpg pour environnements headless
# NB: on écrit dans le home de l'utilisateur, non-root.
sudo -u "${SSH_USER}" mkdir -p "$GPG_HOME"
sudo -u "${SSH_USER}" bash -c "grep -q 'pinentry-mode loopback' '$GPG_HOME/gpg.conf' 2>/dev/null || echo 'pinentry-mode loopback' >> '$GPG_HOME/gpg.conf'"
sudo -u "${SSH_USER}" bash -c "grep -q 'allow-loopback-pinentry' '$GPG_HOME/gpg-agent.conf' 2>/dev/null || echo 'allow-loopback-pinentry' >> '$GPG_HOME/gpg-agent.conf'"

# Exporter les variables pour les sessions interactives de l'utilisateur
if ! grep -q 'GPG_TTY' "/home/${SSH_USER}/.bashrc"; then
  echo 'export GPG_TTY=$(tty)' >> "/home/${SSH_USER}/.bashrc"
  echo 'export PASS_STORE_DIR="$HOME/.password-store"' >> "/home/${SSH_USER}/.bashrc"
fi

Isoler **pass** (+ **GnuPG**) dans un conteneur Debian 13 et **persister** à la fois la *clé GPG* et le *store* `pass` sur l’hôte.  
***

## Objectif

1.  Installer `pass`, `gnupg` et `pinentry-tty` dans l’image.
2.  **Monter 2 volumes persistants**:
    *   `~/.gnupg` (trousseau GPG)
    *   `~/.password-store` (magasin `pass`)
3.  Configurer `pinentry` (mode TTY) et les variables d’environnement pour un usage en SSH/headless.
4.  Préparer l’initialisation du store (`pass init`) et l’import/gestion des clés.



## 1) **Initialiser/Importer ta clé GPG (persistée)**

> Tout ce que tu feras dans `~/.gnupg` sera **persisté** sur l’hôte via `./secrets/gnupg`.

### Option A — Générer une nouvelle clé dans le conteneur

```bash
# (dans le conteneur, en tant que debian)
gpg --full-generate-key    # Choisis par ex. RSA 4096, expiration, etc.
gpg --list-secret-keys --keyid-format=long
# repère l'ID ou l'empreinte, ex: 1234ABCD5678EF90
```

### Option B — Importer une clé existante

Copie tes sauvegardes ASCII‑armored sur l’hôte, puis :

```bash
# dans le conteneur
gpg --import /datas/keys/private.asc
gpg --import-ownertrust </datas/keys/ownertrust.txt # si tu as exporté l'ownertrust
```

***

## 2) **Initialiser `pass` et tester**

```bash
# Toujours en tant que debian dans le container
export PASSWORD_STORE_DIR="$HOME/.password-store"
pass init 1234ABCD5678EF90     # utilise l'ID/empreinte de ta clé GPG
pass insert system/ssh/vps-root
pass show system/ssh/vps-root
```

Le dossier `~/.password-store` (persisté) contiendra les fichiers `.gpg` de tes entrées.

***

## 3) **(Optionnel) Versionner le store avec Git**

Tu as déjà `git` et le CLI GitHub (`gh`) dans l’image. Tu peux versionner/synchroniser ton store:

```bash
cd ~/.password-store
pass git init
pass git remote add origin git@github.com:TonCompte/pass-store.git
pass git add .
pass git commit -m "init store"
pass git push -u origin main
```

> Astuce: `pass` propage les commandes git (`pass git <cmd>`), donc `pass git status`, `pass git pull`, etc., directement depuis le store.

***

## 4) **Sécurité & bonnes pratiques**

*   **Ne bake jamais** les clés dans l’image. Monte-les via volume (comme ci‑dessus).
*   **Permissions strictes** (`700` sur `~/.gnupg`, `600` sur les fichiers clés); l’entrypoint s’en charge au démarrage.
*   **Backups**: exporte périodiquement ta clé privée + ownertrust (à conserver **hors** du repo).
    ```bash
    gpg --export-secret-keys -a > /datas/keys/private.asc
    gpg --export-ownertrust > /datas/keys/ownertrust.txt
    ```
*   **Windows/WSL2**: si tu lances Docker Desktop sous Windows, les ACL hôte peuvent différer. Le `chmod` dans l’entrypoint remet les droits corrects **dans** le conteneur même si le FS hôte ne les applique pas nativement.

***



## 5) Workflow récap

1.  `mkdir -p secrets/gnupg secrets/password-store`
2.  `docker compose build && docker compose up -d`
3.  SSH → conteneur en tant que `${SSH_USER}`
4.  Génère ou importe la **clé GPG** (persistée)
5.  `pass init <KEYID>` puis `pass insert/show …`

***

(Optionnel) Faire petit script **`/startup/pass-setup.sh`** qui :

*   crée les dossiers,
*   pose les droits,
*   te guide pour générer la clé,
*   initialise `pass`,
*   (optionnel) initialise un remote Git.

Suggestion **générer une nouvelle clé** ou **importer** celle que tu utilises déjà (et veux‑tu activer la sync Git du store)?

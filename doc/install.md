# 📘 Démarrage & Connexion SSH

## 🚀 1. Démarrer l’environnement (build + run)

Dans le répertoire du projet :

### Méthode recommandée

```bash
./run.sh
```

### Avec une clé SSH spécifique

```bash
./run.sh --ssh-key chemin/vers/ma_cle_privee
```

> La clé **publique** correspondante doit exister dans le répertoire `ssh_keys/`.

### Via Makefile

```bash
make
```

***

## 🔑 2. Connexion SSH au conteneur

Le script `run.sh` inclut désormais une connexion SSH **automatisée et non interactive**, adaptée au développement local.

### Connexion manuelle (optionnelle)

```bash
ssh -p 2222 -i ssh_keys/debiantools_id_rsa geo@localhost
```

### Connexion automatique

```bash
./autoconnect.sh
```

Le script utilise les options suivantes :

```bash
-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null
```

Ce qui permet :

*   ✔ Pas de question « Are you sure you want to continue connecting? »
*   ✔ Pas de gestion de `known_hosts`
*   ✔ Une connexion automatique idéale pour le développement

***

## 🔁 3. À propos du changement de clé SSH du serveur

Lorsqu’un conteneur est reconstruit, le serveur SSH interne génère **de nouvelles clés d’hôte**.  
Auparavant, cela déclenchait des alertes du type :

    The authenticity of host 'localhost:2222' can't be established.

➡️ **Ce comportement est désormais neutralisé** par les options SSH utilisées dans `run.sh`, ce qui évite toute intervention manuelle.

### Si malgré tout vous souhaitez nettoyer `known_hosts` manuellement :

```bash
ssh-keygen -f ~/.ssh/known_hosts -R [localhost]:2222
```

***

## 🔐 4. Gestion du token GitHub (facultatif)

Le conteneur peut s’authentifier auprès de GitHub via **fichiers de secrets** :

```
secrets/
│── github_token.txt            # générique (optionnel)
│── github_token_perso.txt      # réel, ignoré par Git
│── github_token_perso.example  # modèle commitable
```

```
cp secrets/github_token_perso.example secrets/github_token_perso.txt
```
puis éditez ce fichier pour y coller le token personnel GitHub (PAT).

1. `secrets/github_token_perso.txt` — **prioritaire** (token personnel, ignoré par Git)
2. `secrets/github_token.txt` — **équipe/générique** (optionnel)

Les secrets sont montés dans le conteneur :
- `/run/secrets/github_token_perso`
- `/run/secrets/github_token`

Le script `startup/github.sh` valide et utilise automatiquement le premier token **valide** trouvé.

*   vérifie le token,
*   s'authentifie via `gh auth login --with-token`,
*   et utilise la source la plus sécurisée possible.

***

## 📦 5. Structure recommandée du projet

    debiantools/
    ├── compose.yml
    ├── run.sh
    ├── autoconnect.sh
    ├── startup/
    │   ├── github.sh
    │   └── ...
    ├── ssh_keys/
    │   ├── debiantools_id_rsa
    │   └── debiantools_id_rsa.pub
    ├── secrets/
    │   └── github_token_perso.txt
    │   └── github_token.txt
    ├── datas/
    ├── config/
    │   └── ...
    ├── .env
    └── .env.local

***

## 🧰 6. Notes pour le développement

*   Le conteneur est basé sur Debian avec un utilisateur SSH (`geo` par défaut).
*   `run.sh` active **BuildKit** pour plus de contrôle (build + secret).
*   La connexion SSH automatique est sécurisée dans le contexte *local/dev*.
*   Les secrets ne sont jamais exportés en variables d’environnement.
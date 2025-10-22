## Container docker debian 
- Permet d'utliser un container debian et d'y accéder en ssh.
- L'utilisateur est `sudoers` et peut être modifiable via la variable `SSH_USER` du fichier `.env`
- Voir le fichier `.env` pour d'autres variables personnalisables.
- Connexion sans mot de passe avec échange de clés (Générées automiquement)
- Divers outils installés (voir Dokerfile)
- Pull de l'image `debian:latest` puis création d'une image taguée pour éviter de télécharger sur Docker Hub (Re-Build).

## .env.local
Créer un fichier .env.local pour surcharger .env

## Descriptions
### entrypoint
- dossier `/startup` scripts utilisés lors de la fabrication du container par `docker_entrypoint.sh`

### Description du répertoire datas/
Dossier de données  
- dossier `bash` scripts disponibles à éxécuter une fois connecté dans le container.

## Installation des images

## 1. Démarrer via script ou make
Dans le répertoire du projet:   
`./run.sh`  
ou  
`./run.sh --ssh-key chemin_de_la_cle_ssh` (La clé publique correspondant doit se trouvée dans le container)   
ou  
`make`  

## 2. SSH
`ssh -p 2222 -i ssh_keys/debiantools_id_rsa user@localhost`  
ou  
Lancer le script :  
`./autoconnect.sh`

***

## Clé SSH changée
Si SSH a détecté que la clé d'identité du serveur distant a changé, car le serveur a été réinstallé ou modifié (cas fréquent en développement ou en local).  
Lancer la commande :  
`ssh-keygen -f ~/.ssh/known_hosts -R [localhost]:2222`

## Audit de sécurité
`docker exec -it marmits_ssh sshd -T | grep -E "kex|cipher|macs"`  
=> Doit afficher les algorithmes configurés.

### 🔐 **Points forts la configuration** :
1. **Key Exchange (`kexalgorithms`)** :  
   - `curve25519-sha256@libssh.org` (priorité, le plus sécurisé)  
   - `ecdh-sha2-nistp521`/`nistp384` (backup pour compatibilité)  
   - ✅ **Évite les algorithmes vulnérables** (ex: `diffie-hellman-group1-sha1`).  

2. **Chiffrement (`ciphers`)** :  
   - `chacha20-poly1305@openssh.com` (performant sur mobiles)  
   - `aes256-gcm@openssh.com` (standard robuste)  
   - ✅ **Aucun mode CBC vulnérable** (ex: `aes256-cbc`).  

3. **Intégrité (`macs`)** :  
   - `hmac-sha2-512-etm@openssh.com` (Encrypt-then-MAC, protège contre les attaques par timing)  
   - ✅ **Désactive les MACs obsolètes** (ex: `hmac-sha1`).  

4. **GSSAPI (Kerberos)** :  
   - Bien que listés, ces algorithmes (`gss-group14-sha256-`, etc.) sont **inactifs** sauf si vous utilisez Kerberos.  
   - ℹ️ *Si inutile, désactivez via `GSSAPIAuthentication no` dans `sshd_config`*.

### 📌 **Validation ultime** :
1. **Testez avec différents clients** :  
   ```bash
   ssh -vvv -p 2222 -i ssh_keys/debiantools_id_rsa user@localhost
   ```
   - Vérifiez que la connexion utilise bien `chacha20-poly1305` ou `aes256-gcm`.  

2. **Scan de sécurité** :  
   Utilisez [ssh-audit](https://github.com/jtesta/ssh-audit) pour un audit complet :  
   ```bash
   ssh-audit votre_conteneur
   ```
   - Doit retourner un score **A+** avec votre configuration.

### Exemple de `sshd_config` **ultra-sécurisé** (sans compromis) :  
```ini
# Key Exchange
KexAlgorithms curve25519-sha256@libssh.org

# Chiffrement
Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com

# MACs
MACs hmac-sha2-512-etm@openssh.com

# Désactiver GSSAPI
GSSAPIAuthentication no
```   

## Commandes

### Gestion docker
voir fichiers bash dans répertoire `tools_docker/` du projet.

### Tools or Not

#### PANDOC
Pour convertir du mardown en wiki
- Dans le container, `# cd /datas`  
ex:  
- $ `pandoc -f markdown -t mediawiki volumes.md -o volumes.wikis`

#### CMATRIX
$ `cmatrix -r`

#### COWSAY
- $ `cowsay "Hello, World!"`     
- $ `cowsay -f dragon "I am a dragon! RAWR!"`

#### NYANCAT
- $ `nyancat`

#### GHOSTSCRIPT IMG2PDF PDFTK
- [tools PDF](https://marmits.com/wiki/Linux_tools_PDF)

#### Outils ASCII
- [Outils ASCII](https://marmits.com/wiki/Ascii)

#### Conversion d’une image en ASCII puis en SVG
- [Image => ASCII => SVG](https://marmits.com/wiki/Image_vers_ASCII_vers_SVG)

#### Logiciels pour terminal 
- [Terminal](https://marmits.com/wiki/Cat%C3%A9gorie:Terminal)

#### gist.github.com
1. **Créer le token**
- Connexion sur compte github:
[github.com/settings/tokens](https://github.com/settings/tokens)
- Generate new token (classic)
- Donner une description du token 
- selection des scopes: repo + read.org + gist
- Generate token

2. **Enregistrer le token dans le projet**
- enregistrer le token dans github_token.txt à la racine projet:
```bash
echo "ghp_tokengénéré" > github_token.txt
```

2. (bis)
ou dans `.env.local`  
```bash
echo "GITHUB_TOKEN=ghp_lavaleurdutoken > .env.local
```

3. TEST : 
- Depuis la machine hôte:  
```bash
docker exec -it marmits_ssh gh gist create --public /etc/hosts 
```

- Depuis la machine hôte un fichier sur l'hôte:
```bash
cat unfichier.txt | docker exec -i marmits_ssh gh gist create --public -f "nom_test.txt"
```

- Dans le container:
```bash
sudo gh gist create --public /etc/hosts

# avec alias
gist --help
gist /chemin/unfichier public
gist /chemin/unfichier

```


4. .bashrc (alias)
```bash
#Alias pour envoyer un fichier vers Gist via Docker
docker-gist() {
    # Vérifie que le fichier existe
    if [ -z "$1" ] || [ ! -f "$1" ]; then
        echo -e "\033[31mErreur : Spécifiez un fichier valide\033[0m"
        echo "Usage: docker-gist <fichier> [nom_gist] [--public]"
        echo "Note : --public doit être le dernier argument"
        return 1
    fi

    # Vérifie que Docker est en cours d'exécution
    if ! docker ps | grep -q marmits_ssh; then
        echo -e "\033[31mErreur : Le conteneur marmits_ssh n'est pas démarré\033[0m"
        return 1
    fi

    local filename="$1"
    local gistname
    local visibilite=""

    # Gestion des arguments optionnels
    if [ "$2" = "--public" ]; then
        gistname=$(basename "$filename")
        visibilite="--public"
    elif [ "$3" = "--public" ]; then
        gistname="$2"
        visibilite="--public"
    else
        gistname="${2:-$(basename "$filename")}"
    fi

    # Message de confirmation
    if [ -n "$visibilite" ]; then
        echo -e "\033[32mPublication PUBLIC de $filename en tant que $gistname...\033[0m"
    else
        echo -e "\033[32mPublication PRIVÉE de $filename en tant que $gistname...\033[0m"
    fi

    cat "$filename" | docker exec -i marmits_ssh gh gist create $visibilite -f "$gistname"
}

alias docker-gist='docker-gist'
```


- Gist privé:  
```bash
docker-gist mon_fichier.txt
docker-gist mon_fichier.txt "Nom personnalisé" 
```
- Gist public:  
```bash
docker-gist mon_fichier.txt
docker-gist mon_fichier.txt "Nom personnalisé" --public
```


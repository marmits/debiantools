## gist.github.com
### 1. **Créer le token**
- Connexion sur compte github:
  [github.com/settings/tokens](https://github.com/settings/tokens)
- Generate new token (classic)
- Donner une description du token
- selection des scopes: repo + read.org + gist
- Generate token

### 2. **Enregistrer le token dans le projet**
- enregistrer le token dans github_token.txt à la racine projet:
```bash
echo "ghp_tokengénéré" > github_token.txt
```
- ou **Enregistrer le token dans les secrets (recommandé non-commité)**
```bash
echo "ghp_tokengénéré" > github_token_perso.txt
```

### 3. TEST :
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


### 4.bashrc (alias)
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


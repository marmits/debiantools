## Container docker debian

## Démarrer 
`docker compose up --wait`

### Commandes docker
voir fichiers :
* `docker-stop.sh` => stop et supprime tous les containers
* `docker-clean.sh` => stop, supprime les containers, les images et les volumes

### Extra
Installation de `pandoc` pour convertir du mardown en wiki
- Dans le container, `# cd /datas`  
ex:  
- `pandoc -f markdown -t mediawiki volumes.md -o volumes.wikis`

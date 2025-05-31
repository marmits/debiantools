## Container docker debian 


## Démarrer 
`docker compose up --wait`

## Entrer dans le container
`ssh debian@localhost -p 2222 -i /dir_projet/ssh_keys/debiantools_id_rsa`

### Commandes docker
voir fichiers :
* `docker-stop.sh` => stop et supprime tous les containers
* `docker-clean.sh` => stop, supprime les containers, les images et les volumes

### Extra
Installation de `pandoc` pour convertir du mardown en wiki
- Dans le container, `# cd /datas`  
ex:  
- `pandoc -f markdown -t mediawiki volumes.md -o volumes.wikis`

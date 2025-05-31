## Container docker debian 

## générer une nouvelle paire de clés SSH
dans le répertoire `ssh_keys`
ssh-keygen -t rsa -b 4096

clé privée :  
`ssh_keys/debiantools_id_rsa`

clé publique :  
`ssh_keys/debiantools_id_rsa.pub`

## Démarrer 
`docker compose up --wait`

## Reconstruit proprement
`docker-compose down -v && docker-compose up --build -d`

-v : Supprime aussi les volumes associés (attention, peut effacer des données persistantes).
-d : relance en arrière-plan

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

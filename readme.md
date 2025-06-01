## Container docker debian 
Permet d'utliser un container debian et d'y accéder en ssh.  
Divers outils installés (voir dokerfile)

## Générer une nouvelle paire de clés SSH
dans le répertoire `ssh_keys`  
`ssh-keygen -t rsa -b 4096`

clé privée :  
`ssh_keys/debiantools_id_rsa`

clé publique :  
`ssh_keys/debiantools_id_rsa.pub`

### Description du répertoire datas
- dossier `startup` scripts utlisés lors de la fabrication du container par `docker_entrypoint.sh`  
- dossier `bash` scripts disponibles à éxécuter une fois connecté dans le container.
### Permissions

Ajouter le droit d'éxécution sur les scripts bash dans le répetoire datas :   
`sudo chmod -R +x datas/*`

## Lancer le container
`docker compose up --wait`

## Entrer dans le container
`ssh debian@localhost -p 2222 -i /dir_projet/ssh_keys/debiantools_id_rsa`


## (Raccourci) Démarrer via script ou make
Dans le répertoire du projet:   
`./run.sh --ssh-key chemin_de_la_cle_ssh`   
ou  
`make run SSH_KEY=chemin_de_la_cle_ssh`  

## Reconstruit proprement
`docker-compose down -v && docker-compose up --build -d`
-v : Supprime aussi les volumes associés (attention, peut effacer des données persistantes).
-d : relance en arrière-plan

### Commandes docker
voir fichiers :
* `docker-stop.sh` => stop et supprime tous les containers
* `docker-clean.sh` => stop, supprime les containers, les images et les volumes

### Tools or Not

#### PANDOC
Pour convertir du mardown en wiki
- Dans le container, `# cd /datas`  
ex:  
- $ `pandoc -f markdown -t mediawiki volumes.md -o volumes.wikis`

#### HOLLYWOOD
- Ecran de hacker:   
$ `hollywood`

#### CMATRIX
$ `cmatrix -r`

#### COWSAY
- $ `cowsay "Hello, World!"`     
- $ `cowsay -f dragon "I am a dragon! RAWR!"`

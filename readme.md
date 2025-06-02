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

### entrypoint
- dossier `/startup` scripts utlisés lors de la fabrication du container par `docker_entrypoint.sh`

### Description du répertoire datas
Dossier de données  
- dossier `bash` scripts disponibles à éxécuter une fois connecté dans le container.
### Permissions


## Lancer le container
`docker compose up --wait`

## Entrer dans le container
`ssh debian@localhost -p 2222 -i /dir_projet/ssh_keys/debiantools_id_rsa`


## (Raccourci) Démarrer via script ou make
Dans le répertoire du projet:   
`./run.sh --ssh-key chemin_de_la_cle_ssh`   
ou  
`make run SSH_KEY=chemin_de_la_cle_ssh`  

## Clé SSH changé 
Si SSH a détecté que la clé d'identité du serveur distant a changé, car le serveur a été réinstallé ou modifié (cas fréquent en développement ou en local).  
Lancer la commande :  
`ssh-keygen -f ~/.ssh/known_hosts -R [localhost]:2222`


## Commande 

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

#### CMATRIX
$ `cmatrix -r`

#### COWSAY
- $ `cowsay "Hello, World!"`     
- $ `cowsay -f dragon "I am a dragon! RAWR!"`

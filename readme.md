## Container docker debian 
- Permet d'utliser un container debian et d'y accéder en ssh.
- L'utilisateur est `sudoers` et peut être modifiable via la variable `SSH_USER` du fichier `.env`
- Voir le fichier `.env` pour d'autres variables personnalisables.
- Connexion sans mot de passe avec échange de clés (Générées automiquement)
- Divers outils installés (voir Dokerfile)
- Pull de l'image `debian:latest` puis création d'une image taguée pour éviter de télécharger sur Docker Hub (Re-Build).

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

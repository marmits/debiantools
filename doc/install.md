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

## 3. Clé SSH changée
Si SSH a détecté que la clé d'identité du serveur distant a changé, car le serveur a été réinstallé ou modifié (cas fréquent en développement ou en local).  
Lancer la commande :  
`ssh-keygen -f ~/.ssh/known_hosts -R [localhost]:2222`
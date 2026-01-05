## 🐋 Container docker debian 
⚠️ Ce projet est seulement FUN pour une utilisation locale (aucun interêt en prod).

- Permet d'utliser un container debian et d'y accéder en ssh.
- L'utilisateur est `sudoers` et peut être modifiable via la variable `SSH_USER` du fichier `.env`
- Voir le fichier `.env` pour d'autres variables personnalisables.
- Connexion sans mot de passe avec échange de clés (Générées automiquement)
- Divers outils installés (voir Dokerfile)
- Pull de l'image `debian:latest` puis création d'une image taguée pour éviter de télécharger sur Docker Hub (Re-Build).


## Descriptions
### `/startup`
- Scripts utilisés lors de la fabrication du container par `docker_entrypoint.sh`

### `/datas`
Dossier de données  
- dossier `bash` scripts disponibles à éxécuter une fois connecté dans le container.
- dossier `works` scripts personnalisés pour utiliser les outils installés.

### `/tools_docker`
- Gestion docker

## Installation
- Créer un fichier `.env.local` pour surcharger `.env`
- [doc/install.md](doc/install.md)
- [doc/security_audit.md](doc/security_audit.md)

## Tools or Not
- [doc/tools.md](doc/tools.md)
- [doc/gist.md](doc/gist.md)


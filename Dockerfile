# Build Container Image
# par default debian:latest peut être surchargé via le .env qui transit via compose.yml

# Déclaration des ARG avec valeurs par défaut
ARG BASE_IMAGE=debian:latest
FROM ${BASE_IMAGE} AS ssh

ARG TZ=America/New_York
ARG SSH_USER=debian

LABEL org.opencontainers.image.authors="Marmits" \
      org.opencontainers.image.description="Container image for tools"

# Désactive les prompts interactif
#Force les outils Debian (dpkg, apt) à prendre les valeurs par défaut au lieu de poser des questions.
ENV DEBIAN_FRONTEND=noninteractive

# bonne pratique pour une meilleure gestion des erreurs dans les RUN.
# sert à changer le shell par défaut utilisé pour exécuter les instructions RUN dans le Dockerfile.
# Docker utilise /bin/sh -c pour exécuter les commandes RUN. Ce shell est plus léger, mais moins puissant que bash.
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN apt -y update && apt -y full-upgrade && \
    apt install -y --no-install-recommends locales libicu-dev libpq-dev acl libzip-dev systemd rsyslog netcat-traditional iproute2 iputils-ping dnsutils git && \
    apt install -y wget less curl jq gzip dos2unix ca-certificates tzdata openssl openssh-server sudo nano htop nmap && \
    apt install -y pandoc tmux qrencode bsdmainutils cowsay cmatrix && \
    update-ca-certificates --fresh && \
    ln -fs /usr/share/zoneinfo/$TZ /etc/localtime && \
    echo 'keyboard-configuration keyboard-configuration/layoutcode string fr' > /tmp/debconf-selections && \
    debconf-set-selections /tmp/debconf-selections && \
    rm -f /tmp/debconf-selections && \
    apt clean && apt autoremove --purge && apt autoclean && \
    rm -rf /var/lib/apt/lists/*


# Réactive le mode interactif par défaut (bonne pratique)
ENV DEBIAN_FRONTEND=

RUN echo "en_US.UTF-8 UTF-8" > /etc/locale.gen && \
    echo "fr_FR.UTF-8 UTF-8" >> /etc/locale.gen && \
    locale-gen

# Créer l'utilisateur debian
RUN useradd -m ${SSH_USER} && \
    echo "${SSH_USER}:secret" | chpasswd && \
    echo "${SSH_USER} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers && \
    rm -rf /home/${SSH_USER}/.bash_history
    

# Personnaliser le prompt pour tous les utilisateurs
# Personnaliser le prompt et les alias pour l'utilisateur principal
RUN echo "PS1='\[\e[1;33m\]\D{%H:%M}\[\e[m\] \[\e[47m\e[1;30m\e[7m\] 🐳 \u@\h\[\e[1;31m\]:\[\e[44m\e[1;37m\]\w\[\e[m\]\$ '" >> /home/${SSH_USER}/.bashrc && \
    echo "alias meteo='/datas/bash/meteo.sh'" >> /home/${SSH_USER}/.bashrc && \
    echo "LUNA_CMD='/datas/bash/lune.sh'" >> /home/${SSH_USER}/.bashrc && \
    echo 'alias lune="$LUNA_CMD"' >> /home/${SSH_USER}/.bashrc && \
    echo 'alias moon="$LUNA_CMD"' >> /home/${SSH_USER}/.bashrc && \
    echo "alias i='/datas/bash/infos.sh'" >> /home/${SSH_USER}/.bashrc && \
    # OU pour un utilisateur spécifique (ex: 'root')
    echo "PS1='\[\e[1;33m\]\D{%H:%M}\[\e[m\] \[\e[47m\e[1;31m\e[7m\] 🐳 \u@\h\[\e[1;31m\]:\[\e[44m\e[1;37m\]\w\[\e[m\]\$ '" >> /root/.bashrc



# Configure le répertoire .ssh et copie la clé publique
RUN mkdir -p /home/${SSH_USER}/.ssh && \
    chmod 700 /home/${SSH_USER}/.ssh


RUN --mount=type=secret,id=ssh_pub \
    cat /run/secrets/ssh_pub > /home/${SSH_USER}/.ssh/authorized_keys && \
    chmod 600 /home/${SSH_USER}/.ssh/authorized_keys && \
    chown -R ${SSH_USER}:${SSH_USER} /home/${SSH_USER}/.ssh

# Générer les clés SSH host
RUN ssh-keygen -A

COPY --chmod=600 config/rsyslog-ssh.conf /etc/rsyslog.d/sshd.conf
RUN dos2unix /etc/rsyslog.d/sshd.conf

COPY --chmod=600 config/ssh_config/sshd_config.conf /etc/ssh/sshd_config
RUN dos2unix /etc/ssh/sshd_config

# Copier les fichiers de démarrage pour docker-entrypoint.sh
COPY --chmod=755 startup/ /startup/

# Copier le script d'entrée
COPY --chmod=755 docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN dos2unix /usr/local/bin/docker-entrypoint.sh

#shell par défaut
RUN chsh -s /bin/bash ${SSH_USER}

EXPOSE 22



#Pour les systèmes de supervision (comme Docker Swarm, Kubernetes, Portainer, etc.).
#Pour redémarrer automatiquement un conteneur si le service SSH tombe.
#Pour diagnostiquer des problèmes de santé du conteneur.
HEALTHCHECK --interval=30s --timeout=10s --start-period=10s --retries=3 \
  CMD nc -z localhost 22 || exit 1


ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
#lance un shell interactif
CMD ["/bin/bash -l"]
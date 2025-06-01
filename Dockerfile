# Build Container Image
FROM debian:latest AS tools



LABEL org.opencontainers.image.authors="Marmits" \
      org.opencontainers.image.description="Container image for tools"

      

# Désactive les prompts interactif
#Force les outils Debian (dpkg, apt) à prendre les valeurs par défaut au lieu de poser des questions.
ENV DEBIAN_FRONTEND=noninteractive

RUN apt -y update && apt -y full-upgrade && \
    apt install -y --no-install-recommends locales libicu-dev libpq-dev acl libzip-dev systemd iputils-ping dnsutils git && \
    apt install -y wget curl jq gzip dos2unix ca-certificates tzdata openssl openssh-server sudo nano htop nmap && \
    apt install -y pandoc qrencode bsdmainutils cowsay cmatrix && \
    update-ca-certificates --fresh


#HOLLYWOOD
# Pré-répond aux questions de configuration
RUN echo 'keyboard-configuration keyboard-configuration/layoutcode string fr' | debconf-set-selections \
    && echo 'hollywood hollywood/region select Europe/Paris' | debconf-set-selections

RUN apt install -y --no-install-recommends hollywood

RUN apt clean && \
    apt autoremove --purge && \
    apt autoclean && \
    rm -rf /var/lib/apt/lists/*


# Réactive le mode interactif par défaut (bonne pratique)
ENV DEBIAN_FRONTEND=

RUN echo "en_US.UTF-8 UTF-8" > /etc/locale.gen && \
    echo "fr_FR.UTF-8 UTF-8" >> /etc/locale.gen && \
    locale-gen



# Créer l'utilisateur debian
RUN useradd -m debian && \
    echo "debian:secret" | chpasswd && \
    echo "debian ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
    
# Personnaliser le prompt pour tous les utilisateurs
RUN echo "PS1='\[\e[1;33m\]\D{%H:%M}\[\e[m\] \[\e[47m\e[1;30m\e[7m\] 🐳 \u@\h\[\e[1;31m\]:\[\e[44m\e[1;37m\]\w\[\e[m\]\$ '" >> /home/debian/.bashrc

# OU pour un utilisateur spécifique (ex: 'root')
RUN echo "PS1='\[\e[1;33m\]\D{%H:%M}\[\e[m\] \[\e[47m\e[1;31m\e[7m\] 🐳 \u@\h\[\e[1;31m\]:\[\e[44m\e[1;37m\]\w\[\e[m\]\$ '" >> /root/.bashrc


# Configurer SSH
RUN mkdir -p /home/debian/.ssh && \
    chmod 700 /home/debian/.ssh

# Copier la clé publique dans le conteneur
COPY ssh_keys/debiantools_id_rsa.pub /home/debian/.ssh/authorized_keys

# Définir les bonnes permissions pour le répertoire .ssh et la clé autorisée
RUN chown -R debian:debian /home/debian/.ssh && \
    chmod 600 /home/debian/.ssh/authorized_keys

# Générer les clés SSH host
RUN ssh-keygen -A

# Configurer les options SSH
RUN echo "PasswordAuthentication no" >> /etc/ssh/sshd_config && \
    echo "ChallengeResponseAuthentication no" >> /etc/ssh/sshd_config && \
    echo "PermitRootLogin no" >> /etc/ssh/sshd_config

# Copier le script d'entrée
COPY --link --chmod=755 docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN dos2unix /usr/local/bin/docker-entrypoint.sh

RUN chsh -s /bin/bash debian

EXPOSE 22

WORKDIR /
RUN dos2unix /usr/local/bin/docker-entrypoint.sh


#WORKDIR /home/debian
#USER debian

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]

#lance un shell interactif 
CMD ["/bin/bash -l"]
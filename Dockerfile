# Build Container Image
FROM debian:latest AS tools

LABEL org.opencontainers.image.authors="Marmits" \
      org.opencontainers.image.description="Container image for tools"


RUN apt -y update && apt -y full-upgrade && \
    apt install -y --no-install-recommends locales libicu-dev libpq-dev acl libzip-dev systemd iputils-ping dnsutils git && \
    apt install -y wget curl jq gzip dos2unix ca-certificates tzdata openssl openssh-server sudo nano htop && \
    apt install -y pandoc && \
    update-ca-certificates --fresh

RUN echo "en_US.UTF-8 UTF-8" > /etc/locale.gen && \
    echo "fr_FR.UTF-8 UTF-8" >> /etc/locale.gen && \
    locale-gen


# Créer l'utilisateur debian
RUN useradd -m debian && \
    echo "debian:secret" | chpasswd && \
    echo "debian ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers


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
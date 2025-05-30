# Build Container Image
FROM debian:latest AS tools

LABEL org.opencontainers.image.authors="Marmits" \
      org.opencontainers.image.description="Container image for tools"


RUN apt -y update && apt -y full-upgrade && \
    apt install -y --no-install-recommends locales libicu-dev libpq-dev acl libzip-dev systemd iputils-ping dnsutils git && \
    apt install -y wget jq gzip dos2unix ca-certificates tzdata openssl sudo nano && \
    apt install -y pandoc && \
    update-ca-certificates --fresh

RUN echo "en_US.UTF-8 UTF-8" > /etc/locale.gen && \
    echo "fr_FR.UTF-8 UTF-8" >> /etc/locale.gen && \
    locale-gen

    # 1. Créer l'utilisateur "debian" sans home directory et sans shell de login
RUN useradd --shell /usr/sbin/nologin debian && \
    mkdir /home/debian && \
    chown debian:debian /home/debian && \
    chmod 755 /home/debian && \
    usermod -aG sudo debian && \
    mkdir -p /etc/sudoers.d && \
    echo "debian ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/debian-nopasswd && \
    chmod 0440 /etc/sudoers.d/debian-nopasswd && \
    grep debian /etc/group && sudo -l -U debian


#lance un shell interactif au démarrage
COPY --link --chmod=755 docker-entrypoint.sh /usr/local/bin/docker-entrypoint

WORKDIR /
RUN dos2unix /usr/local/bin/docker-entrypoint

WORKDIR /home/debian
USER debian

ENTRYPOINT ["docker-entrypoint"]
CMD ["/bin/bash"]


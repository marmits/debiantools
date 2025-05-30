#!/bin/sh
set -e

touch /home/debian/test.txt
chmod 755 /home/debian/test.txt

mkdir -p /home/debian/datas
chown debian:debian /home/debian/datas

echo "un contenu généré au démarrage" > /home/debian/test.txt
exec docker-entrypoint "$@"
#!/bin/sh
# Utilise TZ soit de l'environnement, soit valeur par défaut
source /datas/startup/config.env 2>/dev/null || true
ACTUAL_TZ="${TZ:-Europe/Paris}"

cat > /etc/update-motd.d/10-custom-banner << 'EOF'
#!/bin/sh
if [ -f "/datas/bash/infos.sh" ]; then
  /datas/bash/infos.sh
fi
EOF

chmod +x /etc/update-motd.d/10-custom-banner
rm -f /etc/motd
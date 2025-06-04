#!/bin/sh
# Utilise TZ soit de l'environnement, soit valeur par défaut
source /datas/startup/config.env 2>/dev/null || true
ACTUAL_TZ="${TZ:-Europe/Paris}"

cat > /etc/update-motd.d/10-custom-banner << 'EOF'
#!/bin/sh
cat << 'ART'
     _        _      _                 _                 _
  __| |  ___ | |__  (_)  __ _  _ __   | |_  ___    ___  | | ___
 / _` | / _ \| '_ \ | | / _` || '_ \  | __|/ _ \  / _ \ | |/ __|
| (_| ||  __/| |_) || || (_| || | | | | |_| (_) || (_) || |\__ \
 \__,_| \___||_.__/ |_| \__,_||_| |_|  \__|\___/  \___/ |_||___/

ART
echo "----------------------------------------------"
echo "  Bienvenue sur $(hostname)"
echo "  Date: $(date -d "TZ=\"$ACTUAL_TZ\" now")" 
echo "  Uptime hôte: $(uptime -p)"
echo "  Uptime conteneur: $(cat /tmp/container_uptime 2>/dev/null || echo 'N/A')"
echo "----------------------------------------------"
EOF

chmod +x /etc/update-motd.d/10-custom-banner
rm -f /etc/motd
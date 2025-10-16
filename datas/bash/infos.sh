#!/bin/bash
echo -e "\e[1;31m$(cat << 'ART'
     _        _      _                 _                 _
  __| |  ___ | |__  (_)  __ _  _ __   | |_  ___    ___  | | ___
 / _` | / _ \| '_ \ | | / _` || '_ \  | __|/ _ \  / _ \ | |/ __|
| (_| ||  __/| |_) || || (_| || | | | | |_| (_) || (_) || |\__ \
 \__,_| \___||_.__/ |_| \__,_||_| |_|  \__|\___/  \___/ |_||___/
ART
)\e[0m"
echo -e "\e[1;34m🧢🧢🧢🧢🧢🧢🧢🧢🧢🧢🧢🧢🧢🧢🧢🧢🧢🧢🧢🧢🧢🧢🧢🧢🧢🧢🧢🧢🧢🧢🧢🧢\e[0m"
echo -e "\e[1;34m💣💣💣💣💣💣💣💣💣💣💣💣💣💣💣💣💣💣💣💣💣💣💣💣💣💣💣💣💣💣💣💣\e[0m"
echo -e "  \e[1;31mWelcome... $(logname)!\e[0m on $(hostname)"
echo -e "  Date: \e[1;36m$(date -d "TZ=\"$ACTUAL_TZ\" now")\e[0m"
echo "  Uptime hôte: $(uptime -p)"
echo -e "  Uptime container: \e[1;32m$(cat /tmp/container_uptime 2>/dev/null || echo 'N/A')\e[0m"
echo "  shell: $SHELL"
echo "  $(bash --version | head -n 1)"
echo -e "\e[1;34m💣💣💣💣💣💣💣💣💣💣💣💣💣💣💣💣💣💣💣💣💣💣💣💣💣💣💣💣💣💣💣💣\e[0m"
fastfetch

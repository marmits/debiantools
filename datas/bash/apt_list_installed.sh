#!/bin/bash

# Titre en cyan
echo -e "\033[1;36mManually installed packages :\033[0m"

# Résultat en cyan
echo -e "\033[0;36m$(apt-mark showmanual | sort | paste -sd ' ' -)\033[0m"
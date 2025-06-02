#!/bin/bash

echo -e "\n=== Test d'encodage UTF-8 et d'affichage ===\n"

echo -e "Emoji test : 🐳 🚀 💻 🔥 ✅ ❌"
echo -e "Unicode test : é è à ç ñ ü Ω π ∞"
echo -e "Couleurs ANSI :"

echo -e "\e[1;31mRouge clair\e[0m"
echo -e "\e[1;32mVert clair\e[0m"
echo -e "\e[1;33mJaune clair\e[0m"
echo -e "\e[1;34mBleu clair\e[0m"
echo -e "\e[1;35mMagenta clair\e[0m"
echo -e "\e[1;36mCyan clair\e[0m"
echo -e "\e[1;37mBlanc brillant\e[0m"

echo -e "\nFond coloré :"
echo -e "\e[47m\e[30m Texte noir sur fond gris clair \e[0m"
echo -e "\e[44m\e[37m Texte blanc sur fond bleu \e[0m"

echo -e "\nPrompt personnalisé :"
echo -e "\e[1;33m$(date +%H:%M)\e[0m \e[47m\e[1;30m\e[7m 🐳 user@host\e[0m:\e[44m\e[1;37m~/chemin\e[0m\$"

echo -e "\n=== Fin du test ===\n"

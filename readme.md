## Container docker debian

## Démarrer 
`docker compose up --wait`

### Extra
Installation de `pandoc` pour convertir du mardown en wiki
- Dans le container, `# cd /datas`  
ex:  
- `pandoc -f markdown -t mediawiki volumes.md -o volumes.wikis`

Parfait, avec **MediaWiki**, la bonne nouvelle c’est que *rien n’est bloqué par défaut* et que tu peux ajouter proprement tous les en‑têtes manquants via ton serveur Web (Apache/Nginx).  
MediaWiki n’a aucun problème particulier avec ces headers, **à condition d’ajuster la CSP** si tu utilises des extensions (VisualEditor, MathJax, etc.).

Voici ce que tu dois savoir 👇

***

# 🛠️ En‑têtes HTTP recommandés pour MediaWiki

## ✅ 1. HSTS (Strict‑Transport‑Security)

**Totalement compatible.**

    Strict-Transport-Security: max-age=63072000; includeSubDomains; preload

👉 Active-le **uniquement si ton site force HTTPS partout**.

***

## ✅ 2. X‑Frame‑Options

Pour MediaWiki, aucun problème :

    X-Frame-Options: DENY

Si tu veux ALLOW-FROM (site d’intranet par exemple), tu peux, mais `DENY` est le plus sûr.

***

## 👉 3. CSP (Content-Security-Policy)

C’est **le seul header qui demande de l’attention**, car MediaWiki charge parfois :

*   scripts internes `/resources/…`
*   éventuellement jQuery (inclus)
*   extensions : VisualEditor, Math, SyntaxHighlight, etc.
*   éventuellement des CDN si tu en ajoutes

⚠️ Donc **ne mets pas un CSP trop restrictive immédiatement**, sinon tu risques de casser l’interface (ex : bouton Éditer qui disparaît).

### 🔒 CSP *minimaliste* mais fonctionnelle pour MediaWiki vanilla :

    Content-Security-Policy:
     default-src 'self';
     img-src 'self' data:;
     style-src 'self' 'unsafe-inline';
     script-src 'self';
     object-src 'none';
     base-uri 'self';

👉 Ça marche pour un MediaWiki “basique”.

Si tu utilises **VisualEditor ou Parsoid**, il faut adapter (je peux te le générer selon tes modules).

***

# 🧩 4. X‑XSS‑Protection

Obsolète. Tu peux le mettre pour les vieux navigateurs :

    X-XSS-Protection: 1; mode=block

Mais honnêtement, CSP fait le job.

***

# 📌 Comment les ajouter ?

## 🔧 Si tu es sous **Apache**

    Header set Strict-Transport-Security "max-age=63072000; includeSubDomains; preload"
    Header set X-Frame-Options "DENY"
    Header set X-Content-Type-Options "nosniff"
    Header set X-XSS-Protection "1; mode=block"
    Header set Content-Security-Policy "default-src 'self'; img-src 'self' data:; style-src 'self' 'unsafe-inline'; script-src 'self'; object-src 'none'; base-uri 'self';"

***

## 🔧 Si tu es sous **Nginx**

    add_header Strict-Transport-Security "max-age=63072000; includeSubDomains; preload" always;
    add_header X-Frame-Options "DENY" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Content-Security-Policy "default-src 'self'; img-src 'self' data:; style-src 'self' 'unsafe-inline'; script-src 'self'; object-src 'none'; base-uri 'self';" always;

***

# 👍 Conclusion

👉 **Oui**, ton check montre des lacunes,  
👉 **Non**, ce n’est pas “grave urgent”… mais **c’est important à corriger** pour durcir ton MediaWiki.

Le seul point délicat = **CSP**, car elle dépend des extensions activées.

***

# 🎯 Si tu veux une CSP parfaite et sur mesure :

Dis-moi :

1.  **Version de MediaWiki**
2.  **Les extensions que tu utilises**
3.  **Ton serveur web : Apache ou Nginx**
4.  **Si VisualEditor/Parsoid est activé**



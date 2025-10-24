`docker exec -it marmits_ssh sshd -T | grep -E "kex|cipher|macs"`  
=> Doit afficher les algorithmes configurés.

### 🔐 **Points forts la configuration** :
1. **Key Exchange (`kexalgorithms`)** :
    - `curve25519-sha256@libssh.org` (priorité, le plus sécurisé)
    - `ecdh-sha2-nistp521`/`nistp384` (backup pour compatibilité)
    - ✅ **Évite les algorithmes vulnérables** (ex: `diffie-hellman-group1-sha1`).

2. **Chiffrement (`ciphers`)** :
    - `chacha20-poly1305@openssh.com` (performant sur mobiles)
    - `aes256-gcm@openssh.com` (standard robuste)
    - ✅ **Aucun mode CBC vulnérable** (ex: `aes256-cbc`).

3. **Intégrité (`macs`)** :
    - `hmac-sha2-512-etm@openssh.com` (Encrypt-then-MAC, protège contre les attaques par timing)
    - ✅ **Désactive les MACs obsolètes** (ex: `hmac-sha1`).

4. **GSSAPI (Kerberos)** :
    - Bien que listés, ces algorithmes (`gss-group14-sha256-`, etc.) sont **inactifs** sauf si vous utilisez Kerberos.
    - ℹ️ *Si inutile, désactivez via `GSSAPIAuthentication no` dans `sshd_config`*.

### 📌 **Validation ultime** :
1. **Testez avec différents clients** :
   ```bash
   ssh -vvv -p 2222 -i ssh_keys/debiantools_id_rsa user@localhost
   ```
    - Vérifiez que la connexion utilise bien `chacha20-poly1305` ou `aes256-gcm`.

2. **Scan de sécurité** :  
   Utilisez [ssh-audit](https://github.com/jtesta/ssh-audit) pour un audit complet :
   ```bash
   ssh-audit votre_conteneur
   ```
    - Doit retourner un score **A+** avec votre configuration.

### Exemple de `sshd_config` **ultra-sécurisé** (sans compromis) :
```ini
# Key Exchange
KexAlgorithms curve25519-sha256@libssh.org

# Chiffrement
Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com

# MACs
MACs hmac-sha2-512-etm@openssh.com

# Désactiver GSSAPI
GSSAPIAuthentication no
```   
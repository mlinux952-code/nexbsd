# T-04-E — Samba authentifie via l'annuaire OpenLDAP — **EN COURS**

**Protocole exécutable :** `scripts/62-banc-T04E-samba-ldap.sh` (blocs A→F, verdict en fin).
**Prérequis :** T-04 réussi (slapd tourne, annuaire peuplé) — obtenu le 2026-10-24.
**Banc :** VM `nexbsd-test`, console série, réseau user `10.0.2.15`.

## 1. Ce que le test doit démontrer

| Bloc | Preuve attendue |
|---|---|
| A | `slapd` tourne, Samba installé |
| B | Samba compilé avec le support LDAP (`WITH_LDAP`) |
| C | `samba.schema` chargé par `slapd` |
| D | conteneurs `ou=groups/computers/idmap` présents |
| E | `smb4.conf` en `passdb backend = ldapsam:ldap://127.0.0.1`, compte ajouté |
| F1 | `pdbedit -L -v omrane` remonte le compte avec un SID |
| F2 | `ldapsearch` montre `sambaSID` **dans l'annuaire** |
| F3 | `smbclient //127.0.0.1/partage -U omrane%…` **authentifie** |

## 2. Identifiants de laboratoire

| Élément | Valeur |
|---|---|
| Domaine Samba | `NEXBSD` (netbios `NEXBSDFS`) |
| Compte | `omrane` / `omranelab` — **laboratoire uniquement** |
| Partage | `//127.0.0.1/partage` → `/var/samba/partage` |

## 3. Journal d'exécution

_(vide — sortie verbatim à coller après exécution)_

## 4. Verdict

**NON CONCLU** — script écrit, `sh -n` OK, **jamais exécuté à ce jour**.

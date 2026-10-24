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

### Essai 1 — 2026-10-24 12:05 UTC — **ECHEC**

Banc : VM `nexbsd-test`, FreeBSD 15.1-RELEASE. Script `62` **version 1**. Samba installé : `samba423-4.23.11_3-Free`.

```
########## BLOC A - prerequis ##########
  [OK]    slapd tourne
  ...     samba absent : installation
  [OK]    samba present : samba423-4.23.11_3-Free

########## BLOC B - Samba a-t-il le support LDAP ? ##########
  ...     smbd -b ne montre pas WITH_LDAP : la suite dira si ldapsam fonctionne

########## BLOC C - schema samba dans l'annuaire ##########
  [ECHEC] samba.schema introuvable : le compte ne pourra pas etre stocke dans l'annuaire
  [OK]    include du schema ajoute a slapd.conf
  [ECHEC] slapd ne redemarre pas avec le schema : restauration

########## BLOC D - conteneurs et domaine dans l'annuaire ##########
  [OK]    conteneurs samba crees

########## BLOC E - configuration de Samba en ldapsam ##########
  [OK]    smb4.conf ecrit (passdb = ldapsam)
  [OK]    mot de passe d'administration LDAP enregistre dans secrets.tdb
  [ECHEC] smbpasswd -a a echoue :
add_new_domain_info: failed to add domain dn= sambaDomainName=NEXBSDFS,dc=nexbsd,dc=local with: Invalid DN syntax
        invalid DN
smbldap_search_domain_info: Adding domain info for NEXBSDFS failed with NT_STATUS_UNSUCCESSFUL
pdb_init_ldapsam: WARNING: Could not get domain info, nor add one to the domain. We cannot work reliably without it.
pdb backend ldapsam:ldap://127.0.0.1 did not correctly init (error was NT_STATUS_CANT_ACCESS_DOMAIN_INFO)
Failed to open passdb!
  [ECHEC] smbd ne tourne pas

########## BLOC F - PREUVES ##########
  [ECHEC] Samba ne remonte pas le compte
  [ECHEC] aucun attribut samba dans l'annuaire   (ldapsearch => result: 0 Success, dn present, 0 attribut samba)
  [ECHEC] authentification SMB refusee : NT_STATUS_CONNECTION_REFUSED

########## VERDICT ##########
T-04-E : ECHEC - voir les lignes [ECHEC] ci-dessus.
```

**Analyse (trois causes distinctes) :**

| # | Symptôme | Cause établie | Correctif en v2 |
|---|---|---|---|
| 1 | `samba.schema introuvable` | le **paquet** FreeBSD `samba423` ne livre aucun fichier `.schema` (vérifié dans `pkg-plist` du port) | téléchargement depuis `git.samba.org` + **SHA256 vérifiée** |
| 2 | `slapd ne redemarre pas` | **défaut du script v1** : la ligne `include` était ajoutée même sans schéma → fichier absent → slapd refuse | `include` ajouté seulement si le schéma existe ; **`slaptest -u` avant tout redémarrage** ; restauration automatique |
| 3 | `Invalid DN syntax` sur `sambaDomainName` | sans `samba.schema`, l'attribut `sambaDomainName` n'existe pas dans le schéma → DN invalide | conséquence de 1 |

**Point important : l'annuaire T-04 n'a pas été abîmé** — la preuve 2 montre `ldapsearch` répondant `result: 0 Success` et retrouvant `uid=omrane`. La restauration de `slapd.conf` a fonctionné.

**Provenance du schéma (vérifiée, jamais commitée dans le dépôt)** : `https://git.samba.org/?p=samba.git;a=blob_plain;f=examples/LDAP/samba.schema;hb=HEAD`
→ 23 182 octets, 82 `attributetype`, 27 `objectclass`, `sambaDomainName` présent, SHA256 `b9081b7234762c3fc02861fbb88ed8b52a523dced38e15051dc980f0b34b23dd`. Licence Samba (GPL-3.0+) : **reste hors du dépôt NexBSD** (frontière de licences, `docs/12`).

### Essai 2 — à exécuter avec le script v2

_(vide)_

## 4. Verdict

**ECHEC à l'essai 1** (2026-10-24 12:05 UTC), causes identifiées et corrigées dans le script **v2**. Essai 2 à exécuter.

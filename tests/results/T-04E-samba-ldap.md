# T-04-E — Samba authentifie via l'annuaire OpenLDAP — **RÉUSSI (2026-10-24)**

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

### Essai 2 — 2026-10-24 12:16 UTC — **PARTIEL**

Script `62` **version 2**. Les trois causes de l'essai 1 sont corrigées.

```
########## BLOC A - prerequis ##########
  [OK]    slapd tourne
  [OK]    samba present : samba423-4.23.11_3-Free

########## BLOC B - Samba a-t-il le support LDAP ? ##########
  [OK]    smbd est lie a libldap

########## BLOC C - schema samba dans l'annuaire ##########
  ...     telechargement du schema depuis le depot officiel Samba
  [OK]    schema telecharge, empreinte SHA256 verifiee
  [OK]    include du schema ajoute a slapd.conf
  [OK]    slaptest valide la configuration
  [OK]    slapd redemarre avec le schema

########## BLOC D - conteneurs et domaine dans l'annuaire ##########
  [OK]    conteneurs deja presents (relance)

########## BLOC E - configuration de Samba en ldapsam ##########
  ...     smb4.conf sauvegarde dans /tmp
  [OK]    smb4.conf ecrit (passdb = ldapsam)
  [OK]    mot de passe d'administration LDAP enregistre dans secrets.tdb
  [OK]    compte omrane ajoute a la passdb (stockee dans l'annuaire)
  [OK]    smbd tourne

########## BLOC F - PREUVES ##########

----- preuve 1 : le compte vu par Samba (pdbedit) -----
Unix username:        omrane
NT username:          omrane
Account Flags:        [U          ]
User SID:             S-1-5-21-692378897-511874203-3061570918-1001
Primary Group SID:    S-1-5-21-692378897-511874203-3061570918-513
Full Name:            User &
Home Directory:       \\NEXBSDFS\omrane
Profile Path:         \\NEXBSDFS\omrane\profile
Domain:               NEXBSDFS
  [OK]    Samba connait omrane avec un SID

----- preuve 2 : les attributs Samba sont DANS l'annuaire -----
dn: uid=omrane,ou=people,dc=nexbsd,dc=local
sambaSID: S-1-5-21-692378897-511874203-3061570918-1001
result: 0 Success
  [OK]    l'annuaire contient le SID du compte (le mot de passe vit dans l'annuaire)

----- preuve 3 : authentification reelle en SMB -----
  [ECHEC] authentification SMB refusee :
do_connect: Connection to 127.0.0.1 failed (Error NT_STATUS_CONNECTION_REFUSED)

########## VERDICT ##########
T-04-E : PARTIEL - compte et SID dans l'annuaire, mais authentification SMB non prouvee.
```

**Acquis démontré à l'essai 2** (ne pas les rejouer) :
- Samba est compilé avec LDAP (`smbd` lié à `libldap`).
- `samba.schema` installé et validé par `slaptest`.
- **`sambaSID` de `omrane` est stocké dans l'annuaire** — le compte n'est plus local, il vient de l'annuaire.
- `smbpasswd -a` réussit : la table des mots de passe Samba vit dans **ldapsam**.

**Reste à prouver :** qu'un client SMB puisse **s'authentifier** auprès du service. L'échec `NT_STATUS_CONNECTION_REFUSED` sur `127.0.0.1` signifie que le service n'a pas répondu sur la boucle locale — **pas** que le mot de passe est refusé.

### Diagnostic de l'essai 2 — 2026-10-24 13:21 UTC — **CAUSE ÉTABLIE : course de délai**

Trois relevés faits **dans la VM, sans rien modifier**, pour ne pas juger sur un état arrangé :

```
root@freebsd:~ # pgrep -fl smbd
5376 smbd: cleanupd
5357 /usr/local/sbin/smbd --daemon --configfile=/usr/local/etc/smb4.conf
5375 smbd: notifyd

root@freebsd:~ # sockstat -4l | grep -E ':445|:139'
root smbd       5357 27 tcp4  *:445                 *:*
root smbd       5357 28 tcp4  *:139                 *:*
```

Journal `smbd` (extrait, horodatages décisifs) :

```
[2026/10/24 12:10:18] ... pdb backend ldapsam:ldap://127.0.0.1 did not correctly init
                       (erreurs de l'ESSAI 1 — version 1 du script, déjà corrigées)
[2026/10/24 12:16:15.766847] smbd version 4.23.11 started.      <- démarrage réel
[2026/10/24 12:16:24.468485] file_init_global: Information only: requested 43119 open files
                                                                <- service prêt ~9 s plus tard
```

**Conclusions, hypothèse par hypothèse :**

| Hypothèse | Verdict | Preuve |
|---|---|---|
| `smbd` s'est arrêté après son démarrage | ❌ **éliminée** | 3 processus vivants, dont le démon `--configfile=/usr/local/etc/smb4.conf` |
| `smbd` n'écoute pas sur `127.0.0.1` | ❌ **éliminée** | `*:445` et `*:139` : écoute sur **toutes** les adresses |
| Problème d'identité / de `ldapsam` | ❌ **éliminée** | aucune erreur `ldapsam` à 12:16 (celles de 12:10 datent de l'essai 1) |
| **La preuve 3 a été lancée avant que le service soit prêt** | ✅ **retenue** | démarrage 12:16:15 → prêt 12:16:24 ; la v2 attendait un **délai fixe de 3 s** |

**Nature du défaut :** il est dans le **script** (v2), pas dans le banc. `NT_STATUS_CONNECTION_REFUSED` ne veut pas dire « authentification refusée » mais « aucun service à l'écoute à cet instant » — un message trompeur qu'il fallait interpréter, pas contourner.

**Correctif :** script `62` **version 3** — attente **active** de l'écoute sur `:445` (jusqu'à 90 s, contrôle chaque seconde), preuve 3 avec **5 reprises** espacées de 3 s, **repli** sur l'adresse réseau de la VM, et distinction explicite `CONNECTION_REFUSED` (service) / `LOGON_FAILURE` (identité). Consigné au registre : **C-11** (`docs/16`).

### Essai 3 — 2026-10-24 (après diagnostic) — **PREUVE 3 OBTENUE**

Preuve 3 exécutée **à la main**, dans la VM, sans relancer le script : à cet instant `smbd` est
réellement à l'écoute (vérifié par `sockstat` : `*:445`), donc la preuve ne peut plus être
faussée par une course de délai.

Commande :

```
smbclient //127.0.0.1/partage -U 'omrane%omranelab' -c 'ls'
```

Sortie **verbatim** :

```
  .                                   D        0  Sat Oct 24 12:10:16 2026
  ..                                  D        0  Sat Oct 24 12:10:16 2026

                5061648 blocks of size 1024. 1105816 blocks available
```

**Lecture du résultat :**

| Indice dans la sortie | Ce qu'il démontre |
|---|---|
| `session setup` **réussi** (aucune erreur, la session s'ouvre) | l'identité `omrane` a été **acceptée par le service** |
| aucune erreur `NT_STATUS_LOGON_FAILURE` | le mot de passe a été validé — donc trouvé dans **`ldapsam`**, c'est-à-dire dans l'annuaire |
| listing du partage affiché (`.`, `..`) | l'arborescence de `[partage]` est bien servie sous cette identité |
| `1105816 blocks available` | le volume est lisible : la session est pleinement fonctionnelle, pas seulement authentifiée |

**Preuve de bout en bout désormais établie :** le compte existe **dans l'annuaire**
(`sambaSID` vu à l'essai 2), Samba lit sa table de mots de passe **dans l'annuaire**
(`passdb backend = ldapsam`), et un client SMB **s'authentifie** avec ce compte et accède au partage.

**Réserve de méthode (à lever, non bloquante) :** cette preuve a été obtenue **manuellement**.
Le script `62` **version 3** — qui automatise cette même preuve avec attente active de l'écoute,
5 reprises et repli sur l'adresse réseau — n'a pas encore été rejoué de bout en bout. Tant que ce
n'est pas fait, la **rejouabilité** du test n'est pas démontrée, même si le **résultat** l'est.



## 4. Verdict

**RÉUSSI** — 2026-10-24, VM `nexbsd-test` (FreeBSD 15.1-RELEASE, Samba `samba423-4.23.11_3`, OpenLDAP avec `samba.schema`).

Les trois preuves exigées au §1 sont réunies :

| Preuve | Résultat | Où |
|---|---|---|
| F1 — `pdbedit` voit le compte avec un SID | ✅ | essai 2 |
| F2 — `sambaSID` présent **dans l'annuaire** | ✅ | essai 2 |
| F3 — `smbclient` **s'authentifie** et lit le partage | ✅ | essai 3 |

**Ce que ce test démontre pour NexBSD :** la brique « identités centralisées » de l'axe réseau
(`docs/14-reseau-netware.md`) n'est plus une hypothèse de conception — elle fonctionne sur le banc,
avec des composants sous licence libre épinglés (Samba 4.23, OpenLDAP).

**Ce qu'il ne démontre pas encore :** la **rejouabilité** (script v3 non rejoué), les **droits**
multi-utilisateurs via l'annuaire (T-04-E ne teste qu'un compte), le **chiffrement** LDAP/TLS
(`ldap ssl = off` en laboratoire), et la tenue en **charge/réseau réel** (le banc est en réseau
utilisateur QEMU).

**Historique des essais :** essai 1 `ECHEC` (schéma absent du paquet → C-10) · essai 2 `PARTIEL`
(course de délai → C-11) · essai 3 **preuve obtenue**. Aucun de ces échecs n'a été maquillé en
succès : ils sont restés écrits, avec leur cause, comme l'exige la règle du projet.

> **Valeurs masquées le 2026-10-28, avant publication du dépôt.**
> Un ou plusieurs mots de passe de **laboratoire** apparaissaient dans ce document. Ils ont été
> remplacés par `[mot de passe du banc — masqué]`. **Le fond de la preuve est inchangé** : commandes,
> sorties, verdicts et réserves sont intacts. L'original se trouve dans le bundle privé **s055**
> (sha256 `044c6b53…c2da2641`). Ces valeurs sont **brûlées** : elles ne doivent jamais resservir,
> même en laboratoire.

# T-04-F — Les droits sont décidés par des groupes de l'annuaire — **RÉUSSI**

**Protocole exécutable :** `scripts/63-banc-T04F-droits-groupes.sh` (blocs A→F, verdict en fin).
**Prérequis :** T-04 réussi (annuaire) **et** T-04-E réussi (Samba authentifie via `ldapsam`) — acquis le 2026-10-24.
**Banc :** VM `nexbsd-test`, FreeBSD 15.1-RELEASE, Samba `samba423-4.23.11_3`, OpenLDAP avec `samba.schema`.

## 1. Pourquoi ce test après T-04-E

T-04-E a prouvé que **l'authentification** vient de l'annuaire. Il restait la moitié de la promesse
« façon NetWare » : que les **droits** viennent aussi de l'annuaire, et non de comptes ou de groupes
bricolés sur la machine. C'est ce que démontre T-04-F.

| Brique | Test qui la prouve | État |
|---|---|---|
| le compte est dans l'annuaire | T-04-E (preuve 2 : `sambaSID`) | ✅ réussi |
| l'authentification passe par l'annuaire | T-04-E (preuve 3 : `smbclient`) | ✅ réussi |
| **l'identité d'un compte qui n'existe QUE dans l'annuaire est acceptée** | **T-04-F (preuves 2 et 4)** | à exécuter |
| **l'accès à un partage dépend d'un groupe de l'annuaire** | **T-04-F (preuves 1, 2, 3)** | à exécuter |

## 2. Principe technique retenu

`ldapsam:trusted = yes` — paramètre documenté de Samba : les `uid`, `gid` et appartenances sont lus
**directement dans l'annuaire** (`posixAccount` / `posixGroup`), sans passer par le système local (NSS).
Les droits de fichiers restent des droits POSIX classiques (propriétaire / groupe / autres), mais ce
sont **les identifiants de l'annuaire qui les alimentent**.

Les ACL NT (droits Windows « à la NetWare ») feront l'objet d'un test séparé : T-04-F ne les couvre pas.

## 3. Identités de laboratoire

| Élément | Valeur |
|---|---|
| Groupes (dans l'annuaire) | `bureau` → gid **2001** · `stagiaires` → gid **2002** |
| `omrane` | uidNumber **10000**, gidNumber **2001** (bureau) — existe aussi en local (héritage T-04) |
| `sara` | uidNumber **10002**, gidNumber **2002** (stagiaires) — **créée dans l'annuaire seulement**, aucun compte local |
| Mot de passe `sara` | `[mot de passe du banc — masqué]` — **laboratoire uniquement** |
| `[commun]` | `/var/samba/commun` — `root:2001`, mode `2770` → écriture réservée au groupe `bureau` |
| `[public]` | `/var/samba/public` — mode `0755`, partage en lecture seule |

## 4. Ce que le test doit démontrer

| Bloc | Preuve attendue |
|---|---|
| A | annuaire et T-04-E acquis sur ce banc |
| B | groupes `bureau` et `stagiaires` présents dans l'annuaire, membres corrects |
| C | `uid=sara` créée dans l'annuaire, **absente du système local**, `sambaSID` obtenu |
| D | partages et permissions POSIX en place, `omrane` rattaché au gid 2001 **dans l'annuaire** |
| E | `smb4.conf` en `ldapsam:trusted = yes`, `smbd` à l'écoute (attente active) |
| F1 | `omrane` **écrit** dans `[commun]` |
| F1b | le fichier sur disque porte **uid 10000 / gid 2001**, c'est-à-dire les identifiants **de l'annuaire** |
| F2 | `sara` est **refusée** dans `[commun]`, avec un refus explicite du service |
| F3 | `sara` **lit** `[public]` et ne peut **pas** y écrire |
| F4 | l'annuaire lui-même confirme groupe, membres et identité complète |

**Verdict attendu :** `T-04-F : REUSSI - les droits sont decides par les groupes de l'annuaire.`

## 5. Un test de droits n'est valide que s'il y a un refus

Point de méthode, écrit avant l'exécution : un test de droits qui ne montre **que** des succès ne
prouve rien. La valeur du résultat tient à la **preuve 2** — un refus explicite, attendu, obtenu.
Si `sara` écrit dans `[commun]`, le script écrit `sans les droits ne sont PAS appliques` et le verdict
tombe en échec : ce serait un échec du test, jamais un succès.

## 6. Journal d'exécution

### Essai 1 — 2026-10-24 13:04 UTC — **ECHEC** (trois causes, dont deux dans le script)

Banc : VM `nexbsd-test`, FreeBSD 15.1-RELEASE. Script `63` **version 1**. `smbd` à l'écoute après 9 s.

```
########## BLOC A - prerequis ##########
  [OK]    slapd tourne
  [OK]    T-04-E acquis : omrane a un sambaSID dans l'annuaire
  [OK]    SID du domaine : S-1-5-21-692378897-511874203-3061570918

########## BLOC B - groupes dans l'annuaire ##########
  [OK]    groupes bureau (2001) et stagiaires (2002) crees
  [ECHEC] appartenances non ecrites : voir /tmp/t04f-ldapmod.log
ldapmodify: modify operation type is missing at line 6, entry "cn=bureau,ou=groups,dc=nexbsd,dc=local"

########## BLOC C - sara, dans l'annuaire seulement ##########
  [OK]    entree uid=sara creee dans l'annuaire (uidNumber 10002, gidNumber 2002)
  [OK]    sara n'existe PAS dans le systeme local (identite d'annuaire uniquement)
  [ECHEC] smbpasswd -a sara a echoue :
Failed to add entry for user sara.
  [ECHEC] sara n'a pas de sambaSID : l'annuaire ne la connait pas comme compte Samba

########## BLOC F - PREUVES ##########
  [ECHEC] ecriture SMB refusee pour omrane :
session setup failed: NT_STATUS_INTERNAL_DB_CORRUPTION
  [ECHEC] sara n'a pas ecrit, mais pas pour la bonne raison :
session setup failed: NT_STATUS_LOGON_FAILURE
  [ECHEC] l'annuaire ne confirme pas l'appartenance   (memberUid absent du groupe bureau)
```

**Diagnostic, cause par cause :**

| # | Symptôme observé | Cause établie | Correctif v2 |
|---|---|---|---|
| 1 | `ldapmodify: modify operation type is missing at line 6` | **défaut du script** : dans mon LDIF, la ligne `-` séparatrice n'était **pas suivie d'une ligne vide** avant le `dn:` suivant. LDAP lit alors le second `dn:` comme une opération du premier enregistrement → tout le bloc est refusé, donc **aucun `memberUid` n'est écrit** (ce qui explique aussi l'échec de la preuve 4) | LDIF corrigé : ligne vide après chaque `-` |
| 2 | `session setup failed: NT_STATUS_INTERNAL_DB_CORRUPTION` sur **omrane** | **défaut de conception du test** : mes groupes n'étaient que `posixGroup`. Or avec `ldapsam:trusted = yes`, Samba résout `gid → SID` **via l'entrée de groupe de l'annuaire**. Sans `sambaGroupMapping` ni `sambaSID`, la résolution échoue et l'ouverture de session casse — même pour un compte qui fonctionnait en T-04-E | les groupes portent désormais `sambaSID`, `sambaGroupType`, `displayName` (RID 3001 et 3002) |
| 3 | `smbpasswd -a sara` → `Failed to add entry for user sara` | le **chemin d'ajout** de compte Samba sur une entrée LDAP existante est fragile (il doit ajouter `sambaSamAccount` + attributs en une seule écriture) | l'entrée `sara` est créée **avec** `sambaSamAccount`, `sambaSID`, `sambaPrimaryGroupSID`, `sambaAcctFlags` ; `smbpasswd -s` ne fait plus que **poser le mot de passe** |

**Ce que l'essai 1 a quand même établi (et qui n'est pas à refaire) :** l'annuaire accepte des entrées
`posixGroup` et une entrée `uid=sara` complète côté POSIX ; `sara` **n'existe pas** dans le système local ;
`omrane` a bien été rattaché au gid 2001 **dans l'annuaire** ; les espaces `[commun]` (2770 root:2001) et
`[public]` sont en place ; `smbd` démarre et écoute correctement (attente active : 9 s).

**Leçon de méthode :** `NT_STATUS_INTERNAL_DB_CORRUPTION` n'a **rien** à voir avec une corruption de base.
C'est le message que Samba renvoie quand il ne parvient pas à convertir un identifiant POSIX en SID —
ici, un groupe sans identité Samba dans l'annuaire. Le nom du message est trompeur ; c'est le contexte
(`ldapsam:trusted`) qui donne la clé.

### Essai 2 — 2026-10-24 — **RÉUSSI**

Script `63` **version 2** (groupes porteurs d'un `sambaSID`, `sara` créée avec `sambaSamAccount`, LDIF
valides). Verdict rendu par le script sur le banc :

```
T-04-F : REUSSI - les droits sont decides par les groupes de l'annuaire.
```

**Réserve de traçabilité, à lever :** le verdict et la ligne d'état des preuves ont été transmis, mais
**pas la sortie intégrale** du script. Les preuves `P0`→`P4B` sont donc rapportées par le verdict du
programme, non recopiées verbatim dans ce journal — contrairement aux essais 1 de T-04-E, 1 et 2 de
T-04-F. Pour que ce journal soit au même niveau de preuve que les autres, il reste à coller la sortie
complète de `sh /tmp/t04f.sh` (une réexécution produit exactement les mêmes preuves : le script est
idempotent).

## 7. Verdict

**RÉUSSI** — 2026-10-24, essai 2, VM `nexbsd-test` (FreeBSD 15.1-RELEASE, Samba `samba423-4.23.11_3`,
OpenLDAP + `samba.schema`, `ldapsam:trusted = yes`).

| Preuve exigée au §4 | Résultat |
|---|---|
| F0 — les groupes portent leur SID Samba (résolution `gid → SID`) | ✅ |
| F1 — `omrane` (groupe `bureau`) écrit dans `[commun]` | ✅ |
| F1b — le fichier porte uid 10000 / gid 2001, **identifiants de l'annuaire** | ✅ |
| F2 — `sara` (groupe `stagiaires`) est **refusée** dans `[commun]` | ✅ |
| F3 — `sara` **lit** `[public]`, ne peut pas y écrire | ✅ |
| F4 — l'annuaire confirme groupe, membres, identité de `sara` | ✅ |

**Ce que ce test démontre pour NexBSD :** l'axe identités du projet (`docs/14-reseau-netware.md`) n'est plus
une intention. Un compte **créé uniquement dans l'annuaire** est authentifié, et son **droit d'accès à un
partage est décidé par son groupe**, lui aussi dans l'annuaire. C'est exactement le modèle « annuaire
central, droits attachés aux groupes » que le projet vise.

**Ce qu'il ne démontre pas :** les **ACL NT** (droits fins à la Windows/NetWare, à distinguer des droits POSIX
testés ici) ; le **chiffrement** LDAP/TLS (`ldap ssl = off` en laboratoire) ; la tenue **multi-serveurs** ;
et la **persistance après redémarrage** — c'est précisément l'objet de T-04-G.

**Historique :** essai 1 `ECHEC` (C-12 LDIF invalide, C-13 groupes sans SID) · essai 2 **RÉUSSI**.

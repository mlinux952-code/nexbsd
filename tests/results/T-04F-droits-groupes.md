# T-04-F — Les droits sont décidés par des groupes de l'annuaire — **À EXÉCUTER**

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
| Mot de passe `sara` | `saralab` — **laboratoire uniquement** |
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

### Essai 1 — à exécuter

_(vide)_

## 7. Verdict

**NON EXÉCUTÉ** — protocole écrit, jamais passé sur le banc à la date du 2026-10-24.

# T-04-G — Le banc revient seul après redémarrage — **RÉUSSI (11/11)**

**Protocole exécutable :** `scripts/64-banc-T04G-persistance.sh`, en **deux phases** (`avant` puis `apres`).
**Prérequis :** T-04 (annuaire), T-04-E (authentification par l'annuaire) et T-04-F (droits par groupes) réussis — acquis le 2026-10-24.
**Banc :** VM `nexbsd-test`, FreeBSD 15.1-RELEASE, Samba `samba423-4.23.11_3`, OpenLDAP + `samba.schema`.

## 1. Pourquoi ce test maintenant

Tout ce que le banc sait faire depuis T-04 a été obtenu par des **commandes tapées à la main**, service par
service. Or un serveur — et *a fortiori* un système d'exploitation — doit **revenir seul** après une coupure
de courant. Un banc qui exige trois scripts et un redémarrage manuel n'est pas encore une brique du produit :
c'est une démonstration.

T-04-G est donc la charnière entre « ça marche quand je le lance » et « ça marche tout le temps ». Il ne
fabrique rien de nouveau : il **contrôle** que l'existant survit de lui-même.

## 2. Ce que le test doit démontrer — 11 contrôles

| # | Contrôle | Pourquoi il compte |
|---|---|---|
| R0 | la machine a **réellement redémarré** (instant de démarrage différent) | sans redémarrage, le test ne prouve rien |
| R1 | `slapd` tourne sans commande manuelle | l'annuaire est un service du système, pas une session |
| R2 | `smbd` **écoute** sur `:445` sans commande manuelle | idem pour le service de fichiers |
| R3 | aucun entrée LDAP perdue (comptage avant/après) | les données sont sur disque, pas en mémoire |
| R4 | `sara` garde son `sambaSID` | l'identité est persistante |
| R5 | l'appartenance `omrane → bureau` est conservée | les droits reposent sur elle |
| R6 | le fichier témoin écrit avant redémarrage est retrouvé | les partages écrivent bien sur le disque |
| R7 | les droits POSIX des partages sont inchangés | la configuration est reproductible |
| R8 | `omrane` **écrit** toujours dans `[commun]` | le service est réellement utilisable |
| R9 | `sara` est **toujours refusée** dans `[commun]` | les droits survivent au redémarrage |
| R10 | `sara` lit le témoin par le réseau | le partage n'est pas seulement « démarré », il fonctionne |

## 3. Mode opératoire (deux temps, un redémarrage)

```
sh /tmp/t04g.sh avant      # relève l'état, arme les services, écrit /root/nexbsd-t04g-etat.txt
cp /tmp/t04g.sh /root/t04g.sh
reboot
sh /root/t04g.sh apres     # contrôle et verdict
```

L'état de référence est écrit dans `/root/nexbsd-t04g-etat.txt` : il survit au redémarrage, contrairement
à `/tmp` qui peut être vidé.

**Point de méthode :** la phase `avant` **arme** les services si nécessaire (`sysrc … =YES`) — c'est un
prérequis du test, pas son résultat. Le test porte sur ce qui se passe **après** le redémarrage, sans
intervention.

## 4. Journal d'exécution

### Essai 1 — 2026-10-24 13:20 UTC — **ECHEC (7 contrôles sur 11)**

Banc : VM `nexbsd-test`, FreeBSD 15.1-RELEASE, redémarrage réel (démarrage 13:20, `up 29 secs`).

**Ce qui a réussi — et c'est l'essentiel :**

| Contrôle | Résultat |
|---|---|
| R0 redémarrage réel | ✅ instant de démarrage différent |
| R1 `slapd` revenu seul | ✅ aucune commande manuelle |
| R2 `smbd` à l'écoute sur `:445` | ✅ |
| R3 annuaire intact | ✅ **10 entrées avant, 10 après** |
| R4 `sara` garde son SID | ✅ `…-1010` |
| R5 appartenance `omrane → bureau` | ✅ conservée |
| R6 fichier témoin | ✅ retrouvé, daté 13:16:27Z |

**Deux échecs, de nature très différente :**

| # | Symptôme | Nature | Analyse |
|---|---|---|---|
| 1 | `les droits ont change : (avant : )` — la valeur « avant » est **vide** | ❌ **faux échec : défaut du script** | La v1 relisait le fichier d'état par `. fichier` (sourcing). Or la valeur `drwxrws--- 0 2001` contient des espaces : le shell a donc tenté d'exécuter `0` comme commande → `nexbsd-t04g-etat.txt: 0: not found`. `DROITS_COMMUN` était vide **avant comparaison**. Les droits sont en réalité **identiques** : `drwxrws--- 0 2001` des deux côtés |
| 2 | `NT_STATUS_LOGON_FAILURE` sur **omrane**, **sara** et la lecture du témoin | ⚠️ **vrai défaut du banc** | Le service répond (ce n'est pas un refus de connexion), l'annuaire est intact, mais **plus aucun mot de passe n'est validé**. C'est un changement d'état réel : ces mêmes accès fonctionnaient avant le redémarrage (T-04-F) |

**Hypothèse 1 (ordre de démarrage) — ÉLIMINÉE après vérification :** `pdbedit -L -v omrane`, lancé après le
redémarrage, affiche `init_sam_from_ldap: Entry found for user: omrane` et les bons SID. La base de comptes
`ldapsam` s'initialise donc correctement — l'ordre de démarrage n'est pas la cause.

**Hypothèse principale (révisée) : les secrets de Samba ne survivent pas au redémarrage** — cohérente avec
les deux faits observés simultanément : lecture des comptes OK, validation du mot de passe impossible.

**Hypothèse initialement envisagée : l'ORDRE DE DÉMARRAGE.** Avec `ldapsam`, `smbd` doit joindre
l'annuaire **au moment où il s'initialise**. Si `samba_server` démarre avant que `slapd` soit à l'écoute,
l'initialisation de `passdb` échoue ; `smbd` reste ensuite vivant et à l'écoute, mais refuse toutes les
ouvertures de session. C'est un défaut classique et **exactement le genre de chose qu'un serveur doit
résoudre par sa configuration de démarrage**, pas par une commande manuelle.

**Hypothèse secondaire :** perte ou régénération des secrets Samba (`secrets.tdb`) → SID du domaine
différent de celui stocké dans l'annuaire. Le diagnostic automatique ajouté en v2 compare les deux.

**Point de méthode :** l'échec 1 ne doit **pas** être compté comme un défaut du banc — mais il ne doit pas
non plus être effacé. Il est consigné, corrigé, et le test sera rejoué : un journal de tests qui ne montre
que des succès ne vaut rien.

### Entracte — 2026-10-25 : C-14 corrigé

Après établissement de la cause, `scripts/65` a été appliqué avec succès (`nss-pam-ldapd`) et toutes les
preuves SMB ont été retrouvées **sans redémarrage** : `omrane` lit `[commun]`, `sara` lit `[public]` et
reste **refusée** dans `[commun]`. Le test est rejoué en entier (essai 2) pour vérifier que ce correctif
**survit lui-même** à une coupure — ce qui est précisément l'objet de T-04-G.

### Essai 2 — 2026-10-25 19:34 UTC — **RÉUSSI (11 contrôles sur 11)**

Redémarrage réel (`up 22 secs`), script `64` **version 2**, correctif NSS (`scripts/65`) en place.

```
  ...     releve : 10 entrees / SID sara=…-1010 / droits commun=[drwxrws--- 0 2001]
----- 1. redemarrage effectif -----        [OK] la machine a bien redemarre
----- 2. services revenus sans intervention -----
  [OK] slapd tourne, sans commande manuelle
  [OK] smbd ecoute sur :445 sans commande manuelle
----- 3. donnees de l'annuaire intactes -----
  [OK] aucune entree perdue          [OK] sara garde son SID
  [OK] l'appartenance omrane -> bureau est conservee
----- 4. donnees des partages conservees -----
  [OK] fichier temoin retrouve : temoin ecrit avant redemarrage : 2026-10-25T19:32:43Z
  [OK] les droits des partages sont inchanges   (avant : drwxrws--- 0 2001 — identique)
----- 5. service reellement utilisable -----
  [OK] omrane ecrit dans [commun] apres redemarrage
  [OK] sara est toujours refusee dans [commun] : les droits survivent au redemarrage
  [OK] sara lit le fichier temoin par le reseau : le partage fonctionne

Controles reussis : 11 / 11
T-04-G : REUSSI - le banc revient seul apres redemarrage, donnees et droits compris.
```

**Ce que ce test démontre :** le banc d'identités **survit à une coupure**. Trois services (`slapd`,
`nslcd`, `samba_server`) reviennent **sans aucune commande manuelle**, l'annuaire conserve ses 10 entrées,
son SID de domaine, l'appartenance `omrane → bureau`, les mots de passe, les droits POSIX des partages —
et **les droits sont toujours appliqués** : `omrane` écrit, `sara` est refusée.

**Note sur le faux échec de l'essai 1 :** il est désormais derrière nous (`drwxrws--- 0 2001` affiché
**des deux côtés**), ce qui confirme que la v1 du script en était seule responsable (C-15).

## 5. Verdict

**RÉUSSI à l'essai 2 (11/11)** — 2026-10-25 19:34 UTC, VM `nexbsd-test`.

| Preuve | Résultat |
|---|---|
| R0 redémarrage réel | ✅ |
| R1 `slapd` revenu seul | ✅ |
| R2 `smbd` écoute sur `:445` sans intervention | ✅ |
| R3 annuaire intact (10 entrées) | ✅ |
| R4 `sara` garde son SID | ✅ |
| R5 `omrane → bureau` conservé | ✅ |
| R6 fichier témoin retrouvé | ✅ |
| R7 droits des partages inchangés | ✅ |
| R8 `omrane` écrit dans `[commun]` | ✅ |
| R9 `sara` refusée dans `[commun]` | ✅ |
| R10 `sara` lit `[public]` par le réseau | ✅ |

**Historique :** essai 1 `ECHEC 7/11` (défaut réel **C-14** : la machine ne résolvait pas les identités de
l'annuaire ; plus un faux échec **C-15** dû au script) · **essai 2 : RÉUSSI 11/11** après correctif
`nss-pam-ldapd`.

---

## Rejeu du 2026-10-26 (soir) — 11/11, mais **sur le noyau d'origine**

**Objectif du rejeu :** prouver que le banc tient **sur le noyau `NEXBSD_L1`** (derniere case du jalon J1).

**Phase « avant » (2026-10-26T19:33:00Z)** — executee sur le noyau NexBSD :
`# hote : FreeBSD 15.1-NEXBSD-L1 ; phase : avant` — 10 entrees, SID de `sara`, temoin ecrit.

**Phase « apres » (2026-10-26T19:41:15Z)** — sortie verbatim :

```
# date : 2026-10-26T19:41:15Z ; hote : FreeBSD 15.1-RELEASE ; phase : apres
Controles reussis : 11 / 11
T-04-G : REUSSI - le banc revient seul apres redemarrage, donnees et droits compris.
```

| Controle | Resultat |
|---|---|
| redemarrage effectif | OK (up 32 secs) |
| slapd / smbd revenus sans intervention | OK, `:445` en ecoute |
| annuaire : 10 entrees, SID de `sara` | OK |
| appartenance `omrane` -> `bureau` | OK |
| temoin retrouve (`2026-10-26T19:33:00Z`) | OK |
| droits `drwxrws--- 0 2001` | OK |
| `omrane` ecrit / `sara` refusee / `sara` lit `[public]` | OK, OK, OK |

**⚑ Reserve majeure, consignee telle quelle :** la phase « apres » s'annonce
**`hote : FreeBSD 15.1-RELEASE`**, c'est-a-dire le **noyau d'origine**, pas `15.1-NEXBSD-L1`.
Cause identifiee : `nextboot.conf` est **a usage unique** (voir **C-20**) ; le redemarrage a donc
quitte `NEXBSD_L1` pour revenir au noyau par defaut.

**Ce que ce rejeu prouve :** le banc repasse **11/11** apres une coupure, et le mecanisme de secours
`nextboot` ramene bien au noyau d'origine sans intervention — les deux sont des resultats utiles.
**Ce qu'il ne prouve pas :** le banc **sur notre noyau**. Cette case de J1 reste **ouverte**.

**Action :** rendre `kernel="kernel.NEXBSD_L1"` **permanent** dans `/boot/loader.conf`, puis refaire une
paire avant/apres entierement sur `NEXBSD_L1`.

# T-04-G — Le banc revient seul après redémarrage — **EN COURS**

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

### Entracte — 2026-10-25 : C-14 corrigé, rejeu imminent

Après établissement de la cause, `scripts/65` a été appliqué avec succès (`nss-pam-ldapd`) et toutes les
preuves SMB ont été retrouvées **sans redémarrage** : `omrane` lit `[commun]`, `sara` lit `[public]` et
reste **refusée** dans `[commun]`. Le test est rejoué en entier (essai 2) pour vérifier que ce correctif
**survit lui-même** à une coupure — ce qui est précisément l'objet de T-04-G.

### Essai 2 — à exécuter

_(en cours)_

## 5. Verdict

**ECHEC à l'essai 1 (7/11)** — 2026-10-24 13:20 UTC. Les services reviennent seuls et les données sont
intactes ; **l'authentification ne survit pas au redémarrage**. Script v2 écrit (lecture d'état corrigée,
diagnostic automatique ajouté) ; diagnostic de la cause en cours, discriminant : redémarrer Samba seul.

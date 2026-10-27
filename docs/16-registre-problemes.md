# Registre des problèmes connus

**Version :** 1.0 — 2026-10-23
**Rôle :** livrable 13 du méga-prompt. Trace des **problèmes** (≠ risques) : ce qui est cassé, manquant, contradictoire ou bloquant.
**Règle :** un problème ne se supprime pas, il se **clôt** avec sa justification.

Légende gravité : 🔴 bloquant · 🟠 majeur · 🟡 mineur
Légende statut : **ouvert** · **contourné** · **clos**

---

## 1. Problèmes ouverts

| # | Problème | Gravité | Impact | Statut | Suite |
|---|---|---|---|---|---|
| P-01 | **Aucune identification du matériel du PC de 2011** (CPU ? 64 bits ? firmware ?) | 🔴 | bloque T-01/T-02, donc le prototype | ouvert | exécuter `docs/hardware.md` §2 |
| P-02 | **Aucun test d'exécution n'a été réalisé** (0/15 tests) | 🔴 | interdit toute conclusion de faisabilité | ouvert | lancer la VM (plan-action étape 1bis) |
| P-03 | **Profil L3 (« PC fort ») indisponible** | 🟠 | empêche `buildworld`, donc toute image NexBSD | ouvert | décision du responsable (Q4) |
| P-04 | Aucune installation FreeBSD, même en VM | 🟠 | livrables 11, 12, 15 bloqués | ouvert | plan-action étape 1bis |
| P-05 | OpenLDAP ≥ 2.6 : disponibilité sous FreeBSD non vérifiée | 🟠 | bloque la décision annuaire (N-03) | ouvert | `pkg search -x openldap` |
| P-06 | Antériorité du nom « NexBSD » non vérifiée | 🟠 | bloque la publication (porte G1) | ouvert | recherche d'antériorité |
| P-07 | Statut actuel des marques NetWare/Novell non vérifié | 🟡 | risque juridique de communication | ouvert | recherche |
| P-08 | Document fondateur unique non rédigé/signé (livrable 1) | 🟡 | traçabilité de la vision | ouvert | rédaction (sans matériel) |
| P-09 | Étude de faisabilité sans conclusion (livrable 3) | 🟠 | ne peut être écrite sans test | ouvert | après P-02 |
| P-10 | Le script `20-ecrire-usb.sh` n'a **jamais** été exécuté sur un périphérique réel | 🟠 | risque de destruction si bug | ouvert | relire + tester avec une clé sacrifiable |
| P-11 | Le script `30-qemu-freebsd.sh` n'a jamais lancé de VM (QEMU absent de l'environnement de test) | 🟡 | première exécution non validée | ouvert | tester sur le Mint |
| P-12 | `fork/*` jamais compilé (ni `src.conf` ni `KERN_CONF`) | 🟡 | valeurs peut-être inopérantes | ouvert | après P-03 |
| P-13 | **Dépôt GitHub inexistant** (aucun connecteur GitHub disponible) ; Drive fait le 2026-10-23 | 🔴 | pas d'historique distant ni de travail à plusieurs ; subsiste une copie datée sur Drive | **partiellement résolu** | action du responsable : `docs/20-depots-et-sauvegardes.md` §3 |
| P-14 | Le client NCP de test exige une **VM Windows** (licence à vérifier) | 🟡 | bloque le banc B | ouvert | décision du responsable |

## 2. Problèmes clos

| # | Problème | Résolution | Date |
|---|---|---|---|
| C-01 | Modèle d'assemblage « FreeBSD + paquets » inapte à produire un système | remplacé par le modèle fork M2 (ADR-0011) | 2026-10-23 |
| C-02 | `scripts/10-verifier-image.sh` ne reconnaissait pas les en-têtes en majuscules | correction + 3 cas de test exécutés | 2026-10-23 |
| C-03 | `scripts/40-…` : exemptions non appliquées (motif relatif mal compris) | documenté + test corrigé | 2026-10-23 |
| C-04 | 3 matrices CSV avec virgules non échappées (illisibles dans un tableur) | réécrites, vérifiées par analyseur CSV | 2026-10-23 |
| C-05 | Conclusion erronée « NCP impossible sans IPX » | corrigée : NCP sur UDP/TCP 524 depuis NetWare 5 (ADR-0018) | 2026-10-23 |
| C-06 | « Aucun client NCP testable » (inquiétude V-1) | Client for Open Enterprise Server 26.2.1 identifié (ADR-0019) | 2026-10-23 |
| C-07 | **Aucune sauvegarde hors de l'espace de travail** | dépôt Git local (1 commit) + archives + téléversement Google Drive vérifié par l'API (S-007) | 2026-10-23 |
| C-09 | **Mode terminal QEMU imposé par erreur sur la station du responsable** (une session perdue) | cause : l'environnement de l'assistant n'a pas d'écran, ce n'est pas une contrainte de la station ; remplacé par `virt-manager` en session utilisateur (`docs/23-banc-sur-mint.md` §4 ter) | 2026-10-23 |
| C-08 | Livrable 2 (cahier des charges fonctionnel) absent | `docs/02-cahier-des-charges-fonctionnel.md` : 33 exigences avec critères d'acceptation | 2026-10-23 |

## 3. Contradictions détectées entre documents

| # | Contradiction | Résolution |
|---|---|---|
| X-01 | `ETAT.md` v4 annonçait encore « 16 ADR » après l'ajout de 0017/0018 | corrigé en v5 puis v6 |
| X-02 | `ETAT.md` §3 titrait « les 16 ADR » avec une liste de 18 | corrigé |
| X-03 | `ADR-0014` présentait IPX comme inévitable | révisé par ADR-0018, mention croisée ajoutée |

**Aucune contradiction ouverte à ce jour.** Toute nouvelle contradiction doit être inscrite ici avant d'être résolue.

## 4. Ce que ce registre ne contient pas

- Les **risques** (événements possibles) : voir `matrices/risques.csv` (R-01→R-24).
- Les **fonctions non implémentées** : voir `matrices/functions.csv` (état « À faire / À étudier »).

---

## C-10 — Le paquet FreeBSD `samba423` ne fournit pas `samba.schema`

**Constaté :** 2026-10-24, essai 1 de T-04-E. `samba.schema` introuvable dans `/usr/local/etc/openldap/schema/`, `/usr/local/share/examples/samba*/`. Vérification dans le `pkg-plist` du port `net/samba423` : **aucun fichier `.schema` n'est livré**.

**Conséquence :** `passdb backend = ldapsam` échoue à l'initialisation (`Invalid DN syntax` sur `sambaDomainName=…`), car les attributs Samba sont inconnus de l'annuaire.

**Solution retenue :** téléchargement du schéma depuis le dépôt officiel Samba (`examples/LDAP/samba.schema`, HEAD) avec **empreinte SHA256 épinglée**, dans la VM de laboratoire uniquement. Le fichier étant sous **GPL-3.0+**, il n'entre **jamais** dans le dépôt NexBSD (frontière de licences, `docs/12`).

**Correctif :** `scripts/62-banc-T04E-samba-ldap.sh` version 2.

**Statut :** **clos** — vérifié à l'essai 2 de T-04-E (2026-10-24) : schéma téléchargé, empreinte conforme, `slaptest` accepte la configuration, `slapd` redémarre, `sambaSID` présent dans l'annuaire.

---

## C-11 — Attente fixe avant la preuve d'authentification SMB (course de délai)

**Constaté :** 2026-10-24, essai 2 de T-04-E. La preuve 3 (`smbclient`) échoue en `NT_STATUS_CONNECTION_REFUSED` sur `127.0.0.1`, alors que le service est sain.

**Diagnostic établi sur pièces, dans la VM :**

| Élément observé | Ce qu'il prouve |
|---|---|
| `sockstat -4l` → `*:445` et `*:139` en écoute | `smbd` écoute sur **toutes** les adresses, boucle locale comprise : l'hypothèse « pas d'écoute sur 127.0.0.1 » est **éliminée** |
| `pgrep -fl smbd` → démon + `cleanupd` + `notifyd` | le service n'est pas mort : l'hypothèse « arrêt après démarrage » est **éliminée** |
| journal : `smbd version 4.23.11 started` à **12:16:15**, puis `file_init_global` à **12:16:24** | le service met **≈ 9 s** à être réellement prêt (initialisation `ldapsam`) |
| aucune ligne de refus dans le journal à 12:16 | la connexion n'a jamais atteint `smbd` : personne n'écoutait encore |

**Cause :** défaut du **script**, pas du banc. La v2 attendait un délai **fixe de 3 s** (`sleep 3`) avant la preuve 3, insuffisant. Le message `CONNECTION_REFUSED` est **trompeur** : il ne signifie pas « mot de passe refusé » mais « aucun service à l'écoute à cet instant ».

**Correctif :** `scripts/62-banc-T04E-samba-ldap.sh` **version 3** — attente **active** de l'écoute sur `:445` (jusqu'à 90 s, contrôle toutes les secondes), preuve 3 avec **5 reprises** espacées de 3 s, **repli** sur l'adresse réseau de la VM, et messages différenciés `CONNECTION_REFUSED` (service) vs `LOGON_FAILURE` (identité).

**Statut :** **clos** — la preuve 3 a été obtenue le 2026-10-24 (essai 3 : `smbclient` s'authentifie et liste le partage). Réserve de méthode : le script v3 n'a pas encore été rejoué de bout en bout, donc la **rejouabilité** reste à démontrer (tâche de suivi, sans effet sur le résultat).

---

## C-12 — LDIF d'appartenance refusé : ligne vide manquante après le séparateur `-`

**Constaté :** 2026-10-24, essai 1 de T-04-F. `ldapmodify: modify operation type is missing at line 6`.

**Cause :** défaut du script `63` v1. Dans un LDIF multi-enregistrements, chaque bloc `changetype: modify`
doit être terminé par `-` **suivi d'une ligne vide** avant le `dn:` suivant. Sans la ligne vide, le second
`dn:` est lu comme une opération du premier enregistrement et **tout le fichier est rejeté**.

**Conséquence :** aucun `memberUid` écrit ; l'annuaire ne connaissait donc pas l'appartenance de `omrane` au
groupe `bureau` (ce qui explique l'échec de la preuve 4 du même essai).

**Correctif :** `scripts/63` version 2 — ligne vide après chaque `-`.

**Statut :** **clos** — essai 2 de T-04-F réussi (2026-10-24) : les appartenances sont écrites et la preuve 4 de l'annuaire confirme `memberUid: omrane` dans le groupe `bureau`.

---

## C-13 — Sous `ldapsam:trusted`, un groupe sans identité Samba casse l'ouverture de session

**Constaté :** 2026-10-24, essai 1 de T-04-F. `session setup failed: NT_STATUS_INTERNAL_DB_CORRUPTION`
pour `omrane`, alors que le même compte fonctionnait en T-04-E.

**Cause :** les groupes créés n'étaient que `posixGroup`, sans `sambaSID` ni `sambaGroupMapping`. Avec
`ldapsam:trusted = yes`, Samba résout `gid → SID` **via l'entrée de groupe de l'annuaire** ; sans identité
Samba sur le groupe, la conversion échoue et `smbd` renvoie `INTERNAL_DB_CORRUPTION`.

**Point de vigilance :** ce libellé **ne signifie pas** que la base est corrompue. Il désigne une
conversion d'identifiant POSIX → SID impossible. Ne jamais l'interpréter littéralement.

**Correctif :** `scripts/63` version 2 — les groupes portent `sambaSID` (RID 3001/3002), `sambaGroupType = 2`
et `displayName`, avec un chemin de mise à niveau pour les groupes déjà existants.

**Statut :** **clos** — essai 2 de T-04-F réussi (2026-10-24) : `omrane` écrit dans `[commun]` et `sara` y est refusée. La règle est désormais écrite dans le protocole : sous `ldapsam:trusted`, **tout groupe référencé par un `gidNumber` doit porter son identité Samba**.

---

## C-14 — Après redémarrage, les comptes sont refusés (`NT_STATUS_LOGON_FAILURE`)

**Constaté :** 2026-10-24, essai 1 de T-04-G. Avant le redémarrage, `omrane` écrit et `sara` est refusée
comme attendu (T-04-F). Après le redémarrage : `slapd` et `smbd` tournent, `smbd` écoute sur `:445`,
l'annuaire est intact (10 entrées, SID de `sara` et appartenances conservés) — mais **toutes** les
ouvertures de session échouent en `NT_STATUS_LOGON_FAILURE`.

**Ce que ce n'est pas :** ni une panne de service (le port répond), ni une perte de données (l'annuaire est
intact), ni un refus de droits (`LOGON_FAILURE`, pas `ACCESS_DENIED`).

**Hypothèse 1 (ordre de démarrage) — RÉOUVERTE, après avoir été éliminée à tort.**

*Rectification de raisonnement (2026-10-24) :* j'avais d'abord éliminé cette hypothèse parce que
`pdbedit -L -v omrane` réussissait après le redémarrage. **Ce raisonnement était faux.** `pdbedit` est un
**processus séparé** qui ouvre **sa propre** connexion LDAP au moment où on le lance — alors que `slapd`
tourne depuis longtemps. Il ne dit **rien** de l'état interne de `smbd`, qui tourne depuis le démarrage et a
pu initialiser `ldapsam` **avant** que `slapd` soit à l'écoute. Les deux processus peuvent diverger : l'un neuf
et connecté, l'autre ancien et mal initialisé.

Le succès de `pdbedit` prouve donc que **l'annuaire et les données sont sains** — pas que `smbd` les voit
correctement.

Détail révélateur : la recherche porte sur `(sambaDomainName=NEXBSDFS)` et elle **aboutit sans erreur** —
alors qu'en T-04-E (essai 1, sans schéma) la même requête produisait `Invalid DN syntax`.

**Hypothèse 2 (retenue) : les secrets de Samba ne survivent pas au redémarrage.** Si `secrets.tdb` est
perdu ou régénéré, deux conséquences simultanées expliquent exactement ce qui est observé :

- la **lecture** des comptes reste possible (les ACL de slapd autorisent la lecture anonyme) → `pdbedit` marche ;
- la **validation de mot de passe** en session setup compare le SID calculé à partir du domaine **local** au
  compte de l'annuaire → SID local régénéré ≠ SID de l'annuaire → `NT_STATUS_LOGON_FAILURE`.

**Discriminant :** comparer `net getlocalsid` avec `S-1-5-21-692378897-511874203-3061570918` (SID de
l'annuaire), et dater `secrets.tdb`. Un SID local différent, ou un `secrets.tdb` daté d'après le
redémarrage, tranche.

**Hypothèse 2 (secrets perdus) — ÉLIMINÉE le 2026-10-24 :**

```
root@freebsd:~ # net getlocalsid
SID for domain NEXBSDFS is: S-1-5-21-692378897-511874203-3061570918

root@freebsd:~ # ls -l /var/db/samba4/private/
-rw-------  1 root wheel 425984 Oct 24 12:10 secrets.tdb
```

Le SID local est **identique** à celui de l'annuaire, et `secrets.tdb` porte la date du **12:10** — soit
bien avant les redémarrages de 13:20. Les secrets ont donc survécu et le domaine n'a pas été régénéré.

**État du diagnostic :** deux hypothèses éliminées par la preuve, aucune retenue à ce stade. Faits établis :

| Fait vérifié | Conséquence |
|---|---|
| `pdbedit` lit le compte et les SID | `passdb`/`ldapsam` s'initialise après redémarrage |
| `net getlocalsid` = SID de l'annuaire | le domaine est le bon |
| `secrets.tdb` intact et ancien | pas de régénération de secrets |
| `slapd` et `smbd` tournent, `:445` écoute | les services sont là |
| `smbclient` → `NT_STATUS_LOGON_FAILURE` (2 comptes) | la **validation du mot de passe** échoue, alors que la **lecture** du compte réussit |

**Pistes restantes, à départager :**
1. **État interne de `smbd` figé au démarrage** (hypothèse 1 réouverte) : `smbd` a initialisé `ldapsam` avant
   que `slapd` écoute, et n'a jamais réessayé. **Test discriminant :** relancer `samba_server` maintenant que
   `slapd` tourne ; si les sessions reviennent, la cause est établie.
2. **Droits de lecture sur l'attribut `sambaNTPassword`** : la lecture du compte réussirait, mais pas celle de
   l'empreinte du mot de passe.
3. **Correction durable** : si (1) est vrai, le correctif n'est pas de relancer à la main, mais que le service
   Samba **attende** que `slapd` réponde — une dépendance de démarrage, pas une manipulation.

### CAUSE ÉTABLIE — 2026-10-25 19:18 UTC (démarrage à froid, journal exploité)

```
add_local_groups: SID S-1-5-21-692378897-511874203-3061570918-1001 -> getpwuid(10000) failed,
                  is nsswitch configured?
check_sam_security: make_server_info_sam() failed with 'NT_STATUS_NO_SUCH_USER'
```

**Traduction :** Samba trouve bien le compte dans l'annuaire et en déduit son identifiant POSIX
(`uid 10000`). Il demande ensuite au **système local** « qui est l'utilisateur 10000 ? » — et le système
répond **« personne »**, parce que le fichier `/etc/passwd` de la machine ne contient aucun compte d'uid
10000. La construction du jeton d'authentification échoue, donc la session est refusée :
`NT_STATUS_NO_SUCH_USER`.

**Le défaut est donc architectural, pas technique :** l'annuaire **délivre** les identités, mais la
machine **ne les résout pas**. Deux sources d'identités cohabitent sans se parler — c'est exactement ce
qu'un serveur d'identités ne doit jamais faire.

**Hypothèses formellement éliminées par cette sortie :**

| Hypothèse | Preuve de son élimination |
|---|---|
| ordre de démarrage | le journal du 19:18 montre `smbldap_open_connection: connection opened` et la recherche du domaine **réussie** dès le démarrage ; le service attend ensuite les connexions |
| secrets / domaine régénéré | SID local = SID de l'annuaire, `secrets.tdb` du 12:10 |
| droits de lecture sur `sambaNTPassword` | l'attribut est **lisible** en anonyme : `sambaNTPassword: 4AD56ACE56BE3A9E9B6567B7B47EB0E8` |
| mot de passe erroné | `check_sam_security` échoue sur `NT_STATUS_NO_SUCH_USER`, **pas** sur un échec de mot de passe |

**Correctif retenu :** faire résoudre au système les identités de l'annuaire, via **`nss-pam-ldapd`
(`nslcd`)** : `passwd` et `group` dans `/etc/nsswitch.conf` interrogent l'annuaire après les fichiers
locaux. La machine et Samba partagent alors **une seule** source d'identités — c'est le modèle visé par
le projet.

**Point d'honnêteté :** la raison exacte pour laquelle T-04-F réussissait **avant** le redémarrage n'est
pas encore établie avec certitude (état en mémoire/cache de jetons probable). Ce qui est établi : à froid,
l'échec est systématique et sa cause est celle ci-dessus.

**Correctif appliqué et vérifié — 2026-10-25 19:28 UTC :**

```
[OK] nss-pam-ldapd installe ; [OK] nslcd tourne
[OK] resolu : omrane:*:10000:2001:Omrane:/home/omrane:/bin/sh
[OK] resolu : sara:*:10002:2002:Sara Test:/home/sara:/bin/sh
[OK] resolu : bureau:*:2001:omrane
[OK] omrane s'authentifie et lit [commun]
[OK] sara s'authentifie et lit [public]
[OK] sara est bien refusee dans [commun] (refus explicite)
Resolution NSS : uid10000=1 uid10002=1 gid2001=1 | SMB : omrane=1 sara=1 refus=1
```

**Statut :** **clos** le 2026-10-25 — la machine et Samba partagent désormais **une seule** source
d'identités. Réserve : la persistance de ce correctif après redémarrage est précisément ce que T-04-G
doit confirmer (rejeu en cours).

**Règle retenue pour le futur composant `identites` :** un serveur Samba en `ldapsam` **exige** que la
machine résolve les identités POSIX de l'annuaire (NSS) ; sans cela, l'authentification échoue en
`NT_STATUS_NO_SUCH_USER` même avec un annuaire parfait.

---

## C-15 — Fichier d'état relu par *sourcing* : un faux échec de comparaison

**Constaté :** 2026-10-24, essai 1 de T-04-G. `/root/nexbsd-t04g-etat.txt: 0: not found`,
`sec: not found`, puis « les droits ont change » alors que les droits étaient identiques.

**Cause :** la v1 du script `64` relisait son état par `. "$ETAT"` (sourcing). Des valeurs contiennent des
espaces (`drwxrws--- 0 2001`) ou des accolades (`kern.boottime`), donc le shell tentait de les exécuter.
La variable comparée était vide.

**Correctif :** `scripts/64` version 2 — l'état est **lu par clé** (`sed -n "s/^clé=//p"`), jamais exécuté.

**Statut :** corrigé. Leçon générale retenue : **un fichier d'état n'est pas du code** ; on le lit, on ne
l'exécute pas.

---

## C-16 — Le delta du fork avait été supprimé par un commit sans rapport

**Constaté :** 2026-10-25, en cherchant le delta pour répondre à la demande « un système à part entière ».
Les dossiers `build/`, `components/`, `release/` étaient **absents ou vides**, alors que `docs/22` et
`docs/15` décrivaient un delta complet (noyau `NEXBSD_L1`, `src.conf`, `release.conf`, overlay, patch).

**Cause :** le commit `25ae838` (« S-012 : abandon du mode terminal, virt-manager recommandé ») a **supprimé
17 fichiers** de `fork/` — sans aucun rapport avec son objet. Suppression accidentelle, non détectée
pendant deux sessions.

**Aggravant :** la documentation a continué d'affirmer l'existence de ce delta. C'est précisément la faute
que le projet interdit : décrire comme existant ce qui n'existe plus.

**Résolution :** restauration depuis l'historique Git (`git checkout 3d4eceb -- build/`), vérifiée fichier
par fichier (17 fichiers, 149 Ko). Commit de restauration dédié.

**Leçon retenue :** un commit doit être **relu** (`git show --stat`) avant d'être considéré comme anodin ;
et une affirmation documentaire doit être **vérifiable par une commande**, pas par la mémoire.

**Statut :** **clos** le 2026-10-25 (delta restauré).

---

## C-17 — La détection d'erreur de `scripts/68` criait au loup sur `-Werror`

**Constaté :** 2026-10-25, pendant la première construction du noyau. La section « erreurs éventuelles »
de `--etat` affichait **dix lignes de commandes `cc`** parfaitement normales, ce qui a légitimement alarmé
le responsable (« il y a une merde quelque part ? »).

**Cause :** le filtre était `grep -iE "(^|[^a-z])(error|…)"`. Or chaque ligne de compilation contient
`-Werror` et `-Wno-error=…` : le mot « error » y apparaît par construction. Le filtre détectait donc
**toutes** les lignes de compilation, pas les erreurs.

**Correctif :** motifs réels uniquement (`error:`, `Error code`, `Stop.`, `No space left`,
`Cannot allocate memory`, `out of swap`, `signal 6/11`, `panic:`) et **exclusion explicite** de `-Werror`.
Ajout au passage d'un vrai indicateur de progression : présence de `kernel.full` (noyau lié, phase des
modules) puis de `kernel` (fichier final), espace consommé, temps écoulé.

**Leçon :** un filtre d'erreur trop large est **plus dangereux** qu'aucun filtre : il apprend à ignorer
les alertes. Une alerte doit être fiable, sinon elle ne vaut rien.

**Statut :** corrigé le 2026-10-25 (dépôt), à livrer dans l'instantané s026.

---

## C-18 — **Récidive de C-16** : le dossier `build/` disparaît à chaque tour (cause structurelle trouvée)

**Constaté :** 2026-10-25, 22:22, sur la sortie du responsable : le `git merge` de l'instantané **s026**
affiche `delete mode 100644 fork/…` **17 fois**, et le `git push` a propagé la suppression sur GitHub
(`77f441d..7d9fe1c`). Deuxième occurrence du même incident en une seule journée.

**Cause réelle (enfin identifiée, et elle n'est pas humaine) :** l'environnement de travail dans lequel le
dépôt est préparé **exclut de ses instantanés tout répertoire nommé `build`**. Le dossier `build/fork/`
était donc restauré en mémoire, puis **effacé du système de fichiers entre deux tours**. Au tour suivant,
`git add -A` enregistrait fidèlement… une suppression. Le commit `9523462` (C-17), qui ne parlait que de
`scripts/68`, a ainsi supprimé 17 fichiers sans rapport.

**Aggravant :** deux fois de suite, un `git add -A` a transformé un artefact d'environnement en **commit
qui détruit du travail**, puis en **push**.

**Correctifs appliqués :**
1. **Renommage définitif : `build/fork/` → `fork/`** (racine du dépôt). Le nom `build` est désormais interdit
   dans ce dépôt, précisément parce qu'il est effacé par l'environnement.
2. **43 références mises à jour** (`docs/15`, `16`, `22`, `27`, `28`, `29`, `ETAT`, `INDEX`, ADR-0020,
   `CHANGELOG`, `README`, `START-HERE`, `T-17`, `scripts/67`, `fork/README.md`).
3. **Garde-fou exécutable : `scripts/70-verifier-delta.sh`** — vérifie que les 17 fichiers du delta sont
   présents **et suivis par Git**, avec empreintes. À lancer avant **chaque** commit et **chaque** instantané.
4. **Règle de méthode** : plus jamais de `git add -A` sans avoir lu `git status` ligne par ligne ; un commit
   ne doit contenir que ce que son message annonce (`git show --stat` obligatoire).

**Statut : CLOS le 2026-10-25.** Vérifié des deux côtés, verbatim :
- sur la machine du responsable, le `git merge` de s027 affiche **17 lignes `create mode 100644 fork/…`** et
  **aucune** ligne `delete mode` ; le `git push` réussit (`7d9fe1c..d999b1b  main -> main`) ;
- `sh scripts/70-verifier-delta.sh` répond **`VERDICT : DELTA INTACT (17 fichiers, empreintes conformes)`**.

Le delta est donc intact **localement, dans le dépôt Git, sur Mint et sur GitHub** : quatre lieux, une seule
preuve rejouable.

---

## C-19 — `installkernel` refuse d'écrire dans `/boot/kernel` : FreeBSD 15 est « pkgbase »

**Constaté :** 2026-10-26, première tentative d'installation du noyau `NEXBSD_L1` (qui venait d'être compilé
avec succès). Sortie verbatim :

```
ERROR: The kernel at /boot/kernel was installed from packages.
       A packaged kernel should never be updated using installkernel;
       this will cause the package database to become out of sync with
       the live system state.  Either uninstall the packaged kernel,
       or install this kernel to a different path using INSTKERNNAME.
```

**Cause :** depuis FreeBSD 14/15, le système de base est livré en **paquets** (`pkgbase`) :
`/boot/kernel` appartient au paquet `FreeBSD-kernel-generic`. `installkernel` protège la cohérence du
registre de paquets et **refuse** d'écraser un noyau géré par `pkg`. **Le garde-fou a raison.**

**Ce qu'il ne fallait PAS faire :** `souhaiter ALLOW_PKGBASE_INSTALLKERNEL=yes`. Le message le dit lui-même :
« you should not use the pkg(8) utility until you have resolved the inconsistency ». Cela désynchroniserait le
registre de paquets d'un banc validé — exactement le genre de raccourci qui casse un système proprement.

**Correctif retenu (celui que le message d'erreur indique) :** installer **à côté**, via
`INSTKERNNAME=kernel.NEXBSD_L1`. Conséquences, toutes favorables :

| Conséquence | Effet |
|---|---|
| Le noyau s'installe dans **`/boot/kernel.NEXBSD_L1`** | `/boot/kernel` (paquet) reste **intact** : aucune sauvegarde, aucun renommage |
| Le retour arrière devient trivial | remettre `kernel="kernel"` dans `/boot/loader.conf`, ou au chargeur |
| Le registre de paquets reste cohérent | `pkg` continue de fonctionner normalement |
| `MK_KERNEL_SYMBOLS=no` | évite d'installer le fichier `.debug` : indispensable avec **1,1 Go** libres sur la racine |

**Portée pour la suite du projet :** à l'étage 3 (image `release.sh`), c'est la chaîne de release qui produit
**ses propres** paquets — la question ne se posera donc plus de la même façon. À garder en tête pour J3/J4.

**Statut :** corrigé dans `scripts/69` le 2026-10-26 (variable `INSTKERN`, `INSTKERNNAME` passé à `make`,
plus aucun renommage de `/boot/kernel`). **Clos après vérification du démarrage.**

---

## C-20 — `nextboot.conf` est à **usage unique** : on quitte le noyau d'essai sans s'en apercevoir

**Constaté :** 2026-10-26 au soir. Le noyau `NEXBSD_L1` avait été démarré via `/boot/nextboot.conf`
(`nextboot_enable="YES"`, `kernel="kernel.NEXBSD_L1"`). Après le redémarrage suivant, la ligne d'en-tête
du banc affichait `hote : FreeBSD 15.1-RELEASE` — **le noyau d'origine**.

**Cause :** `nextboot` est conçu pour **un seul** démarrage d'essai : le chargeur consomme
`nextboot.conf` puis revient au réglage par défaut (`kernel="kernel"`). C'est une **qualité** pour un essai
risqué, un **piège** pour une campagne de mesures qui s'étale sur plusieurs redémarrages.

**Conséquence sur nos résultats :** le rejeu T-04-G du 2026-10-26 est **11/11**, mais **sur FreeBSD 15.1-RELEASE**.
Il ne doit donc **pas** être compté comme la preuve « banc sur noyau NexBSD ».

**Correctif :** rendre le choix **permanent** :
`sysrc -f /boot/loader.conf kernel=kernel.NEXBSD_L1` (+ `autoboot_delay="5"` pour garder le menu accessible).
Sauvegarde préalable : `/boot/loader.conf.avant-nexbsd`. Retour arrière : `kernel="kernel"`.

**Leçon générale (règle de session) :** **toute** sortie de test doit être lue jusqu'à sa ligne d'en-tête
(`hote :`, `uname -r`) avant d'être comptée comme réussie. Un 11/11 sur le mauvais noyau vaut zéro.

---

## C-21 — `scripts/31` ne lançait pas la vraie VM (mauvais moteur, mauvais nom)

**Constaté :** 2026-10-27, au démarrage de session. `sh 31-lancer-vm-freebsd.sh` répond :

```
ERREUR : image absente : /home/omrane/.cache/nexbsd-vm/FreeBSD-15.1-ufs.qcow2
```

...alors que **la VM existe** et a servi toute la session précédente.

**Cause double :**
1. **mauvais moteur** : le script avait été écrit pour un lancement **QEMU direct** (image `.qcow2` +
   `socat` sur un socket série), recette du 2026-10-23. Depuis, le banc tourne sous **libvirt**
   (`qemu:///session`), lancé par virt-manager, avec une console `ttyu0`.
2. **mauvais nom** : le domaine réel s'appelle **`nexbsd-test`**, pas `nexbsd`. La commande
   `virsh start nexbsd` échoue avec `failed to get domain 'nexbsd'`.

**Effet :** perte de temps en début de session, et doute inutile sur l'intégrité de la VM.

**Correctif (v2 de `scripts/31`, 2026-10-27) :** le script **détecte** au lieu de supposer :
1. si un domaine libvirt contenant « nexbsd » existe → mode libvirt (`start` + `console`) ;
2. sinon, si l'image QEMU directe existe → ancien chemin, conservé ;
3. sinon → message clair avec les deux solutions, sans rien inventer.
Options ajoutées : `--etat` (diagnostic sans rien lancer) et `--stop` (arrêt propre).

**Leçon générale :** **un script de lancement doit interroger la réalité** (quel hyperviseur ? quel domaine ?)
**avant** d'agir. Un script qui suppose est pire qu'aucun script : il fait douter de la machine.

---

## C-22 — `pfctl` échoue avec « Failed to open netlink » : le module `pf` doit être chargé **avant**

**Constaté :** 2026-10-27, première activation du pare-feu (`scripts/71` v1.1). Les deux étapes précédant
l'application réussissent (interface `vtnet0` / `10.0.2.15` détectée, `/etc/pf.conf` écrit, 38 lignes), puis :

```
----- 3. validation A BLANC (aucune application) -----
  [KO]    SYNTAXE INVALIDE — rien n'a ete applique
  ...     pfctl: Failed to open netlink: No such file or directory
```

**Cause :** sur **FreeBSD 15**, `pfctl` parle au module noyau `pf` par **netlink**. Si `pf.ko` **n'est pas
chargé**, `pfctl` ne peut même pas **analyser** un fichier de règles : il échoue à ouvrir le canal netlink.
Le message « SYNTAXE INVALIDE » était donc **trompeur** — la syntaxe n'y était pour rien.

**Faute de conception dans le script (la mienne) :** `kldload pf` figurait à l'**étape 4 (activation)**,
c'est-à-dire **après** la validation de l'étape 3. L'ordre était inversé : on demandait à `pfctl` de valider
un fichier alors que son interlocuteur n'existait pas encore.

**Conséquence heureuse :** le garde-fou a **fonctionné** — rien n'a été appliqué, `/etc/pf.conf` a été
restauré, l'état est resté strictement inchangé. Un échec propre vaut mieux qu'un succès douteux.

**Correctif (v1.2 de `scripts/71`, 2026-10-27) :**
1. nouvelle **étape 3** : chargement de `pf` et `pflog`, puis contrôle explicite que `pfctl -s info`
   répond — si ce n'est pas le cas, le script **s'arrête** avec la cause ;
2. la validation à blanc devient l'**étape 4**, l'activation l'**étape 5** ;
3. la sauvegarde ne recopie plus une version NexBSD de `pf.conf` comme si c'était l'originale.

**Point important pour la confiance :** charger le module `pf` **ne filtre rien**. Le filtrage ne commence
que lorsque des règles sont chargées **et** `pf` activé (`pfctl -e`). `kldload pf` est donc sans risque et
réversible (`kldunload pf`).

---

## C-23 — `pass ... keep state (max 20/s, burst 10)` : une syntaxe qui n'existe pas en `pf`

**Constaté :** 2026-10-27, deuxième tentative d'activation du pare-feu (`scripts/71` v1.2, modules chargés
correctement). La validation à blanc refuse le fichier :

```
----- 4. validation A BLANC (aucune application) -----
  [KO]    SYNTAXE INVALIDE — rien n'a ete applique
  ...     /etc/pf.conf:18: syntax error
```

**Cause :** en `pf`, `max` désigne un **nombre d'états** (une quantité), **pas un débit**. La limitation de
débit s'écrit `max-src-conn-rate <n>/<période>` éventuellement avec `overload <table>`. J'avais écrit
`(max 20/s, burst 10)`, qui **n'existe pas** : erreur de ma part, pas du système.

**Effet :** deuxième échec propre. Rien appliqué, `/etc/pf.conf` restauré, système inchangé.

**Correctif (v1.3) :** la règle ICMP devient un simple `keep state`. La limitation de débit anti-inondation
est **reportée** : elle exige une table `overload` et une décision explicite (« à partir de combien de
requêtes on bloque ? »). Mieux vaut un pare-feu qui démarre et se prouve qu'une protection élégante qui ne
se charge pas.

**Leçon (trois échecs, trois causes différentes, la même racine) :** C-22 (ordre des étapes), C-23 (syntaxe
inventée), et l'échec initial (mauvais hôte de téléchargement). La racine commune est **d'avoir écrit du
`pf` de mémoire au lieu de le valider contre la réalité**. La parade est désormais en place : **chaque
version du script valide à blanc et s'arrête net** si le fichier est refusé — c'est le garde-fou qui a
parlé trois fois de suite.

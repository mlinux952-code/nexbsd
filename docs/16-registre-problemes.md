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
| P-12 | `build/fork/*` jamais compilé (ni `src.conf` ni `KERN_CONF`) | 🟡 | valeurs peut-être inopérantes | ouvert | après P-03 |
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

**Hypothèse 1 (ordre de démarrage) — ÉLIMINÉE le 2026-10-24 :** `pdbedit -L -v omrane` lancé **après** le
redémarrage remonte correctement le compte (`init_sam_from_ldap: Entry found for user: omrane`,
`User SID: …-1001`, `Primary Group SID: …-3001`). La base de comptes `ldapsam` s'initialise donc
normalement : `smbd` joint bien l'annuaire. Si `samba_server` avait démarré avant `slapd`, `pdbedit`
échouerait de la même façon.

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
1. **Droits de lecture sur l'attribut `sambaNTPassword`** : Samba doit lire l'empreinte du mot de passe pour
   vérifier une session ; si l'annuaire ne l'autorise qu'à une liaison privilégiée et que cette liaison échoue,
   la lecture du compte réussit mais la vérification échoue.
2. **État propre au démarrage** : quelque chose diffère entre un `smbd` lancé par `rc.d` au démarrage et un
   `smbd` relancé à chaud. Test discriminant : relancer le service maintenant et réessayer.

**Statut :** ouvert — diagnostic en cours, deux hypothèses éliminées.

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

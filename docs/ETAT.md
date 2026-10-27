# ÉTAT DU PROJET NEXBSD — fiche de référence

**Version de cette fiche :** 24 · **Mise à jour :** 2026-10-27 (session S-020) · **niveau d'indépendance : I2 — J1 COMPLET, noyau REPRODUCTIBLE, harnais 24/24, pare-feu `pf` ACTIF et refus par défaut PROUVÉ depuis une autre machine**

> **Rappel permanent (demande du responsable, 2026-10-25) :** le produit s'appelle **NexBSD**.
> Toute occurrence de « freebsd » dans une sortie d'écran, un `uname` ou un nom d'hôte désigne
> **l'état du socle actuel** (FreeBSD 15.1 stock, non modifié), **pas la cible**. Voir `docs/26`.
**Rôle :** source de vérité en une page. En cas de contradiction avec un autre document, **c'est celui-ci qui décrit l'état**, car il est mis à jour à chaque session.

---

## 1. En trois phrases

NexBSD est un projet de **système d'exploitation expérimental** pour **PC faibles**, dont l'**axe prioritaire est le réseau façon NetWare** (identités, droits, partages, administration unique), visant à terme une **publication grand public**. Le modèle retenu est celui d'un **fork de FreeBSD** (arbre source possédé, images construites par le projet), avec une base **100 % sous licence permissive** et les composants réseau (Samba, OpenLDAP) isolés dans la couche Plateforme. **Un banc d'essai fonctionne désormais** : une VM FreeBSD 15.1 sur la station du responsable, où l'annuaire OpenLDAP et le partage Samba **s'authentifient ensemble** (T-04-E réussi le 2026-10-24). Aucune image NexBSD n'est encore construite : le produit lui-même reste à faire.

---

## 2. Où en est le projet

| Élément | État au 2026-10-25 (S-018) |
|---|---|
| Phase | **0 et 1 : documents produits. 2 et 3 : amorcées. 4 : non commencée.** |
| Code NexBSD | **noyau `NEXBSD_L1` COMPILÉ** le 2026-10-26 (`Kernel(s) NEXBSD_L1 built in 1470 seconds`, `code de retour : 0`) — installation et démarrage en cours de validation. Reste : `buildworld`/image (hors de portée du poste). Delta dans `fork/` (17 fichiers, garde-fou `scripts/70`) |
| Installation FreeBSD | **VM opérationnelle chez le responsable** (virt-manager + KVM, FreeBSD 15.1-RELEASE, console série `ttyu0`) ; **matériel réel : aucune installation** |
| Test d'exécution | **11 sur 20 réussis en VM** : T-01, T-03, T-04, T-04-E, T-04-F, T-04-G, T-16, T-17, T-11, T-18, **T-05 (pare-feu actif)** et **T-05a (fermeture par défaut prouvée depuis le Mint, 2026-10-27)**. T-16 (identité NexBSD du banc, étage 1) écrit, non exécuté |
| Image système | **aucune** — et elle reste **hors de portée du poste** (4 Go de RAM, `docs/28` §2) ; voie d'intégration continue à ouvrir (voie B de `docs/27`) |
| Décisions validées par le responsable | **aucune** — **20 ADR** à l'état `proposition` (dont **ADR-0020**, dérogation bornée pour construire le noyau) |
| **Sauvegarde** | **Google Drive** : instantanés jusqu'à **s042** (public) · **GitHub** : dépôt privé `mlinux952-code/nexbsd`, état du distant **inconnu faute de sortie `git push`** · dépôt Git local : **108 commits** |
| Documents | ~90 fichiers, 5 matrices CSV, **15 scripts** (dont 4 de banc), index complet dans `docs/INDEX-DOCUMENTS.md` ; conformité au mur auditée dans `docs/15-conformite-mega-prompt.md` ; **`docs/25-compte-rendu-session.md`** assure la reprise sans conversation |
| Disque du PC de 2011 | **intact** (aucune action matérielle effectuée) |
| Mesure RAM (ENF-01) | **≈ 100 Mo au repos** sur système nu en VM → objectif ≤ 128 Mo atteignable (à confirmer sur matériel) |
| Chemin NCP (différenciation) | **V-1 tranchée** : client NCP réel, gratuit et maintenu identifié (ADR-0019) ; V-2/V-3 en suspens |

## 3. Ce qui est décidé (proposé) — les 19 ADR

| # | Sujet | Statut |
|---|---|---|
| 0001 | Base = FreeBSD 15.x amd64 (à réviser si cible 32 bits) | proposition |
| 0002 | KaiOS rejeté comme base/composant | proposition |
| 0003 | Gecko B2G abandonné, WebKitGTK retenu | proposition |
| 0004 | MARS_NWE rejeté comme composant | proposition |
| 0005 | Jails + `pf` en refus par défaut | proposition |
| 0006 | Aucune modification du noyau en phase initiale | proposition |
| 0007 | Samba épinglé ≥ 4.23 | proposition |
| 0008 | Trois profils de cible séparés (Lab / NetServer / MobileExp) | proposition |
| 0009 | **Le PC faible est la cible** (budget opposable) | proposition |
| 0010 | Aucune compilation lourde hors profil L3 | proposition |
| 0011 | **Fork (arbre possédé), pas surcouche de paquets** | proposition |
| 0012 | Frontière stricte Base (permissive) / Plateforme (GPL admis) | proposition |
| 0013 | Couche mobile = code NexBSD sur WebKitGTK ; Gaia = inspiration | proposition |
| 0014 | IPX/NCP : réimplémentation propre en espace utilisateur (recherche) | proposition |
| 0015 | Identité = budget PC faible mesuré + fonctions réseau façon NetWare | proposition |
| 0016 | Objectif de publication grand public, conditionné à 10 portes | proposition |
| 0017 | **Le réseau est l'axe prioritaire ; les 4 composants ont chacun un rôle** | proposition |
| 0018 | **Cible protocolaire = NCP sur UDP/TCP 524, pas IPX** (révise 0014) | proposition |
| 0019 | **Client de test NCP = Client for Open Enterprise Server** (usage externe, jamais distribué) | proposition |

## 4. Questions ouvertes (bloquantes ou importantes)

| # | Question | Bloque | Qui décide |
|---|---|---|---|
| Q1 | Le CPU du PC de 2011 est-il **64 bits** ? | tout le test matériel | responsable (commande Windows) |
| Q2 | La cible « PC faible » inclut-elle des **32 bits** ? | ADR-0001 | responsable |
| Q3 | **Le fork est-il assumé, avec son coût ?** (sécurité, images, discipline) | ADR-0011, toute la trajectoire | responsable |
| Q4 | **Quand le profil L3 (« PC fort ») sera-t-il disponible ?** | phase 4bis, toute image | responsable |
| Q5 | Axe d'identité prioritaire : A (budget), B (réseau), ou A+B ? | positionnement | responsable |
| ~~Q6~~ | ~~OpenLDAP ≥ 2.6 packagé sous FreeBSD ?~~ → **RÉSOLU le 2026-10-23 : OUI** (2.6.15_1 et 2.7.1 dans les dépôts) | — | — |
| Q7 | Le nom « NexBSD » est-il libre ? | publication | responsable (recherche d'antériorité) |
| Q8 | Une **VM Windows** peut-elle être montée pour le banc B (client NCP) ? | T-09, validation NCP | responsable |
| Q9 | Le projet vise-t-il d'abord l'**usage domestique** ou la **petite structure avec comptes** ? | priorité N-01…N-11, `docs/vision.md` §7 | responsable |

## 5. Les 3 refus structurants — et ce qui est CONSERVÉ

1. **KaiOS** n'est pas réutilisable comme base (propriétaire, blobs OEM) → ses **idées d'interaction** sont conservées.
2. **Gecko B2G** n'est plus intégrable (archivé, API disparues) → **Gaia (Apache-2.0)** reste une référence de conception, **WebKitGTK** est le moteur.
3. **MARS_NWE** n'est pas intégrable dans le système (GPL-2 + IPX) → il est **conservé comme banc d'essai et source de spécification** (laboratoire isolé).

> **Aucun des quatre composants réseau n'est abandonné** (ADR-0017) : NetWare = modèle · Samba = fichiers · OpenLDAP = annuaire · MARS_NWE = référence et laboratoire.

## 6. Budget de la cible (ADR-0009) — objectifs, non mesurés

| Indicateur | Objectif profil L1 |
|---|---|
| RAM au repos | ≤ 128 Mo |
| RAM avec services réseau | ≤ 256 Mo |
| Espace disque (base / avec services) | ≤ 2 Go / ≤ 4 Go |
| Temps de démarrage (HDD) | ≤ 60 s |

## 7. Prochaine action concrète (révisée le 2026-10-27)

> **Rendre le banc rejouable, puis le durcir.** Dans cet ordre :
>
> 1. **Automatiser la redirection slirp** `127.0.0.1:4450 → VM:445` dans `scripts/31-lancer-vm-freebsd.sh`
>    (`hostfwd_add` après démarrage) : sans cela, la preuve T-05a n'est pas reproductible, et **T-11
>    (reproductibilité) reste partiel pour une raison mécanique**.
> 2. **Synchroniser l'horloge** de la VM (écart ≈ 22 min constaté) : prérequis de Kerberos et de la
>    datation fiable des preuves.
> 3. **Durcir la couche système** : `sysctl` réseau (L4) et accès SSH (clé seulement, `PermitRootLogin no`),
>    puis jails (L3).
> 4. **Client SMB réel depuis une seconde machine physique** (le Mint a servi de client : c'est déjà une
>    autre machine, mais elle héberge la VM — le test sur deux hôtes distincts reste à faire).
> 5. Alors seulement : `release.sh` + intégration continue (`docs/41`) → **image installable (J5)**.
>
> **Livrable 9 du mur (diagnostic matériel) toujours ouvert** : il n'est plus bloquant pour la progression
> du banc, mais il le reste pour **J5 sur le PC de 2011** : relever `docs/hardware.md` §2 sous Windows 7
> (lecture seule) et exécuter `scripts/00-diagnostic-hote.sh` sous Linux Mint.

**Décisions toujours attendues du responsable :** Q3 (fork assumé ?), Q4 (quand L3 ?), Q8 (VM Windows pour le banc B), Q9 (cible d'usage).

## 8. Fichiers pivots

| Sujet | Fichier |
|---|---|
| Protocole de session (à lire en premier) | `START-HERE.md` |
| Modèle de système | `docs/11-fork-pas-surcouche.md` |
| Licences et frontières | `docs/12-licences-et-frontieres.md` |
| Publication grand public | `docs/13-publication-grand-public.md` |
| Cible PC faible | `docs/09-cible-pc-faible.md` |
| Recherches sourcées | `research/*/fiche.md` |
| Risques (25) | `matrices/risques.csv` |
| Tests (15, aucun exécuté) | `tests/plan-tests.md` |
| Fiche NCP/IP (V-1 tranchée) | `research/ncp-ip/fiche.md` |
| Conformité aux 20 livrables du mur | `docs/15-conformite-mega-prompt.md` |
| Problèmes connus | `docs/16-registre-problemes.md` |
| **Le delta NexBSD (ce qui nous distingue de FreeBSD)** | `docs/22-delta-nexbsd.md` |
| Vision du produit | `docs/vision.md` |
| Cahier des charges fonctionnel (33 exigences) | `docs/02-cahier-des-charges-fonctionnel.md` |
| Où vit le projet (Drive, GitHub) | `docs/20-depots-et-sauvegardes.md` |

---

## 9. Historique des sessions

| Session | Date | Objet | Livrables |
|---|---|---|---|
| S-001 | 2026-10-23 | Phases 0 et 1 : cadrage, recherche, matrices, prototypes, plan | 26 fichiers, 8 fiches, 5 matrices, 8 ADR |
| S-002 | 2026-10-23 | Cible PC faible + station Linux Mint | ADR-0009/0010, 4 scripts, 2 documents |
| S-003 | 2026-10-23 | « Système à part entière » → modèle fork | ADR-0011 à 0015, 2 documents, 5 risques |
| S-004 | 2026-10-23 | Protocole de session, objectif grand public, outillage licence | `START-HERE.md`, `ETAT.md`, ADR-0016, `fork/`, script 40 |
| S-005 | 2026-10-23 | **Réseau : rôle des 4 composants, NCP sur IP, index complet** | ADR-0017/0018, `docs/14-reseau-netware.md`, `docs/INDEX-DOCUMENTS.md` |
| S-006 | 2026-10-23 | **V-1 tranchée (client NCP réel) + conformité aux 20 livrables du mur** | ADR-0019, `research/ncp-ip/fiche.md`, `docs/15-conformite-mega-prompt.md`, `docs/vision.md`, `docs/08-schema-flux.md`, `docs/16-registre-problemes.md`, `docs/17-procedure-mise-a-jour.md`, `docs/19-guide-contribution.md`, `LICENSE`, `NOTICE`, `CHANGELOG.md`, `docs/etude-faisabilite.md`, dossiers `components/` `integration/` `release/` |
| S-020 | 2026-10-27 | **T-05 REUSSI : `pf` actif, 11 regles, refus par defaut journalise, banc 24/24 SOUS FILTRAGE** ; C-21 (scripts/31 detecte libvirt), C-22 (netlink), C-23 (max 20/s inexistant) ; T-05a reste a faire | `tests/results/T-05-pare-feu.md`, `scripts/71`, `docs/16` |
| S-019d | 2026-10-26 | **T-18 REUSSI : harnais automatise 24/24, code de retour 0** en ~30 s — les 2 echecs de la v1.0 etaient des defauts du harnais (ls -ld, texte smbclient), pas du systeme. **Audit croise : 0 non conforme** | `tests/harnais.sh`, `tests/results/T-18-harnais.md` |
| S-019c | 2026-10-26 | **T-11 RÉUSSI : noyau REPRODUCTIBLE** — 2e construction a froid (`/build/obj2`, 6533 s) donne **exactement** `82dc5681…`, identique a la 1re. Non-conformite n.1 de l'audit croise CLOSE | `tests/results/T-11-reproductibilite.md` |
| S-019 | 2026-10-26 | **J1 COMPLET** : noyau `NEXBSD_L1` compilé, installé, démarré durablement, **banc T-04-G 11/11 sur ce noyau** (`hote : FreeBSD 15.1-NEXBSD-L1`) ; C-19 (pkgbase), C-20 (`nextboot` à usage unique) ; `docs/33` revue générale | `tests/results/T-17-noyau-propre.md`, `T-04G-persistance.md`, `docs/33`, `docs/16` |
| S-019b | 2026-10-26 | **ÉTAGE 2 FRANCHI : noyau `NEXBSD_L1` compilé, installé ET démarré — `uname -i` = `NEXBSD_L1`, `uname -r` = `15.1-NEXBSD-L1`** ; C-19 (pkgbase) consigné | `tests/results/T-17-noyau-propre.md`, `docs/28` §4 ter, `docs/16` C-19 |
| S-018 | 2026-10-25 | **Campagne de construction du noyau (étage 2) : poste mesuré, ADR-0020, scripts 67/68/69, provenance épinglée** | `docs/28-campagne-construction-noyau.md`, ADR-0020, `scripts/67`→`69`, `tests/results/T-17-noyau-propre.md` |
| S-017 | 2026-10-25 | **C-14 clos, T-04-G 11/11, identité étage 1, C-16 (delta restauré), `docs/27`** | `scripts/65`/`66`, `docs/26`/`27`, `tests/results/T-04G-persistance.md`, `T-16-identite-banc.md` |
| S-014 | 2026-10-24 | **Reprise du banc : méthode en 5 étapes, sans copier-coller, bundle s014 pour synchroniser le dépôt** | `docs/24-reprise-banc.md`, instantané s014 |
| S-010 | 2026-10-23 | **Le delta NexBSD existe en fichiers : noyau NEXBSD_L1 généré depuis GENERIC, options vérifiées, identité, chaîne de construction** | `fork/` complet, `docs/22-delta-nexbsd.md` |
| S-009 | 2026-10-23 | **Premiers tests réels en VM : T-01 et T-03 réussis ; Samba 4.23.11 et OpenLDAP 2.6/2.7 vérifiés** | `tests/results/`, `scripts/31-lancer-vm-freebsd.sh`, matrices K-01/K-09/K-10, ETAT v9 |
| S-008 | 2026-10-23 | **GitHub enregistré + dépannage du push (4 erreurs réelles) + rattrapage des commits** | `docs/21-pousser-sur-github.md`, `scripts/51-installer-depot-github.sh`, bundle `s008` |
| S-007 | 2026-10-23 | **Sauvegarde Drive + dépôt Git local + cahier des charges fonctionnel** | `docs/20-depots-et-sauvegardes.md`, `scripts/50-sauvegarder-session.sh`, `docs/02-cahier-des-charges-fonctionnel.md`, archives + bundle |

# ÉTAT DU PROJET NEXBSD — fiche de référence

**Version de cette fiche :** 7 · **Mise à jour :** 2026-10-23 (fin de session S-007)
**Rôle :** source de vérité en une page. En cas de contradiction avec un autre document, **c'est celui-ci qui décrit l'état**, car il est mis à jour à chaque session.

---

## 1. En trois phrases

NexBSD est un projet de **système d'exploitation expérimental** pour **PC faibles**, dont l'**axe prioritaire est le réseau façon NetWare** (identités, droits, partages, administration unique), visant à terme une **publication grand public**. Le modèle retenu est celui d'un **fork de FreeBSD** (arbre source possédé, images construites par le projet), avec une base **100 % sous licence permissive** et les composants réseau (Samba, OpenLDAP) isolés dans la couche Plateforme. **Rien n'est encore construit** : le projet est en phase de conception et de préparation.

---

## 2. Où en est le projet

| Élément | État au 2026-10-23 |
|---|---|
| Phase | **0 et 1 : documents produits. 2 et 3 : amorcées. 4 : non commencée.** |
| Code NexBSD | **aucun** |
| Installation FreeBSD | **aucune** (ni VM, ni matériel) |
| Test d'exécution | **aucun** — le plan compte 16 tests (T-01→T-15), tous `NON EXÉCUTÉ` |
| Image système | **aucune** (et aucune possible sans profil L3) |
| Décisions validées par le responsable | **aucune** — 19 ADR à l'état `proposition` |
| **Sauvegarde** | **Google Drive fait** (dossier « NexBSD », 5 fichiers) · **GitHub inexistant** (aucun connecteur) · dépôt Git local, 2 commits |
| Documents | ~90 fichiers, 5 matrices CSV, 5 scripts, index complet dans `docs/INDEX-DOCUMENTS.md` ; conformité au mur auditée dans `docs/15-conformite-mega-prompt.md` |
| Disque du PC de 2011 | **intact** (aucune action matérielle effectuée) |
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
| Q6 | OpenLDAP ≥ 2.6 est-il packagé sous FreeBSD ? | décision annuaire | assistant (vérification) |
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

## 7. Prochaine action concrète

> **Débloquer le livrable 9 du mur : le diagnostic matériel.**
>
> Deux relevés en lecture seule, sans rien modifier :
> 1. sous **Windows 7** sur le PC de 2011 : remplir `docs/hardware.md` §2 (modèle, CPU, RAM, disque, firmware, année) — commandes fournies, aucune installation ;
> 2. sous **Linux Mint** : exécuter `scripts/00-diagnostic-hote.sh` et joindre la sortie.
>
> C'est la seule action qui ne demande ni L3, ni matériel supplémentaire, ni décision de gouvernance — et elle débloque T-01, T-02, donc le prototype, donc l'étude de faisabilité. Les fiches de recherche, elles, sont à jour : la fiche NCP (V-1) est faite.

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
| S-004 | 2026-10-23 | Protocole de session, objectif grand public, outillage licence | `START-HERE.md`, `ETAT.md`, ADR-0016, `build/fork/`, script 40 |
| S-005 | 2026-10-23 | **Réseau : rôle des 4 composants, NCP sur IP, index complet** | ADR-0017/0018, `docs/14-reseau-netware.md`, `docs/INDEX-DOCUMENTS.md` |
| S-006 | 2026-10-23 | **V-1 tranchée (client NCP réel) + conformité aux 20 livrables du mur** | ADR-0019, `research/ncp-ip/fiche.md`, `docs/15-conformite-mega-prompt.md`, `docs/vision.md`, `docs/08-schema-flux.md`, `docs/16-registre-problemes.md`, `docs/17-procedure-mise-a-jour.md`, `docs/19-guide-contribution.md`, `LICENSE`, `NOTICE`, `CHANGELOG.md`, `docs/etude-faisabilite.md`, dossiers `components/` `integration/` `release/` |
| S-007 | 2026-10-23 | **Sauvegarde Drive + dépôt Git local + cahier des charges fonctionnel** | `docs/20-depots-et-sauvegardes.md`, `scripts/50-sauvegarder-session.sh`, `docs/02-cahier-des-charges-fonctionnel.md`, archives + bundle |

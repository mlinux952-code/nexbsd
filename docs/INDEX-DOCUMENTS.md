# Index complet des documents NexBSD

**Version :** 1.2 — 2026-10-23 (session S-007)
**Rôle :** « noter tous » — inventaire exhaustif, avec statut et résumé en une ligne. Mis à jour à chaque session.

**Légende des statuts :**
`DÉCISION` validée par le responsable · `PROPOSITION` en attente · `RECHERCHE` document sourcé · `OUTIL` script/données · `ÉTAT` fiche de suivi · `NON VALIDÉ` jamais compilé/exécuté

---

## 1. Racine

| Fichier | Statut | Résumé |
|---|---|---|
| `START-HERE.md` | **protocole** | à lire en premier : séquence, 10 règles anti-dérive, idées closes, fin de session |
| `README.md` | vitrine | vision, état réel, limites, feuille de route, arborescence |
| `00-SYNTHESE-PHASE-0-1.md` | synthèse | résultats des phases 0-1 + 2 addenda (PC faible, fork) |
| `LICENSE` | **PROPOSITION** | BSD 2-Clause (candidat, à valider par le responsable) — couvre le *code propre* NexBSD |
| `NOTICE` | squelette | attributions : FreeBSD, marques de tiers ; **aucun composant intégré à ce jour** |
| `CHANGELOG.md` | ÉTAT | historique de la **conception** (aucune version logicielle publiée) |

## 2. `docs/` — fond

| Fichier | Statut | Résumé |
|---|---|---|
| `docs/ETAT.md` | **ÉTAT** | l'état du projet en une page — source de vérité |
| `docs/00-cadrage-phase0.md` | PROPOSITION | périmètre, hypothèses H-1→H-9, contraintes, critères S-1→S-9 |
| `docs/32-audit-croise.md` | **ÉTAT** | notre travail jugé avec la grille du collègue : 7 conformes, 4 partiels, 2 non conformes, actions correctives |
| `docs/31-apport-externe-noyau-propre.md` | **DÉCISION** | analyse du noyau « depuis zéro » produit par une autre session : ce qu'on adopte, ce qu'on écarte, décision des deux couloirs |
| `docs/29-revision-totale.md` | **ÉTAT** | audit contradictoire : ce qui est prouvé, écrit, ou absent — demandé par le responsable |
| `docs/28-campagne-construction-noyau.md` | PROPOSITION | **étage 2** : ressources mesurées du poste, provenance épinglée des sources, 8 étapes, points sur les I |
| `docs/27-de-freebsd-a-nexbsd.md` | PROPOSITION | feuille de route en trois étages (identité · noyau propre · image propre) |
| `docs/decisions/ADR-0020-derogation-construction-noyau.md` | PROPOSITION | dérogation unique et bornée à l'ADR-0010 pour un seul `buildkernel` |
| `docs/09-cible-pc-faible.md` | PROPOSITION | cible L0-L3, budget de ressources opposable |
| `docs/10-station-linux-mint.md` | PROPOSITION | station de préparation, VM QEMU, limites |
| `docs/11-fork-pas-surcouche.md` | **PROPOSITION** | 3 modèles comparés, test des 7 questions, précédent HardenedBSD, 3 domaines |
| `docs/12-licences-et-frontieres.md` | PROPOSITION | qui peut entrer où, GPL-2 vs GPL-3, marques, obligations de distribution |
| `docs/13-publication-grand-public.md` | PROPOSITION | 10 portes G1-G10, 3 scénarios A/B/C |
| `docs/14-reseau-netware.md` | **PROPOSITION** | **rôle des 4 composants réseau — aucun abandonné** ; NCP sur IP ; 3 chemins |
| `docs/architecture.md` | PROPOSITION | couches A→F, 3 domaines, chaîne de construction, 5 questions ouvertes |
| `docs/architecture/README.md` | renvoi | pointe vers `08-schema-flux.md` (évite deux copies divergentes) |
| `docs/08-schema-flux.md` | **PROPOSITION** | schéma des flux entre modules (8 flux), frontières, ce qu'il ne dit pas |
| `docs/15-conformite-mega-prompt.md` | **ÉTAT** | audit des **20 livrables** du mur : 9 faits, 7 partiels, 4 non faits |
| `docs/16-registre-problemes.md` | ÉTAT | 14 problèmes ouverts (P-01→P-14), 6 clos, 3 contradictions résolues |
| `docs/17-procedure-mise-a-jour.md` | **SQUELETTE NON TESTÉ** | 3 niveaux de mise à jour, règles non négociables, retour arrière |
| `docs/19-guide-contribution.md` | référence | lire d'abord, 5 règles, ce qui est accepté/refusé, format ADR et CR |
| `docs/02-cahier-des-charges-fonctionnel.md` | **PROPOSITION** | livrable 2 : 4 acteurs, 33 exigences (S/N/C/F) avec critère d'acceptation, 8 exigences non fonctionnelles opposables |
| `docs/21-pousser-sur-github.md` | **dépannage** | les 4 erreurs réelles du 2026-10-23, leur cause, procédure en 6 étapes, configuration SSH |
| `docs/24-reprise-banc.md` | **MODE OPÉRATOIRE** | reprendre le banc en 5 étapes, sans copier-coller, avec sorties attendues |
| `docs/22-delta-nexbsd.md` | **CENTRAL** | ce qui fait de NexBSD un système : inventaire du delta, 7 questions, provenance des références, ce qui manque et pourquoi |
| `docs/20-depots-et-sauvegardes.md` | ÉTAT | où vit le projet : Drive (fait), GitHub (à faire, procédure exacte), rythme de sauvegarde, restauration d'urgence |
| `docs/vision.md` | **PROPOSITION** | livrable 1 : problème, apports, non-objectifs, 3 principes, question Q9 |
| `docs/etude-faisabilite.md` | **PROVISOIRE** | livrable 3 : 4 axes, 5 critères de conclusion, score actuel **0/5** |
| `docs/prototypes.md` | PROPOSITION | 3 prototypes comparés (23 / 15 / 10), critères Go-NoGo |
| `docs/plan-action.md` | PROPOSITION | 10 étapes + 1bis (VM), objectif/prérequis/test/risque/critère |
| `docs/hardware.md` | procédure | diagnostic non destructif du PC 2011 + tableau à remplir |
| `docs/security.md` | PROPOSITION | politique initiale, composants à risque, réponse à incident |
| `docs/roadmap.md` | PROPOSITION | phases 0→8 + 4bis/4ter, jalons J1→J9 |
| `docs/glossaire.md` | référence | 28 termes expliqués |
| `docs/source/nexbsd-mega-prompt-maitre-v1.0.md` | **source** | le document fondateur du responsable (lire Parties I, V, VII, X, XI, XVII, XVIII) |
| `docs/source/nexbsd-presentation-projet.md` | **source** | présentation initiale du projet |

## 3. `docs/decisions/` — 19 ADR

| ADR | Statut | Sujet |
|---|---|---|
| 0001 | PROPOSITION | Base = FreeBSD 15.x amd64 (à réviser si cible 32 bits) |
| 0002 | PROPOSITION | KaiOS rejeté comme base/composant |
| 0003 | PROPOSITION | Gecko B2G abandonné, WebKitGTK retenu |
| 0004 | PROPOSITION | MARS_NWE rejeté comme brique embarquée |
| 0005 | PROPOSITION | Jails + `pf` en refus par défaut |
| 0006 | PROPOSITION | Aucune modification du noyau en phase initiale |
| 0007 | PROPOSITION | Samba épinglé ≥ 4.23 |
| 0008 | PROPOSITION | Trois profils de cible séparés |
| 0009 | PROPOSITION | Le PC faible est la cible (budget opposable) |
| 0010 | PROPOSITION | Aucune compilation lourde hors profil L3 |
| 0011 | **PROPOSITION** | **Fork (arbre possédé), pas surcouche** |
| 0012 | PROPOSITION | Frontière Base (permissive) / Plateforme (GPL) |
| 0013 | PROPOSITION | Mobile = code NexBSD sur WebKitGTK ; Gaia = inspiration |
| 0014 | PROPOSITION | NCP/IPX : réimplémentation propre (révisé par 0018) |
| 0015 | PROPOSITION | Identité = budget PC faible + fonctions réseau |
| 0016 | PROPOSITION | Publication grand public conditionnée à 10 portes |
| 0017 | **PROPOSITION** | **Réseau = axe prioritaire ; rôles des 4 composants** |
| 0018 | **PROPOSITION** | **NCP sur UDP/TCP 524, pas IPX** |
| 0019 | **PROPOSITION** | **Client de test NCP = Client for Open Enterprise Server** (externe, jamais distribué) |

## 4. `research/` — 9 fiches sourcées

| Fiche | Sujet | Conclusion |
|---|---|---|
| `freebsd/fiche.md` | fondation système | retenu, 15.1, IPX absent, i386 retiré |
| `kaios/fiche.md` | dimension mobile | rejeté comme composant, gardé comme référence UX |
| `firefox-os/fiche.md` | donneur de composants | Gaia Apache-2.0 = inspiration ; Gonk/Gecko abandonnés |
| `netware/fiche.md` | modèle réseau | modèle retenu ; N-1→N-11 comme cahier des charges |
| `mars-nwe/fiche.md` | compatibilité historique | rejeté comme brique ; retenu comme banc d'essai |
| `samba/fiche.md` | fichiers/impression | retenu ≥ 4.23 ; 4.16 par défaut = dangereux |
| `openldap/fiche.md` | annuaire | retenu ≥ 2.6 sous condition de disponibilité |
| `runtime-web/fiche.md` | moteur mobile | WebKitGTK retenu (candidat non prévu au départ) |
| `ncp-ip/fiche.md` | **protocole NCP sans IPX** | **V-1 OUI** (client OES 26.2.1) ; V-2 partiel ; V-3 probable ; 2 bancs d'essai ; périmètre NCP-1→NCP-6 |

## 5. `matrices/` — 5 CSV + notice

| Fichier | Lignes | Contenu |
|---|---|---|
| `components.csv` | 14 | composants, version, licence, statut, priorité |
| `functions.csv` | 25 | fonctions par couche, priorité P0-P3, test prévu |
| `licences.csv` | 14 | licence, copyleft, **admission dans la base**, obligations |
| `compatibilite.csv` | 15 | questions K-01→K-15 et réponses (OUI/NON/INCONNU) |
| `risques.csv` | 24 | R-01→R-24 : probabilité, impact, mitigation |
| `README.md` | — | conventions de statut et de priorité |

## 6. `tests/` — plan

| Fichier | Contenu |
|---|---|
| `plan-tests.md` | 15 tests (T-01 → T-13 + variantes), **aucun exécuté**, format de compte rendu, mesures à relever |

## 7. `scripts/` — outillage (7 scripts + notice)

| Script | Vérifié ? | Rôle |
|---|---|---|
| `00-diagnostic-hote.sh` | ✅ exécuté | relève CPU/RAM/disque/KVM (lecture seule) |
| `10-verifier-image.sh` | ✅ exécuté (3 cas) | vérifie SHA256/SHA512 d'une image |
| `20-ecrire-usb.sh` | ⚠️ **non testé sur matériel** | écrit une clé USB, 6 garde-fous |
| `30-qemu-freebsd.sh` | ⚠️ syntaxe seulement | lance FreeBSD en VM (1 Go) |
| `40-verifier-frontiere-licence.sh` | ✅ exécuté (3 cas) | contrôle T-13 : copyleft hors de la base |
| `51-installer-depot-github.sh` | ✅ exécuté (3 cas, push testé vers un dépôt local factice) | installe le dépôt depuis le bundle et prépare GitHub ; refuse dossier existant ; ne pousse pas |
| `50-sauvegarder-session.sh` | ✅ exécuté (2 cas : succès + mauvais répertoire) | instantané daté + `SHA256SUMS.txt` ; n'envoie rien par réseau |

## 8. `fork/` — delta propre (aucun fichier compilé)

| Fichier | Statut | Rôle |
|---|---|---|
| `README.md` | NON VALIDÉ | organisation du delta, ordre d'exécution |
| `src.conf` | **NON VALIDÉ** | options de construction (on retire, on n'ajoute pas) |
| `NEXBSD_L1` | **NON VALIDÉ** | noyau : part de GENERIC et retire |
| `release.conf` | **NON VALIDÉ** | réglages de production d'image |
| `exceptions-licence.txt` | vide (état souhaité) | exemptions justifiées du contrôle T-13 |
| `build-nexbsd.sh` | syntaxe OK, **non exécuté** | chaîne garde-fou (refuse hors FreeBSD, <8 Go, <40 Go) |

## 9. `reports/` — 7 comptes rendus

| Fichier | Session | Objet |
|---|---|---|
| `session-2026-10-23.md` | S-001 | phases 0-1 : cadrage, recherche, matrices, prototypes |
| `session-2026-10-23-suite.md` | S-002 | cible PC faible + station Linux Mint |
| `session-2026-10-23-fork.md` | S-003 | « système à part entière » → modèle fork |
| `session-2026-10-23-protocole.md` | S-004 | protocole anti-dérive, publication, outillage licence |
| `session-2026-10-23-reseau.md` | S-005 | **réseau : rôles des 4 composants, NCP sur IP** |
| `session-2026-10-23-conformite.md` | S-006 | V-1 tranchée, audit des 20 livrables, comblement des manques documentaires |
| `session-2026-10-23-sauvegarde.md` | S-007 | sauvegarde Drive vérifiée, dépôt Git local, cahier des charges fonctionnel |

---

## 10. Ce qui n'existe pas (et qu'il ne faut pas prétendre exister)

- Aucun code source NexBSD.
- Aucune image système.
- Aucune installation, aucun test d'exécution.
- Aucun dépôt GitHub, aucun document téléversé sur Google Drive.
- Aucune décision validée par le responsable (19 ADR en proposition).
- Aucune fiche dans `components/`, rien dans `integration/`, aucune image dans `release/` (dossiers créés pour la Partie XIII, avec leur mode d'emploi).
- Aucune étude de faisabilité **conclue** (`docs/etude-faisabilite.md` : 0 critère sur 5 satisfait).
- Aucun guide d'installation **validé** (impossible sans installation réelle).
- Aucune version publiée : `CHANGELOG.md` ne retrace que la conception.

## 11. Dossiers créés pour la Partie XIII (exigence d'arborescence)

| Dossier | Contenu actuel | Ce qu'il doit contenir |
|---|---|---|
| `components/` | `README.md` avec modèle de fiche | une fiche par composant retenu (priorité : Samba, OpenLDAP, NCP NexBSD, WebKitGTK) |
| `integration/` | `README.md` | configurations, gabarits de jail, règles `pf`, procédures **exécutées et vérifiées** |
| `release/` | `README.md` | scripts de production d'image, notes de version, sommes de contrôle, journal des publications (vide) |
| `docs/architecture/` | `README.md` (renvoi) | à terme : `flux.md`, diagrammes, décisions d'architecture détaillées |
| `25-compte-rendu-session.md` | Compte rendu de session normalisé (Parties XVIII et XX §7) — permet la reprise sans conversation | 2026-10-24 |
| `33-revue-generale-2026-10-26.md` | Revue générale : les 4 étages, matrice des 24 ingrédients d'un vrai système, 6 conditions, trajectoire, points sur les i | 2026-10-26 |
| `34-pourquoi-composants-ecartes.md` | Causes exactes du rejet de Firefox OS et MARS_NWE (licence != cause) + regle generale « quand l'age disqualifie » | 2026-10-26 |
| `35-reutilisation-bornee-gaia-mars.md` | Proposition de 2 experiences bornees : porter 1 app Gaia (Apache-2.0) sur WebKitGTK + banc A MARS_NWE pour ecrire la spec NetWare ; plateforme Gaia exclue, MARS_NWE hors produit | 2026-10-26 |
| `36-alternatives-annuaire.md` | Mise au point : 389 DS et FreeIPA sont des alternatives a OpenLDAP, pas a MARS_NWE ; comparaison et maintien d'OpenLDAP | 2026-10-26 |
| `37-apport-externe-centre-de-commande.md` | Contribution n° 2 examinee : principe P-CC adopte (couche D-4), liste des 10 systemes ramenee a une veille, recommandation 'FreeBSD option parmi d'autres' rejetee sur preuve | 2026-10-26 |
| `38-securite-defense-en-profondeur.md` | 8 couches de securite, etat de chacune, priorites ; pf = L1 fait ce soir, jails L3 et restauration L8 prioritaires apres l'image | 2026-10-26 |

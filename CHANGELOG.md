# Historique des versions — NexBSD

Format inspiré de [Keep a Changelog](https://keepachangelog.com/fr/1.1.0/).
**Aucune version n'a été publiée.** Les entrées ci-dessous retracent l'avancement de la **documentation de conception**, pas des versions logicielles.

## [Non publié] — phase de conception

### 2026-10-23 — Session S-006 : lecture du mur, conformité, NCP sur IP
- **Ajouté** : `research/ncp-ip/fiche.md` — V-1 résolu : le *Client for Open Enterprise Server* (OpenText, v26.2.1, août 2026) parle NCP sur le port 524 et peut servir de client de test.
- **Ajouté** : `docs/15-conformite-mega-prompt.md` — audit des 20 livrables exigés par le méga-prompt.
- **Ajouté** : `LICENSE` (BSD 2-Clause, **candidat**, à valider), `NOTICE` (squelette), `CHANGELOG.md`, `docs/08-schema-flux.md`, `docs/16-registre-problemes.md`, `docs/17-procedure-mise-a-jour.md`, `docs/19-guide-contribution.md`.
- **Ajouté** : ADR-0019 (client de test NCP).
- **Modifié** : `docs/ETAT.md` v6, `docs/INDEX-DOCUMENTS.md`, registre des risques.

### 2026-10-23 — Session S-005 : le réseau, axe prioritaire
- **Ajouté** : `docs/14-reseau-netware.md` — rôle des quatre composants réseau (aucun abandonné) ; ADR-0017.
- **Ajouté** : ADR-0018 — cible protocolaire **NCP sur UDP/TCP 524**, plus IPX.
- **Corrigé** : `matrices/compatibilite.csv`, `functions.csv`, `risques.csv` — virgules non échappées (ouverture tableur défaillante).
- **Ajouté** : `docs/INDEX-DOCUMENTS.md` — index exhaustif.

### 2026-10-23 — Session S-004 : protocole anti-dérive et publication
- **Ajouté** : `START-HERE.md` (protocole de session), `docs/ETAT.md` (état en une page), `docs/13-publication-grand-public.md` (10 portes G1-G10, 3 scénarios), ADR-0016.
- **Ajouté** : `scripts/40-verifier-frontiere-licence.sh` (contrôle T-13, testé sur 3 cas).
- **Ajouté** : `build/fork/` — squelette du delta propre (`src.conf`, `NEXBSD_L1`, `release.conf`, `build-nexbsd.sh`). **Aucun fichier compilé.**

### 2026-10-23 — Session S-003 : « système à part entière » → fork
- **Ajouté** : `docs/11-fork-pas-surcouche.md` (3 modèles, test des 7 questions, précédent HardenedBSD), `docs/12-licences-et-frontieres.md`, ADR-0011 à 0015.
- **Retiré** : le modèle « FreeBSD + paquets » comme modèle cible.

### 2026-10-23 — Session S-002 : cible PC faible et station Linux
- **Ajouté** : `docs/09-cible-pc-faible.md` (profils L0-L3, budget), `docs/10-station-linux-mint.md`, ADR-0009/0010.
- **Ajouté** : `scripts/00…30` (diagnostic, vérification d'image, écriture USB, QEMU).

### 2026-10-23 — Session S-001 : phases 0 et 1
- **Ajouté** : cadrage, 8 fiches de recherche sourcées, 5 matrices, 3 prototypes comparés, plan d'action, plan de tests, ADR-0001 à 0008.
- **Constat** : trois hypothèses du concept initial sont infirmées (KaiOS réutilisable, Gecko intégrable, MARS_NWE portable).

## Légende
- Aucune entrée ne correspond à une **version logicielle** : NexBSD n'a ni code, ni image, ni installation.

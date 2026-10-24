# Historique des versions — NexBSD

Format inspiré de [Keep a Changelog](https://keepachangelog.com/fr/1.1.0/).
**Aucune version n'a été publiée.** Les entrées ci-dessous retracent l'avancement de la **documentation de conception**, pas des versions logicielles.

## [Non publié] — phase de conception

### 2026-10-24 — Session S-015 : T-04-E, diagnostic de la preuve 3 et script v3
- **Exécuté** : T-04-E essai 1 (**ECHEC**) puis essai 2 (**PARTIEL**) sur la VM du banc — journals verbatim dans `tests/results/T-04E-samba-ldap.md`.
- **Acquis** : Samba compilé avec LDAP (`smbd` lié à `libldap`), `samba.schema` chargé et validé par `slaptest`, `sambaSID` de `omrane` **stocké dans l'annuaire**, `smbpasswd -a` opérant sur `ldapsam`.
- **Diagnostiqué** : la preuve 3 échoue en `NT_STATUS_CONNECTION_REFUSED` **non** à cause d'une identité refusée, mais parce que `smbd` met ≈ 9 s à être à l'écoute alors que le script attendait un délai fixe de 3 s (`sockstat` montre `*:445` en écoute, journal : démarrage 12:16:15 → prêt 12:16:24). Consigné en **C-11** (`docs/16`), C-10 passé à **clos**.
- **Corrigé** : `scripts/62-banc-T04E-samba-ldap.sh` **version 3** — attente active de l'écoute sur `:445` (90 s max), 5 reprises sur la preuve 3, repli sur l'adresse réseau de la VM, messages différenciés service / identité.
- **REUSSI** : T-04-E **essai 3** (2026-10-24) — `smbclient //127.0.0.1/partage -U 'omrane%omranelab'` s'authentifie et liste le partage ; les trois preuves sont réunies. Verdict consigné, réserves (rejouabilité, droits multi-utilisateurs, TLS) écrites.
- **Bilan des tests** : **4 sur 16** réussis (T-01, T-03, T-04, T-04-E).

### 2026-10-24 — Session S-014 : reprise professionnelle du banc
- **Ajouté** : `docs/24-reprise-banc.md` — mode opératoire en 5 étapes (mise à jour du dépôt, console dans le terminal, service de fichiers, T-04, consignation).
- **Ajouté** : instantané `s014` (29 commits) sur Google Drive, avec empreintes SHA-256.
- **Constat** : la VM du responsable tourne (virt-manager + KVM) et une invite root a été atteinte ; le copier-coller dans la fenêtre graphique ne fonctionne pas (absence de `spice-vdagent` dans l'invité) → contournement par `virsh console` et serveur HTTP local.

### 2026-10-23 — Session S-010 : le delta NexBSD devient du code
- **Ajouté** : `build/fork/reference/` — GENERIC, `src.conf.5`, `newvers.sh`, `config.5` officiels de `releng/15.1` (provenance et URL consignées).
- **Ajouté** : `build/fork/tools/generer-kernel-conf.sh` — **exécuté** : produit `NEXBSD_L1` depuis GENERIC avec 4 retraits motivés et un rapport auditable.
- **Ajouté** : `src.conf` avec **uniquement des options vérifiées** dans la documentation amont ; `release.conf`, `overlay/etc/*`, `patches/0001-identite-version.patch` (non appliqué), `build-nexbsd.sh` (garde-fous testés).
- **Ajouté** : `docs/22-delta-nexbsd.md` — distinction socle/produit, inventaire du delta, 7 questions, Q4 reformulée.
- **Aucun fichier compilé, aucune image produit.**

### 2026-10-23 — Session S-009 : **premiers tests réels en machine virtuelle**
- **Exécuté** : T-01 **réussi** — FreeBSD 15.1-RELEASE démarre en VM QEMU (image officielle, SHA256 vérifié), 81 s jusqu'à `login:`.
- **Exécuté** : T-03 **réussi** — Samba 4.23.11 installé depuis les dépôts, partage authentifié, fichier écrit depuis une autre machine et relu côté serveur.
- **Mesuré** : ≈ 100 Mo de RAM au repos sur système nu (objectif ENF-01 ≤ 128 Mo atteignable).
- **Vérifié dans les dépôts FreeBSD** : samba 4.23.11 / 4.24.7 ; openldap 2.5.20 / 2.6.15 / 2.7.1 → **Q6 et V-4 résolues**.
- **Ajouté** : `tests/results/T-01-demarrage-freebsd.md`, `tests/results/T-03-partage-samba.md`, `scripts/31-lancer-vm-freebsd.sh`.
- **Corrigé** : doublon d'identifiant dans `matrices/compatibilite.csv` (K-15 → K-16).

### 2026-10-23 — Session S-008 : GitHub enregistré
- **Fait (par le responsable)** : dépôt **privé** `mlinux952-code/nexbsd`, branche `main`, push accepté (`* [new branch] main -> main`), authentification SSH vérifiée.
- **Ajouté** : `docs/21-pousser-sur-github.md` — les erreurs réelles rencontrées (bundle introuvable, mauvais dossier, `origin` étranger, `Permission denied (publickey)`, `Key is invalid`, presse-papiers contenant la commande) et leur correction.
- **Ajouté** : `scripts/51-installer-depot-github.sh` — installation du dépôt depuis un bundle (testé 3 cas).
- **Corrigé** : `docs/20-depots-et-sauvegardes.md` — GitHub passe de « inexistant » à « fait », + procédure de rattrapage par bundle.

### 2026-10-23 — Session S-007 : sauvegarde, dépôt, cahier des charges
- **Ajouté** : dépôt **Git local** (1 commit initial, 90 fichiers) + `.gitignore`.
- **Ajouté** : sauvegarde **Google Drive** vérifiée (dossier « NexBSD » : archive, bundle Git, manifeste, empreintes, Doc de lecture).
- **Ajouté** : `docs/20-depots-et-sauvegardes.md` — où vit le projet ; **GitHub : procédure exacte, non exécutée** (aucun connecteur disponible).
- **Ajouté** : `scripts/50-sauvegarder-session.sh` — instantané daté (testé : 2 cas).
- **Ajouté** : `docs/02-cahier-des-charges-fonctionnel.md` — livrable 2 : 33 exigences avec critères d'acceptation.
- **Ajouté** : test **T-15** (découverte de services) pour la traçabilité de EF-N-10.
- **Modifié** : `docs/ETAT.md` v7, `docs/INDEX-DOCUMENTS.md` v1.2, `docs/16-registre-problemes.md` (C-07, C-08, P-13 partiel).

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

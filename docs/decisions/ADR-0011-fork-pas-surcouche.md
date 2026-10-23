# ADR-0011 — NexBSD est un fork (arbre possédé), pas une surcouche de paquets

- **Date :** 2026-10-23
- **Statut :** proposition
- **Référence :** `docs/11-fork-pas-surcouche.md`
- **Remplace partiellement :** l'approche « assemblage » proposée en ADR-0001 (qui ne statuait pas sur la possession de l'arbre)

## Problème
Le responsable du projet refuse explicitement que NexBSD soit « un FreeBSD modifié avec quelques logiciels en surplus ». Le modèle d'assemblage (FreeBSD installé + paquets) ne produit pas un système, mais une configuration.

## Décision proposée
Adopter le modèle **fork M2 — fork léger** :

1. NexBSD **possède son arbre source** (clone de FreeBSD, branches propres `nexbsd/*`).
2. Il **construit lui-même** ses images (`src.conf`, `KERNCONF`, `release.sh`, puis `pkgbase`).
3. Il **signe et publie** ses propres versions, avec son cycle.
4. Il **assure le suivi de sécurité** de sa base par fusion régulière de l'amont.
5. Le **delta propre** (ce que NexBSD change) est **petit, justifié par ADR, isolé et fusionnable**.

## Justification
- La licence BSD-2 de FreeBSD autorise explicitement ce modèle.
- C'est le modèle de projets réels et vivants : GhostBSD, NomadBSD, MidnightBSD, HardenedBSD.
- HardenedBSD démontre qu'une équipe de deux personnes peut maintenir un fork depuis 2014 — à condition de garder un delta faible et de pratiquer la fusion amont (`cherry-pick` de correctifs de sécurité, rapports de statut 2026).
- C'est le seul modèle qui réponde à la demande « système à part entière ».

## Conséquences
- Le projet devient **responsable des correctifs de sécurité** de toute sa base (risque R-17).
- Une **machine de construction sérieuse** (profil L3) devient nécessaire pour produire des images ; d'ici là, aucun livrable ne doit *dépendre* de cette capacité (ADR-0010).
- Le prototype actuel (assemblage, en VM) change de statut : il **dérisque les composants** de la future Plateforme, il ne produit pas le produit.
- Interdiction de la marque « FreeBSD » dans le nom du produit (politique de marque de la FreeBSD Foundation).

## Articulation avec ADR-0006 (pas de modification du noyau)
Sans contradiction : NexBSD **configure** son noyau (`KERNCONF`, `src.conf` — c'est de la configuration, pas du code) mais ne **modifie pas** le code du noyau. Toute modification de code resterait soumise à ADR-0006 et exigerait une preuve d'impossibilité par les mécanismes existants.

## Conditions de révision
- Si la charge de suivi de sécurité s'avère intenable : redescendre vers un modèle hybride (base officielle FreeBSD + couche produit très forte), en l'assumant explicitement.
- Si L3 ne se matérialise jamais : le fork reste une intention documentée, et le projet livre une **distribution de configuration** — ce qui doit être dit, jamais maquillé.

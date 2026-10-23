# ADR-0002 — KaiOS n'est ni la base ni un composant de NexBSD

- **Date :** 2026-10-23
- **Statut :** proposition
- **Référence :** `research/kaios/fiche.md`

## Problème
Peut-on réutiliser KaiOS comme plateforme mobile de NexBSD ?

## Faits
- KaiOS est un logiciel **propriétaire** ; seuls certains composants sont publiés (MPL pour l'héritage B2G, GPLv2 pour les correctifs noyau Linux).
- Il repose sur « Gonk » = noyau Linux + HAL Android : incompatible avec un noyau FreeBSD.
- Aucune image complète ne peut être construite publiquement (bootloader, RIL, pilotes, blobs OEM non distribués).

## Décision proposée
**Rejeter KaiOS** comme base système et comme composant. **Retenir ses principes d'interaction** comme exigences de conception testables.

## Conséquences
- La couche mobile sera conçue par NexBSD (coquille + applications Web).
- Toute communication doit dire « inspiré de KaiOS », jamais « portage de KaiOS ».
- Les critères UX (M-01 à M-08, matrice des fonctions) deviennent des exigences du projet.

## Conditions de révision
Aucune envisagée, sauf changement de licence de KaiOS (hautement improbable) ou autorisation écrite de l'éditeur.

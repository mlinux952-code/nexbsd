# ADR-0006 — Aucune modification du noyau en phase initiale

- **Date :** 2026-10-23
- **Statut :** proposition

## Problème
Faut-il modifier le noyau FreeBSD pour NexBSD ?

## Décision proposée
**Non** en phase 0 à 4. Aucune fonction du périmètre actuel (fichiers, annuaire, interface Web) ne l'exige. Toute modification éventuelle devra faire l'objet d'un ADR dédié avec preuve d'impossibilité par les mécanismes existants.

## Justification
Coût de maintenance très élevé, risque de sécurité, perte de la capacité à suivre les mises à jour FreeBSD. Le projet n'a pas démontré qu'un besoin l'exige.

## Conséquences
- La compatibilité IPX est abandonnée plutôt que résolue par le noyau (cohérent avec ADR-0004).
- Le projet reste « intégrateur » et non « mainteneur de noyau », ce qui est réaliste pour une équipe réduite.

## Conditions de révision
Preuve documentée qu'une fonction P0/P1 est impossible sans modification du noyau.

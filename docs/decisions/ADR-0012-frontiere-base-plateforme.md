# ADR-0012 — Frontière stricte entre NexBSD Base et NexBSD Platform

- **Date :** 2026-10-23
- **Statut :** proposition
- **Référence :** `docs/12-licences-et-frontieres.md`

## Problème
NexBSD veut intégrer Samba (GPL-3), MARS_NWE (GPL-2), WebKitGTK (GPL/LGPL) et OpenLDAP (permissive). Si ce code entre dans l'arbre de base, l'ensemble devient soumis au copyleft et NexBSD perd la maîtrise de sa propre base.

## Décision proposée
Trois domaines, trois régimes :

| Domaine | Licences admises | Exemple |
|---|---|---|
| **NexBSD Base** | permissives uniquement (BSD, ISC, MIT, Apache-2) | noyau, libc, userland, rc.d |
| **NexBSD Platform** | toutes, y compris GPL | Samba, OpenLDAP, WebKitGTK, CUPS |
| **NexBSD Apps** | au choix du projet | coquille mobile, outil d'admin |

Règles :
1. **Aucun code GPL lié ou copié dans la base.**
2. Les composants copyleft sont des **paquets et des processus séparés**.
3. Une **image de release** peut contenir des paquets GPL, à condition de fournir les sources correspondantes et les notices.
4. Vérification automatisée : recherche de `SPDX-License-Identifier: GPL` dans l'arbre de base en intégration continue.

## Justification
- FreeBSD applique déjà cette règle dans son propre arbre (FreeBSD Licensing Policy : isoler les licences non-BSD pour « ne pas contaminer les composants BSD »).
- GPL-2 et GPL-3 sont **incompatibles entre elles** : les séparer évite un conflit réel (MARS_NWE vs Samba).
- La base reste petite, donc compatible avec le budget « PC faible » (ADR-0009).

## Conséquences
- NexBSD doit maintenir un **dépôt de sources Plateforme** correspondant à chaque image.
- L'installateur doit permettre de **ne pas installer** les composants GPL (choix de l'utilisateur).
- La documentation doit dire clairement ce qui est base et ce qui est plateforme.

## Conditions de révision
Si un composant indispensable au fonctionnement de base s'avère n'exister qu'en GPL (situation à éviter activement).

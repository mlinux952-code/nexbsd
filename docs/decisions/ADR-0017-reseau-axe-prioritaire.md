# ADR-0017 — Le réseau façon NetWare est l'axe prioritaire ; les quatre composants ont chacun un rôle

- **Date :** 2026-10-23
- **Statut :** proposition
- **Référence :** `docs/14-reseau-netware.md`
- **Complète :** ADR-0015 (identité), ADR-0014 (NCP/IPX, révisé)

## Problème
Le responsable du projet craint l'abandon des composants réseau (NetWare, MARS_NWE, Samba, OpenLDAP). Il faut lever toute ambiguïté sur le rôle de chacun et sur la priorité du réseau dans le projet.

## Décision proposée
1. **Le réseau est l'axe prioritaire** de NexBSD (avec le budget PC faible), pas une annexe. Les fonctions N-1 (partages), N-2 (droits), N-6 (scripts de connexion) et N-8 (administration centralisée) sont **P0/P1**.
2. **Samba** = composant retenu pour les fichiers et l'impression (Plateforme, ≥ 4.23).
3. **OpenLDAP** = composant retenu pour l'annuaire (Plateforme, ≥ 2.6 sous condition de disponibilité).
4. **NetWare** = **modèle fonctionnel de référence** : ce que le système doit savoir faire.
5. **MARS_NWE** = **banc d'essai et source de spécification**, jamais brique embarquée (GPL-2 + dépendance IPX, cf. ADR-0004).
6. **Aucun de ces quatre composants n'est abandonné.** Leur présence et leur rôle sont distincts et documentés.

## Justification
- Le réseau est l'élément différenciant du projet : sans lui, NexBSD n'est qu'un BSD allégé de plus.
- Samba et OpenLDAP fournissent des fonctions éprouvées et maintenues, sans risque juridique pour la base.
- MARS_NWE, bien qu'intégrable nulle part, est la meilleure source publique d'observation du comportement NetWare — sa valeur est documentaire et expérimentale.

## Conséquences
- La priorité P0/P1 du réseau impose que le prototype 0 (`docs/prototypes.md`) soit conservé : il est la première marche du réseau, pas un détour.
- L'outil d'administration (N-8) devient un **livrable d'identité**, pas un accessoire.
- Un nouveau livrable est exigé : `docs/spec-netware-observee.md`, issu du laboratoire.
- Aucune communication ne devra dire que Samba « remplace » NetWare : il en met en œuvre les **fonctions**, pas le protocole.

## Conditions de révision
- Si V-1 (aucun client NCP sur port 524 disponible) et V-3 (montage MARS_NWE irréalisable) échouent tous les deux : le chemin protocolaire est abandonné, les chemins 1 et 2 restent.

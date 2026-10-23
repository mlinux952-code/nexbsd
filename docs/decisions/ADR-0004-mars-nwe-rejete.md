# ADR-0004 — MARS_NWE rejeté comme composant ; conservé comme référence

- **Date :** 2026-10-23
- **Statut :** proposition
- **Référence :** `research/mars-nwe/fiche.md`, `research/netware/fiche.md`

## Problème
Comment assurer la compatibilité avec les protocoles NetWare historiques ?

## Faits
- MARS_NWE (GPL-2.0) n'a pas évolué depuis 2013 (0.99.pl23).
- Il **exige IPX**, retiré de FreeBSD en 11.0 et de Linux en 4.17 (module noyau hors arbre nécessaire pour Linux récent).
- L'auteur du dépôt avertit explicitement de vulnérabilités et recommande un réseau privé ; le code fait des appels fichiers en root.
- Il n'implémente pas NDS, ni NetWare/IP, ni NCP sur IP natif.

## Décision proposée
- **Rejeter** MARS_NWE comme composant intégré à NexBSD.
- Le conserver comme **référence technique** accessible uniquement dans un laboratoire isolé (option 3, non prioritaire).
- Ne jamais qualifier Samba de « compatible NetWare ».

## Conséquences
- La Couche D-3 est hors périmètre du prototype.
- Le modèle fonctionnel NetWare (identités, droits, trustees, scripts de login) reste le cahier des charges de la Couche D, réalisé avec Samba + OpenLDAP.

## Conditions de révision
- Si un besoin réel d'interopérabilité NCP/IPX était démontré (client existant identifié).
- Si un portage FreeBSD avec pile IPX en espace utilisateur était financé et testé.

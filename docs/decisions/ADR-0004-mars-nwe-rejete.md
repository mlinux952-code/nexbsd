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

## Réexamen du 2026-10-26 (déclenché par ADR-0019)

La condition de révision est **atteinte** : ADR-0019 a identifié un client NCP réel et maintenu
(Client for Open Enterprise Server 26.2.1, port 524). Le rejet est **maintenu**, mais pour une raison
technique explicite et non par inertie : MARS_NWE **exige IPX** (retiré de FreeBSD 11.0) et **ne sait pas
parler NCP sur IP**. La réponse au besoin est **ADR-0018** (réimplémentation propre de NCP sur UDP/TCP 524),
pas l'adoption de MARS_NWE. Voir `docs/34-pourquoi-composants-ecartes.md`.

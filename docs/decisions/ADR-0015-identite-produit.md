# ADR-0015 — L'identité de NexBSD repose sur deux axes : budget PC faible mesuré et fonctions réseau

- **Date :** 2026-10-23
- **Statut :** proposition

## Problème
Un fork sans identité n'est qu'un renommage. Que peut affirmer NexBSD qu'aucun autre BSD n'affirme ?

## Options
| Axe | Réalisable sans matériel exotique ? | Quelqu'un d'autre le fait ? |
|---|---|---|
| A — Budget de ressources garanti et publié | oui | non (aucun BSD ne publie un contrat d'empreinte) |
| B — Fonctions réseau façon NetWare (identités, droits, administration unique) | oui | non sous cette forme |
| C — Image mobile Web | non (pas de pilotes téléphonie) | non |
| D — Sécurité renforcée | oui | oui (HardenedBSD, OpenBSD) |

## Décision proposée
Construire l'identité sur **A + B** :
- **A :** chaque version publie ses mesures (RAM au repos, RAM avec services, espace disque, temps de démarrage) et un plafond assumé.
- **B :** un modèle de droits simple et lisible + un outil d'administration unique, inspirés des fonctions NetWare.

**C** reste une démonstration logicielle, jamais une promesse produit. **D** n'est pas un axe différenciant.

## Conséquences
- Les mesures deviennent un **livrable obligatoire** de chaque version, pas une option.
- Le ton de la communication s'aligne : « le système qui tient dans X Mo et qui gère un petit réseau comme un serveur de fichiers des années 90, mais proprement ».
- Si A ou B échoue, l'identité s'effondre → à surveiller à chaque jalon.

## Conditions de révision
Si les mesures montrent que A est intenable sur le matériel cible, ou si B n'intéresse personne à l'usage.

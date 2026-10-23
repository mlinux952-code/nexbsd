# Feuille de route

**Date :** 2026-10-23 — **Statut :** proposition

| Phase | Objectif | Livrable | Critères de sortie | État |
|---|---|---|---|---|
| 0 | Cadrage | document fondateur, périmètre, critères de réussite | validé par le responsable | **documents produits — validation en attente** |
| 1 | Recherche et inventaire | fiches sourcées + matrices composants/licences/compatibilité | chaque candidat a une fiche datée et un statut | **produit — incertitudes marquées À VÉRIFIER** |
| 2 | Étude de faisabilité | rapport de faisabilité + registre des risques | risques majeurs évalués, Go/No-Go par composant | **amorcé** (risques R-01 à R-16) |
| 3 | Architecture | architecture détaillée, interfaces, flux, ADR | décisions tracées, interfaces définies | **squelette (v0.1)** |
| 4 | Preuve de faisabilité | prototype 0 + rapport de validation | T-01 à T-06 réussis, mesures consignées | **non commencé** |
| **4bis** | **Devenir un fork** (nécessite L3) : arbre source possédé, `src.conf`/`KERNCONF`, premier `buildworld`/`buildkernel`, image signée | image `nexbsd-lab` construite par le projet | build reproductible, image amorçable, delta documenté | non commencé |
| **4ter** | pkgbase NexBSD : base système en paquets signés | dépôt pkgbase du projet | installation et mise à jour par paquets NexBSD | non commencé |
| 5 | Intégration progressive de la Plateforme (Samba, OpenLDAP, WebKit en couches séparées) | version de développement | un composant ajouté = tests + doc mis à jour + licence vérifiée | non commencé |
| 6 | Validation | rapport de validation | sécurité, stabilité, performance mesurées | non commencé |
| 7 | Distribution expérimentale | image de démonstration + procédure de récupération | image rejouable, retour arrière testé | non commencé |
| 8 | Évolution | feuille de route actualisée | — | non commencé |

## Règle de progression

Une phase n'est déclarée terminée que si **tous** ses critères de sortie sont remplis et prouvés. Aucune phase ne peut être sautée. Aucune phase ne peut être déclarée « terminée à 80 % » dans un document officiel : on écrit « en cours » avec la liste de ce qui manque.

## Jalons identifiés

- **J1** — FreeBSD démarre sur le matériel de test (T-01) : *inconnu à ce jour*
- **J2** — inventaire matériel complet documenté (T-02)
- **J3** — partage Samba avec droits vérifiés (T-03)
- **J4** — décision LDAP tranchée, avec preuve (T-04 ou ADR de report)
- **J5** — restauration exercée (T-06)
- **J6** — rapport de validation du prototype 0
- **J7** — démonstration d'interface petit écran (T-10)
- **J8** — première image **construite par NexBSD** (et non installée depuis FreeBSD) : c'est le jalon qui fait de NexBSD un système
- **J9** — premier delta propre versionné et documenté dans la base (ex. noyau allégé + empreinte mesurée)

## Ce qui n'est pas planifié (assumé)

- Un système utilisable sur téléphone.
- La compatibilité NetWare protocolaire.
- Une distribution grand public.

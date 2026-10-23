# ADR-0008 — Trois profils de cible strictement séparés

- **Date :** 2026-10-23
- **Statut :** proposition

## Problème
Le concept initial mélange un système de bureau/serveur et un système mobile. Cette confusion conduit à des promesses intenables (téléphonie, énergie, pilotes).

## Décision proposée
Définir et nommer trois profils distincts, jamais confondus dans les rapports :

| Profil | Cible | Ce qu'on peut affirmer |
|---|---|---|
| **Lab** | PC 2011 amd64 / VM / support externe | système utilisable, services, mesures |
| **NetServer** | PC ou VM sur réseau isolé | fichiers + annuaire + droits |
| **MobileExp** | logiciel seulement (matériel ARM non requis au départ) | interface petit écran, applications Web |

Toute affirmation doit préciser le profil concerné.

## Justification
Évite l'auto-illusion (risque R-10) ; permet de livrer un résultat utile même si le profil mobile n'aboutit jamais.

## Conséquences
- Les rapports de version séparent explicitement ce qui est vérifié pour chaque profil.
- Le profil MobileExp n'implique aucune promesse de téléphonie/SMS/capteurs.

## Conditions de révision
Si un support matériel ARM abouti (par ex. FreeBSD sur un appareil réel) rend MobileExp matériellement démontrable.

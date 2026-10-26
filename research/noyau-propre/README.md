# Couloir recherche — noyau « depuis zéro » (P1)

**Statut : recherche. Ce n'est PAS le produit NexBSD, et aucun document ne doit le présenter comme tel.**

## Provenance

| Élément | Valeur |
|---|---|
| Source | archive `workspace-01a178c9-….zip` fournie par le responsable le 2026-10-26 |
| Taille / empreinte | 12 038 643 o · sha256 `7f754cfd28aba5200e315449bdec43da849e8bdf5561d48166b58668f3e67389` |
| Producteur | une **autre session** d'assistant (Arena.ai), 2026-10-26 |
| Image produite | `nexbsd-p1.iso`, 4 460 544 o, sha256 `f8dd79c2a6439e7819eee41e00de62d1062dfdd91b00d03d5d6f3ece5138266f` |
| Noyau (M8) | 59 840 octets · 3 246 lignes de C au total |

## Ce qui y est prouvé (rapports M1→M8, QEMU uniquement)

framebuffer · shell clavier FR + historique · pagination 4 niveaux · tas noyau · **ring 3** ·
**appels système `int 0x80`** · **deux tâches à espaces d'adressage séparés** · démarrages reproductibles
(empreintes identiques) sur BIOS **et** UEFI · isolation vérifiée (accès ring 3 à la mémoire du noyau refusé
par le processeur, code d'erreur 0x7).

## Ce qui n'existe pas dedans — et qui interdit d'en faire le produit

**Aucune** pile réseau, **aucun** pilote de disque, **aucun** système de fichiers, **aucuns** comptes, groupes,
droits, partages ou annuaire. Or c'est exactement l'axe du projet (`ADR-0017`).

## Règle de temps

Ce couloir **ne consomme aucun temps** du couloir produit avant le jalon **J5** (image NexBSD installable sur
un PC). Il sert de laboratoire d'indépendance (niveau I4) et de réserve de méthode.

## Fichiers conservés ici

- `registre-decisions-P1.md` — décisions D-000→D-011 de cette session
- `P1-specification-perimetre-v1.0.md` — périmètre gelé, tests T1-T5, jalons M0-M5
- `rapport-tests-P1-M8.md` — le rapport le plus avancé (deux tâches isolées)

L'archive complète reste hors dépôt (12 Mo) ; son empreinte ci-dessus en garantit l'identité.

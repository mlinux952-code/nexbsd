# ADR-0016 — Objectif de publication grand public, conditionné à dix portes

- **Date :** 2026-10-23
- **Statut :** proposition
- **Référence :** `docs/13-publication-grand-public.md`
- **Origine :** ambition exprimée par le responsable du projet : « un système à part, qui peut être publié un jour pour le grand public »

## Problème
Le projet doit-il se fixer un objectif de publication, et si oui, sous quelles conditions ? Un objectif de publication change la nature des exigences : responsabilités juridiques (licences, marques) et de sécurité (correctifs, divulgation) envers des utilisateurs inconnus.

## Décision proposée
1. **Assumer l'objectif** de publication grand public comme finalité du projet.
2. **Conditionner** toute publication — y compris expérimentale — au franchissement des **dix portes** G1 à G10 (`docs/13-publication-grand-public.md` §2).
3. **N'annoncer aucune date**, jamais.
4. Viser le scénario **A** (publication expérimentale pour techniciens), puis **B** (distribution utile pour petites structures) si des contributeurs rejoignent. **Ne jamais communiquer sur le scénario C** (système de masse), hors de portée d'un projet non financé.
5. **Démarrer immédiatement** les travaux de préparation à la publication qui ne dépendent d'aucun matériel : licence du code, `NOTICE`, antériorité du nom, contrôle automatisé de la frontière de licence, traçabilité.

## Justification
- La traçabilité et la conformité se construisent **au fil de l'eau** ; les reconstituer après coup est irréaliste.
- La crédibilité d'un projet de système se joue sur l'honnêteté de ses affirmations : promettre trop tôt est fatal.
- Le méga-prompt impose déjà la règle « ne déclarer comme réalisé que ce qui a été vérifié » ; l'objectif de publication la renforce au lieu de la contourner.

## Conséquences
- `LICENSE` et `NOTICE` deviennent obligatoires dès le premier commit du code.
- Le contrôle de frontière de licence (T-13, `scripts/40-verifier-frontiere-licence.sh`) devient une étape de construction, pas une bonne intention.
- La politique de sécurité (`docs/security.md`) devra être complétée d'une politique de divulgation avant G4.
- Une recherche d'antériorité sur le nom « NexBSD » devient une tâche de la phase en cours.
- Aucun document du projet ne pourra annoncer une date de sortie.

## Conditions de révision
- Si le projet reste strictement personnel et non distribué : l'objectif peut être requalifié en « usage privé », et les portes G1-G3 allégées — **en le documentant explicitement**.
- Si des contributeurs rejoignent : renforcer vers le scénario B (gouvernance, support communautaire).

# Objectif : publication grand public — et les dix portes à franchir

**Version :** 1.0 — 2026-10-23
**Statut :** `[PROPOSITION]` — ambition déclarée par le responsable du projet : *« un système à part, qui peut être publié un jour pour le grand public »*
**ADR associé :** ADR-0016

---

## 1. Ce que cet objectif change — et ce qu'il ne change pas

### Ce qu'il change
Un projet personnel peut se permettre l'approximation. **Un système publié, non.** Publier implique : des responsabilités juridiques (licences, marques), des responsabilités de sécurité (correctifs, divulgation), et une **promesse implicite de qualité** envers des utilisateurs inconnus.

Trois conséquences immédiates, **dès aujourd'hui** :

1. **Traçabilité dès le premier fichier** — licences, provenance, versions. Reconstituer un inventaire après coup coûte dix fois plus cher.
2. **Discipline de licence dès le premier commit** — la frontière Base/Plateforme (ADR-0012) doit être automatiquement vérifiée, pas « surveillée ».
3. **Honnêteté de communication** — un projet qui exagère perd toute crédibilité au premier échec public. La règle « ne déclarer que ce qui est vérifié » n'est pas une coquetterie méthodologique : c'est la condition de survie d'un projet publié.

### Ce qu'il ne change pas
- **Aucune date de publication n'est promise.** Ni cette année, ni l'an prochain. Un projet de système d'exploitation publié sans base solide ne rend service à personne.
- L'ordre des phases reste le même. La publication est la **dernière** étape, pas une motivation pour brûler les étapes.

---

## 2. Les dix portes (gates)

Aucune publication — même « alpha », même « à but expérimental » — avant que les dix portes soient franchies. Chaque porte a un **critère vérifiable** et une **preuve** exigée.

| # | Porte | Critère vérifiable | Preuve attendue | Statut |
|---|---|---|---|---|
| **G1** | **Identité juridique** | nom du projet libre de droits (antériorité vérifiée) ; licence du code NexBSD choisie et publiée ; fichier `NOTICE` présent | recherche d'antériorité documentée ; `LICENSE` + `NOTICE` dans le dépôt | ⬜ non atteinte |
| **G2** | **Conformité des licences** | **zéro** code copyleft dans la base (hors fichiers explicitement listés et justifiés) ; sources des composants GPL/LGPL publiées | sortie de `scripts/40-verifier-frontiere-licence.sh` sur l'arbre de base + dépôt de sources Plateforme | ⬜ non atteinte |
| **G3** | **Marques** | aucune marque de tiers dans le nom du produit ; notice d'attribution dans l'image | `NOTICE` mentionnant FreeBSD® et la non-affiliation ; revue du nom | ⬜ non atteinte |
| **G4** | **Sécurité : processus** | politique de divulgation publiée (contact, délais) ; procédure de correctif écrite ; suivi des avis amont effectif | page « Security policy » + journal de fusion des avis FreeBSD | ⬜ non atteinte |
| **G5** | **Sécurité : état** | zéro avis de sécurité amont **connu et non appliqué** sur la version publiée | tableau de correspondance avis amont → version NexBSD | ⬜ non atteinte |
| **G6** | **Construction reproductible** | deux constructions indépendantes produisent une image identique (ou écarts expliqués) | rapport T-11/T-12 avec empreintes comparées | ⬜ non atteinte (exige L3) |
| **G7** | **Image construite par le projet** | l'image est produite par l'arbre NexBSD, pas installée depuis une image FreeBSD | jalon **J8** : image + journal de construction | ⬜ non atteinte (exige L3) |
| **G8** | **Mises à jour et fin de vie** | mécanisme de mise à jour signé ; politique de support (durée, versions) publiée | dépôt de paquets signé + page « cycle de vie » | ⬜ non atteinte |
| **G9** | **Documentation utilisateur** | installation, mise à jour, **récupération** documentées et testées par une personne n'ayant pas participé au développement | guide + rapport de test à l'aveugle | ⬜ non atteinte |
| **G10** | **Matériel testé** | liste de compatibilité publiée, limitée aux machines réellement testées | HCL datée, avec ce qui **ne** fonctionne pas | ⬜ non atteinte |

**Porte zéro, implicite :** ne rien publier avant **J8** (une image construite par NexBSD). Un projet qui publie une configuration FreeBSD en l'appelant « système d'exploitation » se discrédite immédiatement auprès de la communauté technique.

---

## 3. Ce que « grand public » peut vouloir dire — trois scénarios honnêtes

| Scénario | Public | Exigences réelles | Réalisme |
|---|---|---|---|
| **A. Publication expérimentale** | techniciens, curieux, testeurs | G1-G4, G7-G10 ; pas de support ; avertissements clairs | **raisonnable** à moyen terme |
| **B. Distribution utile** | petites structures : association, atelier, école, réseau local | tout A + G5-G6 + documentation en français + support communautaire | ambitieux, atteignable si le projet est repris par plusieurs personnes |
| **C. Système grand public de masse** | monsieur et madame Tout-le-monde | tout B + support commercial, certifications matérielles, mises à jour garanties, ergonomie grand public | **hors de portée** d'un projet non financé |

**Recommandation :** viser **A**, puis **B** si des contributeurs rejoignent. Ne jamais communiquer sur **C**.

C'est le sens de l'honnêteté demandée par le méga-prompt : *« Ne pas ajouter un composant simplement pour satisfaire le concept initial si son intégration rend l'ensemble moins sûr ou moins cohérent. »* Le même principe s'applique aux promesses.

---

## 4. Ce qui doit être fait **maintenant** pour ne pas se fermer la porte

| Action | Coût | Pourquoi maintenant |
|---|---|---|
| Choisir la licence du code NexBSD (proposition : BSD-2-Clause) | 1 décision | tout ce qui est écrit ensuite en dépend |
| Vérifier l'antériorité du nom « NexBSD » | quelques recherches | changer de nom après publication est coûteux |
| Créer `LICENSE` + `NOTICE` dès le premier commit | 10 min | reconstituer l'historique est impossible |
| Brancher le contrôle de frontière de licence (`scripts/40-…`) | déjà écrit | une dérive GPL non détectée est irréversible en pratique |
| Tenir `docs/ETAT.md` et les comptes rendus | 15 min/session | la mémoire du projet ne doit pas être une conversation |
| Documenter les mesures dès le prototype | intégré aux tests | les promesses de performance sans mesure détruisent la crédibilité |

---

## 5. Calendrier réaliste (fourchettes, pas de promesses)

| Jalon | Condition | Fourchette honnête |
|---|---|---|
| J8 — première image construite par NexBSD | disponibilité du profil L3 | **indéterminé aujourd'hui** |
| Portes G1-G3 | décisions + outillage | possible **sans matériel**, dès que le responsable valide |
| Publication expérimentale A | G1-G4 + G7-G10 | plusieurs mois après J8 |
| Distribution utile B | contributeurs supplémentaires | non estimable |

**Aucune de ces lignes n'est une promesse.** Ce sont des ordres de grandeur conditionnels.

---

## 6. Décision proposée

**ADR-0016** : le projet assume l'**objectif** de publication grand public, en acceptant :
1. que cet objectif **ne réduit en rien** les exigences méthodologiques (il les augmente) ;
2. que la publication soit **conditionnée aux dix portes** G1-G10 ;
3. qu'aucune **date** ne soit jamais annoncée ;
4. que le scénario visé soit **A**, puis **B** si des contributeurs rejoignent — jamais **C** ;
5. que les travaux de « préparation à la publication » (licences, marques, traçabilité, outillage) **démarrent immédiatement**, même sans matériel disponible.

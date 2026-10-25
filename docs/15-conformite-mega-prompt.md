# Conformité au méga-prompt maître — audit des 20 livrables

**Version :** 1.1 — 2026-10-24 (session S-016)
**Rôle :** vérifier, livrable par livrable, ce que le document fondateur exige (Partie XIV) et ce que le projet possède réellement.
**Règle :** « non fait » est une information ; « fait » sans preuve est une faute.

---

## 1. Les 20 livrables de la Partie XIV

| # | Livrable exigé | État | Où / pourquoi |
|---|---|---|---|
| 1 | Document fondateur | 🟡 **partiel** | `docs/source/` (présentation + méga-prompt), `docs/00-cadrage-phase0.md` ; il manque un document unique « vision validée » signé par le responsable |
| 2 | Cahier des charges fonctionnel | 🟡 **partiel** | `matrices/functions.csv` (28 fonctions priorisées) + `docs/14-reseau-netware.md` §4 ; pas de document narratif unique |
| 3 | Étude de faisabilité | 🟡 **amorcée** | fiches de recherche + `matrices/risques.csv` ; **conclusion de faisabilité non écrite** — impossible avant le test matériel |
| 4 | Inventaire des composants | ✅ **fait** | `matrices/components.csv` (13 composants, version, licence, statut) |
| 5 | Matrice des licences | ✅ **fait** | `matrices/licences.csv` (14 entrées, colonne « admissible dans la base ») |
| 6 | Matrice des compatibilités | ✅ **fait** | `matrices/compatibilite.csv` (15 questions K-01→K-15) |
| 7 | Architecture générale | ✅ **fait (v0.1)** | `docs/architecture.md` — couches A→F, 3 domaines, chaîne de construction |
| 8 | Schéma des flux entre modules | ✅ **fait (ce jour)** | `docs/08-schema-flux.md` |
| 9 | Diagnostic matériel | 🟡 **procédure prête, mesures absentes** | `docs/hardware.md` — tableau à remplir ; aucune commande exécutée sur le PC de 2011 |
| 10 | Plan de tests | ✅ **fait** | `tests/plan-tests.md` (15 tests définis, **aucun exécuté**) |
| 11 | Prototype minimal | 🟡 **amorcé** | le **banc d'identités** existe et fonctionne en VM (T-01, T-03, T-04, T-04-E, T-04-F réussis). Mais il n'est pas encore un **livrable packagé** : il s'obtient en enchaînant quatre scripts à la main (`60`, `62`, `63`, `64`). Tant que ce n'est pas ramené à **un** composant installable et rejouable, le livrable reste partiel |
| 12 | Rapport de tests | 🟡 **amorcé** | **5 tests réussis** avec journaux verbatim dans `tests/results/` (T-01, T-03, T-04, T-04-E, T-04-F), échecs compris et documentés (C-10→C-13). Manque : le **rapport de validation** unique exigé en sortie de phase 4 |
| 13 | Registre des problèmes | ✅ **fait (ce jour)** | `docs/16-registre-problemes.md` |
| 14 | Guide de construction | 🟡 **partiel** | `fork/README.md` + `build-nexbsd.sh` (non exécuté) |
| 15 | Guide d'installation et de récupération | 🟡 **partiel** | `docs/plan-action.md` étapes 2-6 + `docs/hardware.md` §6 ; pas de guide dédié, car **aucune installation n'a été réalisée** |
| 16 | Politique de sécurité | ✅ **fait** | `docs/security.md` |
| 17 | Procédure de mise à jour | 🟡 **squelette** | `docs/17-procedure-mise-a-jour.md` — ne peut pas être validée avant qu'un système existe |
| 18 | Historique des versions | ✅ **fait (ce jour)** | `CHANGELOG.md` — historique de la **conception**, aucune version logicielle |
| 19 | Guide de contribution | ✅ **fait (ce jour)** | `docs/19-guide-contribution.md` |
| 20 | Rapport final (fonctions opérationnelles + limites) | ❌ **non fait** | par nature : fin de projet |

**Bilan au 2026-10-24 (v1.1) : 9 faits, 8 partiels, 2 non faits** (le n° 20 « rapport final » par nature, et le n° 3 « conclusion de faisabilité » qui reste suspendu au test matériel). Les livrables 11 et 12 sont passés de « non fait » à « amorcé » par l'exécution réelle de cinq tests — pas par déclaration.

---

## 2. Audit des règles du mur (Parties I, VII, X, XI, XVII, XVIII)

| Règle du méga-prompt | Respectée ? | Preuve / remarque |
|---|---|---|
| Ne pas prétendre avoir exécuté des commandes, compilé, testé | ✅ | chaque document marque `NON EXÉCUTÉ` / `NON VALIDÉ` ; `fork/` le dit en tête de chaque fichier |
| Distinguer faits / hypothèses / propositions / résultats / problèmes | ✅ | étiquetage `[FAIT] [HYPOTHÈSE] [PROPOSITION] [À VÉRIFIER] [DÉCISION]` + `START-HERE.md` |
| Ne jamais inventer un dépôt, une version, une compatibilité | ✅ | toutes les affirmations techniques portent une URL et une date de consultation |
| Conserver source + URL + date + version | ✅ | tables « Sources » dans les 9 fiches de recherche |
| Le disque principal ne doit pas être modifié (Partie X) | ✅ | aucune action matérielle ; scripts avec garde-fous ; T-08 prévu |
| Ne pas demander de désactiver une protection sans expliquer | ✅ | `docs/hardware.md` §4 et §7 l'interdisent explicitement |
| Ne pas promettre de performances sans mesures (Partie XII) | ✅ | budget L1 marqué « objectifs, non mesurés » |
| Ne pas confondre PC et téléphone (Partie XII) | ✅ | ADR-0008 (3 profils) ; C-21/C-22 hors périmètre |
| Licences vérifiées avant réutilisation (Partie VI) | ✅ | `matrices/licences.csv` + `scripts/40` (automatisé) + ADR-0012 |
| Ne pas publier de secrets / données personnelles | ✅ | aucune donnée de ce type dans le dépôt ; `docs/security.md` §1.3 |
| Compte rendu de fin de session (Partie XVIII) | ✅ | 6 comptes rendus, + `docs/ETAT.md` |
| Ne pas déclarer un fichier créé sans que ce soit vrai | ✅ | contrôle par `ls` en fin de session (protocole §6.5) |

**Violations constatées : aucune.** Deux **lacunes** (pas des violations) : le document fondateur unique n'est pas signé, et l'étude de faisabilité n'a pas de conclusion rédigée — les deux pour la même raison : il n'y a pas encore de fait technique à conclure.

---

## 3. Ce que le mur exige et que la situation actuelle ne permet pas encore

| Exigence | Blocage réel |
|---|---|
| Étude de faisabilité concluante | exige un démarrage FreeBSD effectif (tests T-01/T-02) |
| Prototype minimal (livrable 11) | exige une installation (VM ou matériel) |
| Rapport de tests (livrable 12) | exige le prototype |
| Guide d'installation validé (livrable 15) | ne peut pas être « validé » sans installation réelle ; peut seulement être rédigé |
| Guide de construction (livrable 14) | exige le profil L3 |

**Aucun de ces blocages n'est documentaire : ils sont tous matériels ou liés à l'absence de L3.** C'est cohérent avec `docs/ETAT.md` §7.

---

## 4. Prochaine action recommandée par cet audit

1. **Débloquer le livrable 9** (diagnostic matériel) : c'est le seul qui ne dépend ni de L3 ni d'une installation, et il conditionne tout le reste. → exécuter `scripts/00-diagnostic-hote.sh` sur le Mint et le rapport `docs/hardware.md` §2 sous Windows 7.
2. **Écrire le document fondateur unique** (livrable 1), en y intégrant les décisions proposées : c'est un travail de rédaction, faisable sans matériel.
3. Ne pas rédiger l'étude de faisabilité (livrable 3) avant d'avoir un premier fait technique : ce serait une étude d'intentions.

---

## 3. Audit de la PARTIE XX (stockage externe, traçabilité, indépendance de l'IA)

**Source :** `docs/source/` — *Présentation du projet NexBSD*, Partie XX, reçue le 2026-10-24. Cette partie
n'était pas connue lors de la rédaction de la v1.0 de cet audit : elle est donc auditée ici pour la première fois.

| Exigence de la Partie XX | Respectée ? | Preuve / réserve |
|---|---|---|
| Le projet ne dépend d'aucune conversation | ✅ | dépôt Git local + GitHub + Drive ; `docs/ETAT.md` sert de source de vérité en une page |
| Drive = référentiel **documentaire** | 🟡 | instantanés `.bundle` déposés à chaque étape (s014 → s016c). **Réserve** : le rangement par dossiers de la Partie XX (`00_Gouvernance/`, `02_Cahier_des_Charges/`…) **n'est pas appliqué** — tout est à plat dans « NexBSD » |
| GitHub = référentiel **technique** | 🟡 | dépôt privé `mlinux952-code/nexbsd`. **Réserve d'honnêteté** : l'assistante **n'a aucun accès** à GitHub ; son état ne peut être affirmé par elle, seulement constaté par le responsable |
| Aucune conversation ne doit être l'unique copie | ✅ | règle appliquée : chaque étape se termine par un commit + un instantané daté |
| Séparation décisions validées / propositions | ✅ | 19 ADR à l'état `proposition` ; aucune décision n'est déclarée validée sans le responsable |
| Ne jamais déclarer un fichier sauvegardé sans confirmation | ✅ | chaque dépôt Drive est vérifié après coup par `list_files` (identifiant, taille, date) |
| Ne rien publier de confidentiel | ✅ | aucun secret dans le dépôt ; les mots de passe de laboratoire sont explicitement marqués comme tels et la VM n'est pas exposée. **Point de vigilance** : `scripts/50-sauvegarder-session.sh` produit des archives locales — vérifier qu'elles ne partent jamais dans un dépôt public |
| Compte rendu de fin de session réutilisable par une autre IA | 🟡 | `docs/ETAT.md` + `CHANGELOG.md` + journaux de tests le permettent. **Manque** : un compte rendu de session normalisé (état / fichiers / décisions / tests / problèmes / suite), à produire en fin de session |

**Deux actions correctives retenues, à faire en fin de session :**

1. **Ranger le dossier Drive** selon l'arborescence de la Partie XX (les fichiers actuels sont à plat).
2. **Créer `docs/25-compte-rendu-session.md`** — modèle normalisé du §7 de la Partie XX, pour que la reprise
   par une autre IA ne dépende plus du mur de discussion.

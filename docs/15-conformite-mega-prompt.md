# Conformité au méga-prompt maître — audit des 20 livrables

**Version :** 1.0 — 2026-10-23 (session S-006)
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
| 11 | Prototype minimal | ❌ **non fait** | aucune installation, ni VM ni matériel |
| 12 | Rapport de tests | ❌ **non fait** | aucun test exécuté (conséquence directe de 11) |
| 13 | Registre des problèmes | ✅ **fait (ce jour)** | `docs/16-registre-problemes.md` |
| 14 | Guide de construction | 🟡 **partiel** | `build/fork/README.md` + `build-nexbsd.sh` (non exécuté) |
| 15 | Guide d'installation et de récupération | 🟡 **partiel** | `docs/plan-action.md` étapes 2-6 + `docs/hardware.md` §6 ; pas de guide dédié, car **aucune installation n'a été réalisée** |
| 16 | Politique de sécurité | ✅ **fait** | `docs/security.md` |
| 17 | Procédure de mise à jour | 🟡 **squelette** | `docs/17-procedure-mise-a-jour.md` — ne peut pas être validée avant qu'un système existe |
| 18 | Historique des versions | ✅ **fait (ce jour)** | `CHANGELOG.md` — historique de la **conception**, aucune version logicielle |
| 19 | Guide de contribution | ✅ **fait (ce jour)** | `docs/19-guide-contribution.md` |
| 20 | Rapport final (fonctions opérationnelles + limites) | ❌ **non fait** | par nature : fin de projet |

**Bilan : 9 faits, 7 partiels, 4 non faits (dont 2 dépendants de tests inexistants).**

---

## 2. Audit des règles du mur (Parties I, VII, X, XI, XVII, XVIII)

| Règle du méga-prompt | Respectée ? | Preuve / remarque |
|---|---|---|
| Ne pas prétendre avoir exécuté des commandes, compilé, testé | ✅ | chaque document marque `NON EXÉCUTÉ` / `NON VALIDÉ` ; `build/fork/` le dit en tête de chaque fichier |
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

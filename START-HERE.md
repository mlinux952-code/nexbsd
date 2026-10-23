# START HERE — Protocole de session NexBSD

> **Ce fichier est le premier à lire, à chaque session, par toute personne ou toute IA qui travaille sur NexBSD.**
> Son rôle : empêcher la dérive, l'oubli et les affirmations non vérifiées.

---

## 0. Règle d'or

> **On ne fait jamais confiance à la mémoire — ni celle de l'IA, ni celle d'une conversation.**
> La vérité du projet est dans les fichiers. Si ce n'est pas écrit dans le workspace et vérifiable, cela n'existe pas.

**Conséquence pratique :** au début de chaque session, on **relit l'état réel** (fichiers, décisions, comptes rendus) avant de produire quoi que ce soit. Et à la fin, on **met à jour l'état**. Une session qui ne met pas à jour l'état est une session perdue.

---

## 1. Séquence de démarrage (obligatoire, dans cet ordre)

| # | À lire | Pourquoi | Durée |
|---|---|---|---|
| 1 | `START-HERE.md` (ce fichier) | les règles du jeu | 2 min |
| 2 | `docs/ETAT.md` | **l'état réel du projet en une page** | 3 min |
| 3 | `reports/` — le **dernier** compte rendu | ce qui a été fait, ce qui reste | 5 min |
| 4 | `docs/decisions/README.md` | les décisions déjà prises (ne pas les rouvrir sans raison) | 3 min |
| 5 | `docs/source/nexbsd-mega-prompt-maitre-v1.0.md` — **Parties I, V, VII, X, XI, XVII, XVIII** | les règles fondatrices imposées par le responsable | 10 min |
| 6 | Le document concerné par la tâche du jour | le sujet | variable |

Puis, **avant de produire** :

```bash
cd nexbsd
find . -type f | sort          # constater ce qui existe réellement
ls docs/decisions/ADR-*.md | wc -l
cat docs/ETAT.md               # relire l'état
```

**Interdit :** affirmer qu'un fichier existe sans l'avoir listé ; affirmer qu'un test est passé sans sortie de commande.

---

## 2. Les 10 règles anti-dérive

1. **Ne jamais déclarer réalisé ce qui n'a pas été exécuté.** Trois états seulement : *existe* (fichier présent), *testé* (sortie de commande présente), *documenté*. Un document n'est pas un résultat.
2. **Étiqueter chaque affirmation** : `[FAIT]` (source datée) · `[HYPOTHÈSE]` · `[PROPOSITION]` · `[À VÉRIFIER]` · `[DÉCISION]` (validation écrite du responsable uniquement).
3. **Ne pas ressusciter une idée rejetée sans fait nouveau.** Liste des idées closes : voir §4.
4. **Toute nouvelle fonctionnalité doit répondre à trois questions** : *quel besoin réel ? quel test la valide ? quelle licence ?* Sinon, elle est refusée.
5. **Le budget « PC faible » est opposable** (ADR-0009) : un composant qui le dépasse est refusé ou isolé, même s'il est intéressant.
6. **Aucun code copyleft dans la base** (ADR-0012) : vérification automatisée, pas de confiance.
7. **Ne jamais toucher au disque principal** du PC de test : support externe uniquement, vérification du périphérique avant toute écriture.
8. **Aucune promesse de date, de performance ou de compatibilité** sans mesure. « Bientôt », « presque », « ça devrait marcher » sont interdits dans un document officiel.
9. **Ne pas confondre le produit et la préparation** : le prototype actuel dérisque les composants ; il ne produit pas NexBSD (ADR-0011).
10. **Terminer chaque session par la mise à jour de `docs/ETAT.md` + un compte rendu.** Sans cela, la session ne compte pas.

---

## 3. Les 5 questions à se poser avant de valider quoi que ce soit

1. **Est-ce vérifié ou supposé ?** Si supposé → étiquette `[HYPOTHÈSE]`, pas de conclusion.
2. **Est-ce dans le périmètre ?** Si non → journal de dérive §5.
3. **Est-ce que ça tient dans le budget PC faible ?** Si non → refus ou image séparée.
4. **Est-ce que ça contamine la licence de la base ?** Si oui → Plateforme, pas Base.
5. **Est-ce que le responsable du projet l'a validé ?** Si non → `[PROPOSITION]`, jamais `[DÉCISION]`.

---

## 4. Idées closes — ne pas rouvrir sans fait nouveau

| Idée | Statut | Pourquoi c'est clos | Fait nouveau qui justifierait une réouverture |
|---|---|---|---|
| Utiliser KaiOS comme base ou composant | **rejeté** (ADR-0002) | propriétaire, aucune image constructible (blobs OEM, RIL), dépendance Linux/Android | changement de licence de KaiOS ou accord écrit de l'éditeur |
| Intégrer Gecko B2G / Firefox OS comme moteur | **rejeté** (ADR-0003) | plus d'API d'intégration tierce ; dépôts archivés depuis 2021 ; API `moz*` disparues | apparition d'un Gecko embarquable maintenu — improbable |
| MARS_NWE comme composant de NexBSD | **rejeté** (ADR-0004) | GPL-2 (interdit dans la base) + dépendance IPX absente de FreeBSD depuis 11.0 | un portage IPX en espace utilisateur testé (cf. ADR-0014, chantier propre) |
| Modifier le noyau en phase initiale | **reporté** (ADR-0006) | aucune fonction du périmètre ne l'exige ; coût de maintenance prohibitive | preuve qu'une fonction P0/P1 est impossible autrement |
| « FreeBSD + paquets » comme modèle du produit | **rejeté** (ADR-0011) | ne produit pas un système, mais une configuration | — (le fork M2 reste le modèle) |
| Compiler Samba/WebKit sur les postes faibles | **rejeté** (ADR-0010) | plusieurs Go de RAM, heures de CPU | disponibilité effective du profil L3 |

---

## 5. Journal de dérive

Quand une session s'écarte (sujet hors périmètre, envie d'ajouter un composant, tentation de promettre), on l'écrit ici **au lieu de le faire** :

| Date | Dérive constatée | Décision | Suite donnée |
|---|---|---|---|
| 2026-10-23 | Tentation initiale d'appeler « NexBSD » un FreeBSD configuré | reformulé en fork M2 (ADR-0011) | traité |
| 2026-10-23 | Tentative de « combler KaiOS avec Firefox OS » | techniquement impossible, idée close (§4) | traité |

---

## 6. Séquence de fin de session (obligatoire)

1. Mettre à jour **`docs/ETAT.md`** (état, phase, prochaine action, questions ouvertes).
2. Rédiger un **compte rendu** dans `reports/` (modèle : `reports/session-2026-10-23.md`).
3. Ajouter les **ADR** correspondants si une décision a été proposée ou prise.
4. Mettre à jour les **matrices** (`matrices/*.csv`) si un composant, une licence ou un risque change.
5. **Vérifier par `ls`** que chaque fichier annoncé existe réellement.
6. Écrire la **prochaine action concrète** — une seule, faisable, vérifiable.
7. **Sauvegarder** : `git commit` puis `sh scripts/50-sauvegarder-session.sh`, puis téléverser l'instantané dans le dossier Drive « NexBSD » (voir `docs/20-depots-et-sauvegardes.md`).

---

## 7. Où se trouve quoi

| Besoin | Fichier |
|---|---|
| **État actuel, en une page** | `docs/ETAT.md` |
| Règles imposées par le responsable | `docs/source/nexbsd-mega-prompt-maitre-v1.0.md` |
| Synthèse lisible des phases 0-1 | `00-SYNTHESE-PHASE-0-1.md` |
| Décisions (19 ADR) | `docs/decisions/` |
| Modèle de système (fork) | `docs/11-fork-pas-surcouche.md` |
| Licences et frontières | `docs/12-licences-et-frontieres.md` |
| Objectif grand public et conditions | `docs/13-publication-grand-public.md` |
| Cible PC faible et budget | `docs/09-cible-pc-faible.md` |
| Recherches sourcées | `research/*/fiche.md` |
| Matrices | `matrices/*.csv` |
| Scripts de préparation | `scripts/` |
| Squelette du delta propre (fork) | `build/fork/` |
| Historique des sessions | `reports/` |
| **Où vit le projet (Drive, GitHub)** | `docs/20-depots-et-sauvegardes.md` |
| **Sauvegarder la session** | `scripts/50-sauvegarder-session.sh` |
| Cahier des charges fonctionnel | `docs/02-cahier-des-charges-fonctionnel.md` |
| Conformité aux 20 livrables du mur | `docs/15-conformite-mega-prompt.md` |
| Problèmes connus | `docs/16-registre-problemes.md` |

---

## 8. Ce que NexBSD est, à la date du 2026-10-23

**Un dossier de conception, sauvegardé.** Pas de code, pas d'installation, pas de test d'exécution. Un modèle de système choisi (fork), un budget de ressources, trois domaines de licence, 19 décisions proposées, un cahier des charges fonctionnel, des recherches sourcées, et une trajectoire vers un système publiable — sous conditions. Le projet existe en trois endroits : l'espace de travail, un dépôt Git local, et un dossier Google Drive daté. **GitHub n'existe pas encore.**

Toute personne qui lit ceci doit pouvoir dire, sans consulter la conversation : *où en est le projet, ce qui est décidé, ce qui est supposé, et quelle est la prochaine action.*

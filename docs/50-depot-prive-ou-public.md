# 50 — Le dépôt est PRIVÉ : trois routes, un coût, une décision qui vous appartient

**Faits mesurés le 2026-10-28, 🖥️ MINT, sortie verbatim :**

```
--- ce que GitHub a (doit etre 26d223d ou plus recent) ---
624ac02d03e949d53e9093f7ee89a71f9933b216	refs/heads/main
--- visibilite du depot (200 = PUBLIC donc gratuit / 404 = PRIVE donc 10$/mois) ---
404
```

| Constat | Conséquence |
|---|---|
| `origin` = `624ac02` alors que l'atelier est à `88327e8` | **le push des 5 derniers commits n'a pas eu lieu** |
| code HTTP `404` en accès anonyme, alors que le push fonctionne | le dépôt **existe** et est **privé** |

---

## 1. Pourquoi cela bloque la route A telle qu'annoncée

Cirrus CI est **gratuit pour les dépôts publics** (dans la limite de 50 crédits/mois).
Pour un dépôt **privé personnel**, il faut le plan à **10 $/mois**.

J'ai annoncé « route A = gratuit » : **c'était vrai pour un dépôt public, faux pour le vôtre.**
Je corrige ici, et je ne décide pas à votre place de la visibilité du code de NexBSD.

---

## 2. Le contrôle de sûreté, fait d'abord

Avant même de parler de rendre le dépôt public, j'ai cherché ce qui ne doit pas l'être (C-31) :

| Contrôle | Résultat |
|---|---|
| mots de passe en **ligne active** dans `fork/`, `scripts/`, `tests/*.sh` | ✅ **corrigé aujourd'hui** (6 fichiers) |
| clés privées, jetons (`ghp_`, `AKIA`, `xox`) | ✅ **aucun** |
| code GPL tiers | ✅ **aucun** (le schéma Samba n'a jamais été committé) |
| mots de passe du banc dans `tests/results/` (preuves verbatim) | ⚠️ **encore présents — non modifiés volontairement** |

**Le dernier point est le seul obstacle.** Réécrire un compte rendu de test pour masquer une valeur,
c'est falsifier une preuve. La manière propre existe (voir §4).

---

## 3. Trois routes, avec leur coût réel

| | Route A1 — dépôt **public** | Route A2 — miroir **public** du seul produit | Route A3 — garder **privé** |
|---|---|---|---|
| Coût | **0 €** | **0 €** | **10 $/mois** |
| Ce qui devient visible | **tout** : docs, audits, preuves, historique | **`fork/` + `scripts/`** seulement | rien |
| Effort de mise en place | 2 minutes (un bouton) | ~1 heure (script d'export + dépôt séparé) | 5 minutes (carte bancaire) |
| Risque | les mots de passe du banc deviennent publics | faible : le produit ne contient aucun secret (C-31 corrigé) | aucun |
| Entretien | rien | **deux dépôts à garder cohérents** | rien |
| Effet secondaire utile | sauvegarde publique + preuve de travail | idem, sur le produit seulement | aucun |

### Ma recommandation : **A2**, avec A1 en repli si A2 résiste

Raisonnement, en clair :
- **A1** publie les comptes rendus de banc, y compris 9 mentions de mots de passe de laboratoire et
  tout le journal de nos erreurs. Ce journal a de la valeur pour nous, pas pour le monde, et il
  contient des choses qui n'ont pas à être indexées par les moteurs de recherche.
- **A3** vous coûte 120 $/an pour un projet qui n'a pas encore produit une seule image. Ce n'est pas
  raisonnable à ce stade.
- **A2** donne exactement ce dont la CI a besoin — `fork/`, `scripts/`, `.cirrus.yml` — sans exposer
  le reste. Et le produit lui-même **ne contient aucun secret** depuis la correction de ce soir.

---

## 4. Si A1 ou A2 est retenu : la rédaction propre des preuves

Pour les 9 mentions dans `tests/results/`, la méthode honnête n'est pas de supprimer :

1. remplacer la valeur par un marqueur explicite : `[mot de passe du banc — masqué à la publication]` ;
2. **conserver la version intégrale** dans le bundle privé (déjà déposé sur Drive avec son SHA256) ;
3. ajouter en tête du fichier : *« valeur masquée le 2026-10-28 avant publication ; original dans le
   bundle s055, sha256 … ; la preuve n'a pas été modifiée sur le fond »*.

Ainsi la preuve reste consultable, la valeur reste retrouvable par vous, et rien n'est inventé.
**Je ne le ferai qu'après votre décision**, parce que cela touche à des preuves.

---

## 5. Ce qui est certain, indépendamment de la décision

**Rien de tout cela n'avance d'un millimètre tant que GitHub n'a pas nos commits.** Le `push` des
5 derniers commits (`26d223d`, `6978f9f`, `eac9621`, `a422495`, `88327e8`) doit passer **en premier**,
sinon Cirrus construira `624ac02` — c'est-à-dire une version qui ne contient ni le maillon
`70-appliquer-overlay.sh`, ni la correction des mots de passe.

---

## 6. DÉCISION DU RESPONSABLE — 2026-10-28 : dépôt PUBLIC, coût zéro

> *« et si on fait notre nexbsd visible et le coût est 0 c'est mieux pour moi sans dépense »*

**Route retenue : A1 — le dépôt devient public.** Coût : **0 €**. Cirrus CI devient gratuit
(50 crédits/mois), sans carte bancaire.

### Ce qui a été fait AVANT de publier (ordre non négociable)

| Action | Résultat mesuré |
|---|---|
| masquage des valeurs d'authentification | **30 occurrences** dans **10 documents** → `[mot de passe du banc — masqué]` |
| idem dans 4 commentaires de `fork/overlay/` | fait |
| note d'en-tête dans chaque document touché | présente : fond de preuve inchangé, original dans le bundle s055 |
| `git grep` sur **tout** le contenu courant | ✅ **aucune occurrence** |
| règle permanente écrite | **R-15** dans `docs/40` |
| delta du produit après modification | ✅ `DELTA INTACT (26 fichiers)` |

### Ce qu'il faut savoir, et que je ne cache pas : L'HISTORIQUE

Masquer dans la version courante **ne lave pas les commits antérieurs**. Mesuré :
**10 commits** contiennent encore les valeurs dans l'historique Git.

**Pourquoi je ne réécris pas l'historique** (décision assumée, pas un oubli) :
- les valeurs sont des mots de passe d'un **banc jetable**, sur un réseau QEMU en mode `user`
  (`10.0.2.15`, non joignable depuis l'extérieur) ;
- elles n'ont **jamais** servi ailleurs et le seront **jamais** (R-15 : valeurs **brûlées**) ;
- réécrire l'historique changerait **tous les identifiants de commit**, invaliderait les 56 bundles
  déposés et casserait la copie de MINT — un coût réel pour un gain quasi nul ;
- **notre dépôt ne contient aucun code GPL tiers** : la frontière de licence reste intacte après
  publication.

**À retenir pour vous** : si ces trois valeurs étaient un jour réutilisées quelque part, il faudrait
les changer immédiatement. Elles sont publiques à partir du moment où le dépôt l'est.

### Ce que la publication change dans nos règles

1. **R-15 s'applique désormais sans exception** : tout ce qui entre dans ce dépôt est public.
2. Toute donnée personnelle, tout chemin de machine, toute adresse doivent être assumés publics.
3. Les 56 bundles Drive restent **privés** : ils contiennent les valeurs en clair. Ils ne doivent pas
   être rendus publics.

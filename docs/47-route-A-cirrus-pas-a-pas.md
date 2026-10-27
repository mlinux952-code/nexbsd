# Route A — Cirrus CI, pas à pas, jusqu'à la première image

**Décision du responsable, 2026-10-27 :** *« on fait A »* — la CI gratuite, pas un achat.
**Objet :** sortir le projet de la VM et produire un **artefact** (une image + son empreinte).
**Règle de conduite :** une commande à la fois, terminal nommé, sortie vérifiée avant de passer à la
suivante. Voir `docs/40` (R-1 → R-14).

---

## 0. Ce que la route A demande, et ce qu'elle ne demande pas

| Demande | Coût |
|---|---|
| Un compte **GitHub** avec le dépôt `nexbsd` | déjà existant (dépôt privé `mlinux952-code/nexbsd`) |
| Un compte **Cirrus CI** (connexion via GitHub) | **gratuit** |
| Que le dépôt GitHub contienne **le code à jour** (commit ≥ `c9aa3a30` / bundle s049) | ⚠️ **c'est le point bloquant n° 1** |
| Vérifier le nom d'image FreeBSD dans le catalogue Cirrus | fait le 2026-10-27 (voir §4) |

**Ce qu'elle ne demande pas :** ni argent, ni machine puissante, ni carte bancaire.

---

## 1. Le point bloquant n° 1 : le dépôt GitHub est en retard (et son état est INCONNU)

**Fait vérifié dans nos documents :** aucune sortie `git push` n'a jamais été observée depuis le
2026-10-23. Nos propres audits (`docs/15`, `docs/43`, `docs/45`) disent la même chose : **l'état du
dépôt distant est inconnu**, et je n'ai aucun accès à GitHub pour le constater.

Or Cirrus CI **construit ce qui est sur GitHub**. Si le dépôt distant est en retard de 60 commits, la CI
construira une version ancienne — et on croira avoir produit l'image de ce soir.

**Conséquence :** la **première** chose à faire n'est pas de configurer Cirrus, c'est de **mettre GitHub
à jour** et de le **prouver par une sortie de commande**.

---

## 2. Les étapes, dans l'ordre (aucune ne peut être sautée)

| # | Étape | Où | Preuve attendue |
|---|---|---|---|
| **1** | Constater l'état du dépôt local et du distant | 🖥️ MINT | `git log`, `git remote -v` |
| **2** | Mettre le dépôt local à jour avec le bundle **s049** | 🖥️ MINT | `fetch` + `log` montrant le commit `565da3b` |
| **3** | **Pousser** vers GitHub | 🖥️ MINT | sortie `git push` **réelle** |
| **4** | Vérifier que GitHub a bien reçu (côté web) | navigateur | le commit apparaît sur la page du dépôt |
| **5** | Connecter Cirrus CI au dépôt | navigateur | Cirrus voit le dépôt |
| **6** | Première exécution : tâches **SONDE** + **CONTRÔLES** (~2 min, aucune construction) | Cirrus | les contrôles passent, la sonde dit quelle version existe |
| **7** | Trancher 15.0 / 15.1 selon la sonde | nous deux | décision écrite |
| **8** | Lancer la tâche **IMAGE** (déclenchement manuel, plusieurs heures) | Cirrus | **une image + son SHA256** |

---

## 3. Ce qui a déjà été préparé de mon côté (ce soir)

| Fichier | État | Contenu |
|---|---|---|
| `scripts/74-produire-image.sh` | écrit, **testé en `--simulation`** | chaîne complète : empreinte de `src.txz`, delta, `buildworld`, `buildkernel`, `release`, manifeste |
| `.cirrus.yml` | écrit, **YAML validé**, jamais exécuté | 3 tâches : SONDE (peut échouer), CONTRÔLES, IMAGE (manuelle) |
| `docs/46` | écrit | constat honnête : 25 fichiers produit, 0 image |
| `docs/47` | ce document | la marche à suivre |

---

## 4. Le nom d'image : ce que la documentation dit vraiment

Vérifié le 2026-10-27 sur `https://cirrus-ci.org/guide/FreeBSD/` — familles listées :

```
freebsd-16-0-snap
freebsd-15-0-amd64-ufs     (15.0-RELEASE, UFS)
freebsd-15-0-amd64-zfs     (15.0-RELEASE, ZFS)
freebsd-14-3
```

**`freebsd-15-1` n'est pas listée.** Or notre `src.txz` est en **15.1-RELEASE**. Deux conséquences :

1. construire des sources **15.1** sur un hôte **15.0** n'est pas la configuration recommandée (FreeBSD
   conseille un hôte au moins aussi récent que la cible) ;
2. la tâche **SONDE** du `.cirrus.yml` existe précisément pour cela : elle essaie `freebsd-15-1` et
   **a le droit d'échouer**. Son résultat tranchera, au lieu qu'on suppose.

**Si 15.1 n'existe pas :** deux options, à décider ensemble — (a) construire 15.0 (changer la cible
dans `scripts/74` et le SHA de `src.txz`), ou (b) demander/utiliser une image 15.1 si elle apparaît.
**Je ne trancherai pas seul : le numéro de version du produit est une décision, pas un détail.**

---

## 5. Ce que cette route va révéler, et qu'aucun test en VM ne peut révéler

| Question | Pourquoi seul le CI peut y répondre |
|---|---|
| `buildworld` passe-t-il avec **notre** `src.conf` ? | il n'a jamais été lancé avec ce fichier |
| `release.sh` accepte-t-il **notre** `release.conf` ? | idem |
| l'image **démarre-t-elle** ? | aucune image n'a jamais existé |
| combien de temps et d'espace cela coûte-t-il réellement ? | l'estimation « 2 à 6 h » n'a jamais été confrontée à un `buildworld` complet |

---

## 6. Journal de la route A

| Date | Étape | Résultat |
|---|---|---|
| 2026-10-27 | `.cirrus.yml` écrit, YAML validé ; nom d'image corrigé (`freebsd-15-0-amd64-ufs`) | ✅ |
| 2026-10-27 | ~~`freebsd-15-1`~~ supposé existant | ❌ **affirmation fausse**, corrigée avant première exécution |
| _(à suivre)_ | état du dépôt local et distant | en attente de la sortie du responsable |

---

## 7. Constat du 2026-10-27 (soir) — l'état du dépôt distant est enfin CONNU

Sortie verbatim du responsable, 🖥️ MINT, `~/Projets/nexbsd` :

```
d999b1b (HEAD -> main, origin/main, bundle/main) C-18 : recidive de C-16 ...
69
bundle  /home/omrane/Téléchargements/nexbsd-depot-2026-10-25-s027.bundle (fetch/push)
origin  git@github.com:mlinux952-code/nexbsd.git (fetch/push)
```
`git status --short` n'a **rien** affiché → arbre de travail propre.

### Ce que cela établit, sans supposition

| Fait | Preuve | Conséquence |
|---|---|---|
| `origin/main` = `d999b1b`, soit **69 commits** | sortie ci-dessus | GitHub **n'a rien reçu depuis le 25/10** |
| l'atelier est à **123 commits** | `git rev-list --count HEAD` | **54 commits de retard** sur le distant |
| `d999b1b` est un **ancêtre** de `34c3449` | `git merge-base --is-ancestor` → OUI | mise à jour **en fast-forward**, aucun conflit possible |
| l'arbre local est **propre** | `git status --short` vide | rien à sauver avant de mettre à jour |
| le transport est **SSH** | `git@github.com:…` | le `push` exige une **clé SSH enregistrée** sur GitHub — non encore vérifié |
| la remorque `bundle` pointe **s027** | sortie ci-dessus | obsolète ; à ne pas utiliser, ne pas supprimer sans décision |

### Conclusion opérationnelle

**A-33 (« état du dépôt GitHub non vérifié ») est levé** : le distant est en retard, ce n'est plus une
inconnue. Si la tâche IMAGE avait été lancée ce soir, elle aurait construit **le code du 25 octobre**,
sans même que ce soit visible. La règle qui en sort : **aucune exécution de CI avant une sortie `git push`
réelle et vérifiée.**

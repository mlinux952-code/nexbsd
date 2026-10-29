# 66 — La Release a été créée, mais elle est **vide** : l'artefact ne contient pas l'image

- **Date :** 2026-10-29, 22 h 42
- **Exécution :** `PUBLIER` #1, identifiant **40967868290**, commit `a9df1e6`, `workflow_dispatch`
- **Résultat :** `failure` — étapes **1 à 5 vertes**, étape **6 (4/4) rouge**
- **Registre :** **C-50**

---

## 1. Ce qui a réussi

| Étape | Résultat |
|---|---|
| 1/4 — télécharger l'artefact de l'exécution #18 | ✅ **succès** |
| 2/4 — empreintes | ✅ succès |
| 3/4 — créer la Release | ✅ succès |
| **4/4 — attacher le fichier** | ❌ **échec** |

**La Release `image-18` existe réellement** (vérifié par l'API) : publique, non brouillon,
**0 actif**.

---

## 2. La découverte, et elle est grave

Le corps de la Release a été écrit à partir de `sha256sum /tmp/img/*`, c'est-à-dire de **tout** ce que
l'artefact contenait après extraction. Il ne cite **qu'un seul fichier** :

```
41fe4de6e0dd5b3d9bae3e8d7c5fe16cfcff23c1c05ca77e4cbda8f83e040fe7  /tmp/img/build.log
```

> **L'artefact `nexbsd-images` ne contient pas l'image. Il contient `build.log`.**

Ce n'est pas une hypothèse : c'est le résultat de la commande qui liste **tout** le contenu.

**Conséquence à dire clairement :** les **1,82 Go** que le responsable a tenté de télécharger toute
la soirée ne sont **probablement pas** le système NexBSD. **Le produit n'a peut-être jamais été
téléversé.**

---

## 3. Les deux causes possibles — et je ne peux pas trancher

Les journaux de l'exécution sont **inaccessibles** : HTTP **403** (« Must have admin rights to
Repository »). Je ne peux donc pas lire le détail. Je donne les deux hypothèses et je corrige les
deux.

**Hypothèse A — la plus probable.** Dans le workflow principal (`nexbsd.yml`) :

```yaml
path: |
  images/**
  build.log
if-no-files-found: ignore
```

**`if-no-files-found: ignore`** : si `images/` était vide au moment de l'envoi, `upload-artifact`
produit **silencieusement** un artefact ne contenant que `build.log`.

> **C'est la leçon M-10 pour la troisième fois ce soir** : un garde-fou qui ne dit rien quand il ne
> trouve rien n'est pas un garde-fou.

**Hypothèse B.** Un actif de Release est plafonné à **2 Gio**. Si `build.log` dépasse cette taille,
`gh release upload` échoue — et `set -eu` arrête tout le reste.

---

## 4. Correctifs appliqués

### a) `nexbsd.yml` — plus jamais d'artefact vide en silence

```yaml
if-no-files-found: error   # C-50 : un artefact SANS image a été produit le 29/10 sans que rien ne le signale
```

### b) `publier-image.yml` réécrit — **le diagnostic passe avant la publication**

| Nouveauté | Pourquoi |
|---|---|
| **1/5 — `find` au lieu de `ls`**, tailles et comptage, **publiés dans le résumé du travail** | voir ce qu'il y a **avant** de publier |
| **échec explicite** si aucun fichier > 100 Mo | une image est forcément plus grosse ; **plus de silence** |
| **3/5 — découpage** de ce qui dépasse **1,9 Gio**, avec `parts.sha256` et la commande de reconstitution | contourne la limite de 2 Gio |
| **5/5 — un actif à la fois**, code de retour par fichier | l'échec d'un fichier n'empêche plus les autres |
| **notes de Release mises à jour** à chaque passage (`gh release edit`) | elles décrivent le contenu **réel** |

---

## 5. Ce que cela change pour la suite

**Le problème n'est plus le téléchargement : c'est la production.** Si l'image n'est pas dans
l'artefact, il faut savoir **pourquoi `images/` était vide** — et la réponse est probablement dans
`docs/56` : `mkimg` est **non fatal**, et `makefs` produit le `.ufs` **dans `$OBJ`**, pas
nécessairement dans `images/`.

**Ordre de travail révisé, à partir de maintenant :**

1. **relancer `PUBLIER`** avec la v2 : son diagnostic dira, en une ligne, **ce que contient
   réellement** l'artefact de l'exécution #18. C'est la seule question qui compte ;
2. si l'image **y est** (hypothèse B) → le découpage et l'envoi un-par-un la publieront ;
3. si l'image **n'y est pas** (hypothèse A) → il faut **relancer une construction** avec
   `if-no-files-found: error`, et le produit sera enfin téléversé ;
4. **dans les deux cas** : la relance coûte 5 minutes, pas 3 heures — l'artefact est déjà là.

---

## 6. Le point positif, et il est réel

**La mécanique de publication fonctionne** : récupération de l'artefact, empreintes, création de
Release, permissions — **tout est vert**. Il ne manque que **le fichier**, et l'étape qui devait le
transporter a dit « non » au lieu de faire semblant.

**Un échec qui nomme sa cause vaut mieux qu'un succès qui cache un fichier vide.**

**Acquis : A-77** (workflow v2 diagnostic-first) · **C-50**.

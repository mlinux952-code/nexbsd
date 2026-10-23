# Dépôts et sauvegardes — où vit le projet

**Version :** 1.0 — 2026-10-23 (session S-007)
**Rôle :** dire exactement où le projet est conservé, ce qui est fait, ce qui reste à faire, et comment le refaire.

---

## 1. État réel au 2026-10-23

| Support | Statut | Détail vérifiable |
|---|---|---|
| **Espace de travail (workspace)** | ✅ **source de vérité** | ~90 fichiers + dépôt Git local (1 commit `5e7c789`) |
| **Google Drive** | ✅ **sauvegarde effectuée ce jour** | dossier « NexBSD », 4 fichiers + 1 Doc de lecture |
| **GitHub** | ✅ **fait le 2026-10-23 à 21h (par le responsable)** | dépôt **privé** `mlinux952-code/nexbsd`, branche `main`, `refs/heads/main = 61293162a2ec…` (2 commits), clé SSH `Mint NexBSD` (`SHA256:QMjZ5F8h…`) |
| Disque local du responsable | ✅ partiel | clone de travail dans `~/Projets/nexbsd` ; `.bundle` téléchargé dans `~/Téléchargements` |

> **Historique du 2026-10-23 :** dépôt GitHub créé et poussé par le responsable — `git push -u origin main` accepté, `* [new branch] main -> main`. Authentification vérifiée par `ssh -T git@github.com` → `Hi mlinux952-code!`.
> **Ce qui reste décalé :** le dépôt distant s'arrête au commit `6129316`. Les commits suivants (`985a244`, `c95a51a`, `d6d2194`, `f6dbd6a`, `8afa24b`, `78c9723`, `0a62862`, …) doivent être récupérés par le bundle `s008` (§6).

## 2. Google Drive — contenu du dossier « NexBSD » (instantané S-008)

Dossier : **`NexBSD`** (racine de « Mon Drive »)
Lien : `https://drive.google.com/drive/folders/1seXkTsMaweSo9UcRFDK-frMbF6x6SE1J`

| Fichier | Identifiant | Taille | Rôle |
|---|---|---|---|
| `nexbsd-depot-2026-10-23-s008.bundle` | `1FNOgeMm50he-0NS_CsV-2wqVxM8h-tIB` | 227 585 o | **historique Git complet, 13 commits, branche `main`** — permet le rattrapage du dépôt GitHub |
| `NexBSD-etat-conception-2026-10-23-s008.tar.gz` | `10GbrAYtVOUMt9hFzKV-XLYB7ixiYWw_k` | 168 592 o | arborescence complète, sans `.git` |
| `MANIFESTE-SAUVERGARDE-2026-10-23-s008.md` | `13ovKKB1VU1wNP7A2iXpBrfc0_oMAcZYv` | 2 294 o | vérification, restauration, fréquence |
| `SHA256SUMS-s008.txt` | `1ikhQVe3Kit8k3quX5RGjYUhVgwV_wQaa` | 214 o | empreintes de l'instantané S-008 |
| `NexBSD — État du projet (S-008, 2026-10-23)` | `1jJsKhcafT-Sssy1Jpe9mata4MX5vV7PLkIF0JoqzdWM` | — | lecture rapide (ETAT v8) |

**Empreintes de l'instantané S-008 (calculées avant envoi) :**
```
ec2459dfbb308c78ae779fb497103f24e5708fe3ee6a00138bc46c24cc456ea4  NexBSD-etat-conception-2026-10-23-s008.tar.gz
8af1eed7b217e95736c31796a82a0f8e2e4f5add559d9fb0ba5bb857c911a9e2  nexbsd-depot-2026-10-23-s008.bundle
```
`git bundle verify` : **`is okay`**, « The bundle contains these 2 refs ». Le bundle s'arrête au commit qui précède cette mise à jour (un instantané ne peut pas contenir sa propre notice).

**Réserve honnête :** les fichiers n'ont pas été retéléchargés depuis Drive pour recontrôler les empreintes. À faire côté responsable : `sha256sum -c SHA256SUMS.txt`.

## 3. GitHub — procédure (conservée pour mémoire ; déjà exécutée avec succès)

### 3.1 Prérequis
- Un compte GitHub (le nom du dépôt doit être **libre** — voir Q7, antériorité du nom).
- Le fichier `nexbsd-depot-2026-10-23-s007.bundle` téléchargé depuis Drive.
- `git` installé (sur le Mint : `sudo apt install git`).

### 3.2 Créer le dépôt distant

> **Erreurs déjà rencontrées le 2026-10-23 :** voir `docs/21-pousser-sur-github.md` (dépannage pas à pas, erreurs réelles et leur cause).
> **Méthode recommandée :** `scripts/51-installer-depot-github.sh` (vérifie, clone, renomme la branche, ajoute le remote — ne pousse pas).

Sur GitHub : **New repository** → nom `nexbsd` → visibilité **Private** (recommandé, cf. `docs/13-publication-grand-public.md`) → **ne rien initialiser** (pas de README, pas de .gitignore).

### 3.3 Pousser depuis la sauvegarde
```bash
git clone nexbsd-depot-2026-10-23-s007.bundle nexbsd
cd nexbsd
git log --oneline          # doit afficher 6129316 puis 5e7c789
git remote add origin git@github.com:<votre-compte>/nexbsd.git
git push -u origin master  # ou 'main' selon la branche affichée
```

### 3.4 Règles de sécurité
- **Aucun jeton (token) dans un fichier du projet.** Authentification par clé SSH ou par le gestionnaire d'identifiants de Git.
- Dépôt **privé** tant que la porte G1 (nom, marques, licence) n'est pas franchie.
- Ne jamais pousser `archives/` (déjà dans `.gitignore`).

## 4. Rythme de sauvegarde

| Quand | Quoi |
|---|---|
| Fin de **chaque** session | nouvel instantané daté + `SHA256SUMS.txt` + téléversement Drive |
| À chaque décision validée | `git commit` avec la décision dans le message |
| Avant toute manipulation matérielle | instantané supplémentaire (le PC de 2011 n'est pas sauvegardable utilement) |

## 5. Restauration d'urgence (scénario « tout est perdu »)

1. Télécharger `nexbsd-depot-2026-10-23.bundle` depuis Drive.
2. `git clone nexbsd-depot-2026-10-23-s007.bundle nexbsd` → tout l'historique revient.
3. Sans Git : décompresser le `.tar.gz`.
4. Lire `docs/ETAT.md` **puis** `reports/` — l'état et la prochaine action y sont écrits.

## 6. Remettre à jour le dépôt GitHub après un nouvel instantané

Depuis un clone existant, sans rien perdre :
```bash
cd ~/Projets/nexbsd
git remote add bundle ~/Téléchargements/nexbsd-depot-2026-10-23-s008.bundle
git fetch bundle main
git merge --ff-only bundle/main      # avance vite, sans fusion, si l'historique est continu
git push
git remote remove bundle
```
`--ff-only` est volontaire : si la fusion n'est pas possible, mieux vaut s'arrêter que créer un commit de fusion involontaire.

## 7. Ce que cette page ne garantit pas

- Aucune redondance hors Drive : si le compte Google est perdu, il ne reste que le workspace.
- Aucune sauvegarde chiffrée : les documents ne contiennent ni secret ni donnée personnelle, mais ils sont lisibles par quiconque accède au compte.
- Aucune automatisation : la sauvegarde est **manuelle et vérifiée**, pas planifiée.

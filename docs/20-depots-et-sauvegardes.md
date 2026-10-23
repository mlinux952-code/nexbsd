# Dépôts et sauvegardes — où vit le projet

**Version :** 1.0 — 2026-10-23 (session S-007)
**Rôle :** dire exactement où le projet est conservé, ce qui est fait, ce qui reste à faire, et comment le refaire.

---

## 1. État réel au 2026-10-23

| Support | Statut | Détail vérifiable |
|---|---|---|
| **Espace de travail (workspace)** | ✅ **source de vérité** | ~90 fichiers + dépôt Git local (1 commit `5e7c789`) |
| **Google Drive** | ✅ **sauvegarde effectuée ce jour** | dossier « NexBSD », 4 fichiers + 1 Doc de lecture |
| **GitHub** | ✅ **fait** | dépôt **privé** `mlinux952-code/nexbsd`, branche `main` ; `6129316` poussé, puis rattrapage → `392541f` (`git merge --ff-only` réussi le 2026-10-23) |
| Disque local du responsable | ✅ partiel | clone de travail dans `~/Projets/nexbsd` ; `.bundle` téléchargé dans `~/Téléchargements` |

> **Historique du 2026-10-23 :** dépôt GitHub créé et poussé par le responsable — `git push -u origin main` accepté, `* [new branch] main -> main`. Authentification vérifiée par `ssh -T git@github.com` → `Hi mlinux952-code!`.
> **Ce qui reste décalé :** le dépôt distant s'arrête au commit `6129316`. Les commits suivants (`985a244`, `c95a51a`, `d6d2194`, `f6dbd6a`, `8afa24b`, `78c9723`, `0a62862`, …) doivent être récupérés par le bundle `s008` (§6).

## 2. Google Drive — contenu du dossier « NexBSD » (instantané S-011)

Dossier : **`NexBSD`** — `https://drive.google.com/drive/folders/1seXkTsMaweSo9UcRFDK-frMbF6x6SE1J`

| Fichier | Identifiant | Rôle |
|---|---|---|
| `nexbsd-depot-2026-10-23-s011.bundle` | `1gzUSFNMJPigrp_kCP_rFNRcxkl7nZVV2` | historique Git complet, **20 commits** — contient le script VM avec KVM |
| `NexBSD-etat-conception-2026-10-23-s011.tar.gz` | `1fWUz4oCA6ovOeQMulFLbK3WUH5o7Htk0` | arborescence complète, delta NexBSD inclus |
| `SHA256SUMS-s011.txt` | `1d9aTSLbM6iTcozPoxTGRnJtqIrMx-lFd` | empreintes |
| `NexBSD — État du projet (S-011)` | `1kRiS3ctZ-CkzESFUBT_7ICWwqRsUMoVBThnGIxd3p9g` | lecture rapide (ETAT v10) |

**Empreintes (calculées avant envoi) :**
```
3ac0a017f11023ea492ba9bf7164f9a5bc08e791b20d210ed3566ac47f9c6215  NexBSD-etat-conception-2026-10-23-s011.tar.gz
6fa8927f4785a1576c7ca9d82c697fdd7ce6d02765dca3b4d7244ef68dc409ca  nexbsd-depot-2026-10-23-s011.bundle
```
`git bundle verify` → **is okay**. Les instantanés antérieurs (S-006 → S-009) sont à la corbeille.

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
git remote add bundle ~/Téléchargements/nexbsd-depot-2026-10-23-s011.bundle
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

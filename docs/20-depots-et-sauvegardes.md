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

## 2. Google Drive — contenu du dossier « NexBSD » (instantané S-009)

Dossier : **`NexBSD`** — `https://drive.google.com/drive/folders/1seXkTsMaweSo9UcRFDK-frMbF6x6SE1J`

| Fichier | Identifiant | Rôle |
|---|---|---|
| `nexbsd-depot-2026-10-23-s009.bundle` | `1MsfgckBzqMwv7DvD9MVSDoYUzFadmjRq` | historique Git complet (restauration `git clone`) |
| `NexBSD-etat-conception-2026-10-23-s009.tar.gz` | `1JMEs0sAv-pgdyUBYVDowqfHOb64GIo3t` | arborescence complète, `tests/results/` inclus |
| `SHA256SUMS-s009.txt` | `1L9eTTM7jAnKUx_9P-smYPDfxLOahxslk` | empreintes |
| `NexBSD — État du projet (S-009)` | `1nYr1xuHhTokZ16DDI7NTQeZTYr3UXa7vN-FfHNYivsQ` | lecture rapide (ETAT v9) |
| `Résultats de tests — T-01 et T-03` | `18bT3UW9givXmEbi_Tzms0rwypxvbJTrAMwzDnM-xjZo` | premier test réel réussi |

**Empreintes (calculées avant envoi) :**
```
79b30daf710a98dca14b4d869033ef6ab2eb95dd30b5ada859523d226c6bd012  NexBSD-etat-conception-2026-10-23-s009.tar.gz
240bf1318530315af04c4203149c58e87cccb66749ab5d60356f55f8f27ee6ce  nexbsd-depot-2026-10-23-s009.bundle
```
`git bundle verify` → **is okay**. Les instantanés S-006, S-007 et S-008 ont été mis à la corbeille.

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

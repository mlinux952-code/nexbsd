# Dépôts et sauvegardes — où vit le projet

**Version :** 1.0 — 2026-10-23 (session S-007)
**Rôle :** dire exactement où le projet est conservé, ce qui est fait, ce qui reste à faire, et comment le refaire.

---

## 1. État réel au 2026-10-23

| Support | Statut | Détail vérifiable |
|---|---|---|
| **Espace de travail (workspace)** | ✅ **source de vérité** | ~90 fichiers + dépôt Git local (1 commit `5e7c789`) |
| **Google Drive** | ✅ **sauvegarde effectuée ce jour** | dossier « NexBSD », 4 fichiers + 1 Doc de lecture |
| **GitHub** | ❌ **non fait — impossible depuis cette session** | aucun connecteur GitHub disponible ; **action du responsable** |
| Disque local du responsable | ❌ non fait | à faire depuis Drive (téléchargement) |

> **Aucun dépôt GitHub n'a été créé. Aucun `git remote` n'est configuré.** Ne pas dire le contraire.

## 2. Google Drive — ce qui a été déposé

Dossier : **`NexBSD`** (racine de « Mon Drive »)
Lien : `https://drive.google.com/drive/folders/1seXkTsMaweSo9UcRFDK-frMbF6x6SE1J`

| Fichier | Identifiant | Taille | Rôle |
|---|---|---|---|
| `NexBSD-etat-conception-2026-10-23-s007.tar.gz` | `1cBM2ptzs8LVUxKVVtc52dX1O2XjRTQnL` | 159 669 o | arborescence complète (92 fichiers), sans `.git` |
| `nexbsd-depot-2026-10-23-s007.bundle` | `1VrjyUIu2RBGNbwWJSEpmi43XPBS7U9sA` | 211 800 o | historique Git complet (2 commits, HEAD `6129316`), vérifié par `git bundle verify` |
| `MANIFESTE-SAUVERGARDE-2026-10-23-s007.md` | `13RRYWWdSKYldIH2eNZox6AQlbogas9db` | 2 226 o | vérification, restauration, fréquence |
| `SHA256SUMS-s007.txt` | `1UdyZOIsYrG436qQHFln3IESA6wkuSinH` | 214 o | empreintes des deux archives |
| `NexBSD — État du projet (S-007, 2026-10-23)` (Google Doc) | `1z7QeBJ4goWWmHbI05SDM4Fra_eSUoAz2a4mVn1lzRjU` | — | lecture rapide (ETAT v7) |

**Vérification faite après dépôt (2026-10-23) :** le dossier a été relisté par l'API et contient **exactement 5 fichiers actifs**, aux identifiants ci-dessus. Un instantané antérieur (S-006, même jour) a été **mis à la corbeille** pour éviter la confusion entre deux versions.

**Empreintes (calculées avant envoi) :**
```
e9a089144a4e5d3a8b31dadc31f159dbf83dd31451aaf50bf9b8acf9d92ed357  NexBSD-etat-conception-2026-10-23-s007.tar.gz
39eecae5e5186610d097ee0e2867602e3b69a4eeb011f834334a3c3d6115e3b8  nexbsd-depot-2026-10-23-s007.bundle
```
**Réserve honnête :** les fichiers n'ont **pas** été retéléchargés depuis Drive pour recontrôler ces empreintes. C'est la première chose à faire côté responsable : `sha256sum -c SHA256SUMS-s007.txt`.

## 3. GitHub — procédure exacte, à exécuter par le responsable

### 3.1 Prérequis
- Un compte GitHub (le nom du dépôt doit être **libre** — voir Q7, antériorité du nom).
- Le fichier `nexbsd-depot-2026-10-23-s007.bundle` téléchargé depuis Drive.
- `git` installé (sur le Mint : `sudo apt install git`).

### 3.2 Créer le dépôt distant
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

## 6. Ce que cette page ne garantit pas

- Aucune redondance hors Drive : si le compte Google est perdu, il ne reste que le workspace.
- Aucune sauvegarde chiffrée : les documents ne contiennent ni secret ni donnée personnelle, mais ils sont lisibles par quiconque accède au compte.
- Aucune automatisation : la sauvegarde est **manuelle et vérifiée**, pas planifiée.

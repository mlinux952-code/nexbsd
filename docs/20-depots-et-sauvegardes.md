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

| Fichier | Identifiant | Rôle |
|---|---|---|
| `NexBSD-etat-conception-2026-10-23.tar.gz` | `1q79NU5A80Ej8cnA9sMPr0sAynmFc0hxe` | arborescence complète (90 fichiers), 148 Ko |
| `nexbsd-depot-2026-10-23.bundle` | `15pxHpY8OvYLKG-5Tp_xdxujIBJr-5xPF` | historique Git complet, 195 Ko |
| `MANIFESTE-SAUVERGARDE-2026-10-23.md` | `18vvfm6PIAOSWmd0TGelWNTf_m7mrXviv` | mode d'emploi, vérification, restauration |
| `SHA256SUMS.txt` | `1wLkfY0lrx8CR3tHgi69UzTowPQcp_KaQ` | empreintes des deux archives |
| `NexBSD — État du projet (2026-10-23)` (Google Doc) | — | lecture rapide sur téléphone |

**Vérification faite après dépôt :** les quatre identifiants ci-dessus sont ceux renvoyés par l'API lors du téléversement. La *taille* et les *empreintes* ont été calculées **avant** l'envoi ; personne n'a encore retéléchargé les fichiers pour les recontrôler — ce contrôle revient au responsable (`sha256sum -c SHA256SUMS.txt`).

## 3. GitHub — procédure exacte, à exécuter par le responsable

### 3.1 Prérequis
- Un compte GitHub (le nom du dépôt doit être **libre** — voir Q7, antériorité du nom).
- Le fichier `nexbsd-depot-2026-10-23.bundle` téléchargé depuis Drive.
- `git` installé (sur le Mint : `sudo apt install git`).

### 3.2 Créer le dépôt distant
Sur GitHub : **New repository** → nom `nexbsd` → visibilité **Private** (recommandé, cf. `docs/13-publication-grand-public.md`) → **ne rien initialiser** (pas de README, pas de .gitignore).

### 3.3 Pousser depuis la sauvegarde
```bash
git clone nexbsd-depot-2026-10-23.bundle nexbsd
cd nexbsd
git log --oneline          # doit afficher 5e7c789
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
2. `git clone nexbsd-depot-2026-10-23.bundle nexbsd` → tout l'historique revient.
3. Sans Git : décompresser le `.tar.gz`.
4. Lire `docs/ETAT.md` **puis** `reports/` — l'état et la prochaine action y sont écrits.

## 6. Ce que cette page ne garantit pas

- Aucune redondance hors Drive : si le compte Google est perdu, il ne reste que le workspace.
- Aucune sauvegarde chiffrée : les documents ne contiennent ni secret ni donnée personnelle, mais ils sont lisibles par quiconque accède au compte.
- Aucune automatisation : la sauvegarde est **manuelle et vérifiée**, pas planifiée.

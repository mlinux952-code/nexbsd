# NexBSD — delta propre (arborescence du fork)

**Statut : `[PROPOSITION]` — squelette préparatoire. Aucun de ces fichiers n'a été validé par une construction réelle.**
**Rôle :** contenir **tout ce que NexBSD ajoute ou change** par rapport à l'arbre FreeBSD. Le delta doit rester **petit, lisible et fusionnable** (ADR-0011).

---

## 1. Principe

L'arbre source FreeBSD reste **intact**. NexBSD vit dans un répertoire séparé, copié dans l'arbre au moment de la construction :

```
nexbsd-src/                     ← clone de git.FreeBSD.org/src.git (non modifié)
├── nexbsd/                     ← CE RÉPERTOIRE = le delta propre NexBSD
│   ├── src.conf                ← ce que le système contient (et ne contient pas)
│   ├── NEXBSD_L1               ← configuration du noyau pour la cible PC faible
│   ├── release.conf            ← réglages de production de l'image
│   ├── exceptions-licence.txt  ← exemptions justifiées du contrôle T-13
│   └── build-nexbsd.sh         ← chaîne de construction garde-fou
├── sys/ …                      ← code FreeBSD, non modifié
└── release/ …                  ← code FreeBSD, non modifié
```

**Règle de discipline :** toute modification d'un fichier FreeBSD existant (et non l'ajout d'un fichier dans `nexbsd/`) est une **divergence** : elle exige un ADR, doit être isolée dans un correctif nommé, et être documentée comme telle. C'est ce qui rend les fusions amont possibles dans cinq ans.

## 2. Contenu

| Fichier | Rôle | Validé par |
|---|---|---|
| `src.conf` | options de construction : retire le superflu (tests, exemples, jeux, profils), garde le nécessaire | **aucun build réel** |
| `NEXBSD_L1` | configuration de noyau : part de `GENERIC` et **retire** des pilotes inutiles | **aucun build réel** |
| `release.conf` | réglages de `release.sh` (nom de produit, image memstick, compression) | **aucun build réel** |
| `exceptions-licence.txt` | exemptions du contrôle de frontière de licence | outil testé, liste vide au départ |
| `build-nexbsd.sh` | enchaîne buildworld / buildkernel / image, avec garde-fous | **non exécuté** |

## 3. Ce qu'il faut avant de lancer quoi que ce soit

| Exigence | Pourquoi | Statut |
|---|---|---|
| Une machine **FreeBSD** (pas Linux, pas Windows) | `buildworld` s'exécute sous FreeBSD ; le multi-OS n'est pas supporté de façon fiable | profil **L3** |
| **≥ 8 Go de RAM** (16 recommandé) | la construction de la base est gourmande | L3 |
| **≥ 40 Go** d'espace libre | sources + objets + images | L3 |
| Sources récupérées | `git clone https://git.FreeBSD.org/src.git` | L3 |
| Patience | plusieurs heures pour un premier build complet | — |

**Sans L3, ce répertoire ne sert à rien de plus qu'à fixer les décisions.** C'est assumé (ADR-0010) : il vaut mieux des fichiers prêts et honnêtes qu'une fausse promesse de « ça marche ».

## 4. Ordre d'exécution (le jour où L3 arrive)

```sh
# 1. récupérer les sources
git clone --depth 1 -b stable/15 https://git.FreeBSD.org/src.git ~/nexbsd-src
cd ~/nexbsd-src

# 2. créer la branche NexBSD
git switch -c nexbsd/15-base

# 3. copier le delta
cp -r ~/nexbsd/fork ~/nexbsd-src/nexbsd

# 4. vérifier la frontière de licence (T-13)
sh nexbsd/build-nexbsd.sh --check-licence

# 5. construire (heures)
sh nexbsd/build-nexbsd.sh --world --kernel

# 6. produire l'image
sh nexbsd/build-nexbsd.sh --release
```

Chaque étape produit un journal dans `nexbsd/logs/` — à conserver, car **c'est la preuve** que l'image vient bien de cet arbre (porte G7 de la publication).

## 5. Ce qui fera de NexBSD « à part entière »

Au sens du test des sept questions (`docs/11-fork-pas-surcouche.md` §2), ce répertoire répond aux questions 1 à 4. Les questions 5 (suivi de sécurité), 6 (identité technique) et 7 (divergence réelle) ne seront satisfaites que par la **pratique** : fusions régulières, mesures publiées, et un delta qui grandit délibérément.

**Le premier vrai signe de vie de NexBSD sera un fichier `nexbsd/logs/build-YYYYMMDD.log` accompagné d'une image dont on sait dire exactement d'où elle vient.**

# Cible matérielle — « PC faible »

**Version :** 1.0 — 2026-10-23
**Statut :** `[PROPOSITION]` — définition de cible, non validée
**Origine :** précision apportée par le responsable du projet : *« NexBSD est un système d'exploitation pour PC faible »*.

---

## 1. Pourquoi ce document existe

Jusqu'ici, « 4 Go de RAM » était traité comme une **limite du matériel de test**. Ce n'est pas la même chose que faire du **PC faible une cible de conception**.

La différence est décisive :

| Approche | Conséquence |
|---|---|
| « On développe normalement, on testera sur une vieille machine » | le système grossit, puis on découvre qu'il ne rentre pas |
| **« Le PC faible est la cible »** | chaque composant est choisi *parce qu'il tient dans le budget*, et le budget est mesuré |

Ce document fixe le budget. Il n'est pas décoratif : il sert à **refuser** des composants.

## 2. Définition de la cible

### 2.1 Profils de matériel visés

| Profil | Processeur | RAM | Disque | Statut |
|---|---|---|---|---|
| **L0 — minimum supporté** | 32 bits, ≥ 1 GHz | 512 Mo | 8 Go | `[HYPOTHÈSE]` — probablement hors d'atteinte avec FreeBSD 15 (voir §3) |
| **L1 — cible principale** | amd64 (64 bits), 2 cœurs | **1 à 2 Go** | 20 Go HDD | cible de référence du projet |
| **L2 — machine de test actuelle** | amd64, 2 cœurs | 4 Go | HDD mécanique | sert à mesurer, pas à définir |
| **L3 — « PC fort », plus tard** | amd64, ≥ 8 cœurs | ≥ 16 Go | SSD | réservé à la construction, aux tests lourds et à la couche mobile |

**Décision de cadrage proposée : la cible de référence est L1 (1-2 Go de RAM, 64 bits).** L2 sert de banc de mesure ; L3 n'existe pas encore et ne doit pas être supposé.

### 2.2 Budget de ressources (objectifs mesurables)

Ces chiffres sont des **objectifs**, pas des résultats. Aucun n'a été mesuré.

| Indicateur | Objectif L1 | Méthode de mesure |
|---|---|---|
| RAM au repos (système seul, sans service) | **≤ 128 Mo** | `vmstat -h`, `top` |
| RAM avec services réseau (fichiers + journaux) | **≤ 256 Mo** | idem |
| Temps de démarrage jusqu'à l'invite | **≤ 60 s** sur HDD | chronomètre |
| Empreinte disque de l'installation de base | **≤ 2 Go** | `df -h` |
| Empreinte disque avec services | **≤ 4 Go** | idem |
| Interface graphique (si activée) | optionnelle, **≤ 256 Mo supplémentaires** | idem |

**Règle :** un composant qui fait dépasser le budget est refusé ou isolé, même s'il est techniquement intéressant.

## 3. Le problème du 32 bits (point dur)

- FreeBSD 15.x **n'existe plus en i386** (retiré, ainsi que armv6 et powerpc 32 bits).
- FreeBSD 14.x conserve i386, avec une branche supportée jusqu'au **30 novembre 2028**.

Conséquence :

| Si la cible « PC faible » inclut des machines 32 bits | Alors |
|---|---|
| **Oui** | la base doit être **FreeBSD 14.x i386**, avec une durée de vie connue (2028) et des paquets en voie d'extinction → dette à assumer explicitement |
| **Non** (PC faibles mais 64 bits) | **FreeBSD 15.x amd64** reste le bon choix, plus durable |

`[À VÉRIFIER]` — cette question n'est pas tranchée à ce jour. Elle conditionne ADR-0001.

> Le PC de 2011 n'est pas concerné par ce doute s'il est 64 bits ; c'est la **définition de la cible** qui est en jeu, pas le banc d'essai.

## 4. Conséquences de conception (ce que « PC faible » interdit ou impose)

### 4.1 Interdits par le budget

| Composant / pratique | Raison |
|---|---|
| **ZFS** comme système de fichiers par défaut | le cache ARC consomme de la RAM de façon agressive ; sur 1-2 Go, c'est disqualifiant → **UFS par défaut** sur le profil L1 |
| Environnement de bureau complet (GNOME, KDE) | plusieurs centaines de Mo pour l'affichage |
| Navigateur/moteur Web moderne en fonctionnement permanent | WebKitGTK/Firefox : 200-500 Mo et + ; réservé au profil « démonstration mobile », jamais au profil serveur |
| Empilement de machines virtuelles sur la cible | bhyve ne partage pas la mémoire |
| Services redondants (deux annuaires, deux serveurs de fichiers) | chaque démon a un coût fixe |
| Base de données lourde, moteur de conteneurs, orchestrateur | hors budget et hors besoin |
| Compilation sur la cible | plusieurs Go de RAM et des heures de CPU ; **réservé à L3** |

### 4.2 Imposés

| Exigence | Raison |
|---|---|
| Installation **minimale** (pas de méta-paquet `xorg`, pas de jeux d'outils inutiles) | budget disque et surface d'attaque |
| Services **désactivés par défaut**, activation explicite | budget RAM et sécurité |
| Mesure systématique de la RAM après chaque ajout de composant | sans mesure, la cible n'est pas tenue |
| Préférence pour les **paquets binaires** | pas de compilation sur cible |
| Documentation « ce qui rentre / ce qui ne rentre pas » à chaque version | honnêteté et reproductibilité |
| Interface : **texte d'abord** ; interface graphique optionnelle | c'est un choix de cible, pas une régression |

### 4.3 Arbitrage sur la couche mobile

Le profil mobile (coquille WebKitGTK) **dépasse largement** le budget L1. Il ne peut donc pas être la configuration par défaut d'un « système pour PC faible ».

**Proposition :** trois images logicielles distinctes, construites à partir de la même base :

| Image | Contenu | Budget RAM visé |
|---|---|---|
| `nexbsd-lab` | base + journaux + outils | ≤ 128 Mo |
| `nexbsd-net` | base + Samba + annuaire + supervision | ≤ 256 Mo |
| `nexbsd-mobile` | base + moteur Web + coquille petit écran | ≤ 768 Mo (profil L2/L3) |

Ce découpage remplace la notion floue de « système unique hybride ».

## 5. Ce que cela change dans les documents existants

| Document | Modification induite |
|---|---|
| `docs/00-cadrage-phase0.md` | le périmètre « PC faible » devient un critère de sélection des composants |
| `docs/architecture.md` | la couche C n'est plus dans la configuration par défaut |
| `matrices/components.csv` | ZFS rétrogradé, WebKitGTK reclassé « profil mobile uniquement » |
| `docs/prototypes.md` | le prototype 0 doit être mesuré **contre le budget §2.2** |
| ADR | ajout d'ADR-0009 (cible PC faible) |

## 6. Ce qui n'est pas décidé

- 32 bits ou 64 bits comme plancher de la cible (§3).
- Le budget exact du profil L1 (128 Mo ou 256 Mo au repos) : à ajuster après la première mesure réelle.
- La pertinence d'un profil « routeur/appliance » sans disque (hors périmètre pour l'instant).

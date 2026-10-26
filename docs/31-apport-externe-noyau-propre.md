# Apport externe — le noyau « depuis zéro » (P1) et son usage dans NexBSD

**Version :** 1.0 — 2026-10-26 · **Rôle :** analyser, sans complaisance, le travail produit par une **autre
session** (dossier partagé par le responsable : `workspace-…zip`, 12 038 643 o, sha256 `7f754cfd…e67389`)
et décider **ce qu'on en prend**, **ce qu'on n'en prend pas**, et **pourquoi**.

---

## 1. Ce que contient réellement ce dossier (constat, pas opinion)

| Élément | Détail vérifié |
|---|---|
| Documentation de projet | 8 dossiers (`00_Gouvernance` → `08_Preuves`), matrice de licences (21 composants), matrice de fonctions (30), registre de risques (R-01→R-12), registre de décisions **D-000 → D-011** |
| Atelier `nexbsd-p1/` | **3 246 lignes de C** au total, 24 fichiers source, dépôt Git local, chargeur **Limine** (BSD-2) |
| Noyau produit | **59 840 octets** (M8), image ISO **4 460 544 o**, sha256 `f8dd79c2…38266f` — **l'ISO existe vraiment**, elle est dans le dossier |
| Jalons franchis | **M1 → M8** avec rapports de tests : framebuffer, shell clavier FR, historique, pagination 4 niveaux, tas noyau, **ring 3**, **appels système `int 0x80`**, **deux tâches à espaces d'adressage séparés** |
| Preuves | journaux bruts cités mot à mot (`M7-ISOLATION-OK`, `CPL = 3`, défauts de page interceptés), captures d'écran, **démarrages reproductibles** (mêmes empreintes à chaque construction), BIOS **et** UEFI |
| Environnement | QEMU uniquement — aucune machine physique touchée |

**C'est un vrai travail, sérieux et bien documenté.** La discipline de preuve y est même, sur certains points,
supérieure à la nôtre (empreintes comparées à chaque construction, journaux bruts cités, verdicts par test).

## 2. Ce que ce noyau n'a pas — et qui décide de tout

Recherche effectuée dans les 24 fichiers source : **aucune trace de réseau, de carte réseau, de disque, de
système de fichiers, de compte utilisateur, de partage, d'annuaire.** Les seules occurrences de « fs » sont le
registre de segment `FS` du processeur.

| Fonction nécessaire au **produit** NexBSD (axe NetWare) | Présente dans P1 ? |
|---|---|
| Pile TCP/IP, carte réseau virtuelle ou réelle | **non** |
| Pilote de disque (AHCI/NVMe/virtio-blk), système de fichiers | **non** |
| Comptes, groupes, droits, partages authentifiés | **non** |
| Serveur d'annuaire | **non** |
| Outils utilisateur (shell système, éditeurs, sauvegarde) | **non** (un programme de 138 octets en ring 3) |

Autrement dit : P1 prouve **l'indépendance** (le cœur du noyau nous appartient) ; il ne fournit **aucune** des
fonctions qui font de NexBSD le remplaçant d'un serveur NetWare. Il est à des **années** — pas des semaines —
d'un serveur de fichiers avec identités centrales, à 5-10 h/semaine.

## 3. Les deux trajectoires, comparées honnêtement

| Critère | **Voie fork** (celle du produit, en cours) | **Voie noyau propre** (P1) |
|---|---|---|
| État au 2026-10-26 | socle FreeBSD 15.1, banc d'identités **11/11**, noyau `NEXBSD_L1` **en construction**, **45 253 lignes compilées** | noyau de 59 840 o, ring 3, 2 tâches, **aucune fonction réseau/disque** |
| Ce qu'elle prouve | le système **rend le service** (identités, droits, partages) et **nous le compilons** | le projet **sait écrire un noyau** de ses mains |
| Délai jusqu'à « NexBSD s'installe sur un PC et sert les identités » | **semaines** (J1 aujourd'hui probable, J3→J5 en intégration continue) | **années** (pile réseau + pilotes + FS + comptes + Samba/NCP à écrire) |
| Risque principal | dépendance à l'amont, delta modeste (5 lignes) | temps ; ne livre jamais le service attendu |
| Niveau d'indépendance | I2/I3 (dérivé maîtrisé, reconstruit par nous) | **I4** (noyau original) |

**Conclusion factuelle :** les deux ne répondent pas à la même question. La voie fork répond à *« le système
rend-il le service, et est-ce nous qui le construisons ? »*. La voie noyau propre répond à *« savons-nous
écrire un noyau ? »*. Le produit a besoin de la première ; la crédibilité technique du projet gagne à la seconde.

## 4. Ce que nous **adoptons** de leur travail (et qui améliore le nôtre)

| Apport | Pourquoi c'est meilleur que ce que nous avions | Où il entre chez nous |
|---|---|---|
| **Échelle d'indépendance I0→I5** | notre formulation par « étages » était locale et non graduée ; I0-I5 permet de **situer chaque livrable** | `docs/32` + une ligne dans `ETAT.md` |
| **Jalons M-numérotés avec critères mesurés et verdict par test** | plus rigoureux que nos « essais 1/2 » | réutilisé pour J1→J7 |
| **Reproductibilité prouvée par empreintes comparées** | nous vérifions les sources, pas encore les **sorties** | à appliquer au noyau : reconstruire et comparer |
| **Harnais QEMU + captures + journaux bruts** | nous dépendons du copier-coller du responsable | à reprendre dès J3 |
| **Matrice de licences (21 composants)** | complète notre `docs/12` | à fusionner |
| **Règle « aucune affirmation sans test réel »** | déjà la nôtre — mais leur mise en forme est plus opposable | reprise telle quelle |

## 5. Ce que nous **n'adoptons pas** comme produit (et pourquoi)

1. **Le noyau propre ne devient pas le produit.** Sans pile réseau ni système de fichiers, il ne peut pas
   porter l'axe NetWare — qui est la raison d'être du projet (`ADR-0017`).
2. **Aucun document ne présentera P1 comme « NexBSD ».** Ce serait exactement la faute que ce projet interdit :
   affirmer l'existence de ce qui n'existe pas encore.
3. **Aucune fusion des deux arbres.** Mélanger un noyau de 59 Ko et une base FreeBSD n'a aucun sens technique.

## 6. Décision (appliquée, révisable par le responsable)

**Deux couloirs, un seul produit.**

| Couloir | Contenu | Règle |
|---|---|---|
| **Produit** (prioritaire) | voie fork : J1 (noyau `NEXBSD_L1`) → J7 (NCP) | **consomme tout le temps disponible** jusqu'à J5 (image installable sur un PC) |
| **Recherche** (`research/noyau-propre/`) | le travail P1, archivé avec attribution et empreintes | **ne consomme aucun temps du produit** avant J5 ; ne se présente jamais comme le produit |

**Et une mise au point de registre :** la session extérieure a enregistré « D-001 → I4 validé ». Chez nous,
l'architecture du **produit** reste `ADR-0001` (base FreeBSD) et `ADR-0011` (fork, pas surcouche) : c'est ce qui
permet de livrer un serveur d'identités. **D-001/I4 est donc traité comme valable pour le couloir recherche
uniquement.** Si le responsable veut l'étendre au produit, cela suppose d'assumer publiquement que NexBSD ne
rendra aucun service NetWare avant plusieurs années — et ce choix doit alors être écrit noir sur blanc.

## 7. Ce que cela change pour aujourd'hui

**Rien, et c'est volontaire.** La construction du noyau `NEXBSD_L1` est en cours sur le banc ; elle finit, elle
s'installe, elle se vérifie (`uname -i` = `NEXBSD_L1`). Ce travail extérieur est une **richesse de méthode**,
pas une raison de changer de route à mi-course.

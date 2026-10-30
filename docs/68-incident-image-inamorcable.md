# 68 — L'image est téléchargée, vérifiée… et elle ne peut pas démarrer

**Date :** 2026-10-30
**Contexte :** le responsable a téléchargé la Release `image-18`, obtenu **l'empreinte exacte**
attendue, et le projet tient enfin un fichier de 2,3 Go entre ses mains.
**Résultat de ce document :** l'image est **authentique et complète**, le système de fichiers
**est bien là**, mais **le disque ne porte aucune chaîne d'amorçage** : il afficherait
« Invalid Bootblock ». **Cause mesurée, pas supposée. Correctif écrit.**
**Identifiants :** incident **C-51**, acquis **A-79**.

---

## 1. Ce qui est prouvé — et c'est beaucoup

### a) Le téléchargement est parfait

```
100  478M  100  478M     0  0  3371k      0 --:--:-- --:--:-- --:--:-- 3479k
8188cba28038884e2ac075c89581132ba27cb5852b1ad765207ee01d599e0d7b  nexbsd.img.gz
```

L'empreinte annoncée dans les notes de la Release est **identique au caractère près**.
`gzip -t` répond **ARCHIVE INTACTE**. `gunzip` produit **2,3 G**.
**Le problème de téléchargement du 29/10 est terminé : 2 min 25 s, sans coupure, sans jeton.**

### b) `file` dit la vérité sur le disque

```
DOS/MBR boot sector; partition 1 : ID=0xa5, active, startsector 1, 4685824 sectors
```

| Champ | Sens |
|---|---|
| `ID=0xa5` | **slice FreeBSD** (165) — ce n'est pas du Linux, c'est bien notre système |
| `active` | le drapeau d'amorçage est posé |
| `4685824 sectors` | × 512 = **2 399 141 888 octets**, exactement la taille annoncée |

### c) J'ai ouvert le disque moi-même (et pas seulement cru `file`)

J'ai retéléchargé l'image dans mon atelier et lu ses premiers 20 Mo :

```
=== SECTEUR 0 (MBR) ===
signature 0x55AA : PRESENTE
440 premiers octets : 415 octets non nuls -> du CODE est present
chaines dans le secteur 0 : ['F6  PXE', 'Boot: ', 'Linu', 'FreeBS', 'Drive ']
  partition 1: amorcable=0x80 type=0xa5 debut_LBA=1 secteurs=4685824
```

> Ces chaînes — `F1 FreeBSD`, `F6 PXE`, `Boot:` — sont la signature **de `boot0`**, l'amorce
> FreeBSD. **Le MBR est correct : il sait afficher un menu et chercher une slice active.**

---

## 2. Ce qui ne va pas — la mesure

```
=== SECTEUR 1 = premier secteur de la slice FreeBSD ===
tout a zero : OUI

=== ZONE D'AMORCAGE DE LA SLICE (8192 premiers octets) ===
  octets     0-  511 :   0 octets non nuls   <-- VIDE
  octets   512- 1023 :   0 octets non nuls   <-- VIDE
  ... (16 blocs, tous vides)

=== DISKLABEL (doit commencer par le magic 0x82564557) ===
  offset 512 dans la slice : 0x0
  offset   0 dans la slice : 0x0

  octets non nuls dans la zone d'amorcage (0-65536) : 0

=== LE SYSTEME DE FICHIERS EST-IL LA ? ===
  magic 0x19540119 -> FS_UFS2 CONFIRME
```

### Traduction

| Constat | Conséquence |
|---|---|
| `boot0` présent dans le secteur 0 | il s'exécute, affiche le menu |
| premier secteur de la slice **à zéro** | `boot0` y cherche `boot1`… et trouve des zéros |
| aucun `disklabel` | même si `boot1` existait, il n'aurait pas de table de partitions à lire |
| 65 536 octets à zéro | la zone d'amorçage UFS entière est vide |
| superbloc UFS2 valide | **le système de fichiers, lui, est intact et complet** |

> ### VERDICT : le disque contient un système, mais **rien pour le lancer**.
> `boot0` affichera **« Invalid Bootblock »** et s'arrêtera. Pas de noyau, pas de login.

**Ce qui est cassé n'est pas le produit : c'est l'enveloppe.**

---

## 3. La cause exacte, dans notre propre code

`fork/build-nexbsd.sh`, étape 6, contenait deux tentatives :

```sh
mkimg -s mbr -f raw -b boot0 -p freebsd:=UFS      # ← celle qui a « réussi »
mkimg -s gpt -f raw -b pmbr  -p freebsd-ufs:=UFS  # ← le repli, jamais atteint
```

**Aucune des deux ne produit un disque amorçable** — ce n'est pas un aléa, c'est une propriété
de `mkimg` :

- **MBR** : `-b boot0` écrit le code dans le **MBR** ; la slice reçoit **le système de fichiers
  brut**, sans `boot1` et sans `disklabel`. `boot0` ne peut pas enchaîner.
- **GPT** : `-b pmbr` écrit `pmbr` ; mais sans partition **`freebsd-boot` contenant `gptboot`**,
  `pmbr` n'a rien à sauter dedans.

Et le commentaire du script l'avouait déjà : *« JAMAIS CONFRONTÉE À UNE VRAIE MACHINE :
best effort »*. **C'était écrit noir sur blanc depuis le 28/10** — et c'est exactement ce qui
est arrivé. La ligne « best effort » n'était pas une précaution : c'était un aveu.

### La chaîne correcte — lue chez FreeBSD, pas inventée

`release/tools/vmimage.subr` (le script officiel qui fabrique les images de VM FreeBSD) :

```sh
BOOTPARTS="-b ${BOOTFILES}/i386/pmbr/pmbr \
           -p freebsd-boot/bootfs:=${BOOTFILES}/${X86GPTBOOTFILE}"

${MKIMG} -s ${PARTSCHEME} -f ${VMFORMAT} ${BOOTPARTS} ${SWAPOPT} ${ROOTFSPART} -o ${VMIMAGE}
```

avec `X86GPTBOOTFILE=i386/gptboot/gptboot` pour un système de fichiers UFS.

**pmbr démarre → lit la table GPT → saute dans gptboot → gptboot charge `/boot/loader`.**

---

## 4. La deuxième panne, trouvée en la cherchant

En relisant l'overlay : **il n'y avait aucun `etc/fstab`**. Or `make distribution` **n'en installe
pas** — c'est l'installeur qui le fabrique, et nous n'en avons pas.

**Même avec une chaîne d'amorçage correcte**, le noyau se serait arrêté sur :

```
Mounting root from ufs:/dev/...
mountroot>
```

**Deux pannes indépendantes, la seconde cachée derrière la première.** Sans l'inspection du
disque, on aurait corrigé la première, relancé trois heures de construction, et buté sur la seconde.

---

## 5. Le correctif (écrit, pas seulement décrit)

| Fichier | Changement |
|---|---|
| **`fork/build-nexbsd.sh`** | `mkimg -s gpt -b boot/pmbr -p freebsd-boot/bootfs:=boot/gptboot -p freebsd-ufs/rootfs:=UFS` |
| **`fork/build-nexbsd.sh`** | ⭐ **nouveau garde-fou `verifier_chaine_amorcage`** : après fabrication, le disque est **ouvert** (`mdconfig` + `gpart show`) et on **compte les partitions `freebsd-boot`**. Zéro → **échec explicite**, le fichier n'est pas publié. |
| **`fork/build-nexbsd.sh`** | vérification **avant** `mkimg` que `boot/gptboot`, `boot/pmbr` et `boot/loader` existent dans la racine |
| **`fork/overlay/etc/fstab`** 🆕 | `/dev/gpt/rootfs / ufs rw 1 1` + `fdescfs` |
| **`fork/overlay/boot/loader.conf`** 🆕 | `vfs.root.mountfrom="ufs:/dev/gpt/rootfs"`, `autoboot_delay="3"` |
| **`fork/70-appliquer-overlay.sh`** | pose ces deux fichiers (`poser` ne les connaissait pas) |
| **`scripts/70`** | delta **39 → 41** fichiers |

**Pourquoi `/dev/gpt/rootfs` et pas `/dev/ada0s1a` :** l'étiquette GPT ne change pas ; le nom
`ada0s1a` change selon le contrôleur (`ada`, `da`, `vtbd`), c'est-à-dire **selon la machine**.
Une image qui ne démarre que sur l'ordinateur qui l'a fabriquée n'est pas une image.

**Pourquoi le contrôle par `gpart` et pas la confiance dans `mkimg` :** c'est **la troisième fois**
ce soir qu'un garde-fou silencieux aurait laissé passer un fichier inutilisable (C-48 `sysctl`,
C-50 artefact vide, C-51 disque inamorçable). **Un disque sans amorçage ne sort plus d'ici sans
que quelqu'un le dise.**

---

## 6. Ce que cela coûte, et ce que cela n'enlève pas

**Ce que cela coûte :** une nouvelle construction complète (buildworld + buildkernel, plusieurs
heures) avant d'avoir un disque amorçable.

**Ce que cela n'enlève rien :**
- les **1,82 Go d'artefact** et le **`.ufs` de 2,3 Go** contiennent le **système complet** ;
- le **noyau `NEXBSD_L1`** est dedans ;
- les **neuf pièces de configuration** sont dedans ;
- la **chaîne de publication** fonctionne (PUBLIER #2 : 8/8 vertes).

**Ce qui reste inconnu, et que je ne peux pas prouver sans monter le système de fichiers :**
la racine contient-elle réellement `/boot/kernel/kernel` et `/boot/loader` ? Le script le
vérifie **avant** `mkimg` (branche `boot/kernel/kernel`, ligne 238 de `scripts/74`), et la
construction est allée jusqu'au bout : **c'est très probable, mais non mesuré ici.**

---

## 7. La leçon, une de plus, et elle est chère

Le 29/10 au soir, j'ai écrit : *« l'artefact ne contient pas l'image »* — **c'était faux**,
mon `glob` ne descendait pas dans `images/`.
Le 30/10 au matin, le téléchargement **prouve** que l'image existe, est complète et authentique.

**Et elle ne démarre pas.** Le projet a donc passé une semaine à rendre téléchargeable un fichier
qui, une fois téléchargé, n'aurait rien affiché.

> **On ne prouve pas une image en la publiant. On la prouve en la démarrant.**
> Le rond vert de la CI ne dit pas « NexBSD fonctionne » : il dit « la chaîne n'a pas planté ».

C'est la raison pour laquelle l'étape 1 de `docs/67` — **DÉMARRER** — reste **le seul vrai
inconnu du projet**, et pourquoi tout le reste (ports, intégrité, CVE, bureau) attend derrière.

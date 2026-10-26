# T-17 — Le banc démarre sur un noyau construit par le projet — **À EXÉCUTER**

**Protocole :** `scripts/67` (préparer) → `scripts/68` (construire) → `scripts/69` (installer) → redémarrage.
**Prérequis :** T-04-G réussi (11/11), T-16 étage 1 appliqué, disque de construction de 30 Go ajouté à la VM,
RAM de la VM portée à 2 048 Mo. Décision **ADR-0020** (dérogation bornée à l'ADR-0010).
**Banc :** VM `nexbsd-test`, socle FreeBSD 15.1-**RELEASE** (donc les sources de *cette* version, pas d'une autre).
**Campagne :** `docs/28-campagne-construction-noyau.md`.

## 1. Ce que ce test prouve — et ce qu'il ne prouve pas

| Démontré si réussi | Toujours NON démontré après réussite |
|---|---|
| le noyau en service est **compilé par le projet**, depuis la configuration du projet (empreinte vérifiée) | que NexBSD soit un système écrit de zéro (c'est un **fork**, comme pfSense ou TrueNAS) |
| `uname -i` répond **`NEXBSD_L1`** : première sortie système qui n'est pas celle de FreeBSD | que le noyau soit profondément différent : **5 lignes de delta** sur 393 |
| `uname -r` répond **`15.1-NEXBSD-L1`** (levier amont `BRANCH_OVERRIDE`, aucun patch) | que `uname -s` dise `NexBSD` (patch 0001 **non appliqué**) |
| le banc complet (annuaire, droits, partages) **fonctionne sur ce noyau** (rejeu de `scripts/64`, 11/11) | qu'une **image installable** existe (étage 3, non faisable sur ce poste) |

## 2. Provenance épinglée (à réutiliser verbatim dans le compte rendu)

```
URL     : https://download.freebsd.org/releases/amd64/amd64/15.1-RELEASE/src.txz
taille  : 253 039 000 octets
SHA256  : cf5762da53fd52e1eaf0f9ceee9bf58cbe314c821031d0d9ffa76823185a89e1
branche : releng/15.1     revision : 96841ea08dcf     construite le : 20260612
config  : NEXBSD_L1, sha256 14c86800fa6ae198d0625fdca885966fe9bd90c9f28853ae67991ab2129eb301
GENERIC : sha256 02491b53b793cc5e1a3d622675d1aaf32d5da1973832cb13ff6d85d541d84878
```

## 3. Procédure exacte

```
# dans la VM (root), apres avoir ajoute le disque de 30 Go et porte la RAM a 2048 Mo
sh /tmp/67-preparer-construction-noyau.sh          # attendu : ETAT : PRET A CONSTRUIRE
sh /tmp/68-construire-noyau-nexbsd.sh --lancer     # 2 a 6 h
sh /tmp/68-construire-noyau-nexbsd.sh --etat       # suivi
sh /tmp/68-construire-noyau-nexbsd.sh --verifier   # attendu : ETAT : NOYAU CONSTRUIT
sh /tmp/69-installer-noyau-nexbsd.sh               # attendu : ETAT : NOYAU INSTALLE
reboot
```

## 4. Vérifications après redémarrage (les cinq critères de `docs/28` §6)

```
uname -a
uname -s ; uname -r ; uname -i
sysctl -n kern.ident ; sysctl -n kern.osrelease ; sysctl -n kern.version
sysctl -n kern.bootfile
dmesg | head -20
sh /tmp/64-banc-T04G-persistance.sh          # doit rejouer 11/11
```

## 5. Journal d'exécution

### Essai 1 — en cours (2026-10-25, S-018)

#### Étape 0 — préparation de la VM (hôte 🖥️ MINT), **exécutée**

Commandes (libvirt en session) : `shutdown`, `setmaxmem 2048M --config`, `setmem 2048M --config`,
`qemu-img create -f qcow2 ~/nexbsd-vm/build-noyau.qcow2 30G`, `attach-disk --target vdb --persistent`,
`start`. Sortie **verbatim** :

```
Domain 'nexbsd-test' is being shutdown
domaine arrete (id) : -
Formatting '/home/omrane/nexbsd-vm/build-noyau.qcow2', fmt=qcow2 cluster_size=65536 extended_l2=off
  compression_type=zlib size=32212254720 lazy_refcounts=off refcount_bits=16
Disk attached successfully
Domain 'nexbsd-test' started
 Target   Source
----------------------------------------------------
 vda      /home/omrane/nexbsd-vm/disque-test.qcow2
 vdb      /home/omrane/nexbsd-vm/build-noyau.qcow2
Max memory:     2097152 KiB
Used memory:    2097152 KiB
```

Lecture : arrêt **propre** (id `-`), disque de construction **32 212 254 720 o = 30 Gio** (qcow2 creux),
disque attaché **de façon persistante**, RAM **2 097 152 Kio = 2 048 Mo**. Étape 0 : **RÉUSSIE**.

#### Étape 1 — `scripts/67` dans la VM : **RÉUSSIE** (2026-10-25 20:43→20:5x UTC)

Commande réellement exécutée : `sh /tmp/67-preparer-construction-noyau.sh vtbd1`
(disque **nommé explicitement** : la détection automatique du dépôt n'avait pas encore été éprouvée ici.)

Sortie **verbatim**, extraits décisifs :

```
RAM totale      : 2009 Mo
processeurs     : 2 fils (le poste a 2 coeurs physiques)
[OK]    RAM suffisante pour un noyau (>= 1800 Mo) — derogation ADR-0020
[ATTN]  RAM < 4000 Mo : le monde complet (buildworld) reste INTERDIT sur ce poste (ADR-0010).
disque systeme : /dev/gpt/rootfs (il ne sera JAMAIS touche)
disque fourni  : vtbd1 (choix explicite de l'operateur)
[OK]    disque de construction distinct du disque systeme
taille de vtbd1 : 30 Go
vtbd1 created / vtbd1p1 added / systeme de fichiers UFS cree / /build monte depuis /dev/gpt/build
entree fstab ajoutee (le montage survit au redemarrage)
espace libre sur /build : 27359 Mo
[OK]    2 Go d'echange actifs sur /dev/md0
telechargement de src.txz (253 Mo) depuis download.freebsd.org ...
taille telechargee : 253039000 octets (attendu 253039000)
[OK]    empreinte SHA256 conforme : cf5762da53fd52e1eaf0f9ceee9bf58cbe314c821031d0d9ffa76823185a89e1
[OK]    arbre extrait
REVISION : REVISION="15.1"
[OK]    /usr/src -> /build/src
GENERIC de l'arbre : 02491b53b793cc5e1a3d622675d1aaf32d5da1973832cb13ff6d85d541d84878
[OK]    GENERIC identique a la reference du depot (reference/GENERIC-15.1)
NEXBSD_L1 genere    : 14c86800fa6ae198d0625fdca885966fe9bd90c9f28853ae67991ab2129eb301
[OK]    IDENTIQUE au fichier du depot (fork/sys/amd64/conf/NEXBSD_L1)
[OK]    ident = NEXBSD_L1
arbre source   : /build/src (1.7G)
ETAT : PRET A CONSTRUIRE
```

**Les deux preuves décisives** (aucune ne vient d'une affirmation, toutes deux d'une empreinte calculée) :

1. `GENERIC de l'arbre : 02491b53…d84878` **= référence du dépôt** → l'arbre extrait est bien celui de la
   version installée, et la référence du dépôt est fiable.
2. `NEXBSD_L1 genere : 14c86800…eb301` **= fichier du dépôt** → la configuration qui va être compilée est
   **prouvablement** celle de `fork/`, à l'octet près.

**Observations consignées :**
- La VM annonce **2 fils** (et non 4 comme l'hôte) : `-j2` reste le bon réglage.
- Ligne cosmétique `echange total : 6 Mo` : calcul d'affichage fautif (unités `1.0G`/`2.0G` additionnées),
  **corrigé depuis** dans le dépôt. N'affecte aucune opération : l'échange réel est bien de 2 Go + 1 Go.
- 27 359 Mo libres sur `/build` pour 12 000 exigés : marge confortable pour les objets.

#### Étape 2 — `scripts/68 --lancer` : **LANCÉE** (2026-10-25 20:53:43 UTC, pid 1676)

Sortie **verbatim** :

```
RAM 2009 Mo · echange 6 Mo · 2 fils · 25344 Mo libres dans /build/obj
[OK]    parallelisme retenu : -j2 (plafonne par la RAM, pas par la bonne volonte)
configuration : /build/src/sys/amd64/conf/NEXBSD_L1
empreinte     : 14c86800fa6ae198d0625fdca885966fe9bd90c9f28853ae67991ab2129eb301
delta vs GENERIC : 10 lignes
ident         : ident         NEXBSD_L1
commande exacte :
| cd /build/src && env MAKEOBJDIRPREFIX=/build/obj KERNCONF=NEXBSD_L1 BRANCH_OVERRIDE=NEXBSD-L1 make -j2 buildkernel
[OK]    construction lancee (pid 1676)
journal : /build/logs/buildkernel-20261025T205343Z.log
ETAT : CONSTRUCTION LANCEE (2 a 6 h). Rien ne se conclut avant la fin.
```

Notes : `delta vs GENERIC : 10 lignes` = 5 lignes retirées + 5 lignes de commentaire/ident ajoutées — cohérent
avec `NEXBSD_L1.rapport`. `echange 6 Mo` reste le défaut d'affichage cosmétique (corrigé dans le dépôt).
L'empreinte de la configuration compilée est bien `14c86800…eb301`, celle du dépôt.

#### Étape 2 — RÉSULTAT : **CONSTRUCTION RÉUSSIE** (2026-10-26, 18:55:40 UTC)

**Preuve verbatim (fin du journal `buildkernel-20261026-reprise.log`) :**

```
>>> Kernel(s)  NEXBSD_L1 built in 1470 seconds, ncpu: 2, make -j2
--------------------------------------------------------------
### code de retour : 0
```

**Chronologie complète de la construction (deux sessions, arrêt propre entre les deux) :**

| Phase | Période | Journal | Objets |
|---|---|---|---|
| 1re tentative | 2026-10-25 20:53 → 22:34 | `buildkernel-20261025T205343Z.log`, **45 253 lignes** | 4,0 Go |
| arrêt propre volontaire | 2026-10-25 ~22:50 | seuil de 45 000 lignes atteint (règle `docs/30` §1 bis) | conservés |
| reprise | 2026-10-26 18:30 → 18:55 | `buildkernel-20261026-reprise.log` | 4,6 Go |
| **fin** | **18:55:40** | `Kernel(s) NEXBSD_L1 built in 1470 seconds` · `code de retour : 0` | **4,6 Go** |

**Ce que cela prouve, exactement :** le projet sait **compiler son propre noyau**, à partir des sources de
FreeBSD 15.1-RELEASE **vérifiées par empreinte**, avec **sa configuration** `NEXBSD_L1` (empreinte
`14c86800…eb301`, identique au dépôt), sous **son** nom de version (`BRANCH_OVERRIDE=NEXBSD-L1`), sur un
portable de 2011 avec 2 Go alloués et sans jamais échanger.

**Ce que cela ne prouve pas encore :** que le noyau **démarre** et que le banc fonctionne dessus. Ce sont les
étapes 3 à 5 (installation, redémarrage, rejeu de `scripts/64`).

**Note d'honnêteté sur le journal de reprise :** le redirection de la commande de reprise a été altérée au
transport (guillemets perdus) ; le journal de reprise ne contient donc que la fin. Le **résultat final est
sans ambiguïté** (`code de retour : 0`), et le journal de la première phase (45 253 lignes) reste complet dans
`buildkernel-20261025T205343Z.log`. Leçon : une commande qui écrit dans un journal doit être revérifiée après
collage — elle a déjà été simplifiée pour la suite.

##### Suivi de la construction (mesures réelles, journal `buildkernel-20261025T205343Z.log`)

| Heure UTC | Lignes | Delta lignes | Debit (lignes/min) | Espace `/build` |
|---|---|---|---|---|
| 20:53:43 | 0 (depart) | - | - | 2,2 Go |
| 20:57:12 | 3 674 | - | - | - |
| 21:01:43 | 5 713 | 2 039 | ~650 | 2,2 Go |
| 21:04:31 | 7 091 | 1 378 | ~658 | 2,2 Go |
| 21:07:31 | 8 571 | 1 480 | ~493 | 2,3 Go |
| 21:10:32 | 9 880 | 1 309 | ~436 | 2,3 Go |
| 21:13:32 | 12 745 | 2 865 | **~955** | 2,4 Go |
| 21:16:32 | 14 905 | 2 160 | ~720 | 2,4 Go |
| 21:19:32 | 16 590 | 1 685 | ~562 | 2,5 Go |
| 21:22:32 | 17 693 | 1 103 | ~368 | 2,6 Go |
| 21:25:33 | 19 061 | 1 368 | ~456 | 2,7 Go |
| 21:28:33 | 19 609 | 548 | ~183 | 2,7 Go |

| 21:31:33 | 20 687 | 1 078 | ~359 | 2,8 Go |
| 21:34:33 | 21 557 | 870 | ~290 | 2,8 Go |
| 21:37:33 | 23 101 | 1 544 | ~515 | 2,9 Go |
| 21:40:33 | 23 693 | 592 | ~197 | 3,0 Go |
| 21:43:33 | 24 897 | 1 204 | ~401 | 3,0 Go |
| 21:46:33 | 27 228 | 2 331 | ~777 | 3,1 Go |
| 21:49:33 | 28 949 | 1 721 | ~574 | 3,2 Go |
| 21:52:34 | 30 055 | 1 106 | ~369 | 3,3 Go |
| 21:55:34 | 30 879 | 824 | ~275 | 3,3 Go |
| 21:58:34 | 31 435 | 556 | ~185 | 3,4 Go |
| 22:01:34 | 32 181 | 746 | ~249 | 3,5 Go |
| 22:04:34 | 32 723 | 542 | ~181 | 3,5 Go |
| 22:07:36 | 33 572 | 849 | ~283 | 3,6 Go |
| 22:10:41 | 34 568 | 996 | ~325 | 3,7 Go |

**Volume atteint : 34 568 lignes, 3,7 Go d'objets.** Un `buildkernel` complet sur cette configuration produit
typiquement de l'ordre de 35 000 à 45 000 lignes : la construction est **proche de son terme** au moment de
l'arrêt. La question posée par le responsable — « est-ce que je perds les 14 % utilisés ? » — a une réponse
factuelle : **non**, ces 3,7 Go sont des **fichiers écrits sur le disque** (`/build/obj`) ; un arrêt propre
les conserve tous et `make` reprend au fichier suivant. Seul le fichier **en cours de compilation** à
l'instant de l'arrêt (quelques secondes de travail) est perdu.

| 22:13:41 | 36 842 | 2 274 | ~758 | 3,8 Go |
| 22:16:41 | 37 914 | 1 072 | ~357 | 3,8 Go |
| 22:19:41 | 40 427 | 2 513 | ~838 | 3,9 Go |
| 22:22:41 | 42 850 | 2 423 | ~808 | 3,9 Go |
| 22:25:41 | 43 809 | 959 | ~320 | 4,0 Go |
| 22:28:41 | 44 314 | 505 | ~168 | 4,0 Go |
| 22:31:42 | 44 781 | 467 | ~156 | 4,0 Go |
| **22:34:42** | **45 253** | 472 | ~157 | **4,0 Go** |

**Seuil de 45 000 lignes atteint à 22:34:42**, conformément à la règle d'arrêt fixée par le responsable
(`docs/30` §1 bis) : **arrêt propre décidé**, reprise le lendemain. Dernier relevé : **45 253 lignes**,
**4,0 Go d'objets** sur `/build`, 23 Go libres, échange toujours négligeable.

**Construction interrompue volontairement le 2026-10-25 vers 22:50 (heure locale)**, à la demande du
responsable (fin de soirée). Arrêt **propre** de la VM (`virsh shutdown`), donc systèmes de fichiers
synchronisés : les **3,1 Go d'objets déjà compilés sont conservés** et `make` **reprendra** au fichier
suivant, sans rien recommencer. Aucune perte de travail : c'est la propriété d'un `build` incrémental.

**Fin de la phase rapide** : le débit tombe de ~950 à ~183 lignes/min entre 21:13 et 21:28. Signature classique
du passage aux tâches lourdes et silencieuses (`ctfmerge`, édition de liens, gros modules). Aucun signe
d'erreur, échange toujours négligeable.

**Lecture :** debit moyen ~650 lignes/min, avec une **acceleration** nette sur le dernier intervalle (phase des
modules, composes de petits fichiers). Echange utilise : **56 K sur 3 Go** - la machine n'echange pas, donc
`-j2` etait le bon reglage. Espace consomme : 2,4 Go (prevision 4-8 Go : on sera en dessous).
**Estimation initiale "2 a 6 h" : trop prudente, les faits la dementent** - la construction s'annonce en
**moins d'une heure** au total.


| Étape | Résultat | Verdict |
|---|---|---|
| 67 préparer | — | — |
| 68 construire | — | — |
| 69 installer | — | — |
| redémarrage | — | — |
| `uname -i` = `NEXBSD_L1` | — | — |
| `uname -r` = `15.1-NEXBSD-L1` | — | — |
| banc 11/11 sur le noyau NexBSD | — | — |

## 6. Verdict

**NON EXÉCUTÉ** — protocole écrit le 2026-10-25, scripts `67`/`68`/`69` vérifiés syntaxiquement,
régénération de `NEXBSD_L1` vérifiée **bit à bit** contre le fichier du dépôt.

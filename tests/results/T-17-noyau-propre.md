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

#### Étape 1 — `scripts/67` dans la VM

_(à remplir : sortie verbatim, y compris en cas d'échec)_

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

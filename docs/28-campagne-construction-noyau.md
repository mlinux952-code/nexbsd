# Campagne de construction — étage 2 : le premier noyau NexBSD

**Version :** 1.0 — 2026-10-25 (session S-018)
**Rôle :** transformer le delta `fork/` (écrit, jamais compilé) en **un noyau réellement construit,
installé et démarré** sur le banc. C'est l'étage 2 de `docs/27`.
**Règle de cette campagne :** une commande à la fois, sortie réelle collée, résultat consigné **verbatim**
dans `tests/results/T-17-noyau-propre.md`. Aucun résultat inventé, aucun « ça devrait marcher ».

---

## 1. Pourquoi cette campagne, et pourquoi elle ne détourne pas l'objectif

Le responsable l'a dit sans détour : *« je veux un système à part entière, pas un FreeBSD modifié »*.
À la date de cette campagne, **100 % de ce qui tourne sur le banc est du FreeBSD d'origine**
(`uname -sr` → `FreeBSD 15.1-RELEASE`) plus des paquets ajoutés à la main. L'étage 1 (nom d'hôte, motd,
invite) a donné un **nom** ; il n'a rien donné au système.

L'étage 2 est le premier acte matériellement vérifiable de possession :
**le noyau qui démarre est compilé par le projet, à partir de la configuration du projet, dans l'arbre du projet.**

Ce que l'on ne fera pas : prétendre que c'est « un nouveau système d'exploitation » (voir §8, points sur les I).

---

## 2. Ressources réellement disponibles (mesuré le 2026-10-25, verbatim)

| Ressource | Valeur mesurée sur 🖥️ MINT | Exigence noyau | Verdict |
|---|---|---|---|
| RAM totale | **3,7 Go** (787 Mo disponibles, 2,9 Go utilisés) | ≥ 2 Go pour la VM | **juste** — VM plafonnée à 2 048 Mo |
| Échange | 3,9 Go (775 Mo déjà utilisés) | — | marge de sécurité, pas un plan |
| Cœurs | 4 fils (i3-3110M, **2 cœurs physiques**) | — | parallélisme plafonné à `-j2` |
| Disque libre `/` | **67 Go** (117 Go, 44 Go utilisés, 40 %) | 30 Go pour le noyau | **suffisant** |

**Conséquences honnêtes :**

| Opération | Faisable sur ce poste ? | Pourquoi |
|---|---|---|
| `buildkernel NEXBSD_L1` | **OUI** (dérogation ADR-0020) | 2 Go / 6 Go / 2–6 h |
| `buildworld` + `release.sh` (image PC) | **NON, pas dans de bonnes conditions** | 4 à 8 Go de RAM exigés, 4 Go disponibles ; il faudrait 20–40 h de swap : c'est un pari, pas une procédure |

L'étage 3 (l'image installable pour le PC de 2011) passera donc par la **voie B** de `docs/27`
(intégration continue avec VM FreeBSD, 4 cœurs / 16 Go) ou par une machine prêtée. Le disque, lui, suffit
(67 Go > 30 Go) : c'est la **RAM** qui bloque, pas l'espace.

---

## 2 bis. La VM réelle du banc — identifiée le 2026-10-25 (ne plus deviner)

| Élément | Valeur constatée |
|---|---|
| Hyperviseur | **KVM** (`/dev/kvm` présent), piloté par **libvirt en session utilisateur** |
| Connexion | `qemu:///session` (**pas** `qemu:///system`, qui est vide) |
| Domaine | **`nexbsd-test`**, état `running` |
| Disque système | `~/nexbsd-vm/disque-test.qcow2` (1,3 Go, image sur copie-à-l'écriture) |
| Image de base | `~/nexbsd-vm/FreeBSD-15.1-RELEASE-amd64-ufs.qcow2` (2,5 Go, **jamais modifiée**) |
| Bus des disques | **virtio-blk** → dans FreeBSD les disques s'appellent **`vtbd0`, `vtbd1`** — *pas* `ada0`/`ada1` |
| RAM actuelle | 1 536 Mo → **à porter à 2 048 Mo** |
| Disque de construction | **absent** → à ajouter : 30 Go, qcow2, `vdb` |

**Le piège évité :** avec virtio, `scripts/67` ne trouvera pas `ada1` mais `vtbd1`. Le script a été
durci en conséquence : il **ignore** `cd*`/`md*`/`fd*` (un lecteur optique ne doit jamais être pris pour un
disque de construction) et il **refuse** d'utiliser le disque qui porte la racine montée.

**Commandes de la VM (hôte, une seule fois) :**

```sh
V="virsh --connect qemu:///session"
$V destroy nexbsd-test                                  # extinction forcée si ACPI ne répond pas
$V setmaxmem nexbsd-test 2048M --config                 # plafond
$V setmem    nexbsd-test 2048M --config                 # valeur de travail
qemu-img create -f qcow2 ~/nexbsd-vm/build-noyau.qcow2 30G
$V attach-disk nexbsd-test --source ~/nexbsd-vm/build-noyau.qcow2 \
   --target vdb --persistent --subdriver qcow2
$V start nexbsd-test
$V domblklist nexbsd-test ; $V dominfo nexbsd-test | grep -i memory
```

**Vérification dans la VM :** `geom disk list` doit montrer **deux** disques et `diskinfo -v vtbd1`
doit annoncer ≈ 30 Go. C'est la preuve que le disque séparé existe (ADR-0020, point 5).

**Fait le 2026-10-25 (verbatim)** : `Disk attached successfully` · `vda` = `disque-test.qcow2`,
`vdb` = `build-noyau.qcow2` · `Max memory: 2097152 KiB` · `Used memory: 2097152 KiB` ·
`formatting … size=32212254720` (30 Gio, creux). La VM a été **arrêtée proprement** avant modification
(`domaine arrete (id) : -`) : aucune modification à chaud, aucun risque pour le banc validé.

---

## 3. Décision appliquée

**ADR-0020** (nouveau) : dérogation **unique et bornée** à l'ADR-0010 pour ce seul noyau, sous garde-fous
mesurés, avec disque séparé et journal conservé. La dérogation expire à la fin de la construction.

---

## 4. Provenance épinglée (aucune improvisation)

Le socle du banc est `FreeBSD 15.1-RELEASE`. On construit donc le noyau **exactement depuis les sources de
cette version**, ce qui évite tout décalage noyau/monde :

| Élément | Valeur épinglée le 2026-10-25 |
|---|---|
| URL | `https://download.freebsd.org/releases/amd64/amd64/15.1-RELEASE/src.txz` |
| Taille | **253 039 000** octets |
| SHA256 | `cf5762da53fd52e1eaf0f9ceee9bf58cbe314c821031d0d9ffa76823185a89e1` |
| Branche du dépôt FreeBSD | `releng/15.1` |
| Révision | `96841ea08dcf` |
| Date de construction | `20260612` |

**Choix expliqué :** on n'utilise **pas** `git clone` (1,5 Go, et `git` à installer). L'archive `src.txz`
(253 Mo) contient **l'arbre source complet de la version installée** — c'est plus léger, plus rapide, et
surtout **de provenance unique et vérifiable par empreinte**.

**Delta NexBSD compilé — empreintes de référence (dépôt) :**

| Fichier | SHA256 dans le dépôt |
|---|---|
| `fork/sys/amd64/conf/NEXBSD_L1` | `14c86800fa6ae198d0625fdca885966fe9bd90c9f28853ae67991ab2129eb301` |
| `fork/reference/GENERIC-15.1` | `02491b53b793cc5e1a3d622675d1aaf32d5da1973832cb13ff6d85d541d84878` |
| `fork/src.conf` | `be95d02df3414d1ca251342f3a82c685808141666fe28d92333cd83fd092ecd2` |
| `fork/release.conf` | `a6bd82ce2310c802301014408a18caa89fe97acf2ecfe880960f946d3ee877e9` |

**Le delta réel de `NEXBSD_L1` est exactement de 5 lignes** par rapport à `GENERIC` 15.1 :
`ident → NEXBSD_L1`, et 4 périphériques retirés (`fdc`, `cbb`, `cardbus`, `hyperv`), chacun justifié dans
`NEXBSD_L1.rapport`. Le script `67` **régénère** ce fichier dans la VM à partir du `GENERIC` de l'arbre
extrait, puis **vérifie l'empreinte** : la configuration compilée est donc prouvablement celle du dépôt.

---

## 4 bis. Mesures réelles du banc après agrandissement (2026-10-25, verbatim)

```
FreeBSD 15.1-RELEASE        nexbsd
=== RAM ===                 2009 Mo          (2 048 Mo annoncés par l'hyperviseur)
swapinfo                    /dev/gpt/swapfs 1.0G  0B utilisé
=== DISQUES ===             vtbd0  6.0G       vtbd1  32212254720 o = 30G
=== LIBRE ===               /dev/gpt/rootfs 4.8G  3.4G utilisés  1.1G disponibles (76 %)
```

**Trois conséquences tirées de ces chiffres, pas d'une supposition :**

1. **La racine est petite : 1,1 Go libres.** `installkernel` écrit le noyau **et ses modules**, deux fois
   (`/boot/kernel.NEXBSD_L1` et `/boot/kernel`). Avec les symboles de débogage du `GENERIC`, cela dépasse
   **1,3 Go** : l'installation échouerait **après plusieurs heures de compilation**. Le script `69` installe
   donc avec **`MK_KERNEL_SYMBOLS=no`** (~350-400 Mo) ; le noyau garde tous ses symboles dans `/build/obj`.
2. **Tout le reste va sur `vtbd1`** (sources, objets, journal, échange) : la racine ne sert que pour `/boot`.
   C'est exactement le découpage exigé par ADR-0020.
3. **`ping` échoue alors que le réseau fonctionne** : la VM utilise le réseau utilisateur de QEMU (slirp),
   qui **ne transporte pas ICMP**. Un `ping` négatif ne prouve donc **rien** sur la connectivité ; seule une
   requête HTTP le prouve (`fetch`). Leçon consignée : ne jamais conclure « pas d'Internet » sur un `ping`.

---

## 5. Les étapes, dans l'ordre (une commande à la fois)

| # | Où | Ce que l'on fait | Script / commande | Sortie attendue |
|---|---|---|---|---|
| 0 | 🖥️ MINT | identifier l'hyperviseur et la VM du banc | `virsh`/`VBoxManage list` | nom exact de la VM, chemin du disque |
| 1 | 🖥️ MINT | **arrêter** la VM proprement | `virsh shutdown` ou `VBoxManage controlvm … acpipowerbutton` | VM éteinte |
| 2 | 🖥️ MINT | **RAM 1 024 → 2 048 Mo** et **ajout d'un disque de 30 Go** | `virsh setmaxmem/setmem` + `attach-disk`, ou `VBoxManage modifyvm/modifystorageattach` | VM redémarrée avec le disque visible |
| 3 | 🐧 VM | voir le nouveau disque | `geom disk list` | un disque supplémentaire (`ada1`) |
| 4 | 🐧 VM | préparer disque, échange, sources, delta | `sh 67-preparer-construction-noyau.sh` | `ETAT : PRET A CONSTRUIRE` |
| 5 | 🐧 VM | **construire** le noyau (2–6 h, journal) | `sh 68-construire-noyau-nexbsd.sh --lancer` | `BUILDKERNEL : TERMINE` |
| 6 | 🐧 VM | installer sans écraser le noyau de secours | `sh 69-installer-noyau-nexbsd.sh` | `/boot/kernel.NEXBSD_L1` présent |
| 7 | 🐧 VM | redémarrer sur le noyau NexBSD | `reboot` | au démarrage : `NexBSD 15.1-NEXBSD-L1` |
| 8 | 🐧 VM | **prouver** (T-17) | `uname -a`, `sysctl kern.ident`, `sh 64-banc-T04G-persistance.sh` | `uname -i` = `NEXBSD_L1`, banc **11/11** |

---

## 6. Critères de réussite de l'étage 2 (verdict T-17)

Réussite **seulement si les cinq** sont vrais, verbatim collés :

1. `uname -i` → `NEXBSD_L1`
2. `uname -r` → `15.1-NEXBSD-L1`
3. `uname -s` → `FreeBSD` *(voir §8 : le nom du noyau reste `FreeBSD` tant que le patch 0001 n'est pas appliqué)*
4. le banc **démarre** sur ce noyau et rend l'invite `root@nexbsd`
5. `scripts/64` rejoue **11/11** : annuaire, droits et partages intacts sur **notre** noyau

Échec (consigné verbatim, sans maquillage) si : panique au démarrage, `uname -i` ≠ `NEXBSD_L1`,
OOM pendant la construction, ou banc dégradé après redémarrage.

---

## 7. Reprise et sécurité

- **Reprise** : `make` reprend une construction interrompue ; relancer le script `68` suffit.
- **Retour arrière** : le script `69` copie `/boot/kernel` en `/boot/kernel.GENERIC-sauvegarde` **avant**
  toute installation ; en cas de noyau NexBSD non amorçable, dans le menu du chargeur :
  `set kernel="kernel.GENERIC-sauvegarde"` puis `boot`.
- **Disque séparé** : la construction vit sur un disque de 30 Go ; le disque système du banc validé n'est
  pas modifié.
- **Ce qui reste interdit** : construire le monde ou une image sur ce poste (ADR-0010 non révisé sur ce point).

---

## 8. Points sur les I (ce que l'étage 2 prouve, et ce qu'il ne prouve pas)

**Ce qu'il prouve :** le projet sait posséder, compiler et faire tourner **son** noyau ; il n'est plus
seulement un assembleur de paquets. `uname -i` répond `NEXBSD_L1` : c'est la première sortie système qui
n'est pas celle de FreeBSD.

**Ce qu'il ne prouve pas, et qu'il ne faut jamais laisser croire :**

| Affirmation tentante | Vérité |
|---|---|
| « NexBSD est un système d'exploitation indépendant » | **Non.** NexBSD est un **fork** de FreeBSD, comme pfSense, TrueNAS, OPNsense ou HardenedBSD : même code source, noyau et image propres. |
| « notre noyau est différent de celui de FreeBSD » | **Presque pas.** 5 lignes de différence sur 393 : le nom et 4 périphériques retirés. C'est une preuve de **capacité**, pas de **divergence**. |
| « NexBSD s'installe sur un PC » | **Pas encore.** Aucune image n'existe à la fin de l'étage 2. Le PC de 2011 reste intact et n'est pas installé. |
| « `uname -s` dit NexBSD » | **Non** : il dit `FreeBSD` tant que le correctif `0001-identite-version.patch` n'est pas appliqué — correctif **non appliqué**, risque documenté. |
| « le userland est à nous » | **Non** : c'est le monde de FreeBSD 15.1-RELEASE. `src.conf` n'a jamais été utilisé ; il le sera à l'étage 3. |

**Et un point d'honnêteté sur le mot « vrai système » :** un système d'exploitation écrit de zéro
demande des décennies et des milliers de développeurs (Linux : 30 ans). Ce que l'industrie appelle
« un système à part entière » et ce que nous visons, c'est : **son nom, son noyau, son userland, son image
d'installation, son cycle de vie, sa documentation** — et la capacité de tout reconstruire. C'est exactement
la différence entre « FreeBSD modifié à la main » et « NexBSD ». Nous sommes en train de la franchir, acte
par acte. Rien de plus, rien de moins, et rien de caché.

---

## 9. Journal des essais

| Essai | Date | Résultat | Verdict | Preuve |
|---|---|---|---|---|
| 1 | 2026-10-25 | Étape 0 (VM agrandie) et **étape 1 (`67`) réussies** : sources vérifiées par SHA256, `NEXBSD_L1` **identique au dépôt** ; construction lancée ensuite | EN COURS | `tests/results/T-17-noyau-propre.md` |

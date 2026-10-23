# Le banc d'essai sur votre Linux Mint — mode d'emploi

**Version :** 1.0 — 2026-10-23 (session S-011)
**Décision :** le banc de test cesse d'être mon bac à sable et devient **votre machine**. Les VM y persistent, vous voyez l'écran, et les résultats restent chez vous.

---

## 0. Verdict pour VOTRE machine (relevé du 2026-10-23)

| | Résultat mesuré |
|---|---|
| Processeur | Intel i3-3110M, 4 threads |
| RAM | 3,7 Gio |
| KVM | **disponible** ✅ |
| Espace libre sur le SSD | **68 Go** ✅ |
| **Héberger les VM de test** | ✅ **OUI** — avec 1536 Mo de RAM alloués à la VM |
| **Construire une image NexBSD** | ❌ **NON** — 8 Go de RAM exigés, la RAM bloque, pas le disque |

## 1. Ce que votre machine peut faire — et ce qu'elle ne pourra pas

Il y a deux questions différentes, souvent confondues :

| Question | Ce qu'il faut | Ce que ça donne |
|---|---|---|
| **A. Faire tourner des VM de test** (FreeBSD, Samba, LDAP, banc NetWare) | ≥ 3,5 Go de RAM, ≥ 20 Go libres | les tests T-01 → T-15 deviennent possibles |
| **B. Construire une image NexBSD** (`buildworld`) | **≥ 8 Go de RAM, ≥ 40 Go libres, plusieurs heures** | NexBSD lui-même |

**Une VM de test ne construit pas NexBSD.** Elle permet de vérifier que les briques fonctionnent et de préparer le terrain. Le jour où la construction sera possible, on réutilisera exactement la même arborescence.

Le script `scripts/00-diagnostic-hote.sh` calcule ces deux verdicts à partir de vos chiffres réels — il ne devine pas.

## 2. Étape 1 — le relevé (lecture seule, 10 secondes)

```bash
cd ~/Projets/nexbsd
bash scripts/00-diagnostic-hote.sh
```

Puis copiez-moi la sortie, en particulier le bloc « Verdict ».

**Aucune commande de ce script ne modifie quoi que ce soit** : pas d'installation, pas d'écriture, pas de partitionnement. Il lit `/proc`, `lsblk`, `df`, `free`.

## 3. Étape 2 — préparer la VM (si le verdict A est favorable)

```bash
sudo apt update
sudo apt install -y qemu-system-x86 qemu-utils
```

Puis télécharger l'image FreeBSD (664 Mo) :

```bash
mkdir -p ~/nexbsd-vm && cd ~/nexbsd-vm
wget https://download.freebsd.org/releases/VM-IMAGES/15.1-RELEASE/amd64/Latest/FreeBSD-15.1-RELEASE-amd64-ufs.qcow2.xz
wget https://download.freebsd.org/releases/VM-IMAGES/15.1-RELEASE/amd64/Latest/CHECKSUM.SHA256
sha256sum FreeBSD-15.1-RELEASE-amd64-ufs.qcow2.xz
grep ufs.qcow2.xz CHECKSUM.SHA256
```

**Les deux empreintes doivent être identiques.** Attendu :
`25ad16e9d0c037f40a43c6f3c474b5c1ba62eaf9204dbd7f034fdbffe2c3dae5`

```bash
xz -d FreeBSD-15.1-RELEASE-amd64-ufs.qcow2.xz
```

## 4. Étape 3 — démarrer (recette déjà testée le 2026-10-23)

```bash
cd ~/nexbsd-vm
qemu-img create -f qcow2 -b FreeBSD-15.1-RELEASE-amd64-ufs.qcow2 -F qcow2 disque-test.qcow2
sh ~/Projets/nexbsd/scripts/31-lancer-vm-freebsd.sh ~/nexbsd-vm
```

**Le disque de travail est une copie sur écriture** : l'image d'origine n'est jamais modifiée. C'est le même principe que la règle « support externe uniquement » du PC de 2011.

Au menu du chargeur, **appuyez sur `5` puis `Entrée`** : la console passe sur le port série et vous pouvez piloter la VM depuis le terminal. Sans cela, la VM écrit sur un écran vidéo que QEMU n'affiche pas (`-display none`).


## 4 bis. Sans le script — la commande QEMU brute (dépannage)

Si `31-lancer-vm-freebsd.sh` n'est pas encore dans votre dépôt, la VM se lance sans lui.
Deux commandes, équivalentes à ce que fait le script :

```bash
cd ~/nexbsd-vm
qemu-img create -f qcow2 -b FreeBSD-15.1-RELEASE-amd64-ufs.qcow2 -F qcow2 disque-test.qcow2
```

```bash
qemu-system-x86_64 -enable-kvm -cpu host -m 1536 -smp 2 -nographic -no-reboot \
  -drive file=$HOME/nexbsd-vm/disque-test.qcow2,if=virtio,cache=writeback \
  -netdev user,id=n0,hostfwd=tcp:127.0.0.1:4450-:445 \
  -device virtio-net-pci,netdev=n0
```

Différences avec le script :
- `-nographic` attache directement la console série au terminal → **pas besoin de `socat`** ;
- `Ctrl-A c` ouvre le moniteur QEMU, `Ctrl-A x` quitte la VM ;
- l'option `5` (console série) du menu du chargeur reste **indispensable**.

Arrêt propre : `shutdown -p now` dans la VM, ou `Ctrl-A x` en dernier recours (l'équivalent d'une coupure de courant).


## 4 ter. VOIE RECOMMANDÉE : virt-manager (interface graphique)

**Décision du 2026-10-23 (soir) :** le mode terminal (`-nographic`) est **abandonné** comme méthode de travail sur la station. Il a coûté une session entière pour une raison simple : le chargeur FreeBSD affiche son menu sur l'écran vidéo, et la touche `5` (bascule console série) doit être pressée **pendant le décompte de 10 s**, ce qui est fragile. Une interface graphique supprime entièrement ce problème.

**Note honnête sur l'origine de l'erreur :** le mode terminal avait été choisi parce que l'environnement de travail de l'assistant **n'a pas d'écran**. Ce n'est pas une contrainte de votre machine. Sur un poste avec affichage, `virt-manager` est l'outil juste.

### Installation

```bash
sudo apt update
sudo apt install -y virt-manager virtinst
```

`virt-manager` fournit : fenêtre graphique, clavier et souris, redimensionnement de la console, capture d'écran, instantanés, et gestion des ressources.

### Point important : session utilisateur, pas root

On travaille en **session utilisateur** (`qemu:///session`) : pas de mot de passe à chaque lancement, et aucun problème de droits sur les images stockées dans votre dossier personnel.

```bash
virt-manager --connect qemu:///session
```

### Créer la VM depuis l'interface

1. **Fichier → Nouvelle machine virtuelle**
2. **Importer une image de disque existante** → `~/nexbsd-vm/disque-test.qcow2`
   *(si ce fichier n'existe pas encore : `qemu-img create -f qcow2 -b FreeBSD-15.1-RELEASE-amd64-ufs.qcow2 -F qcow2 disque-test.qcow2`)*
3. Système d'exploitation : **FreeBSD** (la version exacte n'a pas d'importance)
4. Mémoire : **1536 Mo** — Processeurs : **2**
5. Nom : `nexbsd-test` → **Terminer**
6. La fenêtre de la VM s'ouvre : **là, la touche `5` devient inutile**, l'affichage vidéo est natif.

### Ou en une seule commande

```bash
virt-install --connect qemu:///session --name nexbsd-test \
  --memory 1536 --vcpus 2 --import \
  --disk path=$HOME/nexbsd-vm/disque-test.qcow2,format=qcow2,bus=virtio \
  --graphics spice --network network=default
```

Si `virt-install` se plaint de la version de FreeBSD, retirer l'option correspondante : elle n'est qu'indicative.


### 4 quater. Erreurs réelles de `virt-install` (2026-10-23) — et les corrections

**Erreur 1 (observée) :**
```
ERROR  --os-variant/--osinfo OS name is required, but no value was set or detected.
```
Cause : `virt-install` 4.x exige une identification du système invité.
Correction : `--osinfo name=freebsd13.0` (nom générique le plus proche de notre base).
Si ce nom n'existe pas dans votre base libosinfo :
```bash
virt-install --osinfo list | grep -i freebsd
```
puis reprendre le nom affiché, ou utiliser `--osinfo detect=on,require=off` (comportement permissif).

**Erreur 2 (non encore observée, mais certaine en session utilisateur) :**
`--network network=default` désigne un réseau **libvirt système** (`qemu:///system`), qui n'existe pas dans une session utilisateur (`qemu:///session`). Le lancement échouerait sur « Network not found ».
Correction : `--network user,model=virtio` (réseau utilisateur QEMU, NAT, sans privilège).

**Commande corrigée :**
```bash
virt-install --connect qemu:///session --name nexbsd-test \
  --osinfo name=freebsd13.0 \
  --memory 1536 --vcpus 2 --import \
  --disk path=$HOME/nexbsd-vm/disque-test.qcow2,format=qcow2,bus=virtio \
  --graphics spice \
  --network user,model=virtio
```

**Remarque :** c'est exactement le genre d'erreur où l'interface graphique (`virt-manager`) coûte moins cher que la ligne de commande — elle pose les questions une par une et coche des valeurs par défaut sûres.

### Ce que ça change pour la suite

- Connexion : `root`, mot de passe vide → **`passwd`** immédiatement.
- Arrêt propre : menu *Virtuelle* → **Éteindre** (équivalent de `shutdown -p now`).
- Les instantanés permettent de **revenir en arrière** avant un test risqué : c'est un avantage réel pour les essais LDAP/NCP à venir.

## 5. Étape 4 — commander la VM sans clavier graphique

Dans un second terminal :

```bash
socat -,raw,echo=0 UNIX-CONNECT:$HOME/nexbsd-vm/console.sock
```
*(ou `nc -U ~/nexbsd-vm/console.sock`)*

Identifiants de l'image officielle FreeBSD : **`root`, mot de passe vide.** Changez-le immédiatement :
```bash
passwd
```

## 6. Ce que nous ferons dans cette VM, dans l'ordre

| # | Test | Ce que ça prouve | État |
|---|---|---|---|
| T-01 | FreeBSD démarre | la base fonctionne | ✅ déjà réussi (bac à sable) — à **refaire chez vous** pour la trace locale |
| T-03 | Partage Samba écrit depuis une autre machine | la brique fichiers | ✅ déjà réussi — à refaire |
| **T-04** | Samba authentifie via **OpenLDAP** | la brique annuaire — **cœur de l'axe NetWare** | ⬜ à faire |
| **T-09/T-14** | banc NetWare (MARS_NWE + client NCP) | la différenciation | ⬜ à faire |
| T-08 | isolation (jail + pf) | la sécurité de base | ⬜ à faire |
| T-05 | journaux et supervision | l'administrabilité | ⬜ à faire |

## 7. Règles de sécurité du banc (non négociables)

1. **La VM ne voit jamais un disque physique.** Elle n'a qu'un fichier `qcow2` dans votre dossier personnel.
2. **Aucune commande destructrice** sur `~/nexbsd-vm` : pas de `rm -rf` sur le dossier, pas de `dd` sur un périphérique.
3. **Le PC de 2011 n'est pas concerné** par cette étape. Il reste intact jusqu'à ce qu'on décide, ensemble, du test par clé USB.
4. Réseau de la VM : `user` (NAT) — elle n'est pas joignable depuis l'extérieur, et le partage SMB n'est exposé que sur `127.0.0.1` par redirection de port.

## 8. Ce que ce banc ne réglera pas

- **La construction d'images NexBSD** : elle exige 8 Go de RAM et 40 Go libres. Si votre machine ne les a pas, il faudra une autre machine (Q4).
- **Le matériel réel de 2011** : seul T-02, par clé USB, le dira.
- **Les performances** : mesurées en VM, elles ne valent pas pour le matériel cible.

## 9. Après chaque session sur le banc

```bash
# dans la VM
shutdown -p now
```
Puis sauvegarder l'état du projet côté Mint :
```bash
cd ~/Projets/nexbsd && git add -A && git commit -m "tests: résultats de la session" && git push
```
Les résultats de test sont des **fichiers dans le dépôt** (`tests/results/`) : c'est cela qui fait avancer le projet, pas la mémoire de la conversation.

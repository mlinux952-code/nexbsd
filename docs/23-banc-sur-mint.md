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


## 4 quinquies. Se connecter a l'image FreeBSD officielle (identifiants)

Source : annonce officielle FreeBSD 15.1-RELEASE (https://www.freebsd.org/releases/15.1R/announce/), consultee le 2026-10-23 :
> « a freebsd user with a password of freebsd is available by default for ssh access. Additionally, the root user password is set to root »

| Acces | Identifiant | Mot de passe |
|---|---|---|
| **Console** (fenetre virt-manager) | `root` | `root` — **et si refuse, appuyer simplement sur Entree** (certaines images n'ont aucun mot de passe) |
| **SSH** | `freebsd` | `freebsd` |

**Les deux cas existent selon les images** : nos essais du 2026-10-23 (qemu, meme image ufs.qcow2) ont accepte `root` avec un mot de passe vide, tandis que l'annonce 15.1 documente `root`/`root`. Essayer donc **`root` puis `root`**, et si « Login incorrect », **`root` puis Entree**.

### Piege de la fenetre graphique

Si les touches ne vont pas dans la VM : **cliquer une fois dans la fenetre de la VM** avant de taper. virt-manager capture le clavier a ce moment-la. Pour le liberer : `Ctrl-Alt` (ou `Ctrl-Alt-L` selon la version).

### Si aucun identifiant ne fonctionne — reinitialisation par le mode mono-utilisateur

1. Eteindre la VM (menu *Virtuelle -> Eteindre*).
2. Redemarrer et, **au menu « Welcome to FreeBSD »**, choisir **`2. Boot Single user`**.
3. A l'invite `Enter full pathname of shell or RETURN for /bin/sh:`, **appuyer sur Entree**.
4. Puis, dans l'ordre :
   ```
   mount -u -w /
   mount -a
   passwd root
   ```
   (taper deux fois le nouveau mot de passe — rien ne s'affiche pendant la saisie, c'est normal)
5. `sync` puis `reboot`.

Le mode mono-utilisateur donne un acces root **sans mot de passe** par conception (Handbook FreeBSD §3.2.2) : c'est precisement pour cela qu'il faut en definir un immediatement apres.

### Apres la connexion, deux commandes

```
passwd            # definir un vrai mot de passe root
adduser           # creer un compte utilisateur (ne pas travailler en root)
```

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

## 6. Transférer des commandes dans la VM SANS copier-coller

**Problème constaté le 2026-10-23 :** le copier-coller depuis le Mint ne fonctionne pas dans la fenêtre de `virt-manager`. Cause : le presse-papiers partagé exige `spice-vdagent` **dans le système invité**, absent de l'image FreeBSD officielle.

Trois solutions, de la plus simple à la plus durable.

### 6.1 Servir les scripts depuis l'hôte (immédiat, aucune installation)

Le copier-coller fonctionne **dans un terminal Mint normal**. On s'en sert donc côté hôte :

```bash
cd ~/Projets/nexbsd
sh scripts/61-servir-vers-vm.sh
```

Ce script lance un petit serveur HTTP sur le dossier `scripts/`. Ensuite, **dans la VM**, on tape trois lignes courtes :

```
ifconfig vtnet0 inet
fetch -o /tmp/t04.sh http://10.0.2.2:8000/60-banc-T04-ldap.sh
sh /tmp/t04.sh
```

`10.0.2.2` est l'adresse de l'hôte vue depuis la VM en réseau « user » (vérifié par `ping` le 2026-10-23).

Avantage : aucune frappe longue, et le script peut être corrigé côté hôte puis re-téléchargé.

### 6.2 Console texte dans le terminal (le plus confortable)

Si la VM possède un port série, `virsh console` ouvre la console **dans votre terminal Mint** — et là, le copier-coller fonctionne normalement.

Vérifier la présence du port série :
```bash
virsh --connect qemu:///session dumpxml nexbsd-test | grep -A2 serial
```

S'il est absent, l'ajouter : fenêtre de la VM → *Afficher → Détails* → **Ajouter du matériel → Périphérique série (pty)** → redémarrer.

Puis :
```bash
virsh --connect qemu:///session console nexbsd-test
```
*(sortie : `Ctrl-]`)*

**À vérifier, pas acquis (corrigé le 2026-10-24) :** la version précédente de ce document affirmait que l'image FreeBSD 15.1 ouvre déjà un `getty` sur `ttyu0`. C'était une **hypothèse non testée**. Dans `/etc/ttys`, `ttyu0` est réglé sur `onifconsole`, c'est-à-dire qu'il ne s'active **que si la console du noyau est le port série**. Tant que le chargeur démarre sur `vidconsole` (cas par défaut), `virsh console` risque d'afficher un écran vide.

**Si l'écran reste vide**, activer la console série dans l'invité, **depuis la fenêtre graphique**, en root :

```
sysrc -f /boot/loader.conf boot_serial=YES
sysrc -f /boot/loader.conf boot_multicons=YES
sysrc console=comconsole,vidconsole
```

Attendu : `boot_serial:  -> YES`, `boot_multicons:  -> YES`, `console:  -> comconsole,vidconsole`.
Puis `shutdown -r now`. Au redémarrage, la console apparaît **à la fois** sur l'écran graphique et sur le port série.

### 6.5 Clavier AZERTY dans la VM (constat du 2026-10-24)

- La **console série ne se sert pas de la table de clavier FreeBSD** : les caractères viennent du terminal Mint, déjà en AZERTY. Donc `virsh console` = frappe AZERTY naturelle **et** collage fonctionnel. C'est l'argument décisif en faveur de `virsh console`.
- La table de clavier ne concerne que la **fenêtre graphique** de virt-manager. Noms exacts dans FreeBSD 15 (`share/syscons/keymaps`) : `fr.iso.kbd`, `fr.iso.acc.kbd`, `fr.macbook.acc.kbd`, `fr.dvorak*.kbd`. **`fr` et `fr.acc` seuls n'existent pas** → utiliser `kbdcontrol -l fr.iso.acc`.
- Après passage en AZERTY, les touches `-`, `/`, `:`, `=` changent de place : **ne pas taper de commande longue dans la fenêtre graphique** à ce moment-là.

### 6.3 Partager un dossier (pour la suite)

`virt-manager` sait exposer un dossier de l'hôte, mais FreeBSD n'a pas de client `virtiofs`/`9p` installé par défaut : à réserver au moment où la plateforme NexBSD sera montée.

### 6.4 Ce qu'il ne faut pas faire

Recopier un long script à la main dans la fenêtre graphique : source d'erreurs (tabulations, espaces, caractères perdus) et perte de temps. La règle du projet s'applique aussi ici : **une commande courte, un résultat vérifiable.**

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

# Le banc d'essai sur votre Linux Mint — mode d'emploi

**Version :** 1.0 — 2026-10-23 (session S-011)
**Décision :** le banc de test cesse d'être mon bac à sable et devient **votre machine**. Les VM y persistent, vous voyez l'écran, et les résultats restent chez vous.

---

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

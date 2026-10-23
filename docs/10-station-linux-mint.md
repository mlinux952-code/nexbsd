# La station de préparation Linux Mint

**Version :** 1.0 — 2026-10-23
**Statut :** `[PROPOSITION]` — procédure prête, **aucune commande n'a encore été exécutée sur votre poste**
**Rôle :** transformer un poste Linux Mint à faible capacité en **station de préparation et banc de test**, sans compilation lourde.

---

## 1. Ce que la station permet de faire (et ce qu'elle ne permet pas)

| Capacité | Possible ? | Pourquoi |
|---|---|---|
| Identifier le matériel du poste | ✅ | lecture seule |
| Télécharger et **vérifier l'intégrité** d'une image FreeBSD | ✅ | ~1,5 Go d'espace disque |
| Écrire une clé USB amorçable FreeBSD | ✅ | `dd` + garde-fous (script fourni) |
| **Faire tourner FreeBSD dans une machine virtuelle** pour un premier vrai test | ✅ (avec KVM) / lent (sans KVM) | c'est le gain principal : on peut démarrer **aujourd'hui** |
| Mesurer le comportement en RAM limitée (1 Go) | ✅ | la VM simule un PC faible |
| Compiler Samba, WebKit, Firefox | ❌ | heures de CPU, plusieurs Go de RAM **et** d'espace |
| Construire des images système reproductibles (poudriere) | ❌ | réservé au « PC fort » (profil L3) |
| Stocker une bibliothèque d'images et d'instantanés | ❌ (limité) | surveiller `df -h` |

> **Conséquence assumée :** jusqu'à l'arrivée d'un PC plus puissant, le projet n'utilise que des **paquets binaires** et des **VM légères**. C'est cohérent avec la cible « PC faible » : si NexBSD exige une grosse machine pour être construit, il manque déjà son objectif.

## 2. Étape 0 — Connaître la station (lecture seule, 1 minute)

Aucune commande ci-dessous ne modifie le système.

```bash
# version et architecture du poste
uname -a && lsb_release -d 2>/dev/null || cat /etc/os-release | head -3

# processeur, cœurs, virtualisation
lscpu | grep -Ei 'model name|architecture|cpu\(s\)|virtualisation|flags' | head -20
nproc

# mémoire
free -h

# disques et espace libre
lsblk -o NAME,SIZE,TYPE,TRAN,MODEL,MOUNTPOINT
df -h /home

# support de virtualisation matérielle disponible ?
[ -e /dev/kvm ] && echo "KVM disponible" || echo "KVM absent (VM lente mais utilisable)"
```

Ou, en une commande : `bash scripts/00-diagnostic-hote.sh`

**À reporter dans `docs/hardware.md` §3 (section « poste de préparation ») :** modèle du CPU, nombre de cœurs, RAM, espace libre sur `/home`, présence de KVM.

## 3. Étape 1 — Récupérer une image FreeBSD et vérifier son intégrité

**Pourquoi vérifier ?** Une image corrompue produit des échecs inexplicables (démarrage bloqué, installeur incomplet). C'est la source d'erreur la plus fréquente et la plus coûteuse en temps.

```bash
mkdir -p ~/nexbsd-images && cd ~/nexbsd-images

# Remplacer 15.1 par la version courante au moment du téléchargement
BASE=https://download.freebsd.org/releases/amd64/amd64/ISO-IMAGES/15.1
wget -c $BASE/FreeBSD-15.1-RELEASE-amd64-memstick.img
wget -c $BASE/FreeBSD-15.1-RELEASE-amd64-CHECKSUM

# vérification (le script gère les deux formats de fichier de sommes)
bash ~/nexbsd/scripts/10-verifier-image.sh \
     FreeBSD-15.1-RELEASE-amd64-memstick.img \
     FreeBSD-15.1-RELEASE-amd64-CHECKSUM
```

> `[À VÉRIFIER]` : le nom exact du fichier `CHECKSUM` peut varier selon la version. Si le téléchargement échoue, lister le répertoire : `wget -qO- $BASE/ | grep -E 'CHECKSUM|memstick'`.

**Résultat attendu :** ligne `OK` pour la somme SHA256 **et** SHA512.
**Critère de passage :** les deux sommes sont conformes. Sinon → retélécharger, ne jamais écrire une image non vérifiée.

## 4. Étape 2 — Écrire la clé USB (⚠️ opération destructive)

**Le seul moment du projet où une commande peut détruire des données.** Le script fourni impose trois barrières : détection du disque système, confirmation par recopie du nom du périphérique, vérification que le périphérique est amovible.

```bash
# 1) identifier la clé (regarder TRAN=usb et SIZE)
lsblk -o NAME,SIZE,TYPE,TRAN,MODEL,MOUNTPOINT

# 2) écrire — le script refuse /dev/sda s'il porte le système
sudo bash ~/nexbsd/scripts/20-ecrire-usb.sh \
     ~/nexbsd-images/FreeBSD-15.1-RELEASE-amd64-memstick.img /dev/sdX
```

**Résultat attendu :** écriture terminée, `sync` effectué, message de succès.
**Critère de passage :** le script affiche « écriture terminée » sans avoir touché au disque système (il l'a vérifié).
**Risques :** confusion de périphérique (R-01). Mitigation : débrancher les autres périphériques USB inutiles, vérifier la **taille** de la clé dans `lsblk` avant de lancer.

## 5. Étape 3 — Premier banc de test : FreeBSD en machine virtuelle

C'est ici que le projet fait un **vrai pas technique** sans attendre le PC de 2011 : une VM FreeBSD de 1 Go de RAM, c'est déjà un « PC faible » crédible pour un serveur en mode texte.

### 5.1 Installer l'outillage

```bash
sudo apt update
sudo apt install -y qemu-system-x86 qemu-utils cpu-checker
kvm-ok || echo "KVM indisponible : la VM sera lente, mais fonctionnelle en mode texte"
```

### 5.2 Créer et démarrer la VM

```bash
# disque virtuel de 8 Go (le profil L1 vise 20 Go sur matériel réel)
qemu-img create -f qcow2 ~/nexbsd-vm/nexbsd-lab0.qcow2 8G

# démarrage sur l'image memstick (comme une clé USB), avec 1 Go de RAM
qemu-system-x86_64 \
  -machine q35 -m 1024 -smp 2 \
  -drive file=$HOME/nexbsd-vm/nexbsd-lab0.qcow2,if=virtio,format=qcow2 \
  -drive file=$HOME/nexbsd-images/FreeBSD-15.1-RELEASE-amd64-memstick.img,format=raw,if=virtio \
  -boot order=dc -vga std \
  -netdev user,id=n0 -device virtio-net-pci,netdev=n0 \
  -enable-kvm
```

Ou, en une commande : `bash scripts/30-qemu-freebsd.sh --ram 1024 --create`

Options utiles :

| Option | Effet | Usage |
|---|---|---|
| `-m 1024` | 1 Go de RAM | simule la cible L1 ; essayer `-m 512` pour tester le plancher |
| `-smp 2` | 2 vCPU | cohérent avec la cible |
| `-snapshot` | les écritures sont jetées à l'arrêt | essai jetable sans conséquence |
| `-nographic` | pas de fenêtre graphique | plus économe sur une station faible |
| `-monitor stdio` | console de contrôle QEMU | pour arrêter proprement (`quit`) |

**Résultat attendu :** menu de démarrage FreeBSD, puis l'installeur `bsdinstall`.
**Critère de passage :** la VM atteint l'invite d'installation ; à défaut, l'erreur exacte est consignée dans `reports/`.
**Ce que cela ne prouve pas :** rien sur les pilotes du PC de 2011 (la VM présente du matériel virtuel standard). Le test matériel réel reste nécessaire (étape 2 du plan d'action).

### 5.3 Mesures à relever dans la VM

| Mesure | Commande (dans la VM) | Objectif L1 |
|---|---|---|
| RAM au repos | `vmstat -h` | ≤ 128 Mo |
| Temps de démarrage | chronomètre jusqu'à l'invite | ≤ 60 s (VM : indicatif seulement) |
| Empreinte disque | `df -h` | ≤ 2 Go |

## 6. Règles d'hygiène pour un poste à faible capacité

1. **Un seul téléchargement à la fois**, et vérifier `df -h` avant (les images pèsent 1-2 Go).
2. **Arrêter la VM** avant toute autre tâche lourde (`-m 1024` immobilise 1 Go).
3. Ne pas installer d'environnement de bureau supplémentaire ni de suite bureautique pour le projet.
4. Conserver les images dans `~/nexbsd-images` et les nettoyer après validation sur support physique.
5. Ne jamais lancer de compilation (`make`, `poudriere`) sur cette station : c'est le rôle du futur « PC fort ».

## 7. Ce que ce document n'autorise pas

- Écrire sur un disque interne (le script refuse).
- Installer FreeBSD sur le poste Linux Mint lui-même (aucune procédure de ce type n'est proposée).
- Modifier le BIOS/UEFI du poste.
- Télécharger des images depuis une source non officielle.

## 8. Correspondance avec le plan d'action

| Étape du plan (`docs/plan-action.md`) | Réalisable sur Linux Mint ? |
|---|---|
| 0 — décisions | oui (humain) |
| 1 — inventaire du PC 2011 | non (Windows 7 requis) |
| 2 — préparation du support | **oui, ici** (§3 et §4) |
| 3 — premier démarrage | **oui, en VM** (§5) ; matériel réel : non |
| 4 — installation | **oui, en VM** ; matériel réel : non |
| 5 à 9 — services, mesures | **oui, en VM** (avec réserves de performance) |

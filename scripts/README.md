# Scripts — préparation (Mint) et banc (VM FreeBSD)

Les scripts `00` à `40` sont des outils de préparation **lecture seule** pour la station Mint. Les scripts `60` à `69` s'exécutent **dans la VM FreeBSD** (banc). Jusqu'à l'ADR-0020, aucun ne compilait quoi que ce soit ; depuis l'ADR-0020, **`68` compile un noyau** — c'est la seule exception, bornée, et le monde/l'image restent interdits sur ce poste. Tous ont été testés en syntaxe ; `00`, `10` ont été exécutés dans un environnement de test, `20` et `30` n'ont **pas** été exécutés sur du matériel réel.

| Script | Ce qu'il fait | Modifie le système ? |
|---|---|---|
| `00-diagnostic-hote.sh` | relève CPU, RAM, disques, espace libre, KVM, outils | **non** (lecture seule) |
| `10-verifier-image.sh` | vérifie les empreintes SHA256/SHA512 d'une image téléchargée | **non** (lecture seule) |
| `20-ecrire-usb.sh` | écrit une image sur un support amovible | ⚠️ **OUI — destructif**, garde-fous multiples |
| `30-qemu-freebsd.sh` | lance FreeBSD dans une VM (1 Go de RAM par défaut) | non (écrit uniquement dans `~/nexbsd-vm`) |
| `40-verifier-frontiere-licence.sh` | **contrôle T-13** : détecte tout code copyleft dans un arbre (base NexBSD), avec exemptions justifiées | **non** (lecture seule) |

---

## 1. Diagnostic (lecture seule)

```bash
bash scripts/00-diagnostic-hote.sh
```

Reporter dans `docs/hardware.md` §3 (section « poste de préparation ») : CPU, cœurs, RAM, espace libre sur `/home`, KVM oui/non.

## 2. Télécharger puis vérifier une image FreeBSD

```bash
mkdir -p ~/nexbsd-images && cd ~/nexbsd-images
BASE=https://download.freebsd.org/releases/amd64/amd64/ISO-IMAGES/15.1
wget -c $BASE/FreeBSD-15.1-RELEASE-amd64-memstick.img
wget -c $BASE/FreeBSD-15.1-RELEASE-amd64-CHECKSUM

cd ~/nexbsd
bash scripts/10-verifier-image.sh \
     ~/nexbsd-images/FreeBSD-15.1-RELEASE-amd64-memstick.img \
     ~/nexbsd-images/FreeBSD-15.1-RELEASE-amd64-CHECKSUM
```

Résultat attendu : `RÉSULTAT : image intègre`. Code retour 0.
Si le nom du fichier `CHECKSUM` diffère : `wget -qO- $BASE/ | grep -i checksum`.

## 3. Écrire une clé USB (⚠️ destructif)

```bash
# identifier la clé : repérer le périphérique avec TRAN=usb et la bonne taille
lsblk -o NAME,SIZE,TYPE,TRAN,RM,MODEL,MOUNTPOINT

# écrire (remplacer sdX par le VRAI nom, et le script vous demandera de le retaper)
sudo bash scripts/20-ecrire-usb.sh ~/nexbsd-images/FreeBSD-15.1-RELEASE-amd64-memstick.img /dev/sdX
```

### Garde-fous intégrés

1. refus si la cible n'est pas un périphérique bloc ;
2. **refus si la cible porte le système de fichiers racine** ;
3. refus si la cible n'est pas amovible/USB, sauf `--force` explicite ;
4. refus si la cible est plus petite que l'image ;
5. démontage automatique des partitions de la cible ;
6. **confirmation par recopie exacte** du nom du périphérique.

> **Ce script n'a pas été testé sur un périphérique réel.** Avant la première utilisation : lire le récapitulatif affiché et vérifier la **taille** du périphérique. Le disque interne du PC de 2011 ne doit jamais être visé (contrainte R-01).

## 4. Premier banc de test : FreeBSD en VM

```bash
sudo apt install -y qemu-system-x86 qemu-utils

# créer un disque virtuel de 8 Go
bash scripts/30-qemu-freebsd.sh --create

# démarrer sur l'image d'installation (recherche automatique dans ~/nexbsd-images)
bash scripts/30-qemu-freebsd.sh --from-installer --ram 1024

# essai jetable, sans fenêtre graphique (le plus économe sur un poste faible)
bash scripts/30-qemu-freebsd.sh --snapshot --nographic --ram 512
```

Options : `--ram`, `--cpus`, `--disk-gb`, `--installer`, `--snapshot`, `--nographic`, `--create`, `--from-installer`.

Note : sans `/dev/kvm`, la VM tourne en émulation logicielle — lente mais utilisable en mode texte.

## 5. Contrôle de la frontière de licence (test T-13)

```bash
bash scripts/40-verifier-frontiere-licence.sh <arborescence> [--allow <fichier-d-exemptions>]
```

- Détecte les mentions `SPDX-License-Identifier: …GPL…` et les en-têtes « GNU General Public License ».
- Code retour **0** = conforme, **1** = violations, **2** = erreur d'usage.
- Les motifs d'exemption sont **relatifs à l'arborescence scannée** (`third_party/*`).

**Testé** dans un environnement de test : arbre propre → 0 ; arbre contaminé (3 fichiers) → 1 avec localisation exacte ; exemptions correctement appliquées → 1 exempté, violations restantes comptées.

**Limite :** détection par signatures textuelles ; ne remplace pas une revue humaine, attrape les oublis évidents.

---

## Règles d'usage

- **Un téléchargement à la fois** ; vérifier `df -h` avant (une image pèse 1-2 Go).
- **Arrêter la VM** avant toute autre tâche lourde (1 Go immobilisé).
- Ne jamais lancer de compilation : elle relève du futur profil L3 (ADR-0010).
- Consigner toute action matérielle dans `reports/` (date, commande, résultat observé).

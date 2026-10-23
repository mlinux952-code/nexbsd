# Résultat T-01 — FreeBSD 15.1 démarre-t-il ? — **RÉUSSI**

**Date d'exécution :** 2026-10-23, 20h45 → 21h25 (heure locale, Tunis)
**Exécutant :** assistant, dans une VM QEMU du banc de travail
**Nature :** premier test **réellement exécuté** du projet (les 15 autres restent `NON EXÉCUTÉ`)

---

## 1. Environnement d'exécution (mesuré, pas supposé)

| Élément | Valeur | Commande / preuve |
|---|---|---|
| Hyperviseur | QEMU **10.0.13** (paquet Debian 13) | `qemu-system-x86_64 --version` |
| Accélération | **aucune** — `/dev/kvm` absent → émulation TCG | `ls /dev/kvm` → No such file |
| Machine hôte | 2 vCPU, **1,9 Gio de RAM**, 25 Go disque | `nproc`, `free -h` |
| Ressources allouées à la VM | 1 vCPU, **768 Mo**, disque qcow2 6,03 Gio | ligne de commande QEMU |
| Image | `FreeBSD-15.1-RELEASE-amd64-ufs.qcow2` | voir §2 |

## 2. Image utilisée — provenance et intégrité **vérifiées**

- URL : `https://download.freebsd.org/releases/VM-IMAGES/15.1-RELEASE/amd64/Latest/FreeBSD-15.1-RELEASE-amd64-ufs.qcow2.xz`
- Taille téléchargée : **664 540 212 octets**
- **SHA256 recalculé et comparé au `CHECKSUM.SHA256` officiel → identique** :
  `25ad16e9d0c037f40a43c6f3c474b5c1ba62eaf9204dbd7f034fdbffe2c3dae5`
- Après décompression : 2,46 Gio sur disque, taille virtuelle 6,03 Gio (UFS, GPT)

**Le disque de travail est un overlay qcow2** (`disque-test.qcow2`) : l'image d'origine n'est jamais modifiée. C'est le même principe anti-destruction que `docs/hardware.md` impose au matériel réel.

## 3. Ce qui a été observé (verbatim)

```
FreeBSD freebsd 15.1-RELEASE FreeBSD 15.1-RELEASE releng/15.1-n283562-96841ea08dcf GENERIC amd64
```

Démarrage en mode multi-utilisateur : **atteint l'invite `login:`** — 4 démarrages successifs (dont 2 après arrêt propre) sans panique ni erreur bloquante.

**Temps de démarrage mesuré : 81 s** entre le lancement du chargeur et l'invite `login:`, en **émulation pure sans KVM**, sur 1 vCPU. C'est une borne haute : le matériel réel de 2011, même lent, n'émule pas.

## 4. Mesure de mémoire — **le chiffre clé pour ADR-0009**

Relevé juste après démarrage, avant toute installation :

| Indicateur | Valeur mesurée |
|---|---|
| Mémoire totale vue par le noyau | 182 085 pages × 4 096 o = **746 Mo** |
| Pages libres | 165 224 = 645 Mo |
| Pages inactives | 348 = 1,4 Mo |
| Pages *wired* | 13 605 = **53 Mo** |
| **Mémoire occupée au repos** | **≈ 100 Mo** |

➡️ **L'objectif ENF-01 (≤ 128 Mo au repos) est atteignable** sur un système FreeBSD nu. Il reste à vérifier avec les services réseau actifs (ENF-02) sur un démarrage propre — la mesure faite après installation de Samba est **polluée par le cache de paquets** (164 Mo en *laundry*) et ne vaut pas comme résultat.

## 5. Verdict

**RÉUSSI**, avec deux réserves explicites :

1. **Ce n'est pas le matériel de 2011.** C'est une VM amd64 émulée. T-02 (démarrage sur le vrai PC, par clé USB) reste **entièrement à faire** et c'est lui qui tranchera la question K-01.
2. Le chiffre « 81 s » n'est **pas** une mesure de performance du PC cible : c'est une borne supérieure obtenue par émulation logicielle.

## 6. Ce que ce test change dans les documents

- `docs/ETAT.md` : le compteur de tests exécutés passe de **0 à 1**.
- `matrices/compatibilite.csv` : la ligne « FreeBSD 15.x démarre-t-il ? » passe de `INCONNU` à `OUI — en VM`, avec la nuance matérielle.
- `docs/etude-faisabilite.md` : premier critère de conclusion coché **partiellement**.

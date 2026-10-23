# Diagnostic matériel — procédure non destructive

**Date :** 2026-10-23
**Statut :** procédure prête à exécuter — **aucune mesure n'a encore été prise**
**Matériel concerné :** PC de bureau d'environ 2011, 4 Go de RAM, disque mécanique, Windows 7 installé, processeur inconnu.

> ⚠️ **Contrainte absolue :** aucune commande de cette procédure n'écrit sur le disque. Aucun partitionnement, formatage, `diskpart clean`, `chkdsk /f`, défragmentation, ni modification du BIOS n'est autorisé à ce stade.

---

## 1. Pourquoi cette étape est bloquante

Deux inconnues peuvent arrêter le projet :

1. **Le processeur est-il 64 bits ?** FreeBSD 15.x n'existe plus pour i386 (32 bits). Un CPU 32 bits rendrait le prototype impossible sur cette machine.
2. **Le firmware accepte-t-il le démarrage sur USB ?** Sans cela, impossible d'amorcer un système externe.

Ces deux réponses s'obtiennent sans rien modifier.

## 2. Inventaire à réaliser (Windows 7, lecture seule)

Ouvrir une invite de commandes : **Démarrer → Rechercher → `cmd` → clic droit → Exécuter en tant qu'administrateur** (nécessaire pour certaines lectures, pas pour toutes).

| # | Commande | Ce que l'on obtient | À noter dans le tableau §3 |
|---|---|---|---|
| 1 | `systeminfo` | type de système (`x64-based PC` attendu), RAM totale, version du BIOS (fin du rapport) | Type de système, RAM |
| 2 | `wmic cpu get name,NumberOfCores,DataWidth,MaxClockSpeed` | nom exact du CPU et **`DataWidth` : 64 = 64 bits** | CPU, cœurs, DataWidth |
| 3 | `wmic bios get manufacturer,version,releasedate,SMBIOSBIOSVersion` | constructeur et date du BIOS | Firmware |
| 4 | `wmic baseboard get manufacturer,product` | modèle de carte mère | Carte mère |
| 5 | `wmic memorychip get capacity,speed,manufacturer` | barrettes installées | RAM détaillée |
| 6 | `wmic diskdrive get model,size,interfaceType,status` | modèle et taille du disque interne | Disque |
| 7 | `wmic path win32_VideoController get name,driverversion` | carte graphique | GPU |
| 8 | `wmic path win32_NetworkAdapter where "PhysicalAdapter=true" get name,MACAddress` | cartes réseau (filaire + Wi-Fi) | Réseau |
| 9 | `msinfo32` | fenêtre complète (processeur, BIOS, mémoire) | capture d'écran |
| 10 | `dxdiag` | onglets Système et Affichage | capture d'écran |

**État du disque (optionnel, lecture seule) :** un outil portable de lecture SMART (par ex. CrystalDiskInfo en version portable, sans installation sur le disque) permet de relever l'état de santé. Ne pas lancer de test d'écriture.

**Démarrage USB :** au redémarrage, observer l'écran de POST et la touche annoncée pour le **menu de démarrage** (souvent F12, F11, F9 ou Échap). **Ne pas entrer dans le BIOS pour changer des réglages** à ce stade : il suffit de constater que le menu existe et propose « USB » ou « Removable Device ».

## 3. Tableau à remplir

| Élément | Méthode | Valeur observée | Date |
|---|---|---|---|
| Type de système | `systeminfo` | _à remplir_ | |
| Processeur (nom exact) | `wmic cpu get name` | _à remplir_ | |
| Nombre de cœurs | `wmic cpu` | _à remplir_ | |
| **DataWidth (64 ?)** | `wmic cpu get DataWidth` | _à remplir_ | |
| RAM totale | `systeminfo` | _à remplir_ | |
| Barrettes | `wmic memorychip` | _à remplir_ | |
| Firmware (constructeur/date) | `wmic bios` | _à remplir_ | |
| Mode de démarrage | POST | BIOS ou UEFI ? | |
| Menu de démarrage USB | POST | touche observée | |
| Disque interne (modèle/taille) | `wmic diskdrive` | _à remplir_ | |
| État SMART | outil portable | _à remplir_ | |
| Carte réseau filaire | `wmic NetworkAdapter` | _à remplir_ | |
| Carte Wi-Fi | `wmic NetworkAdapter` | _à remplir_ | |
| Carte graphique | `wmic VideoController` | _à remplir_ | |
| Virtualisation matérielle (VT-x/AMD-V) | `systeminfo` (« Virtualisation : activée ») | _à remplir_ | |

## 4. Interprétation

| Résultat | Conséquence |
|---|---|
| `DataWidth = 64` | FreeBSD 15.x amd64 envisageable ✔ |
| `DataWidth = 32` | **Arrêt** : FreeBSD 15 impossible ; envisager FreeBSD 14 i386 (support jusqu'en 2028) ou une autre machine |
| Menu USB absent du POST | envisager un disque USB externe en premier périphérique, ou un autre PC ; sinon, prototype en machine virtuelle |
| Pas de VT-x/AMD-V | bhyve/local VM impossible sur cette machine |
| RAM < 4 Go | réduire le périmètre (pas de service réseau + UI simultanés) |
| Carte Wi-Fi non reconnue sous FreeBSD | utiliser le port Ethernet (chemin sûr) |

## 5. Sauvegarde des données personnelles

Avant toute expérimentation (même non destructive), copier les fichiers personnels du Windows 7 vers un support distinct. Cette opération ne fait pas partie du projet technique, mais elle conditionne la sérénité des tests.

## 6. Plan de retour arrière

1. **Avant** toute expérimentation : noter dans ce document les valeurs de l'inventaire (§3).
2. Le disque interne n'étant jamais modifié, le retour arrière théorique est « débrancher le support externe et démarrer normalement ».
3. **Vérifier ce théorème au moins une fois** après la première installation externe : retirer le support, démarrer Windows 7, constater qu'il fonctionne.
4. En cas d'anomalie de démarrage : ne pas « réparer » le BIOS à l'aveugle ; revenir à l'ordre de démarrage d'origine.

## 7. Ce que ce document n'autorise pas

- Modifier l'ordre de démarrage de façon permanente.
- Désactiver le Secure Boot ou une protection sans explication et sans accord du responsable.
- Toute opération d'écriture disque sur le disque interne.
- Installer un logiciel sur le Windows 7 (« portable » uniquement).

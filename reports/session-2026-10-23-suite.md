# Compte rendu de session — suite du 2026-10-23

**Session :** S-002 (suite de S-001, même journée)
**Déclencheur :** trois précisions du responsable du projet :
1. son poste de travail est un **Linux Mint à faible capacité** ;
2. **NexBSD est un système pour PC faible** ;
3. « un jour, un PC fort » permettra des modifications — donc **plus tard, pas maintenant**.

**Ce qui n'a pas changé :** le projet reste en phase de conception. Aucune installation FreeBSD n'a été réalisée, aucun test n'a été exécuté, le disque du PC de 2011 est intact.

---

## 1. Effet des précisions sur le cadrage

| Précision | Effet |
|---|---|
| « système pour PC faible » | **Change la nature du projet**, pas seulement ses tests : le PC faible devient une **cible de conception** avec un budget de ressources opposable → **ADR-0009**, `docs/09-cible-pc-faible.md` |
| « poste Mint à faible capacité » | Devient une **station de préparation** utilisable immédiatement (vérification d'images, écriture USB garde-fou, VM QEMU 1 Go) → `docs/10-station-linux-mint.md`, 4 scripts |
| « un jour un PC fort » | Report explicite des compilations lourdes et de la construction reproductible au profil **L3**, sans en dépendre → **ADR-0010** |

## 2. Décisions de conception induites

1. **Budget de ressources** (objectifs, non mesurés) : ≤ 128 Mo de RAM au repos, ≤ 256 Mo avec services réseau, ≤ 2 Go d'espace disque, démarrage ≤ 60 s sur disque mécanique.
2. **UFS par défaut**, ZFS rétrogradé en option : le cache ARC de ZFS est incompatible avec 1-2 Go de RAM.
3. **Trois images séparées** au lieu d'un système hybride unique : `nexbsd-lab` (≤ 128 Mo), `nexbsd-net` (≤ 256 Mo), `nexbsd-mobile` (≤ 768 Mo).
4. **La couche mobile quitte la configuration par défaut** : un moteur Web permanent (200-500 Mo) disqualifierait la cible.
5. **Aucune compilation sur les postes faibles** : paquets binaires uniquement jusqu'à L3.

## 3. Question ouverte importante (nouvelle)

La cible « PC faible » inclut-elle des machines **32 bits** ?

- FreeBSD 15.x n'existe plus en i386 ; FreeBSD 14.x i386 est supporté jusqu'au **30 novembre 2028**.
- Si la réponse est « oui », ADR-0001 (FreeBSD 15.x amd64) doit être révisé vers FreeBSD 14.x i386, avec une durée de vie connue et des paquets en voie d'extinction.

`[À VÉRIFIER]` — question au responsable du projet, en attente.

## 4. Fichiers créés ou modifiés dans cette suite

**Créés :**
- `docs/09-cible-pc-faible.md`
- `docs/10-station-linux-mint.md`
- `docs/decisions/ADR-0009-cible-pc-faible.md`
- `docs/decisions/ADR-0010-pas-de-compilation-sur-poste-faible.md`
- `scripts/00-diagnostic-hote.sh`
- `scripts/10-verifier-image.sh`
- `scripts/20-ecrire-usb.sh`
- `scripts/30-qemu-freebsd.sh`
- `scripts/README.md`
- `reports/session-2026-10-23-suite.md` (ce fichier)

**Modifiés :**
- `README.md` (cible, station, arborescence)
- `docs/architecture.md` (UFS par défaut, trois images)
- `docs/plan-action.md` (ajout de l'étape 1bis — banc de test virtuel)
- `matrices/components.csv` (C-13 UFS ; WebKitGTK restreint à l'image mobile)
- `docs/decisions/README.md` (registre +2 ADR)
- `tests/plan-tests.md` (ajout T-01v)

## 5. Vérifications réellement effectuées sur les scripts

Les quatre scripts ont été **exécutés dans un environnement de test** (Debian 13, conteneur), pas sur le poste du responsable :

| Vérification | Résultat |
|---|---|
| `bash -n` sur les 4 scripts | syntaxe valide |
| `00-diagnostic-hote.sh` exécuté | fonctionne ; produit un relevé lisible |
| `10-verifier-image.sh` — image intacte, format FreeBSD `SHA256 (nom) = …` | ✅ 2/2 empreintes vérifiées, code retour 0 |
| `10-verifier-image.sh` — image corrompue volontairement | ✅ détectée, code retour 1, message explicite |
| `10-verifier-image.sh` — format standard GNU (`sha256sum`) | ✅ détecté et vérifié |
| `20-ecrire-usb.sh` | **non testé sur un vrai périphérique** (aucun disque amovible disponible) — seuls les garde-fous ont été relus |
| `30-qemu-freebsd.sh` | **non testé** (QEMU non installé dans l'environnement de test), syntaxe seulement |

> **Ces vérifications ne valent pas validation sur votre poste.** Le script d'écriture USB en particulier doit être relu avant usage : c'est le seul du projet capable de détruire des données.

## 6. Limites assumées de la station Mint

- Elle ne permet **pas** de compiler Samba, WebKit ou Firefox.
- Elle permet de **démarrer FreeBSD en VM** dès aujourd'hui, avec 1 Go de RAM — un banc de test cohérent avec la cible L1.
- Une VM ne prouve **rien** sur les pilotes du PC de 2011 : le test matériel réel reste obligatoire.

## 7. Prochaines actions

**Immédiat (responsable, ~30 min, aucun risque) :**
1. Lancer `bash scripts/00-diagnostic-hote.sh` sur le Mint et communiquer la sortie (CPU, RAM, espace libre, KVM oui/non).
2. Répondre à la question du §3 : la cible inclut-elle des machines **32 bits** ?

**Ensuite (assistant) :**
3. Ajuster le budget L1 si la RAM du Mint est très faible (par ex. 512 Mo pour la VM).
4. Préparer la configuration du prototype 0 dans la VM (jail, Samba, `pf`) — en paquets binaires uniquement.

**Optionnel, si le Mint a moins de 3 Go libres :**
5. Poursuivre uniquement sur le PC de 2011 (étape 1 du plan : inventaire Windows), la VM attendant un peu d'espace disque.

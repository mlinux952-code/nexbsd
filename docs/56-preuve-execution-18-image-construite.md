# 56 — Exécution #18 : **la chaîne complète est verte, un système NexBSD a été produit**

> **Ce document est une PREUVE.** Les faits ci-dessous ont été lus le 2026-10-29 par l'API GitHub
> (`/actions/runs/40826237095` et `/jobs`), **pas** rapportés de mémoire ni déduits d'une capture.
> Là où je ne sais pas, c'est écrit « non vérifié ».

---

## 1. Le fait principal

```
Exécution #18   —   commit 30f1d47b   —   workflow_dispatch
début 2026-10-29T05:56:17Z   ->   fin 2026-10-29T08:25:08Z
durée : 2 h 29

conclusion : SUCCESS

SONDE      success
CONTRÔLES  success
BUREAU     success
IMAGE      success
```

Détail de la tâche IMAGE — **treize étapes, treize vertes** :

```
success  Set up job
success  Run actions/checkout@v5
success  Libérer de l'espace disque
success  DÉMARRER LA VM FreeBSD 15.1 (4 CPU, 8 Go)
success  1/4 — la machine peut-elle construire ? (30 secondes)
success  2/4 — télécharger, VÉRIFIER l'empreinte, extraire src.txz
success  2bis — pré-vol de la construction (10 secondes)
success  3/4 — construction + assemblage NexBSD (plusieurs heures)
success  4/4 — empreintes des fichiers produits
success  Rapport lisible (en haut de la page, sans rien déplier)
success  Déposer l'artefact
success  Post Run actions/checkout@v5
success  Complete job
```

## 2. L'artefact existe, et il est gros

```
nom      : nexbsd-images
taille   : 1 912 892 702 octets = 1 824,3 Mo (1,82 Go)
expire   : 2026-11-28T08:22:59Z   (30 jours)
archive  : /actions/artifacts/12883077040/zip
```

Une seule annotation sur toute l'exécution, et c'est un avertissement sans effet :
`Node.js 20 is deprecated… actions/upload-artifact@v5`.

## 3. Ce que le vert de `3/4` PROUVE, par déduction rigoureuse

`fork/build-nexbsd.sh` commence par `set -eu`. Chaque étape est enchaînée par `||`. Donc
**si une seule commande avait échoué, l'étape aurait été rouge.** Elle est verte, donc :

| Commande | Statut prouvé |
|---|---|
| `buildworld` (le monde, avec `src.conf` NexBSD) | ✅ **a abouti** |
| `buildkernel NEXBSD_L1` (notre noyau) | ✅ **a abouti** |
| `make installworld DESTDIR=$RACINE` | ✅ **a abouti** |
| `make distribution DESTDIR=$RACINE` | ✅ **a abouti** |
| `make installkernel NEXBSD_L1 DESTDIR=$RACINE` | ✅ **a abouti** |
| `70-appliquer-overlay.sh` (les 9 pièces + 2 fusions) | ✅ **a abouti** |
| **`makefs`** (fabrication du système de fichiers) | ✅ **a abouti** — une erreur ici aurait fait échouer l'étape |
| `mkimg` (enveloppe bootable) | ⚠️ **a abouti ou a averti** — les deux chemins sortent en code 0, on ne peut pas trancher |
| `gzip -1` (compression pour le transport) | ✅ **a abouti** — l'artefact de 1,82 Go en est la trace |

**Conclusion certaine : un système de fichiers NexBSD complet a été fabriqué, avec le noyau
NEXBSD_L1 et la configuration du produit, puis compressé et déposé en artefact.**

C'est la **première fois** que le projet produit ce fichier.

## 4. Ce que ce vert NE PROUVE PAS — et c'est décisif

| Affirmation | Statut |
|---|---|
| l'image **démarre** | ❌ **jamais essayé** — aucune VM n'a booté ce fichier |
| le système **fonctionne** | ❌ inconnu |
| Samba, OpenLDAP, nslcd sont **installés** | ❌ **non** — `installworld` installe le socle FreeBSD, **pas** les paquets. C'est le rôle de `fork/80-installer-nexbsd.sh`, **jamais exécuté** |
| les services **démarrent** | ❌ leur configuration est dans `/etc/rc.conf`, mais les binaires sont absents |
| PAM vérifie un mot de passe | ❌ jamais |
| la session graphique s'affiche | ❌ jamais |
| le nom des fichiers produits et leurs sha256 | ⚠️ **non vérifié** — l'artefact exige une authentification (HTTP 401 depuis ce banc) ; seul le titulaire du compte peut le télécharger |

**Autrement dit : le système est CONSTRUIT et EMBALLÉ, mais il n'a jamais été ALLUMÉ, et il ne
contient pas encore les services réseau.**

**Phrase exacte :**
> *NexBSD existe désormais sous forme d'un système de fichiers de 1,82 Go compressé, construit à
> partir de FreeBSD 15.1-RELEASE avec le noyau NEXBSD_L1 et les neuf pièces de configuration du
> produit. Ce fichier n'a jamais été démarré, et les services réseau (Samba, OpenLDAP, nslcd) n'y
> sont pas encore installés.*

## 5. Le chemin parcouru, en huit exécutions

| # | résultat | ce qui a été appris |
|---|---|---|
| 1 | rouge, 1 min | la VM ne démarrait pas (`ubuntu-latest` → Ubuntu 26) |
| 2 | rouge, 38 s | `git` n'est pas dans FreeBSD de base (C-34) |
| 3 | rouge | le texte de l'erreur n'arrivait jamais (C-35) |
| 4 | rouge | le refus de root pris pour un bug (C-36) |
| **5** | **VERT** | première exécution verte ; 31 cas du bureau passent sur FreeBSD |
| 7 | rouge | **une empreinte SHA256 avait été inventée** (C-37) |
| 10 | rouge, 2 min | la chaîne cherchait la sortie au mauvais endroit (C-38) |
| 14 | rouge, 10 s | `src.txz` s'extrait un niveau plus bas ; le pré-vol l'a dit aussitôt |
| 16 | rouge, 3 h 14 | **le système a été assemblé**, échec sur `rc.conf` absent |
| **18** | **VERT, 2 h 29** | **`makefs` a produit le système NexBSD** |

**Deux choses ont rendu le #18 possible, et ni l'une ni l'autre ne concerne la compilation :**
1. **le pré-vol** (10 s) qui refuse une construction vouée à l'échec ;
2. **le fait de corriger trois défauts d'un coup** avant de relancer — parce qu'un essai coûte
   3 heures sans aucune reprise possible.

## 6. La prochaine étape, et elle est décisive

**Démarrer ce fichier.** C'est le test T-01 appliqué au produit lui-même, et il n'a jamais été
fait. Trois résultats possibles, tous informatifs :

- il démarre jusqu'à l'invite → **on verra `/etc/motd` NexBSD s'afficher**, et le projet aura un
  système qui existe pour de vrai ;
- il ne démarre pas → on apprend ce qui manque dans le média (chargeur, table de partitions),
  et on le corrige ;
- il démarre en mode dégradé → on saura ce qui doit entrer dans le noyau `NEXBSD_L1`.

Ensuite seulement : `fork/80-installer-nexbsd.sh` pour poser les paquets, puis N-06 (les lecteurs
réseau), qui est l'âme de NetWare et n'existe toujours pas.

# Rapport de tests — M8 (deux tâches, espaces d'adressage séparés)

**Date :** 2026-10-26 · **Suite complète : `VERDICT GLOBAL : OK`** (exit 0)
**Noyau `24b1a74f…`** (59 840 octets) · **image `f8dd79c2…`** (4 460 544 octets) · 19 vérifications distinctes · 11 fichiers dans l'image

---

## 1. Ce qui est prouvé, avec le journal brut

```
[OK] tache A : 128 octets a 0x400000, pile 0x800000, espace d'adressage propre (PML4 0x11e000)
[OK] tache B : 141 octets a 0x500000, pile 0x900000, espace d'adressage propre (PML4 0x125000)
[OK] deux taches creees, espaces d'adressage distincts (A: 0x400000, B: 0x500000)
[TEST] premier passage en ring 3 (tache A)
utilisateur[A]> BONJOUR - ce programme vient d'un FICHIER de l'ISO (hello.bin), pas du noyau.
isolation : acces utilisateur REFUSE par le processeur
  tache         : A (espace d'adressage 0x11e000)
  adresse visee : 0xffffffff80000000  (code d'erreur 0x7)
  page presente mais interdite a l'utilisateur (bit U/S a 0) : memoire du NOYAU
tache A : terminee (statut -2) - acces interdit a la memoire du noyau
commutation -> tache B (espace d'adressage 0x125000)
utilisateur[B]> TACHE B : je tourne a 0x500000, et l'adresse 0x400000 de la tache A doit m'etre invisible.
isolation : acces utilisateur REFUSE par le processeur
  tache         : B (espace d'adressage 0x125000)
  adresse visee : 0x400000  (code d'erreur 0x6)
  page absente de CET espace d'adressage : memoire d'une AUTRE tache
tache B : terminee (statut -2) - acces a une page absente de son espace d'adressage
plus aucune tache active : retour au noyau
M8 : toutes les taches sont terminees, le noyau a repris la main
  bilan A : statut -2 (acces interdit a la memoire du noyau)
  bilan B : statut -2 (acces a une page absente de son espace d'adressage)
M8-TACHES-OK
ring 3 : CPL observe dans les appels systeme = 3
ring 3 : appels systeme traites = 2
ring 3 : fautes utilisateur interceptees = 2
M7-RING3-OK
M7-ISOLATION-OK
M8-ISOLEMENT-OK
noyau toujours vivant apres l'arret des programmes utilisateur.
M8-OK
```

| Preuve | Valeur mesurée | Pourquoi c'est solide |
|---|---|---|
| Deux espaces d'adressage distincts | **PML4 `0x11e000`** (A) vs **`0x125000`** (B) | deux tables de pages physiquement différentes, chacune avec ses propres mappings utilisateur |
| A ne peut pas écrire dans le noyau | code d'erreur **0x7** (présent + écriture + user) | refus du **processeur**, bit U/S à 0 sur la page noyau |
| **B ne peut pas voir la mémoire de A** | code d'erreur **0x6** (user + écriture + **absente**) à l'adresse `0x400000` | dans l'espace de B, cette page **n'est pas mappée** : les deux tâches ne partagent rien |
| Commutation réelle | `commutation -> tache B` après la mort de A | le noyau a réécrit le cadre d'interruption et changé CR3 |
| Noyau survivant | 2 fautes, 0 panique, invite `nexbsd>` atteinte | le noyau n'est pas emporté par ses programmes |
| Retour propre | `plus aucune tache active : retour au noyau` | le noyau reprend la main en ring 0 après la dernière tâche |

## 2. Ce que M8 ne fait **pas** (à ne jamais oublier)

1. **Pas de préemption** : la commutation est **coopérative** (sur `exit` ou sur faute). L'horloge continue de battre mais l'ordonnanceur ne l'utilise pas. Un programme qui boucle sans appeler le noyau **bloquerait la machine** — les programmes de démonstration ne le font pas.
2. **Deux tâches maximum en démonstration** (`TASK_MAX = 4`), pas de `fork`/`exec`.
3. **Pas de système de fichiers** : les programmes sont des **modules d'amorçage** posés sur l'ISO par l'outil de construction.
4. **Pas de sécurité de compte** : aucune notion d'utilisateur, de droits ou de propriétaire ; les deux tâches ont les mêmes appels système.
5. **Pas de mémoire partagée, pas d'IPC** : les tâches ne communiquent pas.
6. **Aucun test sur matériel physique** (D-011) ; mono-processeur.

## 3. Métriques

| Élément | M7 + chargeur | M8 | Δ |
|---|---|---|---|
| Noyau + en-têtes | 2 296 l. | **2 501 l.** | +205 |
| Outillage | 735 l. | **763 l.** | +28 |
| Noyau ELF64 | 55 232 o | **59 840 o** | +4 608 o |
| Fichiers dans l'image | 10 | **11** (hello.bin, world.bin) | +1 |
| Vérifications distinctes | 18 | **19** | +1 (T10) |
| Démarrage BIOS | 2,52–2,57 s | **2,57–2,67 s** | +0,1 s |
| Démarrage UEFI | 4,14–4,29 s | **3,99–4,19 s** | — |

## 4. Formulations autorisées / interdites

**Autorisé :** « deux programmes s'exécutent successivement en ring 3 sur NexBSD, chacun dans **son propre espace d'adressage** ; une tâche qui tente d'écrire dans la mémoire du noyau ou dans celle de l'autre tâche est **arrêtée par le processeur**, le noyau survit et reprend la main ».
**Interdit :** « NexBSD fait tourner plusieurs applications simultanément » (pas de préemption, exécution séquentielle), « NexBSD est multitâche préemptif », « NexBSD a un ordonnanceur » (il n'y a pas de quantum, pas de priorité, pas de réveil), « NexBSD a un système de fichiers ».

## 5. Suite

- **M9 proposé — préemption** : quantum sur IRQ0, sauvegarde/restauration complète du contexte sur pile noyau par tâche, un programme qui boucle sans appeler le noyau et se fait **déloger** au bout d'un quantum. C'est la seule brique qui manque pour parler de multitâche.
- Puis **système de fichiers minimal en lecture** (FAT ou format propre) pour cesser d'utiliser des modules d'amorçage.

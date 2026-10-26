# P1 — « Squelette NexBSD » : spécification de périmètre v1.0

**Statut : décision D-003 validée par le responsable le 2026-10-26.** Ce document gèle le périmètre du premier prototype.
**Environnement autorisé : machine virtuelle isolée uniquement.** Le disque principal du PC Windows 7 n'est **pas** concerné par ce prototype.
**Aucun élément décrit ci-dessous n'existe à ce jour.** Tout ce qui suit est un plan ; chaque affirmation future devra être accompagnée d'une preuve (journal, empreinte, capture).

---

## 1. Objectif unique et mesurable

> Démontrer, en machine virtuelle isolée, que NexBSD peut produire par une **seule commande reproductible** une image autonome qui démarre, prend en charge le clavier, affiche son identité et exécute une boucle de commandes minimale — **sans aucun composant d'un système d'exploitation tiers dans l'image**.

Cette phrase est le seul critère de succès de P1. Tout le reste est hors périmètre.

## 2. Périmètre gelé

### 2.1 Inclus (et rien d'autre)

| Bloc | Contenu minimal | Justification |
|---|---|---|
| B1 — Atelier | `build.sh`, `run.sh`, `test.sh`, arborescence versionnée, `git init` local | sans reproductibilité, aucune preuve n'est vérifiable |
| B2 — Chaîne de démarrage | chargeur (Limine, BSD-2-Clause) **ou** chargeur propre ; passage en mode long 64 bits ; remise de la main au noyau avec une structure d'informations de démarrage | cœur de l'identité « NexBSD démarre » |
| B3 — Noyau minimal | console (série + framebuffer si disponible), GDT/IDT, gestion des interruptions (horloge minimal), boucle principale | base de tout système |
| B4 — Entrées | clavier PS/2 ; décodage des touches ; tampon d'événements | exigence « navigation au clavier » du projet |
| B5 — Shell minimal | lire une ligne, exécuter des commandes internes (`help`, `version`, `mem`, `reboot`, `halt`) | prouve que le système « répond » |
| B6 — Identité | bannière, version, niveau d'indépendance affiché (I4-embryon) | honnêteté de statut, exigée par la charte du projet |
| B7 — Tests | T1–T5 (§5) automatisés, exécutés par `test.sh`, sorties brutes conservées | preuve |
| B8 — Rapport | `07_Rapports/rapport-tests-P1.md` avec empreintes, journaux, verdicts | traçabilité |

### 2.2 Explicitement exclu (toute demande d'ajout = nouveau prototype)

Mémoire virtuelle complète et pagination avancée · multitâche préemptif · appels système et espace utilisateur · libc · chargeur d'exécutables · système de fichiers · pilote AHCI/NVMe · réseau et pile TCP/IP · USB · graphique accéléré (GPU) · son · ACPI avancé · gestion de l'énergie · modèle applicatif (N0/N1) · moteur JavaScript · interface graphique · sécurité applicative (W^X, ASLR, isolation) · **démarrage sur le PC 2011 depuis une clé USB** (étape 3 séparée, soumise à autorisation).

> **Règle de gel :** pendant P1, toute idée séduisante est notée dans `idees-reportees.md`, **jamais** implémentée. C'est la principale protection contre l'abandon (risque R-02).

## 3. Outils et prérequis

### 3.1 Hôte de développement
- Linux x86-64 (l'espace de travail actuel convient : 2 vCPU, ~1,9 Go de RAM, 21 Go libres — vérifié le 2026-10-26), **ou** une machine Linux dédiée.
- Réseau uniquement pour récupérer des sources à licence vérifiée.

### 3.2 Outils requis

| Outil | Rôle | Licence | État dans l'espace de travail (2026-10-26) |
|---|---|---|---|
| `gcc` (`-m64 -ffreestanding`) | compiler le noyau | GPL-3 + exception runtime | **présent** (14.2) |
| `ld` / `objcopy` | lier, produire des binaires bruts | binutils, GPL-3 | **présent** (2.44) |
| `make` | orchestrer | GPL-3 | **présent** |
| `nasm` ou GNU `as` en `.code16` | code d'amorçage si chargeur propre | BSD-2 / GPL | absent → à installer |
| `qemu-system-x86_64` | émulation isolée (= environnement autorisé) | GPL-2 | absent → à installer |
| `xorriso` / `mtools` | fabriquer l'image ISO/HDD | GPL-3 | absents → à installer |
| `git` | versionnement local | GPL-2 | **présent** |
| `gdb` | débogage du noyau via QEMU | GPL-3 | à vérifier |
| Limine | chargeur d'amorçage | **BSD-2-Clause (vérifié 2026-10-26)** | à récupérer |

### 3.3 Principe de licence appliqué (cohérent avec D-005)

- Code original NexBSD : **provisoirement permissif** (BSD-2 ou MIT), non définitif.
- Outils sous GPL utilisés **comme outils**, non intégrés au produit : ni gcc, ni QEMU, ni xorriso ne sont distribués dans l'image NexBSD.
- Le chargeur retenu (Limine) est permissif : il laisse ouvertes **les deux** options de licence finale (permissive ou copyleft). Aucune dépendance copyleft n'entre dans l'image P1. C'est une décision technique destinée à préserver la liberté de choix.
- Registre des licences tenu à jour dans `../05_Licences_et_Compatibilite/matrice-licences.csv`.

## 4. Arborescence de travail prévue

```
nexbsd-p1/
├── README.md              # ce qu'est P1, comment construire, comment tester
├── LICENSE                # licence provisoire du code original (à figer)
├── src/
│   ├── boot/              # configuration du chargeur
│   ├── kernel/
│   │   ├── main.c         # point d'entrée
│   │   ├── console.c      # série + framebuffer
│   │   ├── gdt_idt.c
│   │   ├── irq.c
│   │   ├── keyboard.c     # PS/2, disposition de touches
│   │   └── shell.c
│   └── include/
├── third_party/limine/    # COPYING conservé (BSD-2)
├── tools/{build.sh,run.sh,test.sh,bootstrap.sh}
├── tests/                 # note d'orientation (les scripts sont dans tools/)
└── docs/{environnement.md,decisions/}
```

**Écart constaté et corrigé lors de la revue du 2026-10-26 (M5) :** le fichier `LICENSE` prévu ci-dessus **n'existait pas** ; il a été créé (BSD-2-Clause, marqué *provisoire*, décision D-005). Les scripts de test sont dans `tools/` et non dans `tests/` ; `tests/README.txt` l'explique désormais. Les critères n'ont pas changé.

## 5. Tests — définition exacte et critères de réussite

Aucun de ces tests n'a été exécuté. Les critères sont écrits **avant** l'implémentation, pour empêcher l'ajustement du critère au résultat.

| # | Test | Procédure | Résultat attendu | Critère de réussite |
|---|---|---|---|---|
| **T1** | Reproductibilité | `build.sh` deux fois dans deux répertoires propres | mêmes octets | **même SHA-256** ; aucune dépendance implicite (date, chemin, `$USER`) |
| **T2** | Démarrage nominal | `qemu-system-x86_64` sur l'image, console série capturée | bannière `NexBSD` + version + niveau d'indépendance | bannière affichée en **< 5 s**, sur 3 exécutions |
| **T3** | Clavier | injection de 20 frappes (monitor QEMU ou périphérique clavier) | 20 caractères affichés et journalisés | 20/20 reconnus, ordre conservé |
| **T4** | Robustesse | 10 démarrages consécutifs automatisés | aucun blocage | 10/10 sans panique non gérée, code de sortie contrôlé |
| **T5** | Autonomie de l'image | inventaire du contenu de l'image (fichiers + provenance) | aucun binaire d'un autre OS | inventaire complet ; **100 %** des fichiers produits par NexBSD ou Limine ; toute autre provenance = échec |

**État au 2026-10-26 après M2 (mesuré) :** **T1a OK** (noyau ELF reproductible) · **T1b OK** (image reproductible, dette M1 résolue par `SOURCE_DATE_EPOCH` + normalisation des horodatages) · **T2 BIOS OK** · **T2 UEFI OK** · **T3-partiel OK** (preuve visuelle du framebuffer) · **T4-partiel OK** (10/10 démarrages) · **T5 OK** (0 provenance inconnue).
**État après M4 (2026-10-26) :** **T3 complet OK** (clavier PS/2 réel) · **T4 OK** (10/10 démarrages) · T3-bis OK (`reboot` réel) · T2-bis mesuré (M3 : BIOS 2,31–2,42 s, UEFI 3,93–3,99 s ; M4 : BIOS 2,36–2,42 s, UEFI 3,83–3,84 s) · **T6 OK** (14 vérifications : entrée série, disposition FR, AltGr, historique, défilement réel prouvé au pixel) · **T7 OK** (métriques reproductibles). **M6 (2026-10-26) : mémoire virtuelle livrée** (noyau `700b1098…`, image `7bfe5036…`) — 17 vérifications distinctes vertes, dont 15 autotests mémoire exécutés à chaque démarrage.

**M5 (2026-10-26) : P1 CLOS** — rapport final `../07_Rapports/rapport-tests-P1.md` (T1–T7 verts, journaux, empreintes, inventaire, remise en une commande) et dossier de revue D-010 `../07_Rapports/revue-D-010-niveau-independance.md`. **Aucun critère n'a été abaissé pendant tout P1.**

**Definition of Done de P1 :** T1–T5 passent, avec journaux bruts, empreintes et inventaire joints à `../07_Rapports/rapport-tests-P1.md`, **et** `README.md` permettant à un tiers de reproduire en une commande.

## 6. Jalons courts (5–10 h/semaine, durées = estimations [E], non mesurées)

| Jalon | Contenu | Durée [E] | Sortie vérifiable |
|---|---|---|---|
| **M0** | Atelier : outils installés, versions consignées, `git init`, arborescence, `build.sh` vide | 1 semaine | `docs/environnement.md` avec versions réelles |
| **M1** | Image amorçable « de démonstration » (code non NexBSD) démarrant en QEMU | 1 semaine | **✅ RÉALISÉ le 2026-10-26** — voir `../07_Rapports/rapport-tests-P1-M1.md` |
| **M2** | Noyau NexBSD réel : entrée 64 bits, GDT/TSS, IDT + exceptions, console série + framebuffer, identité | 1–2 semaines | **✅ RÉALISÉ le 2026-10-26** — voir `../07_Rapports/rapport-tests-P1-M2.md` |
| **M3** | Interruptions (PIC/PIT), clavier PS/2, shell minimal | 1–2 semaines | **✅ RÉALISÉ le 2026-10-26** — voir `../07_Rapports/rapport-tests-P1-M3.md` |
| **M2** | Remplacement progressif par le code NexBSD : entrée 64 bits + console | 1–2 semaines | ligne `NexBSD` émise par notre code |
| **M3** | Interruptions, horloge, clavier, shell minimal | 1–2 semaines | T3 passant |
| **M4** | Robustesse et démonstrabilité (choix option B de D-013) : clavier FR + AltGr, entrée série, historique et défilement réel de la console, métriques mesurées, T6/T7 intégrés | 1–2 semaines | **✅ RÉALISÉ le 2026-10-26** — voir `../07_Rapports/rapport-tests-P1-M4.md` |
| **M5** | Clôture de P1 : rapport final, revue D-010 (I2/I3/I4) | 1 semaine | **✅ RÉALISÉ le 2026-10-26** — `../07_Rapports/rapport-tests-P1.md` + `revue-D-010-niveau-independance.md` |
| **M6** | (post-P1, décision D-010 = I4) Mémoire virtuelle : pmm, tables de pages propres, tas noyau, protection vérifiée | 2–3 semaines | **✅ RÉALISÉ le 2026-10-26** — 15 autotests, 3 défauts de page interceptés — `../07_Rapports/rapport-tests-P1-M6.md` |
| **M7** | Ring 3, appels système minimaux (`write`, `exit`), isolation vérifiée | 2–4 semaines | **✅ RÉALISÉ le 2026-10-26** — `../07_Rapports/rapport-tests-P1-M7.md` |
| **M7 bis** | Programme utilisateur **externe** (fichier de l'ISO chargé par le chargeur) | 1 semaine | **✅ RÉALISÉ le 2026-10-26** — `../07_Rapports/rapport-chargeur-programme-externe.md` |
| **M8** | Deux tâches ring 3, espaces d'adressage séparés, commutation coopérative, isolation entre tâches | 2–4 semaines | **✅ RÉALISÉ le 2026-10-26** — `../07_Rapports/rapport-tests-P1-M8.md` |
| **M9** | (proposé) Préemption sur quantum (IRQ0), pile noyau par tâche | 3–6 semaines | non commencé |
| **M5** | Revue de fin de P1 → décision D-010 (étude I2/I3/I4 sur faits) | 0,5 semaine | décision écrite et argumentée |

**Point d'arrêt obligatoire après M5 :** aucune poursuite vers la mémoire virtuelle ou le réseau sans décision explicite.

## 7. Risques spécifiques à P1 et parades

| Risque | Parade |
|---|---|
| Dérapage de périmètre | gel §2.2 + `idees-reportees.md` + revue à chaque jalon |
| Code de tutoriel recopié sans compréhension | en-tête de provenance obligatoire par fichier ; aucun fichier sans origine traçable |
| Contamination de licence (code GPL recopié) | inventaire par fichier (T5) ; interdiction de copier hors permissif vérifié |
| Faux positif « ça marche » | T1–T5 doivent passer **avant** toute annonce ; sinon statut « en cours » |
| Environnement non persistant (paquets à réinstaller) | `tools/bootstrap.sh` idempotent et documenté |
| Illusion de sécurité | P1 n'a **aucune** prétention de sécurité : ni W^X, ni isolation, ni utilisateur ; écrit dans le README |

## 8. Ce que P1 ne prouvera jamais

Pilotes réels (stockage, réseau, USB, GPU) · multitâche · espace utilisateur · sécurité · modèle applicatif · moteur Web · compatibilité binaire · usage quotidien · démarrage sur le PC 2011 (étape séparée).

## 9. Étape 3 conditionnelle (hors P1, soumise à autorisation explicite)

Le démarrage sur le PC 2011 depuis une clé USB n'aura lieu **que si** :
(a) T1–T5 verts en VM ;
(b) fiche matérielle renseignée (architecture, firmware, disques) ;
(c) procédure de récupération écrite (retrait de la clé → Windows 7 doit démarrer normalement) ;
(d) nom de périphérique cible vérifié deux fois ;
(e) accord explicite du responsable.

**Aucune écriture sur le disque interne, à aucune étape.**

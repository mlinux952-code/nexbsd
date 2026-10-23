# Le delta NexBSD — ce qui fait de NexBSD un système, et pas un FreeBSD décoré

**Version :** 1.0 — 2026-10-23 (session S-010)
**Rôle :** répondre à l'exigence du responsable : *« notre objectif est le système NexBSD, pas installer un FreeBSD modifié — on construit un système unique et non pas de décoration système »*.
**Statut :** document de travail. **Aucun fichier du delta n'a été compilé.** Ce document décrit ce qui est écrit, ce qui manque, et ce qui ne peut pas être fait sans le profil L3.

---

## 1. La distinction, en une phrase

| | FreeBSD + paquets (rejeté, ADR-0011) | NexBSD (le seul modèle accepté) |
|---|---|---|
| Noyau | celui de FreeBSD, tel quel | **`NEXBSD_L1`**, généré depuis GENERIC, retraits motivés |
| Userland | celui de FreeBSD | construit par NexBSD avec **son `src.conf`** |
| Version | `15.1-RELEASE-p6` | **`15.1-NEXBSD-L1`** (et, plus tard, `uname -s` = NexBSD) |
| Image | celle de FreeBSD, gravée | **produite par NexBSD**, avec son `motd`, son `/etc/nexbsd-version` |
| Cycle | suit FreeBSD | **fusion amont choisie**, versions décidées par le projet |
| Ce qui est « FreeBSD » | tout | **l'arbre amont**, jamais l'identité du produit |

**Ce que j'ai testé hier en VM (T-01, T-03) est le socle, pas le produit.** C'était légitime comme *banc d'essai* — on vérifie qu'une brique fonctionne — mais cela ne doit jamais être présenté comme NexBSD. Cette distinction est désormais écrite noir sur blanc, et l'état du projet l'affiche.

## 2. Le delta existe maintenant sous forme de fichiers, pas d'intentions

| Fichier | Ce qu'il fait | Vérifié ? |
|---|---|---|
| `build/fork/reference/GENERIC-15.1` | GENERIC **officiel** de `releng/15.1`, téléchargé et conservé comme référence | ✅ source amont, URL en §5 |
| `build/fork/tools/generer-kernel-conf.sh` | **génère** le noyau NexBSD à partir de cette référence, par règles explicites | ✅ **exécuté**, sortie ci-dessous |
| `build/fork/sys/amd64/conf/NEXBSD_L1` | le noyau du profil L1 (identité + retraits) | ✅ généré — ❌ **jamais compilé** |
| `build/fork/sys/amd64/conf/NEXBSD_L1.rapport` | liste chaque ligne retirée et sa justification | ✅ produit |
| `build/fork/src.conf` | options du monde, chacune **vérifiée** dans `src.conf.5` 15.1 | ✅ noms vérifiés — ❌ jamais utilisé |
| `build/fork/release.conf` | identité et contenu de l'image (`KERNCONF`, `BRANCH_OVERRIDE`) | ❌ jamais exécuté |
| `build/fork/overlay/etc/motd` | l'écran d'accueil de NexBSD, avec la mention FreeBSD obligatoire | ❌ non intégré |
| `build/fork/overlay/etc/nexbsd-version` | fiche d'identité du système installé | ❌ non intégré |
| `build/fork/overlay/etc/rc.conf.defaults` | services **activés au démarrage** (leçon du test T-03) | ❌ non intégré |
| `build/fork/patches/0001-identite-version.patch` | fait passer `uname -s` à « NexBSD » | ❌ **non appliqué** (risque documenté) |
| `build/fork/build-nexbsd.sh` | chaîne complète, avec garde-fous L3 | ❌ jamais exécuté (garde-fou testé) |

## 3. Ce que la génération du noyau a produit — et ce qu'elle n'a pas fait

Exécution réelle du 2026-10-23 :

```
Généré : build/fork/sys/amd64/conf/NEXBSD_L1
TOTAL : 4 ligne(s) retirée(s) sur 393 du GENERIC d'origine.
```

Retraits appliqués, chacun justifié : Hyper-V (la cible est un PC de 2011, pas un hôte), lecteur de disquette, CardBus (deux lignes).

**Pourquoi si peu :** un noyau allégé « pour faire sérieux » est une faute. Chaque périphérique retiré est un matériel qui ne démarrera pas chez un utilisateur. Le delta grossira quand un fait le justifiera (mesure de taille, matériel identifié), pas avant.

**Le noyau s'appelle désormais `NEXBSD_L1`** — c'est un changement réel dans la chaîne : `KERNCONF=NEXBSD_L1`, un binaire de noyau produit par le projet.

## 4. Les sept questions de `docs/11-fork-pas-surcouche.md` — où en est NexBSD

| # | Question | Réponse aujourd'hui |
|---|---|---|
| 1 | NexBSD possède-t-il son arbre source ? | ⬜ **non** — le delta est écrit, l'arbre n'est pas cloné ni versionné par le projet |
| 2 | NexBSD choisit-il ce qu'il y a dans sa base ? | 🟡 **le choix est écrit** (`src.conf`, `NEXBSD_L1`), pas encore appliqué par une construction |
| 3 | NexBSD produit-il ses propres images ? | ⬜ non — `release.conf` prêt, jamais exécuté |
| 4 | NexBSD a-t-il son propre cycle de versions ? | ⬜ non — `nexbsd-version` existe, aucune version publiée |
| 5 | NexBSD a-t-il une identité visible ? | 🟡 partielle — `uname -r` = `15.1-NEXBSD-L1` prévu ; `uname -s` reste FreeBSD (patch non appliqué) |
| 6 | NexBSD assure-t-il le suivi de sécurité de sa base ? | ⬜ non — procédure écrite, jamais exercée |
| 7 | NexBSD est-il autre chose qu'une configuration de FreeBSD ? | 🟡 **en cours** : oui sur le papier (noyau, options, image, overlay, cycle), non dans les faits |

**Score : 0 réponse pleine, 3 partielles, 4 négatives.** C'est le point de départ honnête. Ce tableau est la mesure du chemin qui reste, et il ne se remplira pas avec des documents.

## 5. Provenance des fichiers de référence (vérifiable)

| Fichier | URL | Rôle |
|---|---|---|
| `GENERIC-15.1` | `https://raw.githubusercontent.com/freebsd/freebsd-src/releng/15.1/sys/amd64/conf/GENERIC` | noyau amont de référence |
| `src.conf.5-15.1` | `.../releng/15.1/share/man/man5/src.conf.5` | **validation des noms d'options** |
| `newvers.sh-15.1` | `.../releng/15.1/sys/conf/newvers.sh` | mécanisme réel de l'identité de version |
| `config.5-15.1` | `.../releng/15.1/share/man/man5/config.5` | format des fichiers de noyau |

Consultés le 2026-10-23, branche `releng/15.1`. **Aucune option inventée** : toute option de `src.conf` absente de `src.conf.5` a été refusée (ex. `WITHOUT_IPX`, `WITHOUT_PROFILE` — non documentées, donc non utilisées).

## 6. Ce qui manque pour que NexBSD soit NexBSD — et pourquoi ce n'est pas ici

| Manque | Pourquoi ce n'est pas faisable dans cet environnement |
|---|---|
| Cloner et versionner l'arbre FreeBSD | 1 à 3 Go de source ; l'espace de travail est petit et jetable — l'arbre doit vivre sur le PC fort |
| `buildworld` + `buildkernel` | **≥ 8 Go de RAM, ≥ 40 Go de disque, plusieurs heures** ; l'hôte a 1,9 Go et 2 vCPU |
| Image signée | dépend de la construction, plus d'une décision sur les clés (porte G8) |
| `uname -s` = NexBSD | patch écrit, **volontairement non appliqué** sans compilation de vérification |
| pkgbase NexBSD | étape suivante après la première image (P2 dans `docs/11`) |

**Conclusion nette :** la seule chose qui sépare NexBSD d'un « FreeBSD modifié » est une **construction réelle**. Elle exige le profil L3 (Q4). Tant qu'il n'existe pas, tout ce que le projet peut produire est un delta écrit, vérifié, motivé — utile, mais pas encore un système.

## 7. Ce que le responsable doit décider (Q4, devenue bloquante)

La question n'est plus « quand aura-t-on un PC fort ? » mais **« sur quelle machine la première image NexBSD sera-t-elle construite ? »**. Trois options réalistes :

1. **Un PC avec ≥ 8 Go de RAM et 60 Go libres**, même ancien — suffisant pour un `buildworld` en `-j4` (une nuit de calcul).
2. **Une machine louée à l'heure** (VPS puissant) — coût faible, mais l'arbre et les images devraient y être copiés, et la question de la confiance se pose.
3. **Emprunter une machine** le temps d'une construction.

Sans l'une des trois, NexBSD restera un dossier de conception très bien tenu — et il faut le dire ainsi, plutôt que d'appeler « NexBSD » un FreeBSD installé.

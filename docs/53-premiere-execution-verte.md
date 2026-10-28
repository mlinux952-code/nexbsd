# 53 — Première exécution verte de la chaîne NexBSD (2026-10-28)

> **Ce document est une PREUVE.** Il contient la sortie verbatim de la page GitHub Actions,
> telle que le responsable l'a collée. On ne la réécrit jamais : si elle devient fausse,
> on la masque explicitement en le disant.

Exécution **#5**, déclenchée par un `push` du commit **`f6c78a7`** sur `main`.

```
Status Success
Total duration 1m 16s

SONDE — la VM FreeBSD et son environnement     ✅
CONTRÔLES — delta, registre, simulation         ✅
BUREAU — tests de session et d'authentification ✅
```

---

## 1. SONDE — voici la machine, enfin décrite

```
NexBSD — rapport de la SONDE
SONDE — environnement de la VM

FreeBSD freebsd 15.1-RELEASE-p3 FreeBSD 15.1-RELEASE-p3
        releng/15.1-n283611-88e7371d9dc2 GENERIC amd64
15.1-RELEASE-p3
15.1-RELEASE-p3
utilisateur : root (uid 0)
repertoire  : /home/runner/work/nexbsd/nexbsd

git  : ABSENT (c est normal : git n est pas dans FreeBSD de base)
.git : present dans la copie
pkg  : /usr/sbin/pkg
node : ABSENT (a installer par pkg)

fichiers dans fork/    : 33 (attendu 33)
scripts en fork/bureau : 5
espace libre /usr     : 195G
```

Trois faits qui comptent, et qui étaient **supposés** jusqu'ici :

| Fait | Statut |
|---|---|
| le noyau de la VM est **`GENERIC`**, pas NexBSD | **mesuré** — c'est bien une VM FreeBSD standard, pas notre produit |
| **`git` est absent**, `pkg` est présent | **mesuré** — confirme C-34, la cause de l'échec #2 |
| **195 Go libres** sur `/usr` | **mesuré** — la construction d'un monde est possible en disque |

Le dernier point enterre une inquiétude réelle : on craignait 25–30 Go à peine suffisants.
La VM en offre **195**. Le seul frein restant sera le **temps**, pas l'espace.

---

## 2. CONTRÔLES — les trois garde-fous, dans la vraie machine

```
NexBSD — CONTRÔLES dans une vraie VM FreeBSD 15.1

1/3 — delta du fork — code 0
... mode de comptage : disque — git absent, on compte les fichiers reellement presents
... fichiers comptes dans fork/ : 33 (attendu : 33)
VERDICT : DELTA INTACT (33 fichiers, empreintes conformes)

2/3 — registre des acquis — code 0
... mode de verification des cibles : disque (git absent)
VERDICT : REGISTRE CONFORME — chaque acquis a une destination, chaque cible PRODUIT existe.

3/3 — simulation de production — code 0
[KO] RAM insuffisante : 6091 Mo < 7000 Mo
[KO] cette machine NE PEUT PAS construire (voir §3) — c'est exactement pour cela que la CI existe (docs/41)
SIMULATION : le delta est complet et propre. Rien n'a été construit.
```

**Les deux `[KO]` de la ligne 3/3 ne sont pas un échec** : c'est le garde-fou de capacité qui
dit la vérité. La VM de cette tâche a **6 Go** de RAM (défaut de l'action), et il en faut 7 pour
construire. Le script `74` le dit, et sort en **code 0** parce que c'est une simulation.

C'est exactement pour cela que la tâche **IMAGE** déclare `mem: 8192` : 8 Go, au-dessus du seuil.

**Le correctif de C-34 est prouvé en conditions réelles** : le mode de comptage bascule tout seul
sur `disque — git absent`, et trouve **33 fichiers sur 33** au lieu de zéro.

---

## 3. BUREAU — 31 cas, tous verts, sur FreeBSD

```
1/3 — installation de node
Extracting pkg-2.8.4: .......... done
Bootstrapping pkg from pkg+https://pkg.FreeBSD.org/FreeBSD:15:amd64/latest, please wait...
Verifying signature with trusted certificate pkg.freebsd.org.2013102301... done
bootstrap : code 0
[15/15] Installing node22-22.23.4...
[15/15] Extracting node22-22.23.4: .......... done
install node22 : code 0
node : /usr/local/bin/node
v22.23.4

2/3 — session (17 cas) — code 0
[OK] utilisateur simple / avec tiret / avec souligné
[OK] demo=1 / demo=0 n'est PAS une session
[OK] balise HTML dans le nom / nom avec espace / nom avec point-virgule
[OK] nom trop long (40) / nom commençant par un chiffre / nom valide
[OK] paramètre encodé / deux paramètres, demo prioritaire
VERDICT : 17 cas, 0 échec. La logique de session se comporte comme décrit.

3/3 — authentification (14 cas), sous un compte ordinaire
utilisateur de la CI avant : root (uid 0)
compte de test : nexbsd-test
  [OK] code de sortie
  [OK] stdout contient seulement le nom
  ...
  [OK] la règle anti-root est écrite
  [OK] aucun mot de passe en argument
VERDICT : 14 cas, 0 échec.
code de sortie : 0
```

**17 + 14 = 31 cas verts**, exécutés sur **FreeBSD 15.1-RELEASE-p3 amd64**, dans une vraie
machine virtuelle. C'est la première fois du projet.

Et la correction de C-36 est visible dans le verbatim lui-même :
`utilisateur de la CI avant : root (uid 0)` puis `compte de test : nexbsd-test`.
Le test tourne maintenant **sous un compte ordinaire**, comme la session réelle le fera — et il
aurait été **impossible** de le faire passer en root, par conception.

---

## 4. Ce que cette exécution PROUVE

| Affirmation | Preuve |
|---|---|
| une VM FreeBSD 15.1 démarre dans GitHub Actions | `FreeBSD 15.1-RELEASE-p3 … GENERIC amd64` |
| le dépôt arrive complet dans la VM | `fichiers dans fork/ : 33 (attendu 33)` |
| les garde-fous fonctionnent **sans git** | `mode de comptage : disque — git absent` |
| le delta est intact **dans une vraie VM** | `VERDICT : DELTA INTACT (33 fichiers, empreintes conformes)` |
| le registre des acquis est conforme | `VERDICT : REGISTRE CONFORME` |
| `pkg` s'amorce et installe `node22` | `bootstrap : code 0` · `v22.23.4` |
| la logique de session du bureau est saine | `17 cas, 0 échec` |
| la logique de l'écran d'ouverture est saine | `14 cas, 0 échec` |
| la chaîne de production est simulable | `3/3 — simulation de production — code 0` |

## 5. Ce que cette exécution NE PROUVE PAS

| Affirmation | Statut réel |
|---|---|
| un mot de passe est réellement vérifié par **PAM** | ❌ **jamais** — `su` était un faux dans les tests |
| la session graphique X11 / openbox / WebKitGTK s'affiche | ❌ **jamais** — aucun serveur X n'a été lancé |
| une **image NexBSD** existe | ❌ **jamais** — aucune `buildworld` n'a tourné |
| l'installeur `fork/80` a été exécuté | ❌ **jamais** |
| le noyau `NEXBSD_L1` a été compilé | ❌ **jamais** |

**Phrase exacte à retenir :** *NexBSD dispose d'une chaîne de vérification qui fonctionne sur une
vraie machine FreeBSD, et d'un bureau dont la logique est testée ; aucune image NexBSD n'existe
encore et aucune session n'a jamais été affichée.*

---

## 6. Ce que cela a coûté, en toute transparence

**Cinq exécutions pour arriver au premier vert.**

| # | durée | cause | enseignement |
|---|---|---|---|
| 1 | 1m 04s | `ubuntu-latest` migré vers Ubuntu 26 | épingler la version du système |
| 2 | 38s / 53s | `git` absent de FreeBSD (C-34) | un garde-fou doit mesurer avec un instrument présent |
| 3 | 1m 27s | cause inconnue, log illisible (C-35) | **instrumenter AVANT de corriger** |
| 4 | 1m 05s | refus de root pris pour un bug (C-36) | une sécurité qui refuse n'est pas une panne |
| 5 | **1m 16s** | — | **SUCCESS** |

La leçon la plus chère est la ligne 3 : quatre corrections à l'aveugle parce que le texte de
l'erreur n'était jamais remonté. La v4 a coûté 30 minutes et a supprimé cette classe entière de
gaspillage. **Un bon diagnostic vaut plus que dix corrections.**

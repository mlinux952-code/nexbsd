# Résultat T-19 — le banc réseau est **rejouable** : `scripts/31` v3 — **RÉUSSI (à blanc)**

**Date :** 2026-10-27, ~20h15 UTC
**Objet :** supprimer la réserve n° 1 du rapport T-05a — *« `hostfwd_add` est volatil, donc la preuve n'est
pas rejouable »*. Sans cela, T-11 (reproductibilité) restait partiel pour une raison **mécanique** :
un résultat qu'on ne peut pas rejouer n'est pas une preuve.

**Nature :** validation **à blanc** du script par une **doublure de `virsh`** qui rejoue les sorties
réellement collées par le responsable pendant T-05a. Aucune VM n'a été touchée pendant les essais.

---

## 1. Ce que fait la v3

| Étape | Ce que le script fait | Pourquoi |
|---|---|---|
| 1 | lit le nom du netdev slirp avec `info network` | **jamais deviné** (leçon C-24) |
| 2 | ne l'ajoute que si `info usernet` ne le montre pas déjà | **idempotence** : rejouable à volonté |
| 3 | `hostfwd_add <netdev> tcp:127.0.0.1:4450-:445` | ajout **à chaud**, sans arrêter la VM |
| 4 | **relit** `info usernet` et exige d'y voir la redirection | le silence de QEMU n'est **pas** une preuve (leçon C-26 : ne pas confondre silence et succès) |

Options : `--reseau` (applique), `--lancer` (défaut : démarre + applique + console), `--etat`, `--stop`,
`--aide`. Variable `PORT` (défaut 4450). La redirection est **toujours bornée à `127.0.0.1`** : le partage
n'est jamais exposé au réseau domestique.

## 2. Défaut trouvé **avant** la mise en service

Premier motif de détection écrit : `grep "[.:]${PORT}[[:space:]]"`. Testé contre la sortie réelle :

```
  TCP[HOST_FORWARD] 106       127.0.0.1  4450      10.0.2.15   445     0     0
  --- detection 'deja presente' (port 4450) ---
  0
```

**Zéro détection alors que la redirection est bien là** : entre `127.0.0.1` et `4450` il y a des **espaces**,
pas un `:`. Le motif corrigé — `(^|[[:space:]])4450([[:space:]]|$)` — donne `1`, et `0` pour le port absent.
**Sans cet essai, le script aurait ajouté la règle en double à chaque exécution.**

## 3. Trois essais, sorties verbatim

### Essai A — redirection absente (doit ajouter puis prouver)

```
-> mode LIBVIRT detecte : domaine 'nexbsd-test' (etat : running)
----- redirection reseau (slirp) -----
  [OK]    netdev slirp detecte : hostnet0
  [OK]    hostfwd_add 127.0.0.1:4450 -> VM:445 (silence = succes cote QEMU)
  [OK]    redirection PROUVEE par le moniteur :
          TCP[HOST_FORWARD] 106       127.0.0.1  4450      10.0.2.15   445     0     0
          -> le partage n'est joignable que depuis CETTE station (127.0.0.1), jamais du reseau
code retour = 0
```

Commande réellement envoyée à QEMU (journal de la doublure) :

```
-c qemu:///session qemu-monitor-command nexbsd-test --hmp hostfwd_add hostnet0 tcp:127.0.0.1:4450-:445
```

### Essai B — redirection déjà présente (doit ne rien ajouter)

```
  [OK]    netdev slirp detecte : hostnet0
  [OK]    redirection 127.0.0.1:4450 -> VM:445 deja en place (rien ajoute)
  [OK]    redirection PROUVEE par le moniteur :
nombre d'appels hostfwd_add au total (doit rester 1) : 1
```

**Idempotence prouvée** : relancé deux fois, un seul `hostfwd_add`.

### Essai C — VM arrêtée (doit refuser proprement, sans rien tenter)

```
-> mode LIBVIRT detecte : domaine 'nexbsd-test' (etat : shut off)
code retour = 1
ERREUR : 'nexbsd-test' n'est pas en cours d'execution (etat : shut off)
         lancer d'abord : virsh -c qemu:///session start nexbsd-test
```

Échec **propre** : message explicite, aucune modification, code retour non nul.

## 4. Verdict

**RÉUSSI** (3 essais sur 3 à blanc, **+ détection validée sur la sortie réelle**).

### 4.1 Validation de terrain du motif de détection (2026-10-27, ~20h10 UTC)

🖥️ MINT, sortie **verbatim** :

```
$ virsh -c qemu:///session qemu-monitor-command nexbsd-test --hmp "info usernet" | grep -E "(^|[[:space:]])4450([[:space:]]|$)"

  TCP[HOST_FORWARD] 106       127.0.0.1  4450       10.0.2.15   445     0     0
```

Le motif corrigé fonctionne **sur la machine réelle**, pas seulement sur la doublure. C'est cette ligne
précise que la v3 cherche avant de décider d'ajouter ou non.

⚠️ **Ce qui reste à faire pour transformer ce succès en succès de terrain complet :** exécuter
`sh scripts/31-lancer-vm-freebsd.sh --reseau` **sur le Mint**, contre la vraie VM. Tant que ce n'est pas
fait, le test est un test **de logique et de détection**, pas encore d'exécution du script complet — et il
est consigné comme tel.

## 5. Ce que cela change pour le projet

- T-05a devient **rejouable en une commande** après chaque démarrage de VM ;
- la limite « redirection volatile » est désormais **traitée par un script**, pas par une note de bas de page ;
- le chemin reste ouvert pour un vrai réseau ponté (`bridge`) quand le banc passera sur matériel réel :
  la redirection slirp est un confort de laboratoire, **pas** l'architecture cible.

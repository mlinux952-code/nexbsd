# Résultat T-20 — horloge : synchronisation NTP armée dans la VM — **RÉUSSI (avec une réserve de délai)**

**Date :** 2026-10-27, ~20h16 UTC
**Objet :** supprimer la vraie réserve laissée par T-05a — la VM n'avait **aucune** synchronisation
automatique. Une horloge juste aujourd'hui peut dériver après une suspension, et Kerberos exige moins de
5 minutes d'écart.

**Contexte préalable (C-27) :** j'avais annoncé au responsable un « écart d'horloge de ≈ 22 minutes ». C'était
**faux** : je comparais l'heure **UTC** de la VM à l'heure **locale** de la station. Mesure propre :

```
MINT UTC   : 2026-10-27T20:13:09Z
MINT local : 2026-10-27T21:13:09 CET (+0100)
VM UTC     : 2026-10-27T20:14:45Z
VM local   : 2026-10-27T20:14:45 UTC (+0000)
```

---

## 1. Commande exécutée (🐧 VM, root@nexbsd)

```
sysrc ntpd_enable=YES; service ntpd onestart; sleep 6; ntpq -pn 2>&1 | head -8
```

## 2. Sortie verbatim

```
ntpd_enable: NO -> YES
Security policy loaded: MAC/ntpd (mac_ntpd)
Starting ntpd.
     remote           refid      st t when poll reach   delay   offset  jitter
==============================================================================
 0.freebsd.pool. .POOL.          16 p    -   64    0    0.000   +0.000   0.000
 2.freebsd.pool. .POOL.          16 p    -   64    0    0.000   +0.000   0.000
 160.119.230.39  .GNSS.           1 u    1   64    1  389.375   -5.059   0.000
 196.10.55.57    210.182.58.253   2 u    1   64    1  270.442  +21.370   0.000
```

## 3. Lecture (points sur les i)

| Élément | Signification |
|---|---|
| `ntpd_enable: NO -> YES` | `rc.conf` modifié : le service reviendra **seul** au prochain démarrage (même exigence que T-04-G) |
| `Security policy loaded: MAC/ntpd (mac_ntpd)` | politique MAC de FreeBSD : `ntpd` tourne avec des privilèges réduits, il ne peut pas changer l'heure à la légère. Effet de bord **positif** |
| `0.freebsd.pool.` / `2.freebsd.pool.` à `st 16`, `.POOL.` | entrées de **poule** ; `st 16` = « pas encore un serveur réel ». C'est le mécanisme de résolution du pool, pas une erreur |
| `160.119.230.39` `refid .GNSS.` `st 1` | serveur de **stratum 1**, temps issu d'un récepteur **GNSS** (satellite) |
| `196.10.55.57` `st 2` | second serveur, de secours, synchronisé sur un autre serveur de temps |
| **`reach 1`** | **une réponse reçue** → les paquets **UDP 123** sont sortis de la VM : traversée de `pf` (`pass out all keep state`) **et** du NAT slirp. **Première preuve de flux sortant UDP du projet** |
| `offset -5.059` / `+21.370` (ms) | écart mesuré : **millisecondes**, pas minutes. L'horloge est juste |
| **absence de `*`** | **normal à 6 secondes** : `ntpd` n'élit une référence qu'après plusieurs sondes. `reach` doit monter jusqu'à `377` en ≈ 8 minutes |

## 4. Verdict

**RÉUSSI** pour l'objectif visé : la synchronisation est **armée de façon persistante** et les serveurs de
temps sont **joignables depuis la VM** (prouvé par `reach 1` et par les `offset`).

**Réserve de délai, explicitement assumée :** l'élection de la référence (`*`) et la stabilisation de
`reach` à `377` n'ont **pas** été observées. Elles exigent plusieurs minutes. Ce test ne pourra donc être
déclaré **complet** qu'après un second relevé.

**Commande de clôture (à rejouer plus tard, aucune modification) :**

```
ntpq -pn; date -u
```

Critère de réussite complet : **un `*` devant un serveur** et `reach` ≥ `377`.

## 5. Ce que cela change pour le produit

- conditions d'une authentification « à preuve d'heure » (Kerberos) réunies côté client ;
- les preuves de test sont désormais datables de façon fiable **et vérifiable** ;
- à terme, NexBSD devra **servir** l'heure au réseau (`ntpd` en mode serveur, ou `chrony`), pour qu'une
  seule référence existe sur tout le réseau : c'est un service attendu d'un serveur de réseau local.

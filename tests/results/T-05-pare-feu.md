# T-05 / T-05a — Pare-feu `pf` : refus par défaut

**Date :** 2026-10-27 · **Verdict : RÉUSSI — `pf` actif, 11 règles, banc 24/24 sous filtrage**

---

## 1. Objet

Prouver que NexBSD refuse **par défaut** tout trafic entrant non déclaré, tout en restant **pleinement
fonctionnel** (annuaire, SMB, droits). Le critère n'est pas « le pare-feu est activé » mais **« le banc passe
toujours 24/24 avec le pare-feu actif »**.

## 2. Conditions initiales (relevées le 2026-10-27)

```
kldstat | grep -c pf   -> 0        (module non chargé)
sysctl net.inet.ip.forwarding -> 0 (la machine n'est pas un routeur : correct)
/etc/pf.conf           -> absent
```

## 3. Trois tentatives, trois corrections

| # | Version | Résultat | Cause (registre) |
|---|---|---|---|
| 1 | v1.1 | `[KO] SYNTAXE INVALIDE` — `pfctl: Failed to open netlink: No such file or directory` | **C-22** : le module `pf` était chargé **après** la validation ; sur FreeBSD 15 `pfctl` parle au noyau par netlink |
| 2 | v1.2 | `[KO] SYNTAXE INVALIDE` — `/etc/pf.conf:18: syntax error` | **C-23** : `(max 20/s, burst 10)` n'existe pas en `pf` (`max` = nombre d'états, pas un débit) |
| 3 | **v1.3** | **RÉUSSI** | — |

**Dans les trois cas, rien n'a été appliqué et `/etc/pf.conf` a été restauré automatiquement.**
Le système n'a **jamais** été modifié par un échec : c'est le rôle du garde-fou (validation à blanc).

## 4. Résultat — sortie verbatim (tentative 3)

```
############## NexBSD — L1 pare-feu pf ##############
# date : 2026-10-27T19:10:45Z ; noyau : NEXBSD_L1 15.1-NEXBSD-L1

----- 1. detection de l'interface -----
  [OK]    interface : vtnet0 (10.0.2.15)

----- 2. ecriture de /etc/pf.conf -----
  [OK]    /etc/pf.conf ecrit (      40 lignes)

----- 3. chargement des modules (prerequis de pfctl sur FreeBSD 15) -----
  [OK]    module pf deja charge
  [OK]    module pflog deja charge
  [OK]    pfctl dialogue avec le noyau

----- 4. validation A BLANC (aucune application) -----
  [OK]    syntaxe valide : pfctl -n -f accepterait ces regles

----- 5. activation -----
  [OK]    pf_enable=YES (arme au demarrage)
  [OK]    pflog_enable=YES (journalisation au demarrage)
  [OK]    service pf demarre
  ...     regles actives : 11
  ...     Status: Enabled for 0 days 00:00:00           Debug: Urgent

----- 6. PREUVE : le banc fonctionne-t-il encore ? -----
  ...     harnais utilise : /tmp/harnais2.sh
  ...     controles : 24 au total | 24 reussis | 0 en echec | 0 non applicables
  ...     HARNAIS : REUSSI (24/24 obligatoires)
  [OK]    le harnais passe TOUJOURS (le pare-feu n'a rien casse)

ETAT : PARE-FEU ACTIF — refus par defaut, ouvertures prouvees.
```

## 5. Politique appliquée

| Règle | Justification |
|---|---|
| `set skip on lo0` | ne pas filtrer la boucle locale (les services se parlent) |
| `scrub in all` | normalisation, anti-fragmentation évasive |
| **`block in log all`** | **refus par défaut, journalisé** |
| `pass out all keep state` | le système doit pouvoir sortir (mises à jour, fetch) |
| `pass ... icmp-type echoreq` / `unreach` / `timex` | diagnostic (echo) et bon fonctionnement de TCP ; `unreach`/`timex` **ne sont pas bloqués** pour ne pas casser le PMTU |
| `pass ... tcp to port 445` | SMB, prouvé par T-03 / T-04-F / T-04-G |
| `pass ... tcp to port 139` et `udp {137,138}` | NetBIOS : nécessaire pour qu'un **client Windows réel** trouve `NEXBSDFS` |
| `pass ... tcp to port 389` **sur `lo0` seulement** | LDAP : les identités ne sont **pas** exposées au réseau |
| `pass ... tcp to port 22` | administration |

**Total : 11 règles actives.** Tout le reste est **refusé et journalisé**.

## 6. Points sur les i

**Prouvé :**
- `pf` est actif (`Status: Enabled`), **11 règles** chargées, `pf_enable`/`pflog_enable` armés au démarrage ;
- le banc passe **24/24** sous filtrage : annuaire, NSS, droits, SMB, écriture/refus, le tout **derrière un refus par défaut** ;
- un échec de syntaxe **n'applique rien** (vérifié deux fois).

**Non prouvé / réserves :**
- **aucun test depuis une autre machine** : le `pass 445` n'a été validé qu'en local (`127.0.0.1`). Une
  machine distante pourrait être bloquée par une règle que nous n'avons pas vue — c'est l'objet de l'étape
  suivante (client réel) ;
- **aucun test de refus** : nous n'avons **pas** encore vérifié qu'un port fermé est bien rejeté et
  journalisé (ex. un `nc` depuis le Mint vers 8080). **C'est le complément indispensable de T-05a** ;
- limitation anti-inondation ICMP **non faite** (reportée, exige une table `overload`).

**Conséquence :** T-05 = **RÉUSSI**. T-05a (vérification que les ports fermés le sont vraiment, **depuis une
autre machine**) reste **À FAIRE**.

# Résultat T-05a — accessibilité depuis une autre machine et preuve de refus — **EN COURS**

**Date d'ouverture :** 2026-10-27, ~19h20 UTC (Tunis)
**But :** lever les deux réserves de T-05 :
1. le pare-feu n'a **jamais** été atteint depuis une autre machine ;
2. le **refus par défaut** n'a jamais été prouvé par une tentative réelle.

**Nature :** test en cours d'exécution. Ce document ne contient que ce qui a été **observé**. Aucune case n'est cochée dans `tests/plan-tests.md` tant que le test n'est pas terminé.

---

## 1. Point de départ — ce qui est déjà prouvé (T-05)

- `pf` actif, **11 règles**, `Status: Enabled` ;
- refus par défaut **journalisé** : `block in log all` ;
- ouvertures : `445/tcp`, `139/tcp`, `137-138/udp`, `22/tcp`, `389/tcp` sur `lo0` seulement, ICMP `echoreq`/`unreach`/`timex` ;
- banc 24/24 **sous filtrage** ;
- ⚠️ tout cela a été mesuré **depuis la VM elle-même** : aucun paquet n'a traversé `vtnet0` depuis l'extérieur.

## 2. Obstacle rencontré — la VM est en NAT QEMU (slirp)

Relevé réseau dans la VM (🐧 VM, root@nexbsd) :

```
vtnet0: flags=...<UP,BROADCAST,RUNNING,SIMPLEX,MULTICAST> metric 0 mtu 1500
	inet 10.0.2.15 netmask 0xffffff00 broadcast 10.0.2.255
	ether 52:54:00:e5:5e:97
net.inet.ip.forwarding = 0
```

Relevé côté station (🖥️ MINT, omrane@omrane-Inspiron-3520), sortie **verbatim** :

```
omrane@omrane-Inspiron-3520:~$ virsh -c qemu:///session dumpxml nexbsd-test | grep -A3 "interface\|redirdev\|portForward"
    <interface type='user'>
      <mac address='52:54:00:e5:5e:97'/>
      <model type='virtio'/>
      <alias name='net0'/>
--
    </interface>
    <serial type='pty'>
      <source path='/dev/pts/2'/>
      <target type='isa-serial' port='0'>
--
    <redirdev bus='usb' type='spicevmc'>
      <alias name='redir0'/>
      <address type='usb' bus='0' port='2'/>
    </redirdev>
    <redirdev bus='usb' type='spicevmc'>
      <alias name='redir1'/>
      <address type='usb' bus='0' port='3'/>
    </redirdev>
    <memballoon model='virtio'>
      <alias name='balloon0'/>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x08' function='0x0'/>
```

### Lecture (points sur les i)

| Élément | Signification |
|---|---|
| `interface type='user'` | réseau **utilisateur QEMU / slirp** : la VM sort (via `10.0.2.2`), mais **aucune connexion entrante** n'est possible sauf redirection explicite. |
| absence de `<portForward>` / `<qemu:commandline>` | **aucune redirection déclarée** dans le domaine libvirt. |
| `redirdev … spicevmc` (×2) | redirections **USB**, sans rapport avec TCP/IP. Ne pas confondre. |
| `serial type='pty'` → `/dev/pts/2` | console série = `virsh console nexbsd-test` (méthode d'accès actuelle). |

### Conséquence

`127.0.0.1:4450` utilisé avec succès en **T-03** n'existe plus : T-03 lançait QEMU à la main avec `-netdev user,hostfwd=…`. Sous libvirt, la redirection n'est pas créée automatiquement.

**Ce n'est ni une panne de `pf`, ni une régression de Samba.** C'est un défaut de **plomberie réseau côté station**.

## 3. Méthode retenue

1. Vérifier l'identifiant du netdev slirp depuis le moniteur QEMU : `info network`.
2. Ajouter **à chaud** (sans arrêter la VM, donc sans perdre `pf` ni Samba) :
   - `hostfwd_add <netdev> tcp:127.0.0.1:4450-:445` → port **déclaré** (doit passer) ;
   - `hostfwd_add <netdev> tcp:127.0.0.1:4451-:8080` → port **non déclaré** (doit être refusé par `pf`, et **vu dans `pflog`**).
3. Écouteur témoin à l'intérieur de la VM sur `8080` avant le test de refus : sans lui, un refus ne prouverait rien (on ne saurait pas distinguer « `pf` bloque » de « personne n'écoute »).
4. Client réel depuis 🖥️ MINT.

### Limite à documenter (honnêteté)

`hostfwd_add` est une commande de **moniteur** : elle **ne survit pas** à l'arrêt de la VM. Elle devra être **rejouée à chaque démarrage**, ou automatisée dans `scripts/31-lancer-vm-freebsd.sh`. Ce point sera écrit dans le rapport final, pas caché.

---

## 4. Journal d'exécution

_(à remplir au fil des commandes — sorties verbatim uniquement)_

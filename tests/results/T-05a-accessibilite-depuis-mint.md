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

## 4. Journal d'exécution (sorties verbatim)

### 4.1 Commande 1 — lecture du netdev (2026-10-27, ~20h00 UTC)

🖥️ MINT :

```
$ virsh -c qemu:///session qemu-monitor-command nexbsd-test --hmp "info network"

net0: index=0,type=nic,model=virtio-net-pci,macaddr=52:54:00:e5:5e:97
 \ hostnet0: index=0,type=user,net=10.0.2.0,restrict=off
```

Lecture : `net0` = périphérique (la carte vue par FreeBSD comme `vtnet0`, MAC identique à `ifconfig`) ;
`hostnet0` = **netdev slirp**. Aucune ligne `hostfwd` → aucun transfert entrant. Diagnostic du XML confirmé.

### 4.2 Commande 2 — création de la redirection, à chaud

🖥️ MINT :

```
$ virsh -c qemu:///session qemu-monitor-command nexbsd-test --hmp "hostfwd_add hostnet0 tcp:127.0.0.1:4450-:445"

$ (aucune sortie — silence = succès pour QEMU)
```

### 4.3 Commande 3 — `info network` : **attente erronée de ma part (C-24)**

Nouvelle sortie **identique** à 4.1 : `info network` **n'affiche jamais** les règles `hostfwd`, quelle que
soit la version de QEMU. Ce n'était donc ni un succès ni un échec de la commande 2 : c'était **mon tableau
d'attente qui était faux**. Incident consigné : ne jamais attendre `hostfwd` dans `info network` ;
la commande qui liste réellement les redirections est **`info usernet`**.

### 4.4 Commande 4 — `info usernet` : la redirection est prouvée

🖥️ MINT, sortie **verbatim** :

```
$ virsh -c qemu:///session qemu-monitor-command nexbsd-test --hmp "info usernet"

Hub -1 (hostnet0):
  Protocol[State]    FD  Source Address  Port  Dest. Address  Port RecvQ SendQ
  TCP[HOST_FORWARD] 106       127.0.0.1  4450      10.0.2.15   445     0     0
  UDP[163 sec]      105       10.0.2.15   138     10.0.2.255   138     0     0
```

- `TCP[HOST_FORWARD] 127.0.0.1:4450 → 10.0.2.15:445` : redirection active, **confinée à la station**
  (choix de sécurité : le partage n'est pas exposé au réseau domestique) ;
- `UDP … 10.0.2.15:138 → 10.0.2.255:138` : trafic NetBIOS émis par la VM, donc pile Samba réveillée.

### 4.5 Commande 5 — premier paquet entrant : transport OK

🖥️ MINT :

```
$ nc -zv -w 5 127.0.0.1 4450
Connection to 127.0.0.1 4450 port [tcp/*] succeeded!
```

`succeeded` = handshake complet → le paquet a traversé slirp, `vtnet0`, `pf` (sinon *timed out*) et
`smbd` a répondu. Preuve de **transport** seulement, pas encore de service.

### 4.6 Commande 6 — échec, dû à **mon** erreur d'identifiants (C-24)

🖥️ MINT :

```
$ smbclient //127.0.0.1/partage -p 4450 -U nexbsd%Test1234 -c 'ls'
session setup failed: NT_STATUS_LOGON_FAILURE
```

**Cause réelle :** identifiants repris de **T-03**. Or T-04 a remplacé la passdb par `ldapsam` ; les comptes
sont `omrane` et `sara`, les partages `[commun]` et `[public]`. Le compte `nexbsd` n'existe plus.
L'échec était donc **attendu**, et il est instructif : `smbd` a interrogé `ldapsam`, obtenu un refus et
répondu proprement — la chaîne d'identité était déjà vivante.
Source vérifiée dans nos propres rapports : `T-04E-samba-ldap.md:197`, `docs/25-compte-rendu-session.md:82`.

### 4.7 Commande 7 — client SMB réel : **VOLET 1 RÉUSSI**

🖥️ MINT, sortie **verbatim** :

```
$ smbclient //127.0.0.1/commun -p 4450 -U 'omrane%omranelab' -c 'ls'

  .                                   D        0  Tue Oct 27 20:10:47 2026
  ..                                  D        0  Tue Oct 27 20:10:47 2026
  apres-omrane.txt                    A       35  Mon Oct 26 20:54:31 2026
  harnais-221555.txt                  A       29  Mon Oct 26 23:15:56 2026
  harnais-221933.txt                  A       29  Mon Oct 26 23:19:33 2026
  harnais-191046.txt                  A       29  Tue Oct 27 20:10:47 2026

		5061648 blocks of size 1024. 942596 blocks available
```

**Chaîne prouvée de bout en bout, pour la première fois du projet :**

```
Mint (client SMB 4.x) -> slirp 127.0.0.1:4450 -> vtnet0 10.0.2.15:445
   -> pf (pass in ... 445/tcp) -> smbd -> ldapsam -> slapd 127.0.0.1:389 (fermé au réseau)
   -> nslcd/NSS -> groupes POSIX -> droits [commun]
```

Conséquences à retenir :

- le pare-feu **laisse passer ce qu'il doit**, et Samba **authentifie par l'annuaire** depuis l'extérieur ;
- l'annuaire reste **injoignable du réseau** (389 n'est ouvert que sur `lo0`) tout en servant les clients :
  c'est exactement l'architecture voulue — le service d'identité n'est pas exposé ;
- la réserve n° 1 de T-05 (« aucun test depuis une autre machine ») est **levée pour le cas nominal**.

### 4.8 Volet 2 — en cours

Reste à prouver le **refus** : tentative sur un port non déclaré (8080), avec écouteur témoin dans la VM
et relevé dans `pflog`.

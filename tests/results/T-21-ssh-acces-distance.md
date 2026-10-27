# Résultat T-21 — accès SSH distant sur le banc — **RÉUSSI**

**Date :** 2026-10-27, ~20h25 UTC
**Objet :** prouver que l'on peut administrer NexBSD **à distance**, par un vrai terminal, à travers le
pare-feu, avec un compte de la machine — et sur le **noyau du projet**.

---

## 1. État initial

```
root@nexbsd:~ # sockstat -4l | grep ':22 '; echo "--- sshd_enable ---"; sysrc -n sshd_enable 2>&1
--- sshd_enable ---
NO
```

`sshd` n'avait **jamais** été activé sur ce banc : ce n'était pas une panne, mais une case jamais cochée.

## 2. Activation (🐧 VM) — sortie verbatim

```
root@nexbsd:~ # sysrc sshd_enable=YES; service sshd onestart; sleep 2; sockstat -4l | grep ':22 '; ...
sshd_enable: NO -> YES
Generating RSA host key.
3072 SHA256:nsNRz/GCrgq6DtzFxEFoNd7SzusJdRt+hyeuyOM8kV4 root@nexbsd (RSA)
Generating ECDSA host key.
256 SHA256:izLFpQRoaZ9/koxyHAyXgqngOzaSVlM60ygJT2DCvj4 root@nexbsd (ECDSA)
Generating ED25519 host key.
256 SHA256:Ab/8o9q26GR8DPVwDz7fVG8iFgxoR30wXnbEaRmeWvo root@nexbsd (ED25519)
Performing sanity check on sshd configuration.
Starting sshd.
root sshd       2493  7 tcp4  *:22                  *:*
--- politique ---
(aucune ligne active : ce sont les valeurs par defaut d OpenSSH qui s appliquent)
```

**Vérification de l'écoute AVANT toute redirection** (leçon C-25 : sous slirp, une connexion « réussie » ne
prouve rien ; il faut d'abord savoir que quelqu'un écoute réellement).

## 3. Avertissement `known_hosts` — traité, pas contourné

Première connexion : `WARNING: REMOTE HOST IDENTIFICATION HAS CHANGED!`, avec
`Offending ECDSA key in /home/omrane/.ssh/known_hosts:4`.

**Analyse :** l'empreinte **reçue** (`SHA256:Ab/8o9q26GR8DPVwDz7fVG8iFgxoR30wXnbEaRmeWvo`) était **identique**
à celle affichée par la console de la VM. La cause était donc une **entrée périmée** (ancien banc à la même
adresse et au même port), pas une attaque. Traitement choisi : **supprimer l'entrée obsolète**
(`ssh-keygen -R '[127.0.0.1]:2222'`, sauvegarde `known_hosts.old` conservée) **et non** désactiver
`StrictHostKeyChecking` — on ne désarme pas le seul garde-fou contre l'homme du milieu.

## 4. Identité : un mot de passe Unix inconnu, puis posé

Trois `Password for omrane@nexbsd:` puis :

```
omrane@127.0.0.1: Permission denied (publickey,keyboard-interactive).
```

**Cause exacte :** `scripts/60-banc-T04-ldap.sh:26` crée le compte (`pw useradd -n omrane …`) **sans poser de
mot de passe** ; le secret Unix a été saisi à la main en T-04 et **n'a jamais été consigné**. Il ne s'agit
donc pas d'une perte mais d'une valeur **jamais écrite**. Ce n'est pas non plus un blocage de compte :
OpenSSH refuse la tentative, il n'y a pas de verrouillage.

**Point technique utile :** la réponse `(publickey,keyboard-interactive)` prouve que l'authentification par
mot de passe simple est désactivée et que c'est **PAM** qui valide — donc que la connexion **arrive bien
jusqu'à `sshd`**. Le transport était déjà prouvé à cet instant.

**Correctif appliqué** (🐧 VM) : `passwd omrane`, valeur **`omranelab`** (même secret que l'annuaire, pour que
le banc n'ait qu'un seul secret par compte).

## 5. Connexion réussie — sortie verbatim (🖥️ MINT)

```
omrane@omrane-Inspiron-3520:~$ ssh -p 2222 omrane@127.0.0.1
(omrane@127.0.0.1) Password for omrane@nexbsd:
FreeBSD 15.1-NEXBSD-L1 NEXBSD_L1

Welcome to FreeBSD!
...
omrane@nexbsd:~ $
```

## 6. Ce qui est prouvé

| # | Preuve | Statut |
|---|---|---|
| 1 | `pf` règle `pass in ... port 22` **éprouvée depuis l'extérieur** | ✅ jamais testée auparavant |
| 2 | `sshd` + PAM + compte `omrane` fonctionnels | ✅ |
| 3 | session ouverte **sur `15.1-NEXBSD-L1`** (`NEXBSD_L1`), le noyau du projet | ✅ |
| 4 | terminal utilisable (copier-coller, historique) à la place de `virsh console` | ✅ |
| 5 | empreinte d'hôte **vérifiée à l'œil** contre la console | ✅ |

## 7. Défaut produit relevé (à ne pas laisser passer)

L'écran d'accueil annonce encore :

```
Welcome to FreeBSD!
Release Notes, Errata: https://www.FreeBSD.org/releases/
```

**Devant un utilisateur, NexBSD se présente comme FreeBSD.** L'invite est correcte (`omrane@nexbsd`), le
message d'accueil ne l'est pas. C'est un reste de **T-16 étage 1** : le nom d'hôte a été changé, pas
`/etc/motd`. À corriger avant toute démonstration — c'est la première chose que voit celui qui se connecte.

## 8. Deux autorités d'identité, assumées

- **Samba/LDAP (`ldapsam`)** valident les accès **aux fichiers** (prouvé T-04-E/F/G, T-05a) ;
- **Le compte Unix local** valide la **session SSH**.

Le mot de passe a été **aligné à la main** : cela débloque le banc mais **ne démontre pas** l'identité unique.
Le chantier réel — faire interroger l'annuaire par **PAM/NSS** pour les sessions système — est ouvert et
consigné. À ne pas confondre avec un succès.

## 9. Suites immédiates

1. **clé SSH** (`ssh-copy-id`) → la connexion ne dépendra plus d'un mot de passe ;
2. puis `PermitRootLogin no` et `PasswordAuthentication no` — **seulement après** que la clé fonctionne ;
3. corriger `/etc/motd` (identité NexBSD) ;
4. chantier **identité PAM/LDAP**.

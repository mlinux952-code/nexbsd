# Résultat T-03 — partage Samba accessible depuis une autre machine — **RÉUSSI (cœur)**

**Date d'exécution :** 2026-10-23, 21h05 → 21h20
**Nature :** deuxième test réellement exécuté du projet.

---

## 1. Ce qui a été installé (dans la VM, depuis les dépôts officiels)

| Étape | Commande | Résultat observé |
|---|---|---|
| dépôts | `pkg update -f` | **38 288 paquets** (FreeBSD-ports) + 509 (FreeBSD-base) traités |
| version de pkg | `pkg -v` | **2.6.2** |
| Samba | `pkg install -y samba423` | **samba423-4.23.11_3**, 80 paquets, 104 Mio téléchargés, 605 Mio installés |

Durée de l'installation : **≈ 4 min 30** en émulation TCG.

## 2. Configuration testée

```
[global]
   workgroup = NEXBSD
   server string = NexBSD VM
   security = user
   passdb backend = tdbsam
   server min protocol = SMB2
   disable netbios = yes
[partage]
   path = /srv/partage
   read only = no
   valid users = nexbsd
```

- `testparm -s` → **aucune erreur** ;
- utilisateur Unix `nexbsd` créé (`pw useradd`), mot de passe Samba posé (`smbpasswd -s -a`), `pdbedit -L` → `nexbsd:1001:User &` ;
- `service samba_server onestart` → `smbd`, `nmbd`, `winbindd` démarrés ; `sockstat` → **smbd à l'écoute sur `*:445` (tcp4 et tcp6)**.

## 3. Le test qui compte : **accès depuis une machine différente**

La VM est en réseau utilisateur QEMU avec redirection `127.0.0.1:4450 → VM:445`.
Le client est **Debian (hors VM)**, `smbclient 4.22.11` :

```
$ smbclient //127.0.0.1/partage -p 4450 -U nexbsd%Test1234 -c 'ls; put /tmp/preuve-linux.txt preuve-linux.txt; ls'
  .                                   D        0  Fri Oct 23 21:11:54 2026
  ..                                  D        0  Fri Oct 23 21:11:54 2026
  lisez-moi.txt                       N       15  Fri Oct 23 21:11:54 2026
putting file /tmp/preuve-linux.txt as \preuve-linux.txt
  preuve-linux.txt                    A       62  Fri Oct 23 21:18:06 2026
```

Puis, **relu dans la VM** :

```
root@freebsd:~ # cat /srv/partage/preuve-linux.txt
fichier ecrit depuis la station Linux le 2026-10-23T21:16:53Z
```

➡️ **Aller-retour complet** : listing authentifié, écriture depuis une autre machine, relecture côté serveur, contenu identique.

## 4. Deux échecs rencontrés — et ce qu'ils apprennent

| Symptôme | Cause | Correction |
|---|---|---|
| `NT_STATUS_ACCESS_DENIED` à l'écriture | `/srv/partage` appartenait à `root`, l'utilisateur Samba n'y avait pas droit ; `read only = no` ne suffit pas | `chown -R nexbsd:nexbsd /srv/partage` |
| `NT_STATUS_CONNECTION_RESET` au premier essai | `smbd` n'était pas démarré après le redémarrage (service lancé en `onestart`, pas activé au boot) | `service samba_server onestart` — et **prévoir `sysrc` dans le système final** |

**Leçon pour NexBSD :** ces deux erreurs sont exactement celles que rencontrera un utilisateur non technicien. L'outil d'administration (N-08) doit les rendre impossibles : droits corrects à la création d'un partage, service activé au démarrage par défaut.

## 5. Ce qui n'est **pas** testé

- L'authentification par **annuaire** (OpenLDAP) : non installé, non testé (T-04).
- Les **ACL** fines et l'héritage de droits (N-02).
- L'**impression** (N-07).
- La persistance après redémarrage propre (le service n'était pas activé au boot).
- Les performances : aucun débit mesuré.

## 6. Verdict

**RÉUSSI pour le cœur de EF-N-01** (partager un répertoire, y écrire, le relire depuis une autre machine), **NON EXÉCUTÉ** pour EF-N-02 (droits par utilisateur) et tout le reste de la chaîne.

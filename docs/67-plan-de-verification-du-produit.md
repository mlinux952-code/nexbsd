# 67 — Le plan de vérification complet de NexBSD : quels outils, où, et ce qu'ils prouvent

> **Question du responsable (2026-10-30) :** *« waw, maintenant qu'on peut télécharger, on peut
> vérifier tout NexBSD avec tous les machins des images que j'ai proposées hier ? C'est-à-dire
> tous ? »*
>
> **Réponse courte : oui, mais pas « tous », et pas dans n'importe quel ordre.**
>
> Sur **~110 outils** cités par les neuf affiches, **une dizaine** servent réellement à vérifier
> NexBSD. **Aucun** ne tourne sur NexBSD lui-même s'il est offensif. Et surtout :
>
> **rien de tout cela ne peut commencer avant que l'image ne démarre.** Un système éteint ne se
> vérifie pas.

---

## 1. L'ordre est non négociable

| # | Étape | État |
|---|---|---|
| **0** | Télécharger `nexbsd.img.gz` (478 Mo, reprenable) | ⏳ à faire demain |
| **0 bis** | **Vérifier le fichier lui-même** (sha256, intégrité gzip, table de partitions) | ⏳ **sans démarrer**, faisable tout de suite |
| **1** | **DÉMARRER** l'image dans une VM | ⏳ **le seul vrai inconnu du projet** |
| **2** | Vérifier **de l'extérieur** (depuis MINT) : ports, silence, bannière | ⏳ `scripts/76`, écrit aujourd'hui |
| **3** | Vérifier **de l'intérieur** : `pkg audit`, `sysctl`, `freebsd-update IDS` | ⏳ après démarrage |
| **4** | Vérifier **les fonctions** : partage SMB, annuaire, session, lecteurs réseau | ⏳ demande `fork/80`, jamais exécuté |

**Si l'étape 1 échoue, les étapes 2 à 4 n'existent pas.** C'est pour cela que tout le projet attend
ce démarrage.

---

## 2. Étape 0 bis — ce qu'on peut vérifier **sans rien démarrer**

C'est le seul contrôle possible dès ce soir, et il est déjà utile :

```bash
sha256sum nexbsd.img.gz
# attendu : 8188cba28038884e2ac075c89581132ba27cb5852b1ad765207ee01d599e0d7b

gzip -t nexbsd.img.gz && echo "archive intacte"
gunzip -k nexbsd.img.gz && ls -lh nexbsd.img
# attendu : 2,3 Go

file -b nexbsd.img
# DOS/MBR boot sector  ou  GUID Partition Table  -> le disque est amorçable
```

**Ce que cela prouve :** le fichier est complet, non corrompu, et **contient une table de
partitions** (donc `mkimg` a réellement fabriqué un disque, et non un simple système de fichiers).

**Ce que cela ne prouve pas :** qu'il démarre.

---

## 3. Étape 2 — la vérification **de l'extérieur** (le nouvel outil `scripts/76`)

C'est ici que les affiches servent enfin, **mais pas comme elles le suggèrent**.

> ### La règle, en une ligne
> **Les outils offensifs tournent SUR LA MACHINE QUI MESURE, JAMAIS sur la machine MESURÉE.**

`scripts/76-verifier-produit-distant.sh` s'exécute **sur MINT**, vise l'adresse IP de NexBSD, et
**constate** sans attaquer :

| Contrôle | Ce qu'il prouve |
|---|---|
| ping | la machine est vivante |
| ports **445 / 139** ouverts | le service de fichiers écoute |
| **22 ports interdits** fermés (telnet 23, ftp 21, tftp 69, RDP 3389, VNC 5900, messagerie, bases de données, NFS) | la surface d'attaque est bien celle du produit, pas celle d'un serveur bavard |
| **un port fermé est MUET** (silence, pas de refus) | `net.inet.tcp.blackhole=2` (A-74) est **réellement actif** — un scan devient long et repérable |
| SSH refuse les mots de passe | `sshd_config.nexbsd` est appliqué |
| SMB1 non proposé | `server min protocol` (C-48) est en place |

**Déjà testé au banc ce matin :** il refuse proprement une cible absente (« sans machine vivante, le
reste du contrôle n'a aucun sens : on s'arrête ») au lieu de produire un faux rapport.

**D'où viennent ces outils :** `nmap` (affiche 1 et 7), `tcpdump`/`wireshark` (affiche 8) — **sur
MINT uniquement**. C'est exactement **T-05a** : la règle `block in log all` n'a été crue que parce
qu'elle a été mesurée **depuis une autre machine**.

---

## 4. Étape 3 — la vérification **de l'intérieur** (à écrire, sur la machine NexBSD)

| Contrôle | Outil | Vient de | Ce qu'il prouve |
|---|---|---|---|
| vulnérabilités des paquets | **`pkg audit -F`** | affiche 1 | aucun paquet installé n'a de CVE connue — déjà intégré au bureau (**A-67**) |
| réglages noyau appliqués | `sysctl security.bsd.see_other_uids` | affiche 8 | `sysctl.conf` (**A-74**) est bien lu au démarrage |
| **intégrité du système** | **`freebsd-update IDS`** | affiche 8 | **chaque fichier du système correspond à son empreinte connue** |
| intégrité des paquets | `pkg check -a` | affiche 8 | les binaires installés n'ont pas été modifiés |
| permissions des fichiers | `mtree -f /etc/mtree/BSD.usr.dist -p /usr` | affiche 8 | les droits n'ont pas été altérés |
| politique de mot de passe | `john` **sur une copie des hashes, sur MINT** | affiches 4 et 8 | la politique résiste — **jamais sur le serveur** |

**`freebsd-update IDS` est le contrôle le plus fort de toute la liste**, et il ne vient d'aucune
affiche Linux : c'est un outil **natif de FreeBSD**. Contrairement à `rkhunter`, qui compare à des
*signatures*, il compare à **l'empreinte exacte** : une modification d'un octet est signalée.

**Et il se combine avec l'ADR-0021 :** avec une racine en lecture seule, **toute différence détectée
est une anomalie certaine** — plus de faux positifs dus aux fichiers légitimement modifiés.

---

## 5. Étape 4 — la vérification **des fonctions** (après `fork/80`)

| Fonction | Comment on la prouve | État |
|---|---|---|
| partage SMB authentifié | un client réel lit un fichier | config écrite, **serveur jamais installé** |
| annuaire OpenLDAP | `ldapsearch` depuis un poste | idem |
| session graphique | ouvrir le bureau, saisir un mot de passe | jamais affiché |
| **lecteurs réseau (A-68)** | ouvrir une session, voir `H:` et `P:` | logique testée, **jamais branchée** |
| console d'administration (N-08) | xrdp depuis un poste Windows | décidé, **non installé** |

**C'est le cœur du produit, et c'est entièrement à faire.** Aucun outil de vérification ne remplace
cela : **on ne prouve pas un serveur de fichiers sans client.**

---

## 6. Ce qu'on ne fera **jamais** sur NexBSD, quoi qu'en disent les affiches

| Outil | Pourquoi jamais sur le serveur | Où il sert |
|---|---|---|
| **hydra, medusa, ncrack, brutus** | ce sont des casseurs de mots de passe ; les installer ferait signaler NexBSD comme suspect par tout antivirus, à juste titre | nulle part, pour l'instant |
| **hashcat, john, rainbowcrack, ophcrack** | cassage de hash | **MINT**, sur une **copie** des hashes, pour éprouver notre politique |
| **metasploit, sqlmap, burp, beEF** | exploitation | **nulle part** : NexBSD n'a ni site web, ni base SQL, ni navigateur client |
| **aircrack, droidhunter** | Wi-Fi, Android | **nulle part** : hors sujet |
| **openvas/greenbone** | 50 000 tests réseau, métier à part entière | éventuellement sur MINT, un jour |
| **rkhunter, chkrootkit** | signatures, aveugles à une porte dérobée sur mesure | **remplacés** par `freebsd-update IDS` + `mtree` |

---

## 7. Le tableau final : les ~110 outils, ramenés à 11

| Où | Outil | Rôle |
|---|---|---|
| **MINT** | `nmap` | prouver de l'extérieur que les ports sont ceux du produit |
| **MINT** | `tcpdump` / `wireshark` | voir ce qui circule réellement |
| **MINT** | `scripts/76` | le contrôle extérieur complet, écrit aujourd'hui |
| **MINT** | `john` (plus tard) | éprouver la politique de mot de passe sur une copie |
| **NexBSD** | `pkg audit -F` | **aucune CVE** dans les paquets |
| **NexBSD** | `sysctl -a` | les réglages noyau sont appliqués |
| **NexBSD** | **`freebsd-update IDS`** | **intégrité exacte du système** |
| **NexBSD** | `pkg check -a` | intégrité des paquets |
| **NexBSD** | `mtree` | intégrité des permissions |
| **NexBSD** | `ipfw`/`tcpdump` local | vérifier ce qui entre réellement |
| **CI (GitHub)** | `scripts/70/72/74/75` | delta, registre, simulation, **durcissement** — déjà verts |

**Onze outils. Pas cent dix.** Et **aucun** d'entre eux ne remplace l'essentiel : **démarrer et faire
fonctionner**.

---

## 8. Ce que je proposerai demain, dès que l'image démarre

1. `sh scripts/76-verifier-produit-distant.sh <ip>` **depuis MINT** → le premier vrai rapport de
   sécurité de NexBSD ;
2. `pkg audit -F` et `sysctl` **dans la VM** ;
3. `freebsd-update IDS` → la première empreinte d'intégrité du produit ;
4. et ensuite seulement, `fork/80-installer-nexbsd.sh` pour installer Samba et l'annuaire.

**Acquis : A-78** — plan de vérification complet, `scripts/76` écrit et testé au banc.

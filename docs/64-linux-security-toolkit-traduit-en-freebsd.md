# 64 — « Linux Security Toolkit » : la traduction en FreeBSD, et le piège qu'elle révèle

> **Image n° 8 du responsable (2026-10-29).** Sept catégories, **21 outils**, tous Linux.
>
> **C'est la plus utile des huit** — non pas pour ses outils, dont **aucun ne s'installe tel quel**,
> mais parce qu'elle pose la bonne question : *« que font SELinux, Grsecurity et AppArmor ? »*.
> FreeBSD a des réponses **meilleures et plus anciennes** à cette question, et l'une d'elles nous a
> fait découvrir **une interaction dangereuse entre deux fonctions que nous avons déjà écrites**.
>
> **Résultat concret du soir : un fichier du produit de plus** (`fork/overlay/etc/sysctl.conf`,
> 13 réglages) et **le trou C-48 réduit de 4 à 3 éléments absents**.

---

## 1. La traduction, catégorie par catégorie

### 1.1 Secure Shell — SSHGuard, DenyHosts, Fail2ban

Les trois font la même chose : **bannir une adresse après trop d'échecs de connexion**.

| Outil de l'affiche | FreeBSD ? | Verdict NexBSD |
|---|---|---|
| **SSHGuard** | ✅ `security/sshguard` (C, très léger) | **meilleur des trois** pour un profil « PC faible » |
| **Fail2ban** | ✅ `security/py-fail2ban` | fonctionne, mais **Python** : lourd à côté de sshguard |
| **DenyHosts** | ❌ **Python 2**, projet mort depuis ~2015 | **refusé** : ne se maintient plus |

**Mais voici la vraie réponse, et elle est meilleure que les trois :** **pf sait le faire seul.**

```
table <bruteforce> persist
block in quick from <bruteforce>
pass in on $iface proto tcp to port 22 keep state \
     (max-src-conn-rate 3/60, overload <bruteforce> flush global)
```

**Trois lignes, zéro programme supplémentaire, zéro démon à surveiller.** C'est l'esprit de
NexBSD : *moins de pièces mobiles*. **Décision : protection par tables pf d'abord ; sshguard
seulement si le besoin dépasse pf.**

⚠️ **Et une remarque importante :** cette protection n'a de sens que si SSH est accessible. Or
`rc.conf.defaults` contient **`sshd_enable="NO"`** (R-13 : aucun accès entrant par défaut). **La
protection anti-force-brute est donc, aujourd'hui, sans objet** — c'est une bonne nouvelle, mais il
faut la garder prête pour le jour où l'administrateur activera SSH.

### 1.2 VPN — IPsec, OpenVPN, WireGuard

**C'est la catégorie la plus utile de l'image, et elle répond directement à C-47.**

| Outil | FreeBSD ? | Verdict |
|---|---|---|
| **IPsec** (IKEv2) | ✅ **dans le noyau** | puissant, mais **notoirement difficile à configurer** |
| **OpenVPN** | ✅ `security/openvpn` | éprouvé, mais SSL lourd |
| **WireGuard** | ✅ `net/wireguard-kmod` | **retenu** : moderne, peu de code, rapide |

**Pourquoi c'est décisif :** notre décision sur le bureau à distance (`docs/61`) dit *« jamais 3389
ni 5900 exposés en direct, passer par un tunnel SSH »*. C'est bon pour **un** administrateur. Mais
pour **une entreprise** dont plusieurs personnes doivent accéder au serveur depuis l'extérieur, la
bonne réponse est **le VPN** : le serveur reste **invisible depuis Internet**, et seuls les membres
du VPN le voient.

**Décision : WireGuard devient le moyen d'accès distant à NexBSD** (nouvelle exigence à créer).
Le serveur n'ouvre **aucun port** vers l'extérieur ; le VPN ouvre un chemin privé.

### 1.3 Password Security — pwgen, John the Ripper

| Outil | FreeBSD ? | Verdict |
|---|---|---|
| **pwgen** | ✅ `sysutils/pwgen` | 🔜 **utile à l'installation** : générer le mot de passe initial de l'administrateur au lieu d'en choisir un faible |
| **John the Ripper** | ✅ `security/john` | ❌ **jamais dans le produit** ; ✅ **sur MINT**, pour **prouver** que notre politique de mot de passe résiste |

**Et c'est précisément le trou C-48 :** il n'existe **aucune politique de mot de passe** dans
NexBSD. Le jour où elle existera, **John the Ripper sera l'instrument qui la vérifie** — sur une
copie des hashes, dans le laboratoire, jamais sur le serveur.

### 1.4 Network Monitoring — Wireshark, Arkime, tcpdump

| Outil | FreeBSD ? | Verdict |
|---|---|---|
| **tcpdump** | ✅ **dans le système de base** — rien à installer | ✅ **notre instrument** (déjà utilisé pour T-05a) |
| **Wireshark** | ✅ `net/wireshark` | ✅ sur **MINT** seulement |
| **Arkime** | ❌ architecture lourde (Elasticsearch + Java) | **refusé** : hors de portée d'un « PC faible » |

### 1.5 Security Hardening — SELinux, Grsecurity, AppArmor

**C'est ici que l'affiche est la plus utile, et de façon inattendue : les trois sont Linux, et
FreeBSD a des équivalents plus anciens.**

| Outil Linux | Équivalent FreeBSD | Ce qu'il fait |
|---|---|---|
| **SELinux** | **cadre MAC** : `mac_bsdextended` (règles type ACL système), `mac_seeotheruids`, `mac_portacl` (limiter qui peut ouvrir quel port) | contrôle d'accès obligatoire |
| **Grsecurity** | **`PAX`/`ASLR` natif + `kern.securelevel`** | durcissement du noyau |
| **AppArmor** | **Capsicum** (mode capacité) + **jails** | enfermer un programme dans un périmètre |
| — | **`/etc/sysctl.conf`** | les réglages de noyau qui rendent les processus invisibles entre eux |

**C'est de là que vient le fichier livré ce soir.** `fork/overlay/etc/sysctl.conf`, 13 réglages,
chacun expliqué en une phrase :

| Réglage | Effet |
|---|---|
| `security.bsd.see_other_uids=0` / `see_other_gids=0` | un utilisateur ne voit plus les processus des autres |
| `security.bsd.unprivileged_read_msgbuf=0` | `dmesg` fermé aux utilisateurs ordinaires |
| `security.bsd.unprivileged_proc_debug=0` | pas d'inspection de la mémoire d'autrui |
| `security.bsd.hardlink_check_uid/gid=1` | attaque par lien physique dans `/tmp` bloquée |
| `kern.sugid_coredump=0` | un programme setuid qui plante n'écrit pas ses secrets |
| `kern.randompid=1` | numéros de processus imprévisibles |
| `net.inet.tcp.blackhole=2` / `udp.blackhole=1` | un port fermé reste **muet** |
| `net.inet.tcp.syncookies=1` | inondation de connexions absorbée |
| `net.inet.icmp.drop_redirect`, `ip.redirect`, `sourceroute`, `accept_sourceroute` | détournement de trafic refusé |

Chacun est **explicable en une phrase** — c'est la règle que j'ai suivie : *un durcissement
incompris sera désactivé au premier incident.*

### 1.6 Rootkit Detection — chkrootkit, Lýnis, rkhunter

**Une correction factuelle sur l'affiche :** **Lynis n'est pas un détecteur de rootkit**, c'est un
outil d'**audit** de configuration. Le classement est faux.

| Outil | FreeBSD ? | Verdict |
|---|---|---|
| **chkrootkit** | ✅ `security/chkrootkit` | possible, mais compare à des **signatures** : aveugle à une porte dérobée sur mesure |
| **rkhunter** | ✅ `security/rkhunter` | idem, plus lourd |
| **Lynis** | ✅ `security/lynis` | audit, pas détection |

**Mais FreeBSD a une réponse supérieure, et native :**

| Mécanisme FreeBSD | Ce qu'il fait | Pourquoi c'est meilleur |
|---|---|---|
| **`freebsd-update IDS`** | compare **chaque fichier du système** à son empreinte connue | ce n'est pas une signature : c'est **l'empreinte exacte**. Une modification, même d'un octet, est signalée |
| **`mtree`** (`/etc/mtree`) | arborescence de référence avec tailles, droits, empreintes | vérifie aussi les **permissions**, qu'un rootkit change souvent |
| **`pkg check -a`** | vérifie l'intégrité des paquets installés | couvre **notre** code, pas seulement FreeBSD |

**Et cela se combine parfaitement avec l'ADR-0021 :** avec une racine en lecture seule, **toute
différence détectée par `freebsd-update IDS` est une anomalie certaine** — plus de faux positifs dus
aux fichiers légitimement modifiés.

**Décision : `freebsd-update IDS` + `mtree` + `pkg check -a`, pas de rkhunter.** Trois commandes du
système valent mieux que trois paquets de plus.

### 1.7 Security Auditing — OpenSCAP, OpenVAS, Nmap

| Outil | FreeBSD ? | Verdict |
|---|---|---|
| **Nmap** | ✅ `security/nmap` | ✅ **notre instrument de mesure** — c'est **T-05a** : la règle `block in log all` n'est crue que parce qu'elle a été **mesurée depuis une autre machine** |
| **OpenSCAP** | ❌ très orienté RHEL | **refusé** — **nous avons `scripts/75`**, qui dit exactement ce que *nous* voulons vérifier |
| **OpenVAS / Greenbone** | ❌ pile énorme (milliers de tests réseau) | **refusé** : c'est un métier à part entière, pas une fonction de serveur de fichiers |

---

## 2. Le piège découvert — et c'est le vrai apport de cette image

En écrivant `sysctl.conf`, il a fallu se demander **où** placer `kern.securelevel`. La réponse
correcte sur FreeBSD est **dans `rc.conf`** (`kern_securelevel_enable`, `kern_securelevel`), et non
dans `sysctl.conf` — sinon il s'applique **pendant le démarrage** et empêche les montages.

**Et là, une conséquence que personne n'avait vue :**

> **Au niveau de sécurité 1, plus aucun module noyau ne peut être chargé après le démarrage.**
> Or `mount_smbfs`, qui branche les **lecteurs réseau** écrits aujourd'hui (**A-68**), a besoin du
> module **`smbfs`**.

**Sans précaution, relever le niveau de sécurité casserait les lecteurs réseau.** Deux fonctions
écrites le même jour, dans deux documents différents, qui **se nuisent** l'une à l'autre.

**La correction, une ligne :**

```
# dans /etc/rc.conf
kern_securelevel_enable="YES"
kern_securelevel="1"
kld_list="smbfs"          # ← obligatoire : chargé AVANT que le niveau ne monte
```

**C'est noté dans `sysctl.conf` lui-même** (section « ce qui n'est pas ici, et pourquoi »), dans
`docs/64`, et **il faudra le vérifier sur la machine réelle** — le jour où elle démarrera.

**Ce piège ne vient d'aucun outil de l'affiche.** Il vient d'avoir cherché *où* poser un réglage
que l'affiche suggérait.

---

## 3. Ce qui a été livré ce soir, et ce qui ne l'a pas été

| | |
|---|---|
| ✅ **`fork/overlay/etc/sysctl.conf`** | 13 réglages, chacun justifié, avec les trois exclusions argumentées |
| ✅ **`scripts/75` enrichi** | 2 contrôles de plus : les 8 protections de noyau, et le **piège d'ordonnancement** de `securelevel` |
| ✅ **Résultat mesuré** | **19 protections correctes** (contre 17), **0 faiblesse**, **3 éléments absents** (contre 4) |
| ❌ **Aucun outil de l'affiche n'a été installé** | ni sshguard, ni fail2ban, ni rkhunter, ni WireGuard |
| ❌ **Aucune règle pf ajoutée** | la protection anti-force-brute n'a pas d'objet tant que SSH est désactivé (R-13) |

**Le trou C-48 est réduit de 4 à 3 :** il reste `login.conf` (politique de mot de passe — **le plus
grave**), `server min protocol` dans Samba, et `AllowUsers` dans SSH.

---

## 4. Les nouvelles décisions à porter au cahier des charges

| Exigence proposée | Contenu | Priorité |
|---|---|---|
| **Protection anti-force-brute par pf** | tables `bruteforce` sur SSH et SMB, **sans démon supplémentaire** | à écrire quand SSH sera activé |
| **Accès distant par VPN WireGuard** | le serveur n'ouvre **aucun** port vers Internet ; le VPN ouvre un chemin privé | **haute** — complète `docs/61` |
| **Intégrité par les outils natifs** | `freebsd-update IDS`, `mtree`, `pkg check -a` — au lieu de rkhunter | à brancher avec l'ADR-0021 |
| **`pwgen` à l'installation** | générer le mot de passe initial plutôt que le laisser choisir | basse |

---

## 5. Récapitulatif : huit images, et ce qu'il en reste

| Image | Sujet | Ce qu'elle a **réellement** produit |
|---|---|---|
| 1 | Protocoles réseau | 19 décisions écrites ; **NTP → N-05** découvert |
| 2-3 | Bureau à distance | **xrdp** choisi, réutilise `nexbsd-session` |
| 4 | Casseurs de mots de passe | **`scripts/75`** créé |
| 5 | Cybersécurité IA | Suricata, osquery candidats |
| 6 | Distributions immuables | **ADR-0021** |
| 7 | Outils Kali | Nmap et tcpdump confirmés comme instruments |
| **8** | **Linux Security Toolkit** | **`sysctl.conf` livré** + **piège `securelevel`/`smbfs` découvert** |

**Sur ~110 outils cités par les huit affiches : 1 fichier du produit, 1 script, 1 ADR, 4 exigences
nouvelles, 2 défauts trouvés — et 0 outil installé.**

**Acquis : A-74** (`sysctl.conf` + 2 contrôles) · **A-75** (traduction FreeBSD des 7 catégories) ·
**C-48 réduit**.

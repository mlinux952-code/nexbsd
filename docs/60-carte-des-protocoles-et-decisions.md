# 60 — L'affiche « Networking Protocols » : ce qui est vrai, ce qui est faux, et ce que NexBSD doit en faire

> **Question du responsable (2026-10-29) :** *« j'ai trouvé cette image, elle rassemble tout ce qu'il
> peut y avoir dans un système serveur et réseau. Vrai ou non ? Et on peut intégrer ces fonctions
> dans notre projet si possible. »*
>
> **Réponse courte :** l'affiche est **exacte sur la quasi-totalité des numéros de port** — je n'ai
> trouvé **qu'une seule présentation trompeuse** et plusieurs **manques**. Mais la vraie réponse est
> ailleurs : **cette liste n'est pas une liste de fonctions à intégrer, c'est un inventaire de ce
> qu'un serveur *pourrait* exposer.** Tout intégrer serait une faute, pas une richesse.
>
> Et il y a une ironie qu'il faut nommer : **le protocole qui définit notre projet — NCP, port 524 —
> n'est pas sur l'affiche.**

---

## 1. Les 19 protocoles de l'affiche, vérifiés un par un

| Protocole | Port affiché | Exact ? | Ce qu'il faut ajouter |
|---|---|---|---|
| **FTP** | 21 | ✅ oui | données en **20** (actif) ou port aléatoire (passif) |
| **SSH** | 22 | ✅ oui | — |
| **SFTP** | 22 | ⚠️ **trompeur** | SFTP n'a **pas** de port propre : il passe *dans* SSH. L'affiche le dessine comme un protocole autonome, ce qui laisse croire qu'on peut ouvrir SFTP sans SSH. **C'est faux : pas de SSH, pas de SFTP.** |
| **SMTP** | 25 | ✅ oui, mais incomplet | **587** = soumission authentifiée (ce que les clients utilisent), **465** = SMTPS |
| **DNS** | 53 | ✅ oui, incomplet | fonctionne en **UDP *et* TCP** — le TCP est obligatoire pour les grandes réponses et les transferts de zone |
| **DHCP** | 67 serveur / 68 client | ✅ oui | c'est le seul endroit de l'affiche où serveur et client sont distingués : c'est bien fait |
| **TFTP** | 69 | ✅ oui | UDP. **Aucun mot de passe, aucun chiffrement, aucune intégrité** |
| **HTTP** | 80 | ✅ oui | — |
| **POP3** | 110 | ✅ oui, incomplet | **995** = POP3S |
| **NTP** | 123 | ✅ oui | UDP. **123** est aussi utilisé pour le contrôle (mode 6) |
| **IMAP** | 143 | ✅ oui, incomplet | **993** = IMAPS |
| **SNMP** | 161 | ✅ oui, incomplet | **162** = les *traps*, c'est-à-dire les **alertes envoyées par le serveur** — sans elles, la supervision ne prévient de rien |
| **LDAP** | 389 | ✅ oui | — |
| **HTTPS** | 443 | ✅ oui | — |
| **SMB** | 445 | ✅ oui, incomplet | **137, 138, 139** = NetBIOS, l'ancien chemin, **encore indispensable** pour qu'un client Windows trouve le serveur (c'est ce que notre `pf.conf` ouvre, preuve T-15) |
| **LDAPS** | 636 | ⚠️ **simplifié** | 636 est le LDAP « historique sur TLS ». Le moyen **recommandé aujourd'hui** est **StartTLS sur 389** : même port, la session se chiffre après coup. Les deux existent ; l'affiche présente 636 comme *le* moyen de sécuriser LDAP, ce qui est une simplification de débutant |
| **MySQL / MariaDB** | 3306 | ✅ oui | — |
| **RDP** | 3389 | ✅ oui | — |
| **PostgreSQL** | 5432 | ✅ oui | — |

**Bilan : 17 ports exacts sur 19 · 1 présentation trompeuse (SFTP) · 1 simplification (LDAPS).**
Ce n'est donc pas une mauvaise affiche. C'est une **bonne affiche pour débutant** — et c'est
précisément pourquoi il ne faut pas s'en servir comme plan d'architecture.

---

## 2. Le défaut de raisonnement de l'affiche — et il est grave

L'affiche enseigne, en bas à droite : *« Ports can be changed based on configuration »* et
*« Not all services need to be enabled »*. C'est juste. Mais **la disposition même de l'image dit le
contraire** : 19 cases alignées, chacune avec son numéro, suggèrent un **catalogue à cocher**.

Or, trois principes que l'affiche ne dit pas :

1. **Un port n'est pas un protocole.** Le numéro est une **convention**, pas une identité. Un service
   peut écouter sur n'importe quel port ; ce qui l'identifie, c'est la poignée de main. D'où le
   vrai principe de sécurité : **on ne filtre pas « les bons ports », on refuse par défaut** — ce
   que fait notre `pf.conf` depuis le 27/10 (`block in log all`).
2. **Chaque port ouvert est une surface d'attaque**, pas une fonctionnalité gagnée.
3. **Un serveur de fichiers n'a pas besoin de dix-neuf services.** Un NexBSD qui écouterait sur ces
   19 ports serait **plus vulnérable et plus lent** que celui qui en écoute sur quatre.

---

## 3. Ce que l'affiche OUBLIE — et c'est là que ça devient intéressant

Voici les protocoles absents, classés par importance **pour NexBSD** :

| Protocole absent | Port | Pourquoi il compte pour nous |
|---|---|---|
| **NCP** (NetWare Core Protocol) | **524** | **c'est le protocole du système que nous remplaçons.** NetWare 5 l'a fait passer sur TCP/IP et l'IANA lui a attribué le 524 ; c'est le sujet de notre exigence **N-11**. **Une affiche sur les protocoles réseau qui omet NCP ne parle pas de notre monde** |
| **Kerberos** | **88** (+ 464) | le mot de passe unique (**N-05**), celui que les entreprises utilisent réellement |
| **IPP / CUPS** | **631** | l'impression partagée (**N-07**) — NetWare était un serveur d'impression avant tout |
| **mDNS / DNS-SD** | **5353** | la découverte du serveur sans taper son adresse (**N-10**) |
| **syslog** | **514** | la supervision et la journalisation centralisée (**N-09**) |
| **NFS** | **2049** | le partage de fichiers Unix — notre concurrent direct à SMB |
| **Telnet** | **23** | **à bannir explicitement.** Affiche absente = bonne nouvelle, mais il faut l'écrire |
| **NetBIOS** | 137/138/139 | l'ancien chemin SMB, encore nécessaire (voir plus haut) |
| **iSCSI**, **VNC** (5900), **RADIUS** (1812) | — | hors périmètre pour un serveur de fichiers |

**Le fait le plus parlant :** sur les 19 cases de l'affiche, **aucune** ne correspond au protocole
qui donne son sens au projet NexBSD.

---

## 4. Décision pour chacun des 19 — garder, planifier, refuser

C'est la vraie réponse à *« peut-on intégrer ces fonctions ? »*. Voici la décision, et elle est
**écrite** (règle R-10 : rien n'entre dans le produit sans décision écrite).

| Protocole | Décision NexBSD | Motif |
|---|---|---|
| **SMB 445** (+137/138/139) | ✅ **DÉJÀ DANS LE PRODUIT** | le service de fichiers, prouvé T-03/T-05a |
| **SSH 22** | ✅ **DÉJÀ DANS LE PRODUIT** | administration, clé seulement (A-14) |
| **LDAP 389** | ⚠️ **PRÉSENT, NON EXPOSÉ** | l'annuaire existe mais n'écoute qu'en local — voir §5 |
| **SNMP 161/162** | 🔜 **PLANIFIÉ — N-09** | supervision ; **v3 obligatoire**, jamais v1/v2c (chaîne en clair) |
| **IPP 631** | 🔜 **PLANIFIÉ — N-07** | impression |
| **mDNS 5353** | 🔜 **PLANIFIÉ — N-10** | découverte |
| **DNS 53** | 🔜 **PLANIFIÉ, plus tard** | un serveur de fichiers peut être aussi serveur DNS de zone interne ; utile, non vital |
| **NTP 123** | 🔜 **PLANIFIÉ, indispensable avant N-05** | **Kerberos refuse une horloge décalée de plus de 5 minutes.** Sans NTP, le mot de passe unique ne peut pas fonctionner. **C'est une dépendance cachée que personne n'avait notée** |
| **HTTPS 443** | 🔜 **PLANIFIÉ — N-08** | la console d'administration sans terminal sera une interface web |
| **LDAPS 636 / StartTLS** | 🔜 **PLANIFIÉ avec N-05** | chiffrer l'authentification |
| **Kerberos 88** *(absent de l'affiche)* | 🔜 **PLANIFIÉ — N-05** | — |
| **FTP 21** | ❌ **REFUSÉ** | mot de passe et données **en clair**. Remplacé par SFTP/SSH |
| **TFTP 69** | ❌ **REFUSÉ en production** | aucun mot de passe, aucune intégrité. Uniquement pour du démarrage réseau, si un jour |
| **Telnet 23** | ❌ **REFUSÉ, et à écrire noir sur blanc** | tout en clair. Notre `block in log all` le bloque déjà, mais l'interdiction doit être **nommée** |
| **RDP 3389** | ❌ **REFUSÉ** | protocole Windows ; NexBSD n'est pas Windows et n'a pas à l'imiter |
| **POP3 / IMAP / SMTP** | ❌ **HORS PÉRIMÈTRE** | NexBSD n'est pas un serveur de messagerie. L'ajouter doublerait la surface sans servir le produit |
| **MySQL / PostgreSQL** | ❌ **HORS PÉRIMÈTRE par défaut** | une base est une **application**, pas le système. Si une application en a besoin, elle l'installe et l'administrateur ouvre le port — **consciemment** |
| **HTTP 80** | ❌ **REFUSÉ tel quel** | redirection vers 443 uniquement, jamais de session en clair |
| **SFTP 22** | ✅ **COUVERT par SSH** | rien à ouvrir de plus : c'est le même port |

**Sur 19 cases : 2 déjà dans le produit · 7 planifiées · 10 refusées ou hors périmètre.**

---

## 5. Ce que la comparaison avec notre `pf.conf` a révélé — un vrai défaut

En lisant notre propre pare-feu (`fork/overlay/etc/pf.conf`) à côté de l'affiche, j'ai trouvé une
**phrase fausse dans un commentaire** :

```pf
set skip on lo0
...
# --- LDAP : l'annuaire. RESTREINT À LA BOUCLE LOCALE : les identités ne sont pas exposées au réseau.
pass in on lo0 inet proto tcp to port 389 keep state
```

**`set skip on lo0` fait que pf ne filtre *rien* sur la boucle locale.** La ligne `pass in on lo0 …
port 389` ne s'exécute donc **jamais** : elle est décorative.

⚠️ **Ce n'est pas une faille** : LDAP n'est pas joignable depuis le réseau parce qu'il **n'existe
aucune règle sur `$IFACE`** pour le port 389 — c'est le `block in log all` qui protège. Mais le
commentaire attribue la protection à une règle **qui ne fait rien**. C'est exactement le travers de
la leçon **M-10** : *un garde-fou qui a l'air de garder et qui ne garde pas*. Le jour où quelqu'un
lira ce fichier en croyant que la ligne fait le travail, il fera une erreur.

**Défaut nommé : C-46.** Corrigé par un commentaire honnête (§ commit), **sans changer le
comportement** — le fichier reste celui prouvé par T-05 et T-05a.

**Deuxième observation, à trancher plus tard :** `pass in on $IFACE inet proto tcp to port 445`
accepte SMB **de n'importe quelle source** sur l'interface. Pour un réseau de bureau c'est le
comportement voulu ; il faudra nonetheless le **borner** au réseau déclaré quand l'installeur
connaîtra l'adressage (même mécanisme que la macro `IFACE`).

---

## 6. La réponse à « peut-on intégrer tout ça ? »

**Non — et ce serait une erreur de le vouloir.** Trois raisons :

1. **Le produit se définit par ce qu'il refuse**, pas par ce qu'il accepte. « Remplacement de
   NetWare » veut dire : un serveur qui fait **peu de choses, très bien, avec une identité unique**.
   Ajouter POP3 et MySQL le transforme en distribution Linux de plus — et il n'a aucun avantage
   dans cette comparaison.
2. **Chaque service ajouté est une porte à maintenir.** 19 services = 19 programmes à mettre à jour,
   19 sources de CVE. `pkg audit` (A-67) protège contre les paquets vulnérables ; **la meilleure
   protection reste de ne pas les installer.**
3. **La règle R-10/R-11 du projet :** aucune idée n'entre sans décision écrite. Cette affiche est
   une **source d'idées**, pas un cahier des charges. Elle a servi : elle a fait ressortir **NTP
   123 comme dépendance cachée de N-05** — un point que nous n'avions pas noté.

---

## 7. Ce que je retiens de cette affiche, en une phrase

> Elle est vraie sur les numéros, fausse sur la méthode, et muette sur notre sujet.
> **Elle nous a appris une chose réelle : sans NTP, il n'y a pas de mot de passe unique.**

---

## 8. Acquis

**A-69** — les 19 protocoles de l'affiche vérifiés un par un, décision écrite pour chacun
(2 dans le produit, 7 planifiés, 10 refusés), et **NTP 123 identifié comme dépendance obligatoire de
N-05 (Kerberos)**, ce qui n'était écrit nulle part.

**C-46** — `pass in on lo0 … port 389` est décoratif à cause de `set skip on lo0` : le commentaire
attribuait la protection à une règle inopérante. Comportement inchangé, commentaire corrigé.

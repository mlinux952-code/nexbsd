# 69 — Révision sincère : qu'avons-nous vraiment, et peut-on récupérer NexBSD ?

**Date :** 2026-10-30, pendant la construction #25.
**Demande du responsable :** *« révise tout notre machin pour vérifier que nous sommes dans le
juste chemin, pas de bavardage et pas de FreeBSD, puis parle sincèrement et avec une grande
honnêteté : on peut récupérer notre vrai système NexBSD, oui ou non ? »*

**Réponse : OUI. Mais pas celui qu'on croit, et pas en une soirée.**
Ce document mesure, puis dit les choses sans les enjoliver.

---

## PARTIE 1 — LA MESURE

### 1.1 Le delta réel entre NexBSD et FreeBSD

| Élément | Mesure |
|---|---|
| Configuration NexBSD (`fork/overlay/`) | **28 027 octets** = **28 Ko** |
| Noyau `NEXBSD_L1` vs `GENERIC` | **5 périphériques retirés** sur 393 lignes de configuration |
| Tout le reste de l'image | **FreeBSD 15.1-RELEASE** |
| Taille de l'image | **2 399 142 400 octets** = 2,4 Go |

> **28 Ko de NexBSD dans 2,4 Go de FreeBSD.**
> Rapport : **0,0012 %**.

**Voilà la vérité crue.** Aujourd'hui, « NexBSD » est **un nom, une configuration de 28 Ko, et
cinq pilotes en moins**. Ce n'est pas une insulte : **Debian est Linux plus une configuration**.
Mais il faut le dire ainsi, parce que c'est la seule façon de savoir ce qui manque.

### 1.2 Ce que les 28 Ko contiennent — et c'est du bon travail

| Fichier | Octets | Ce qu'il établit |
|---|---|---|
| `etc/sysctl.conf` | 4 728 | 13 réglages de durcissement (A-74) |
| `install-annuaire-base.ldif` | 3 798 | la structure de l'annuaire |
| `etc/pf.conf` | 3 782 | le pare-feu, **prouvé au banc T-05/T-05a** |
| `usr-local-etc-smb4.conf` | 2 285 | le partage de fichiers (le cœur du remplacement de NetWare) |
| `etc/ssh/sshd_config.nexbsd` | 2 267 | clé seule, root interdit |
| `etc/rc.conf.defaults` | 2 204 | les services |
| `usr-local-etc-openldap-slapd.conf` | 1 964 | l'annuaire (le remplacement du bindery) |
| `usr-local-etc-nslcd.conf` | 1 600 | les identités de l'annuaire côté système |
| `etc/pam.d/su` | 1 201 | l'authentification |
| `etc/fstab` + `boot/loader.conf` | 2 322 | 🆕 **la capacité de démarrer (C-51)** |
| 5 autres | ~4 000 | motd, version, nsswitch, session |

**Ces fichiers ne sont pas des brouillons :** `pf.conf`, `sshd_config`, `pam.d/su`, `smb4.conf`,
`slapd.conf`, `nslcd.conf` ont été **mesurés au banc** (T-04, T-04-E/F/G, T-05, T-05a, T-21) sur
une vraie VM FreeBSD. C'est la partie **solide** du projet.

### 1.3 Le trou central, que personne n'avait nommé

> ### `fork/80-installer-nexbsd.sh` n'est **JAMAIS appelé par la chaîne de production.**

Vérifié par recherche dans `scripts/74-produire-image.sh`, `fork/build-nexbsd.sh` et
`.github/workflows/nexbsd.yml` : **aucune occurrence**. Zéro.

Or c'est **lui** qui fait :

```sh
pkg install -y openldap-server samba419 nss-pam-ldapd
SID=$(net getlocalsid)          # le domaine, lu et non inventé
service slapd start
service samba_server start
service nslcd start
```

**Conséquence directe et mesurable :** l'image de 2,4 Go **ne contient ni Samba, ni OpenLDAP,
ni nslcd, ni X11, ni WebKit.** Elle contient FreeBSD, le noyau NexBSD, et 28 Ko de fichiers de
configuration **qui désignent des services absents**.

**Autrement dit : même une fois amorcée, elle affichera un login FreeBSD avec un `motd` NexBSD.**
Ce n'est pas le vrai système NexBSD. C'est **le socle**, avec l'étiquette du produit.

Ce n'est pas une surprise : les notes de la Release `image-18`, écrites par la CI elle-même,
le disent noir sur blanc depuis le 29/10 — *« Samba, OpenLDAP et nslcd n'y sont pas installés
(le socle FreeBSD seulement) »*. **La chaîne ne ment pas. C'est nous qui ne lisions pas.**

### 1.4 L'état des 79 acquis — la répartition honnête

| État | Nombre | Ce que cela veut dire |
|---|---|---|
| **FERMÉ** | **55** | configuré **et** mesuré au banc |
| **OUVERT** | **18** | écrit, **jamais vu fonctionner** |
| **A-FAIRE** | **6** | pas commencé |

Les 18 ouverts sont **exactement le produit** :

| Acquis | Ce qui manque |
|---|---|
| A-02 | partage SMB lu **depuis une autre machine** |
| A-03 | annuaire OpenLDAP **opérationnel** |
| A-04 | Samba authentifié **via** l'annuaire |
| A-05 | droits appliqués **par groupes** de l'annuaire |
| A-06 | le banc **revient seul après redémarrage** |
| A-08 | le système s'appelle **nexbsd** |
| A-13/A-14 | SSH par clé, `su` exigeant un mot de passe |
| A-21 | le **bureau** NexBSD |
| A-22 | identité unique PAM/LDAP |
| A-53 | **l'installeur** (celui qui n'est jamais appelé) |
| A-54 | la **session** bureau |
| A-79 | **l'image qui démarre** |

> **Les 55 fermés sont la plomberie et la configuration. Les 18 ouverts sont le produit.**

---

## PARTIE 2 — LE CHEMIN EST-IL LE BON ?

### 2.1 Ce qui est juste — sans réserve

1. **Le socle est le bon.** FreeBSD 15.1, noyau maison, déterministe, reproductible.
2. **La configuration est prouvée au banc**, pas supposée. T-04/T-05/T-05a/T-21 ont mesuré
   `pf.conf`, `smb4.conf`, `slapd.conf`, `nslcd.conf` sur une vraie machine FreeBSD.
3. **La chaîne de CI est honnête** : 4 travaux, aucun n'a jamais produit de faux vert silencieux
   — et quand elle a failli (C-48, C-50, C-51), **elle a été corrigée pour crier**.
4. **La publication fonctionne** : Release publique, 10 actifs, empreintes, `curl -C -`.
5. **Les garde-fous font leur travail** : trois fois aujourd'hui, un contrôle a **refusé** de
   laisser passer quelque chose (registre 72, delta 70, chaîne d'amorçage).
6. **La décision de produit est tenue** : pas de GNOME, pas de KDE, pas de GPL dans le dépôt.

### 2.2 Ce qui n'est pas juste — et qu'il faut corriger

| # | Défaut | Gravité |
|---|---|---|
| **1** | **L'installeur n'est jamais appelé** ⇒ l'image ne contient pas le produit | 🔴 **critique** |
| **2** | **Aucune image n'a jamais démarré** (C-51) | 🔴 critique, **en cours** |
| **3** | **Le disque n'a pas la place** pour le bureau : 827 Mo libres estimés, il en faut ~960 | 🟠 bloquant à court terme |
| **4** | **`motd` annonce encore « FreeBSD »** (A-17) | 🟠 visible à l'écran, humiliant |
| **5** | **Aucun client n'a jamais lu un partage** : A-02 est le produit, et il est ouvert | 🔴 critique |
| **6** | **L'ADR-0021 (racine immuable) est encore en PROPOSITION**, comme les 20 ADR | 🟡 dette de décision |
| **7** | **Rien ne prouve que `pkg` a un dépôt accessible** dans la VM de CI | 🟡 inconnu |

### 2.3 Le piège dans lequel le projet est tombé, et dont il sort

Pendant huit jours, le travail a porté sur **la capacité à produire et à publier une image**
(pipeline, artefacts, Release, bundles). C'était nécessaire — sans cela, rien ne sortait.
**Mais la tuyauterie a pris la place du produit.** Le responsable l'a dit le 28/10 :
*« seulement ajuster une version de VM… faute grave »* ; et le 29/10 :
*« les composants du produit doivent avancer »*.

**Cette révision le confirme : le produit n'a pas avancé depuis le banc T-04.** Ce qui a avancé,
c'est la capacité à le transporter. **C'était indispensable. Ce n'est pas suffisant.**

Le chemin est désormais le bon **à une condition** : qu'après le démarrage, la priorité absolue
soit **l'appel à `fork/80` et la preuve d'un partage lu depuis MINT**. Tant que ce n'est pas fait,
tout le reste est de la décoration.

---

## PARTIE 3 — LA RÉPONSE : OUI OU NON ?

### 3.1 Oui — et voici pourquoi c'est sérieux

**Rien n'est perdu.** Le système existe, complet, dans un fichier de 2,4 Go. Le noyau est dedans.
La configuration est dedans, et elle a été mesurée. L'installeur existe déjà et sait installer le
produit. **Il n'y a pas à recommencer : il y a à brancher.**

### 3.2 Non — si l'oncle appelle « récupérer » le fait d'avoir ce soir un NexBSD qui remplace
un serveur NetWare. Ce n'est pas le cas, et voici l'écart exact :

| Fonction du vrai NexBSD | Aujourd'hui |
|---|---|
| la machine démarre | ❌ jamais (C-51, correctif en cours, ~2 h) |
| elle s'appelle NexBSD | ❌ `motd` dit FreeBSD (A-17) |
| un utilisateur ouvre une session | ❌ aucune session jamais ouverte |
| un partage est lu depuis un autre poste | ❌ **jamais** |
| les comptes viennent d'un annuaire | ❌ **Samba et LDAP ne sont pas dans l'image** |
| un bureau s'affiche | ❌ X11 et WebKit absents, et le disque est trop petit |
| les lecteurs réseau `H:` et `P:` apparaissent | ❌ logique écrite, jamais branchée (A-68) |

### 3.3 Le chemin exact, avec des durées honnêtes

| Étape | Ce que ça donne | Durée réaliste | Risque |
|---|---|---|---|
| **1. Démarrer** | un login FreeBSD/NexBSD à l'écran | **ce soir** (~2 h de CI) | faible : la cause est mesurée, la correction est celle de FreeBSD |
| **2. `motd` + nom d'hôte** | l'écran dit **NexBSD** | 30 min | nul |
| **3. Appeler `fork/80`** | Samba + LDAP + nslcd **installés et démarrés** | **1 à 2 jours** | 🟠 moyen : `samba419` existe-t-il sur FreeBSD 15.1 ? `pkg` a-t-il un dépôt ? |
| **4. Prouver le partage depuis MINT** | **A-02 fermé** : le cœur du produit | 1 journée | 🟠 moyen : c'est là que se cachent les vraies surprises |
| **5. Annuaire + identités** | A-03, A-04, A-05, A-06, A-22 | 2 à 3 jours | 🟠 moyen |
| **6. Bureau** | A-21, A-54 | **1 à 2 semaines** | 🔴 **élevé** : WebKitGTK 600 Mo, disque trop petit, X11 sur matériel de 2011 |
| **7. Image installable** | jalon J5, A-19 | après 6 | 🟡 |

**Total honnête pour un NexBSD qui remplace vraiment un serveur de fichiers NetWare : 2 à 3
semaines de travail régulier, pas ce soir.** Pour « ça démarre et ça s'appelle NexBSD » : **ce soir,
si #25 est vert.**

### 3.4 Les trois risques que je ne veux pas cacher

1. **FreeBSD 15.1 est très récent.** Les paquets `samba419`, `xorg`, `webkit2gtk` peuvent manquer
   ou être incomplets. Si `pkg install samba419` échoue, le produit n'existe pas — et il faudra
   choisir : une version plus ancienne de FreeBSD (14.x, mieux fournie), ou attendre.
   **C'est le risque numéro un, et il n'est pas technique : il est de calendrier.**
2. **Le disque est trop petit.** 827 Mo libres estimés ; le bureau demande ~960 Mo.
   **Il faudra augmenter `TAILLE_MO`** dans `fork/build-nexbsd.sh` — c'est une ligne, mais si on
   l'oublie, `fork/80` échouera à mi-parcours, après des heures de construction.
3. **Rien de tout cela n'a jamais tourné.** Le banc T-04 a prouvé les fichiers de configuration
   **sur une machine FreeBSD d'essai**, pas dans **l'image NexBSD**. Entre les deux, il y a
   `fork/70` (qui copie) et `fork/80` (qui installe) : **deux maillons jamais exécutés ensemble.**

---

## PARTIE 4 — CE QUE JE PROPOSE, ET DANS QUEL ORDRE

**Ce soir :** terminer #25, lire `gpart show`, publier, télécharger, **démarrer**.
**Objectif unique : voir un login à l'écran.** Rien d'autre.

**Demain :** `motd` → NexBSD, nom d'hôte → `nexbsd`, et **appeler `fork/80`** dans la chaîne.
Objectif : un partage SMB qui existe et qui **demande un mot de passe**.

**Après-demain :** `scripts/76` depuis MINT + `smbclient` depuis MINT.
**Objectif : A-02 fermé.** Ce jour-là, le projet aura un produit, pas une image.

**Ensuite seulement :** l'annuaire, les identités, puis le bureau.

---

## Verdict en une phrase

> **Oui, on peut récupérer le vrai système NexBSD — le socle est sain, la configuration est
> prouvée, l'installeur est écrit. Non, il ne l'est pas encore : ce que nous avons ce soir est
> FreeBSD avec 28 Ko de NexBSD dessus, et c'est le branchement de `fork/80` qui fera la
> différence. Ce n'est pas un problème de code, c'est un problème de branchement.**

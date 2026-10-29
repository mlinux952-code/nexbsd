# 57 — Les dix intervenants du méga-prompt : qui a servi, qui n'a pas servi, et ce que chacun doit encore apporter

> **Question du responsable (2026-10-29) :** *« et qui concerne les intervenants qui sont indiqués
> dans nos prompts dans les uploads, sont-ils utilisés ? Et surtout leurs applications, qu'elles
> soient utiles pour enrichir notre système. »*
>
> **Réponse courte :** les dix rôles du méga-prompt **ne sont pas dix personnes**. C'est **une
> seule** liste de compétences que je dois faire tourner sur chaque question. Sur les dix,
> **six ont réellement produit** quelque chose de vérifiable, **deux ont produit des documents mais
> aucune application**, et **deux n'ont rien produit du tout**. Ce document le prouve fichier par
> fichier, puis dit ce que chacun doit encore apporter.

Source : `/uploads/NEXBSD — MÉGA-PROMPT MAÎTRE.md`, **PARTIE I**, lignes 16 à 25.

---

## 1. Le tableau d'ensemble

| # | Intervenant (rôle du prompt) | A-t-il servi ? | Preuve dans le dépôt | Application livrée au système |
|---|---|---|---|---|
| 1 | Architecte de systèmes d'exploitation | ✅ **oui** | `docs/architecture.md`, 20 ADR, couches A→F | le découpage du système et ses frontières |
| 2 | Ingénieur FreeBSD / Unix | ✅ **oui, massivement** | `fork/sys/amd64/conf/NEXBSD_L1`, `scripts/67-69`, `fork/build-nexbsd.sh` | **le noyau `NEXBSD_L1` compilé**, le monde, l'image |
| 3 | Spécialiste systèmes mobiles / embarqués | ⚠️ **partiellement** | `docs/09-cible-pc-faible.md`, `docs/35`, ADR-0008 | le profil « PC faible » (RAM, pas de jeux, pas de doc) — **rien d'autre** |
| 4 | Ingénieur Web / Gecko / applications mobiles | ⚠️ **partiellement** | `fork/bureau/nexbsd-bureau.html`, `docs/51` | **le bureau** (HTML + WebKitGTK) — mais **pas Gecko** |
| 5 | Spécialiste protocoles réseau et systèmes de fichiers | ✅ **oui** | `smb4.conf`, `slapd.conf`, `nsswitch`, `scripts/60-66`, `docs/14` | **le partage SMB + l'annuaire LDAP** (testés au banc) |
| 6 | Administrateur systèmes et services réseau | ✅ **oui** | `pf.conf`, `sshd_config`, `pam.d/su`, `scripts/71`, `T-05`, `T-21` | **le pare-feu, SSH en clé seule, `su` exigeant un mot de passe** |
| 7 | Ingénieur logiciels libres et licences | ✅ **oui** | `docs/12`, `scripts/40-verifier-frontiere-licence.sh`, `fork/exceptions-licence.txt` | la frontière GPL : **rien de GPL tiers dans le dépôt** |
| 8 | Spécialiste cybersécurité et dépendances | ⚠️ **partiel, avec un trou nommé** | `docs/38`, `A-14`, `C-36` (refus de root) | la défense en profondeur — **mais `pkg audit` n'a jamais été écrit** |
| 9 | Ingénieur tests, validation, reproductibilité | ✅ **oui, c'est notre point fort** | `scripts/70/72/74`, 15 comptes rendus, 18 exécutions CI | **la chaîne qui a produit l'image** |
| 10 | Rédacteur technique | ✅ **oui** | 59 documents, `matrices/acquis.csv` (65 acquis), preuves verbatim | la mémoire du projet — **sans elle, les 18 exécutions seraient perdues** |

**Bilan : 6 rôles pleinement utilisés · 3 partiellement · 1 avec un trou nommé.**

---

## 2. Ce que chaque intervenant doit encore APPORTER — applications concrètes

C'est la deuxième moitié de votre question : *« leurs applications, qu'elles soient utiles pour
enrichir notre système »*. Voici, rôle par rôle, ce qui manque **dans le produit**, pas dans la
documentation.

### Intervenant 5 — Protocoles réseau : **le plus gros manque du projet**

Il a livré Samba et OpenLDAP au banc. Il n'a **rien** livré de ce qui fait l'identité NetWare :

| Application à écrire | Ce qu'elle fait | Pourquoi c'est vital |
|---|---|---|
| **N-06 — scripts de connexion** | à la connexion d'un utilisateur, le poste reçoit ses **lecteurs réseau** (H: → son dossier, P: → le partage commun) | **c'est la fonction n°1 de NetWare.** Sans elle, NexBSD est « FreeBSD + Samba » |
| **N-11 — client NCP** | un client NetWare historique se connecte sur le port 524 et lit des fichiers | la différenciation revendiquée dans le cahier des charges |
| **N-07 — impression partagée** | CUPS + file d'impression Samba | NetWare était un serveur d'impression avant tout |
| **N-10 — découverte réseau** | mDNS/DNS-SD : le serveur est visible sans taper son adresse | l'esprit « SAP » de NetWare |

### Intervenant 8 — Cybersécurité : **un trou nommé depuis le 28/10**

| Application à écrire | Ce qu'elle fait |
|---|---|
| **`pkg audit` au démarrage de session** | vérifier les CVE des paquets installés, et **refuser** de lancer le bureau si un paquet critique est vulnérable |
| **un contrôle de dépendances** | lister ce que chaque paquet ajoute, et signaler ce qui n'a pas de mainteneur |

**Le trou est réel et déjà documenté** : `www/webkit2-gtk` porte **20 CVE (mai 2026)**. Or le bureau
en dépend. `docs/51` §80 dit *« `pkg audit` doit tourner au démarrage de session »* — **ce n'est
toujours pas écrit**. C'est la première chose que cet intervenant doit livrer.

### Intervenant 3 — Systèmes mobiles / embarqués : **un rôle presque muet**

Il a produit le profil « PC faible » (pas de jeux, pas de doc, noyau minimal) et a **écarté** la
téléphonie avec une raison écrite (ADR-0008 : aucun pilote, aucun appareil cible). C'est honnête.
Mais il n'a rien apporté sur :

| Application attendue | État |
|---|---|
| gestion de la **batterie** et de la mise en veille (EF-C-21) | ❌ rien |
| interface lisible sur **1024×768 et 10 pouces** (EF-C-17) | ⚠️ le bureau est responsive, **jamais mesuré sur un vrai écran** |
| fonctionnement **sans disque dur** (clé USB, RAM) | ❌ rien |

### Intervenant 4 — Web / Gecko : **un choix assumé, à réévaluer**

Il a livré le bureau en **HTML + WebKitGTK** (couche C). **Gecko et Firefox OS ont été écartés**
avec motif écrit (`docs/34`). Ce qui manque :

| Application attendue | État |
|---|---|
| **N-08 — console d'administration sans terminal** | ❌ le bureau n'administre rien ; il affiche des icônes |
| applications intégrées (fichiers, utilisateurs, journaux) | ❌ rien |
| `pkg audit` visible dans le bureau | ❌ rien |

### Intervenant 1 — Architecte : **une contradiction à trancher**

Il a produit le découpage en couches A→F. Mais **deux de ses choix se contredisent** et personne ne
l'a signalé :

- il exige **un annuaire unique** (couche D) ;
- il accepte que la **session graphique passe par PAM local**, sans l'annuaire (couche C).

**Conséquence concrète** : un utilisateur créé dans l'annuaire LDAP ne peut **pas** ouvrir de
session graphique. C'est l'acquis **A-22**, toujours à l'état A-FAIRE depuis le 27/10.

---

## 3. Les deux rôles qui n'ont produit AUCUNE application

Ce sont les deux que le prompt présente comme « spécialistes » et qui, dans les faits, n'ont fait
que de la documentation :

| Rôle | Ce qu'il a fait | Ce qu'il n'a jamais fait |
|---|---|---|
| **3 — mobiles / embarqués** | un document d'analyse (`docs/09`) | aucune application, aucun test sur un vrai portable |
| **8 — cybersécurité** | `docs/38`, la règle anti-root (A-14) | **aucun outil** : ni `pkg audit`, ni contrôle de dépendances |

**C'est exactement ce que vous pressentez :** « il y a beaucoup de composants, mais rien n'a été
fait ». Sur dix intervenants, **deux n'ont laissé que du texte**.

---

## 4. Ce que je propose pour la suite, dans l'ordre

Chaque ligne est une **application à écrire**, pas un document de plus.

| Priorité | Application | Intervenant responsable | Pourquoi maintenant |
|---|---|---|---|
| **1** | **démarrer l'image** produite (exécution #18) | 2 + 9 | tant que rien ne démarre, tout le reste est théorique |
| **2** | **`pkg audit` au démarrage de session** | 8 | 20 CVE connues dans le paquet qui fait tourner le bureau |
| **3** | **N-06 : scripts de connexion / lecteurs réseau** | 5 | **l'âme de NetWare**, absente depuis le début |
| **4** | **N-08 : console d'administration** | 4 + 6 | remplacer le terminal, objectif d'origine du projet |
| **5** | **A-22 : identité unique PAM/LDAP** | 1 + 5 | aujourd'hui un compte d'annuaire n'ouvre pas de session |
| **6** | **A-18 : comment l'administrateur obtient root** | 6 + 8 | question ouverte depuis le 27/10, jamais tranchée |

---

## 5. Une remarque de méthode, parce qu'elle explique tout le reste

Les dix rôles fonctionnent **comme une équipe**, et une équipe se juge sur ce qu'elle **produit**,
pas sur ce qu'elle **discute**. Or trois rôles sur dix ont passé leur temps à écrire des analyses
pendant que le rôle 2 (FreeBSD) et le rôle 9 (tests) faisaient tout le travail réel.

**Règle que je m'impose à partir de maintenant :** quand je fais parler un intervenant, je dois
pouvoir nommer **le fichier qu'il a produit**. Si je ne peux pas, il n'a pas travaillé — il a
commenté. Et je le dirai.

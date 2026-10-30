# 70 — Nos protagonistes, extraits du cahier des charges, et nos défauts, corrigés

**Date :** 2026-10-30
**Demande du responsable :** *« on attrape nos défauts et on corrige tous. D'abord on lit nos
prompts, on extrait nos protagonistes et on essaie de corriger. »*
**Méthode :** relire `NEXBSD — MÉGA-PROMPT MAÎTRE.md` (929 lignes), en extraire la structure
imposée, la confronter au dépôt, **nommer les défauts, en corriger ce qui se corrige
aujourd'hui**.

---

## 1. Ce que le cahier des charges impose — les protagonistes

### 1.1 Six couches (PARTIE IV)

| Couche | Nom | Ce qu'elle doit faire |
|---|---|---|
| **A** | Base système | démarrage, noyau, mémoire, fichiers, réseau, utilisateurs, sécurité |
| **B** | Services d'intégration | configuration, journaux, contrôles de santé, scripts de démarrage |
| **C** | Plateforme mobile | interface, applications, notifications, permissions, énergie |
| **D** | Services réseau | 1 fichiers/impression · 2 annuaire/identités · 3 protocoles historiques · 4 administration · 5 supervision |
| **E** | Applications et administration | environnement utilisateur, outil d'administration, comptes, diagnostic |
| **F** | Distribution et maintenance | construction, paquets, mises à jour, sauvegardes, images, intégrité |

### 1.2 Une matrice des fonctions à huit colonnes et quatre priorités (PARTIES VIII et IX)

`Fonction | Besoin | Candidat | Dépendances | Compatibilité | Risques | Test | État`
et **P0** (prototype minimal), **P1** (première version utilisable), **P2**, **P3**.

### 1.3 La matrice existe — et voici ce qu'elle dit

`matrices/functions.csv` : **28 fonctions**, réparties **P0 : 8 · P1 : 9 · P2 : 6 · P3 : 5**.

---

## 2. LE CHIFFRE QUE NOUS AURIONS DÛ REGARDER DEPUIS LE DÉBUT

> ## **0 fonction P0 terminée sur 8.**

| ID | Fonction | État réel au 30/10 | Ce qui existe |
|---|---|---|---|
| **S-01** | Démarrage et initialisation | **BLOQUÉ** | cause mesurée (C-51), correctif écrit, **jamais démarré** |
| **S-02** | Détection et inventaire matériel | **À TESTER** | la sonde a tourné **sur FreeBSD**, jamais sur NexBSD |
| **S-03** | Réseau TCP/IP | **À TESTER** | `pf.conf` prouvé au banc, **réseau jamais éprouvé dans l'image** |
| **S-04** | Stockage et systèmes de fichiers | **PARTIEL** | UFS2 fabriqué et **vérifié dans le fichier**, jamais monté au démarrage |
| **S-05** | Gestion des utilisateurs | **À FAIRE** | `pam.d/su` écrit ; **aucun compte créé, aucune session** |
| **S-09** | Sauvegarde et restauration | **À FAIRE** | rien |
| **N-01** | **Partages de fichiers** | **À FAIRE** | `smb4.conf` écrit ; **Samba n'est pas dans l'image** |
| **N-02** | **Droits par fichier et répertoire** | **À FAIRE** | rien de mesuré |

Par couche : **A 0/5 · B 0/1 · C 0/6 · D-1 0/4 · D-2 0/3 · E 0/1 · F 1/2.**

> **Le responsable a raison. Ce n'est pas une impression, c'est notre propre matrice qui le dit,
> et nous ne la regardions pas.**

### 2.1 Et le cahier des charges prévoyait exactement cette dérive

PARTIE XVI, mot pour mot :

> *« La réussite ne se mesure pas au nombre de systèmes ou de composants ajoutés. Elle se mesure
> à la qualité, à la cohérence et à la validation des fonctions obtenues. »*

Nous avons compté **80 acquis**, **171 commits**, **95 documents**, **24 scripts**. **Aucun de ces
chiffres ne mesure le produit.** Le seul qui comptait était **0/8**, et il n'était affiché nulle part.

---

## 3. Nos défauts — mesurés, numérotés

| # | Défaut | Gravité | Corrigé aujourd'hui ? |
|---|---|---|---|
| **D-01** | **Aucun script ne vérifiait `matrices/functions.csv`** : les 28 protagonistes n'étaient ni suivis, ni audités, ni mis à jour | 🔴 **la cause racine de tout le reste** | ✅ **`scripts/77`** |
| **D-02** | `functions.csv` était **en virgules**, seul fichier du projet dans ce format ⇒ invisible pour tous les outils | 🟠 | ✅ converti en `;` |
| **D-03** | **Aucun état ne citait de preuve** : « À faire » et « Fait » se ressemblaient | 🔴 | ✅ **colonne `Preuve` + règle : `FAIT` exige une preuve vérifiable** |
| **D-04** | Les états n'avaient **jamais été mis à jour** depuis la création de la matrice | 🔴 | ✅ 28 états établis sur mesure |
| **D-05** | **`fork/80-installer-nexbsd.sh` n'est jamais appelé** par la chaîne ⇒ l'image ne contient pas le produit | 🔴 **critique** | ❌ **demain** (A-80, docs/69) |
| **D-06** | Le **nombre d'acquis** servait de mesure d'avancement alors que **0/8 P0** | 🔴 | ✅ `scripts/77` affiche le seul chiffre utile |
| **D-07** | **N-10** n'avait aucun test prévu tout en étant « à étudier » — soit on la teste, soit on dit qu'elle est en recherche | 🟡 | ✅ état **RECHERCHE**, cohérent avec N-11 |

**Sur 7 défauts nommés : 6 corrigés aujourd'hui, 1 reste (D-05), et c'est le plus grave.**

---

## 4. Ce qui a été corrigé, concrètement

### `scripts/77-verifier-fonctions.sh` — le garde-fou qui manquait

Il refuse :
1. un **état hors vocabulaire** fermé (`FAIT`, `PARTIEL`, `A FAIRE`, `BLOQUE`, `A TESTER`,
   `RECHERCHE`, `A ETUDIER`, `A CONCEVOIR`, `HORS PERIMETRE`) ;
2. une fonction **active sans test prévu** ;
3. une fonction **déclarée `FAIT` sans preuve** — fichier existant, ou `CI:run/<id>` (leçon C-50 :
   un garde-fou ne doit pas se taire quand il ne trouve rien) ;
4. un fichier **malformé**.

Et il affiche, à chaque exécution, **le tableau des 8 P0 et le compte `n/8`**.

**Résultat de sa première exécution : `0/8 P0 terminées`.** C'est laid, et c'est vrai.

### La correction de D-07, dans l'esprit de la règle

`N-10` (découverte de services, esprit SAP) n'avait **aucun test** tout en étant « à étudier ».
Deux issues honnêtes : lui écrire un test, ou reconnaître qu'elle est de la **recherche**.
**J'ai choisi la seconde**, et je n'ai pas affaibli le garde-fou : `HORS PERIMETRE` et `RECHERCHE`
sont les **seules** exceptions admises à « une fonction a un test ».

---

## 5. L'ordre de correction du produit — le seul qui compte

**Le P0 est le prototype minimal exigé par notre propre cahier des charges.** Il ne se discute
pas : il est écrit depuis le premier jour. Voici l'ordre, et il est contraint par les dépendances :

| # | Fonction | Comment on la ferme | Dépend de |
|---|---|---|---|
| **1** | **S-01 Démarrage** | un login s'affiche dans QEMU | — *(en cours : #25)* |
| **2** | **S-02 Matériel** | `dmesg`, `pciconf -lv`, `sysctl hw.model` **dans NexBSD** | S-01 |
| **3** | **S-03 Réseau** | une adresse IP, `ping` vers MINT | S-01 |
| **4** | **S-04 Stockage** | `df -h` sur `/`, plus un fichier écrit puis relu | S-01 |
| **5** | **S-05 Utilisateurs** | `pw useradd`, `su` **qui demande un mot de passe** | S-01 |
| **6** | **N-01 Partages** | `pkg install samba419` **puis** `smbclient` **depuis MINT** | S-03, S-05 |
| **7** | **N-02 Droits** | un utilisateur ne lit pas le dossier d'un autre | N-01 |
| **8** | **S-09 Sauvegarde** | `tar` d'un dossier, restauration, comparaison | S-04 |

> **Les huit P0 tiennent dans UNE machine et UN partage lu depuis MINT.**
> Ce n'est pas un projet de trois semaines : c'est **huit étapes**, dont la première est déjà
> lancée. Ce qui prenait du temps, c'était de ne pas savoir où on en était. **Maintenant on sait.**

---

## 6. Ce que je ne dis pas

**Je ne dis pas que le travail passé n'a servi à rien.** Les 55 acquis fermés sont réels, la
configuration est mesurée, la chaîne de publication fonctionne, et la cause de C-51 a été trouvée
en ouvrant un disque octet par octet — ça, aucun compteur ne l'aurait donné.

**Je dis que nous mesurions la mauvaise chose.** Le tableau de bord affichait les acquis ; il
fallait afficher **les fonctions**. C'est désormais le cas, et il affiche **0/8**.

**C'est le seul tableau de bord honnête que ce projet ait eu.**

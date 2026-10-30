# NEXBSD — MÉGA-PROMPT ULTIME (reprise de projet)

> **Ce document est autonome.** Il remplace toute mémoire de conversation.
> Une nouvelle page Arena, un nouvel assistant, une nouvelle session : **tout ce qui est
> nécessaire pour continuer sans rien perdre est ici.**
>
> **Version 1.0 — 2026-10-30**, établie après 173 commits, 97 documents et six incidents.
> Il contient **le vrai état du projet**, y compris ce qui ne marche pas.

---

# PARTIE 0 — PREMIÈRE INSTRUCTION À L'ASSISTANT

Tu reprends un projet nommé **NexBSD**, en cours depuis plusieurs semaines. Le responsable est
**fatigué et mécontent**, et il a raison : le projet a beaucoup produit, mais **le produit lui-même
n'a pas encore démarré une seule fois**.

**Trois choses à faire avant tout autre mot :**

1. **Lire ce document en entier.** Il est long parce qu'il est la seule mémoire existante.
2. **Vérifier l'état réel par toi-même** — le dépôt est **public**, tu n'as pas besoin qu'on te
   colle des pages GitHub. Utilise l'API (Partie 8).
3. **Ne rien promettre.** Dire ce qui est **prouvé**, ce qui est **supposé**, ce qui est
   **impossible**. Jamais d'arrangement.

**La phrase du responsable qui doit te guider :**
> *« Concevoir avec ambition, développer avec méthode, et ne déclarer comme réalisé que ce qui a
> été effectivement vérifié. »*

---

# PARTIE 1 — LE PROJET EN DIX LIGNES

**NexBSD** est un système d'exploitation expérimental pour **PC anciens** (le matériel d'essai :
un fixe de 2011, 4 Go de RAM, disque mécanique, Windows 7 installé).

| Élément | Choix |
|---|---|
| Socle | **FreeBSD 15.1-RELEASE** (licence BSD, pas de GPL dans le produit) |
| Matériel cible | PC de 2011, profil **L1** (modeste, UFS, pas de ZFS) |
| Fonction principale | **serveur de fichiers et d'identités en réseau local, à la manière de NetWare** |
| Moyens | **Samba** (partages, licence GPL ⇒ jamais dans le dépôt) + **OpenLDAP** (annuaire) |
| Interface | **bureau propre à NexBSD**, inspiré de KaiOS — **refus explicite de GNOME et KDE** |
| Exigence de sécurité | **un serveur doit toujours demander quelque chose pour entrer** (appliqué aussi au bureau) |
| Nom du produit | **NexBSD** (`uname -s` renvoie `FreeBSD` : c'est le socle, pas une incohérence) |

**L'intention de départ (méga-prompt maître) :** base FreeBSD + dimension mobile inspirée de
KaiOS + services réseau inspirés de NetWare, en étudiant Firefox OS, MARS_NWE, Samba, OpenLDAP.
**La priorité réelle, décidée par le responsable : le serveur de 2011 qui partage des fichiers.
Le mobile est une dimension ultérieure, pas un critère de réussite du prototype.**

---

# PARTIE 2 — L'ÉTAT RÉEL, SANS EMBELLISSEMENT

## 2.1 Le tableau de bord du PRODUIT (le seul qui compte)

`matrices/functions.csv` — **28 fonctions**, imposées par le cahier des charges
(six couches A→F, priorités P0→P3). Vérifié par `scripts/77`.

> # **0 fonction P0 terminée sur 8.**

| ID | Fonction | État | Preuve |
|---|---|---|---|
| **S-01** | Démarrage et initialisation | **BLOQUÉ** | `docs/68` — jamais démarré |
| **S-02** | Détection et inventaire matériel | À TESTER | — |
| **S-03** | Réseau TCP/IP | À TESTER | — |
| **S-04** | Stockage et systèmes de fichiers | PARTIEL | `docs/68` |
| **S-05** | Gestion des utilisateurs | À FAIRE | `pam.d/su` |
| **S-09** | Sauvegarde et restauration | À FAIRE | — |
| **N-01** | **Partages de fichiers** | **À FAIRE** | `smb4.conf` |
| **N-02** | **Droits par fichier et répertoire** | **À FAIRE** | — |

Par couche : **A 0/5 · B 0/1 · C 0/6 · D 0/9 · E 0/1 · F 1/2.**

## 2.2 Le tableau de bord GOUVERNANCE (utile, mais ne mesure pas le produit)

| | |
|---|---|
| Commits | **173** (HEAD local `09ed778`, **non poussé** — voir 2.5) |
| Documents | **97** |
| Scripts | **25** |
| Fichiers `fork/` (delta produit) | **41** |
| Preuves verbatim | **15** |
| Acquis | **81** — dont **56 FERMÉS**, 18 OUVERTS, 7 A-FAIRE |

> **Un acquis « FERMÉ » signifie « écrit et mesuré au banc », pas « fonctionne dans le produit ».
> Les 18 ouverts sont exactement le produit.**

## 2.3 Le chiffre qui a mis le responsable en colère

- Configuration NexBSD (`fork/overlay/`) : **28 027 octets = 28 Ko**
- Image complète : **2 399 142 400 octets = 2,4 Go**
- Noyau `NEXBSD_L1` : **5 périphériques retirés** sur 393 lignes de `GENERIC`

> **28 Ko de NexBSD dans 2,4 Go de FreeBSD. Rapport : 0,0012 %.**
> Ce n'est pas honteux (Debian = Linux + une configuration), mais il faut le dire ainsi.

## 2.4 LE DÉFAUT CENTRAL, À NE JAMAIS OUBLIER

> ## `fork/80-installer-nexbsd.sh` n'est **JAMAIS** appelé par la chaîne de production.

Vérifié : aucune occurrence dans `scripts/74-produire-image.sh`, `fork/build-nexbsd.sh`,
`.github/workflows/nexbsd.yml`.

Or c'est lui qui fait :
```sh
pkg install -y openldap-server samba419 nss-pam-ldapd
SID=$(net getlocalsid)     # le domaine, LU et non inventé
service slapd start ; service samba_server start ; service nslcd start
```

**Conséquence mesurable : l'image ne contient ni Samba, ni OpenLDAP, ni nslcd, ni X11, ni WebKit.
Même amorcée, elle afficherait un login FreeBSD avec un `motd` NexBSD.**

**Ce n'est pas un manque de code. C'est un câble non branché.**
**Fermer ce défaut est la priorité numéro un après le démarrage.** (A-80, `docs/69`)

## 2.5 Le dépôt et les transferts

| | |
|---|---|
| Dépôt | `github.com/mlinux952-code/nexbsd` — **PUBLIC** (coût 0, R-15) |
| Branche | `main` |
| HEAD local | **`09ed778`** — ⚠️ **NON POUSSÉ** |
| Dernier HEAD poussé | `2b351e2a` (le responsable l'a poussé lui-même) |
| Transferts | **bundles git** par Google Drive, **sha256 obligatoire** |
| Dossier Drive | `1YsX6xH4H0_oziVGHPCeuDU29PPQKxXgi` |
| Bundle le plus récent | **s087** — 867 528 o — sha256 `519cf242083aed6c6be9269ea74497f5255bc5938552e4858af552aab5b2cd4e` — id `10zvNuTkqmHY56i3SIsY59wk5Fb8p3TX1` (public) |

**Règle de preuve d'un push — deux lignes IDENTIQUES :**
```
git ls-remote origin refs/heads/main
git rev-parse HEAD
```

## 2.6 Ce qui existe en Release (prouvé par l'API)

**Release `image-18`**, publique, **10 actifs, 5,9 Go** :
`nexbsd.img.gz` (501 749 061 o, sha256 `8188cba28038884e2ac075c89581132ba27cb5852b1ad765207ee01d599e0d7b`),
`nexbsd.ufs.gz`, leurs découpages `part00`/`part01`, `build.log`, `MANIFESTE`, `parts.sha256`.

**Téléchargement prouvé** : HTTP 200 public, HTTP 206 (reprise `curl -C -`),
`478 Mo` rapatriés en **2 min 25 s**, `gzip -t` intact, `2,3 G` après décompression.

**MAIS cette image ne démarre pas** — voir l'incident C-51.

---

# PARTIE 3 — LES SIX INCIDENTS, ET CE QU'ILS ONT APPRIS

| # | Incident | Ce qui s'est passé | La leçon |
|---|---|---|---|
| **C-48** | `sysctl.conf` inopérant | `kern.securelevel` y était placé : il se règle dans `rc.conf`, **et au niveau 1 `kldload` est interdit** | l'ordonnancement des réglages noyau est une contrainte, pas un détail |
| **C-49** | **jeton exposé** | le responsable a collé un `ghp_…` dans la conversation | **AUCUN SECRET DANS LA CONVERSATION. JAMAIS.** (voir Partie 5) |
| **C-50** | artefact vide silencieux | `if-no-files-found: ignore` a produit un artefact sans image, sans rien dire | **un garde-fou qui se tait n'est pas un garde-fou** |
| **C-51** | **image inamorçable** | le disque a `boot0` mais **65 536 octets de zéros** dans la zone d'amorçage de la slice | **on ne prouve pas une image en la publiant, mais en la démarrant** |
| — | **mon erreur du 29/10** | j'ai annoncé « l'artefact ne contient pas l'image » : **faux**, mon `glob` ne descendait pas dans `images/` | ne pas conclure d'un glob |
| — | **la dérive mesurée** | 80 acquis, 171 commits, **0/8 P0** | **on mesurait la mauvaise chose** |

## 3.1 C-51 en détail (le plus important)

**Mesure faite en ouvrant le disque octet par octet :**
```
secteur 0        : boot0 PRÉSENT (chaînes « F1 FreeBSD », « F6 PXE », « Boot: »)
slice 1          : type 0xa5 (FreeBSD), active, 4 685 824 secteurs
secteur 1        : TOUT À ZÉRO
octets 0-65535   : 0 octet non nul  ⇒  ni boot1, ni disklabel
offset 65536     : magic 0x19540119  ⇒  SUPERVBLOC UFS2 VALIDE
```
**Diagnostic : le disque contient un système complet, mais rien pour le lancer.**
`boot0` charge le premier secteur de la slice, y cherche `boot1`, trouve des zéros,
affiche **« Invalid Bootblock »** et s'arrête. **Confirmé à l'écran par le responsable.**

**Deux causes dans notre code (`fork/build-nexbsd.sh`) :**
```sh
mkimg -s mbr -b boot0 -p freebsd:=UFS      # boot0 dans le MBR, slice sans boot1
mkimg -s gpt -b pmbr  -p freebsd-ufs:=UFS  # pas de partition freebsd-boot/gptboot
```
Le commentaire du script avouait : *« jamais confrontée à une vraie machine : best effort »*.

**Seconde panne cachée derrière : aucun `/etc/fstab`.** `make distribution` n'en installe pas
(c'est l'installeur qui le fabrique, nous n'en avons pas) ⇒ le noyau se serait arrêté sur `mountroot>`.

---

# PARTIE 4 — LE CHEMIN, DANS L'ORDRE, ET IL N'EST PAS NÉGOCIABLE

## 4.1 La correction du cap (le responsable y a tenu, et il avait raison)

> **Nous avons construit l'emballage avant le produit.**
> Pendant huit jours : artefacts, releases, bundles, jetons, découpages, Drive, `gptboot`.
> C'était nécessaire pour **transporter**. Mais **le produit, lui, n'a pas avancé depuis le banc T-04.**

**Nouvelle règle, à appliquer sans exception :**
1. **D'abord un système qui fonctionne.**
2. **Ensuite seulement, son emballage.**

**Ce qui est interdit :** relancer une construction de plusieurs heures pour « voir »,
tant qu'un partage n'a pas été lu depuis une autre machine.

## 4.2 Les huit étapes P0 (le prototype minimal exigé par notre propre cahier des charges)

| # | Fonction | Ce qui la ferme | Dépend de |
|---|---|---|---|
| **1** | S-01 Démarrage | **un login s'affiche** dans QEMU | — |
| **2** | S-02 Matériel | `dmesg`, `pciconf -lv`, `sysctl hw.model` **dans NexBSD** | 1 |
| **3** | S-03 Réseau | une IP, `ping` vers MINT | 1 |
| **4** | S-04 Stockage | `df -h`, un fichier écrit puis relu | 1 |
| **5** | S-05 Utilisateurs | `pw useradd`, **`su` qui demande un mot de passe** | 1 |
| **6** | **N-01 Partages** | **`smbclient` depuis MINT lit un fichier** | 3, 5 |
| **7** | N-02 Droits | un utilisateur ne lit pas le dossier d'un autre | 6 |
| **8** | S-09 Sauvegarde | `tar`, restauration, comparaison | 4 |

> **Les huit P0 tiennent dans UNE machine et UN partage lu depuis MINT.**

## 4.3 La voie la plus courte pour y arriver (proposition, à décider avec le responsable)

**Le blocage actuel est S-01.** Deux routes :

**Route A — attendre la reconstruction.** Le correctif C-51 est écrit (chaîne officielle
`pmbr → gptboot → loader` + `fstab` + `loader.conf` + garde-fou `gpart`). Une construction
`buildworld`+`buildkernel` prend **~2 h 30** en CI et ne prouve que le démarrage.

**Route B — installer FreeBSD 15.1 dans QEMU sur MINT (~25 min), y appliquer les 28 Ko,
puis lancer `fork/80` (~15 min), puis lire le partage depuis MINT (~5 min).**
→ **On ferme cinq P0 en une soirée, et l'image devient ensuite la recopie d'un système qui marche.**

⚠️ **Cette route doit être validée par le responsable.** Elle ne viole pas la règle R-14
(« ne pas s'arrêter à une VM ajustée ») **à condition** que l'objectif reste l'image installable
et que la VM serve à **fabriquer et prouver** le produit, pas à le remplacer.

---

# PARTIE 5 — LES RÈGLES DU RESPONSABLE (ne jamais les enfreindre)

## 5.1 Sécurité — absolu

> **AUCUN SECRET DANS LA CONVERSATION. JAMAIS.** (A-76, née de C-49)
> Un jeton, mot de passe ou clé collé dans un message est un secret **perdu**.
> Un secret se saisit **là où il est utilisé** (terminal, notebook, *Secrets* du dépôt).
> Si un jeton est un jour nécessaire : **fine-grained**, un seul dépôt, une seule permission,
> une expiration.

- **Dépôt public ⇒ aucun mot de passe** dans le dépôt ni dans les workflows (R-15).
- `mdp-de-laboratoire-a-remplacer` ne subsiste que dans **l'historique git** : ne pas le réutiliser.
- **GPL (Samba, autres) jamais committé** dans le dépôt — transfert par bundles/Drive.

## 5.2 Communication

- **Écrire en français**, exhaustif et pédagogique, **sans supposer que le responsable suit le jargon**.
- **Quand il ne comprend pas, répondre en langage courant.**
- **Nommer le terminal en titre** : 🐧 **VM** (Debian invitée) vs 🖥️ **MINT** (son portable Ubuntu).
- **Une seule commande à la fois, avec la sortie attendue.**
- **Numéroter les étapes**, une sortie attendue par étape.
- **Aucune surveillance au premier plan.** Simplicité d'abord.
- **Ne plus poser de questions** quand on peut décider : décider et avancer.
  (Exception : une décision lourde de conséquences, comme la Route B ci-dessus.)
- **Ne jamais inventer ni « arranger » un résultat.** Distinguer **prouvé / supposé / impossible**.

## 5.3 Méthode

- **Ce qui n'est pas dans l'image n'est pas dans le produit** ; une configuration que rien n'applique
  n'y est pas non plus.
- **« Seulement ajuster une VM » est une faute grave (R-14)** : converger vers l'image.
- **Les composants du produit doivent avancer** — tout tour passé sur la tuyauterie doit être justifié.
- **Un intervenant qui parle doit pouvoir nommer LE FICHIER qu'il a produit** ; sinon il a commenté.
- **Quand un trou est nommé, l'exécuter tout de suite** (commit + bundle + Drive + sha256).
- **Un serveur doit toujours demander quelque chose pour entrer** — y compris le bureau.
- **On ne réécrit JAMAIS une preuve verbatim** (`tests/results/`) : on la **masque explicitement**.
- **L'âge d'un logiciel n'est pas un motif de rejet.**
- **Aucune idée n'entre sans décision écrite** (R-10/R-11).
- **Un garde-fou ne doit pas crier à tort** (M-10, C-41, C-48) **ni se taire quand il ne trouve rien** (C-50).

## 5.4 Matériel — contrainte absolue (PARTIE X du cahier des charges)

> **Le disque principal du PC de 2011 contenant Windows 7 NE DOIT PAS être modifié**
> pendant la phase initiale. Aucune installation, aucun partitionnement, aucun formatage
> sur ce disque. Préférer une image de test indépendante et une méthode de démarrage documentée.

---

# PARTIE 6 — CE QUI EXISTE DÉJÀ (ne pas le refaire)

## 6.1 Le delta produit : `fork/` — 41 fichiers

| Fichier | Rôle |
|---|---|
| `fork/sys/amd64/conf/NEXBSD_L1` | noyau du profil PC faible (5 périphériques retirés) |
| `fork/reference/GENERIC-15.1` | référence de comparaison (delta prouvé par `scripts/70`) |
| `fork/build-nexbsd.sh` | buildworld + buildkernel + installworld + **overlay** + `makefs` + `mkimg` (**corrigé C-51**) |
| `fork/70-appliquer-overlay.sh` | applique les 28 Ko sur une racine de système |
| **`fork/80-installer-nexbsd.sh`** | ⚠️ **installe Samba, OpenLDAP, nslcd, services — JAMAIS APPELÉ** |
| `fork/overlay/etc/pf.conf` | pare-feu, **prouvé au banc T-05/T-05a** |
| `fork/overlay/etc/sysctl.conf` | 13 réglages de durcissement (A-74) |
| `fork/overlay/etc/ssh/sshd_config.nexbsd` | clé seule, root interdit |
| `fork/overlay/etc/pam.d/su` | `su` exige un mot de passe |
| `fork/overlay/usr-local-etc-smb4.conf` | le partage (cœur du remplacement de NetWare) |
| `fork/overlay/usr-local-etc-openldap-slapd.conf` + `install-annuaire-base.ldif` | l'annuaire |
| `fork/overlay/usr-local-etc-nslcd.conf` + `etc-nsswitch.conf.fragment` | identités de l'annuaire |
| `fork/overlay/etc/fstab` + `boot/loader.conf` | 🆕 **capacité de démarrer (C-51)** |
| `fork/overlay/etc/rc.conf.defaults`, `motd`, `nexbsd-version` | services, message d'accueil, version |
| `fork/bureau/*` | bureau autonome (HTML/JS) + session X + **authentification PAM** + 31 tests |
| `fork/tools/` | outils d'analyse du noyau |

## 6.2 Les garde-fous — 25 scripts dans `scripts/`

| Script | Ce qu'il vérifie | État |
|---|---|---|
| `70-verifier-delta.sh` | le delta `fork/` est intact (**41 fichiers**, empreintes) | ✅ vert |
| `72-verifier-acquis.sh` | chaque acquis a une destination ; chaque cible existe | ✅ vert |
| `74-produire-image.sh` | la chaîne de production (6 étapes) | ✅ a produit 3 images |
| `75-verifier-durcissement.sh` | **19 protections**, 0 faiblesse, **3 absents** | ✅ vert |
| `76-verifier-produit-distant.sh` | 🆕 vérification **depuis MINT** : ports, silence, SSH, SMB1 | ✅ écrit et testé au banc |
| **`77-verifier-fonctions.sh`** | 🆕 **les 28 protagonistes ; affiche `n/8 P0`** | ✅ vert — affiche **0/8** |
| `20-ecrire-usb.sh`, `30/31-qemu-*.sh` | écrire une clé, lancer une VM | existants |

**Règles des garde-fous, apprises à leurs dépens :**
- `scripts/70` compte les fichiers **suivis par git** ⇒ `EXPECTED=41` échoue **avant** le commit.
- **`chmod +x` + `git update-index --chmod=+x`** : l'instantané perd les bits exécutables (C-30).
- `scripts/72` exige **exactement 7 champs** et **une seule cible qui existe** ; **`;` interdit dans
  les descriptions** (piège revenu **cinq fois**).
- Un `FAIT` sans preuve est refusé par `scripts/77`.

## 6.3 Les workflows

| Workflow | Travaux | État |
|---|---|---|
| **`nexbsd.yml`** | SONDE · CONTRÔLES · BUREAU · IMAGE (manuel) | ✅ 3/3 verts, **0 annotation** |
| **`publier-image.yml`** v2 | 5 étapes : `find` + échec si aucun fichier > 100 Mo · empreintes · découpage > 1,9 Gio · Release · envoi un par un | ✅ **8/8 vertes**, Release `image-18` publiée |

**Exécution #25** (`41108532795`, sha `2b351e2a`, lancée 2026-10-30 18:37Z) : **IMAGE en cours** —
c'est la première construction avec le correctif C-51. **Vérifier son résultat par l'API.**

## 6.4 Le bureau

`fork/bureau/nexbsd-bureau.html` (interface autonome), `nexbsd-session.sh` (X11 + openbox +
WebKitGTK), `nexbsd-authentifier.sh` (**PAM, refuse root**), et **31 cas de test** exécutés en CI.
**Il n'a JAMAIS été affiché à l'écran.**

---

# PARTIE 7 — CE QUI N'A JAMAIS ÉTÉ FAIT (l'honnêteté du projet)

| Jamais fait | Conséquence |
|---|---|
| **Aucune image NexBSD n'a démarré** | C-51 |
| **Aucun partage SMB lu depuis une autre machine** | **A-02, le cœur du produit** |
| **Aucune session utilisateur ouverte** | S-05, A-22 |
| **Aucun compte créé dans l'annuaire** | A-03, A-04, A-05 |
| **Le bureau n'a jamais été affiché** | A-21, A-54 |
| **`fork/80` n'a jamais été exécuté** | **D-05, le défaut central** |
| **Aucune impression réseau** | N-07 |
| **Aucune compatibilité NCP testée** | N-11 (recherche) |

---

# PARTIE 8 — COMMENT TRAVAILLER AVEC CE DÉPÔT (procédures exactes)

## 8.1 Lire l'état réel par l'API (le dépôt est PUBLIC)

```bash
# dernière exécution
curl -s "https://api.github.com/repos/mlinux952-code/nexbsd/actions/runs?per_page=5" \
  | python3 -c "import sys,json;[print(r['run_number'],r['name'][:40],r['status'],r['conclusion'],r['head_sha'][:8]) for r in json.load(sys.stdin)['workflow_runs']]"

# détail des travaux et étapes d'une exécution
curl -s "https://api.github.com/repos/mlinux952-code/nexbsd/actions/runs/<ID>/jobs" \
  | python3 -c "import sys,json;[print(j['name'],j['conclusion'],[(s['number'],s['name'][:50],s['conclusion']) for s in j['steps']]) for j in json.load(sys.stdin)['jobs']]"

# contenu d'une Release, actif par actif
curl -s "https://api.github.com/repos/mlinux952-code/nexbsd/releases/tags/image-18" \
  | python3 -c "import sys,json;d=json.load(sys.stdin);print(len(d['assets']),'actifs');[print(' ',a['name'],a['size']) for a in d['assets']]"

# le correctif est-il bien sur GitHub ?
curl -s "https://raw.githubusercontent.com/mlinux952-code/nexbsd/main/fork/build-nexbsd.sh" | grep -c "freebsd-boot/bootfs"
```

⚠️ **`GET /actions/runs/<id>/logs` renvoie 403** (« Must have admin rights ») : **les journaux ne
sont pas lisibles**. Raisonner sur ce que l'API expose (jobs, steps, releases) et sur ce que le
workflow a **écrit** dans le corps de la Release.

## 8.2 Transférer du travail (bundles)

```bash
# dans l'atelier : créer + empreinte
git bundle create s0NN.bundle --all && sha256sum s0NN.bundle
# uploader sur Drive PUIS make_public DANS LA MÊME ACTION (oublié 10 fois)

# sur MINT : récupérer + appliquer + pousser + PROUVER
cd ~/Téléchargements && curl -L -o s0NN.bundle "https://drive.usercontent.google.com/download?id=<ID>&export=download&confirm=t" \
 && sha256sum s0NN.bundle \
 && cd ~/Projets/nexbsd && git fetch "/home/omrane/Téléchargements/s0NN.bundle" main:refs/bundles/s0NN \
 && git merge --ff-only refs/bundles/s0NN \
 && GIT_SSH_COMMAND="ssh -o BatchMode=yes -o StrictHostKeyChecking=accept-new" git push origin main \
 && git ls-remote origin refs/heads/main && git rev-parse HEAD
```

## 8.3 Avant CHAQUE commit

```bash
chmod +x $(find scripts fork -name '*.sh')
git add -A && git update-index --chmod=+x $(find scripts fork -name '*.sh')
git commit -m "…"
sh scripts/70-verifier-delta.sh     # attendu : DELTA INTACT (41 fichiers)
sh scripts/72-verifier-acquis.sh    # attendu : REGISTRE CONFORME
sh scripts/77-verifier-fonctions.sh # attendu : affiche n/8 P0
```

## 8.4 Publier une image

Actions → **PUBLIER — l'image NexBSD en Release** → Run workflow
→ `run_id` = id de l'exécution IMAGE, `tag` = `image-NN`.

---

# PARTIE 9 — LES PROCHAINES ACTIONS, DANS L'ORDRE

## Immédiat (à faire avant tout)

1. **Pousser `09ed778`** (bundle **s087**, Drive `10zvNuTkqmHY56i3SIsY59wk5Fb8p3TX1`).
   Prouver avec les **deux lignes identiques**.
2. **Lire le résultat de l'exécution #25** par l'API. Le résumé doit contenir :
   ```
   [OK ] .../boot/gptboot     [OK ] .../boot/pmbr     [OK ] .../boot/loader
   gpart :  1  40  1  freebsd-boot      ← la ligne décisive
   [OK ] partition freebsd-boot presente
   ```
   - **présente** ⇒ le disque est amorçable ⇒ publier (`tag = image-25`) et **démarrer**.
   - **absente** ⇒ le script échoue exprès : on diagnostique, on ne publie pas.

## Ensuite, dans cet ordre strict

3. **Démarrer** (QEMU sur MINT, **overlay qcow2** pour ne pas abîmer la preuve) → **login** ⇒ **S-01 fermé**.
4. **`motd` → NexBSD**, nom d'hôte `nexbsd` ⇒ A-17, A-08 (**toujours hors de l'image aujourd'hui**).
5. **Appeler `fork/80`** dans la chaîne (ou à la main dans la VM) ⇒ **D-05 fermé**.
6. **`smbclient` depuis MINT** ⇒ **N-01 fermé — A-02 fermé. Ce jour-là, le projet a un produit.**
7. `scripts/76` depuis MINT ⇒ premier rapport de sécurité extérieur.
8. Annuaire + identités (A-03 → A-06, A-22).
9. Bureau (A-21, A-54) — **⚠️ disque trop petit : 827 Mo libres estimés, il en faut ~960.
   Augmenter `TAILLE_MO` dans `fork/build-nexbsd.sh` avant.**

## Décisions encore ouvertes

- **ADR-0021** (racine en lecture seule, `bectl`, `securelevel ≥ 1`, `/etc` séparé) : **en PROPOSITION**,
  comme les 20 autres ADR. Trois choix, **recommandation : choix 2 (plus tard)**.
- Restes : 🔴 `login.conf` (politique de mot de passe) · 🟠 `server min protocol` (SMB) ·
  🟡 `AllowUsers` (SSH) · câbler `nexbsd-script-connexion.sh` · A-18 (comment devient-on root).

---

# PARTIE 10 — CE QU'IL NE FAUT PAS FAIRE (erreurs déjà commises)

| Ne pas refaire | Pourquoi |
|---|---|
| **Chercher de nouveaux outils à ajouter** | sur **~110 outils** des affiches, **11 seulement** servent à vérifier NexBSD ; **aucun** n'ajoute une fonction au produit (`docs/67`) |
| Installer des outils offensifs **sur NexBSD** | ils tournent **sur la machine qui mesure** (MINT), jamais sur la machine mesurée |
| Relancer une construction de 2 h 30 « pour voir » | tant qu'un partage n'a pas été lu depuis MINT |
| Mesurer l'avancement au **nombre d'acquis/commits/docs** | le seul chiffre est **`n/8` P0** |
| Compter sur un débogage par les journaux GitHub | **403, illisibles** |
| Mettre un secret dans la conversation | **jamais** (A-76) |
| Croire qu'un rond vert de CI = produit qui fonctionne | il dit seulement « la chaîne n'a pas planté » |
| Réécrire une preuve verbatim | on la **masque**, on ne la réécrit pas |
| Oublier `make_public` après un upload Drive | **oublié 10 fois** — même action |
| Réutiliser `samba419` sans vérifier qu'il existe sur FreeBSD 15.1 | **risque n° 1 du projet** : 15.1 est très récent |

---

# PARTIE 11 — LES TROIS RISQUES QUI PEUVENT TOUT ARRÊTER

1. **FreeBSD 15.1 est très récent.** `samba419`, `xorg`, `webkit2gtk` peuvent manquer ou être
   incomplets. Si `pkg install samba419` échoue, **le produit n'existe pas** — il faudra choisir
   entre descendre en 14.x (mieux fournie) et attendre. **C'est un risque de calendrier, pas de code.**
2. **Le disque est trop petit** (827 Mo libres vs ~960 Mo pour le bureau). **Une ligne à changer,
   mais si on l'oublie, `fork/80` échoue après des heures.**
3. **`fork/70` et `fork/80` n'ont jamais tourné ensemble.** Les bancs T-04/T-05 ont prouvé la
   configuration **sur une VM FreeBSD d'essai**, pas **dans l'image NexBSD**.

---

# PARTIE 12 — LA RÉPONSE À LA QUESTION DU RESPONSABLE

> *« On peut récupérer notre vrai système NexBSD, oui ou non ? »*

**OUI.** Le socle est sain, la configuration est prouvée au banc, l'installeur est écrit,
la chaîne de publication fonctionne, les garde-fous font leur travail. **Il n'y a pas à
recommencer : il y a à brancher.**

**NON, pas ce soir.** Ce que nous avons est **FreeBSD avec 28 Ko de NexBSD dessus**, et **0/8** des
fonctions minimales. **Le branchement de `fork/80` et la lecture d'un partage depuis une autre
machine sont ce qui fera la différence — une journée de travail, pas un mois.**

**Délais honnêtes :**

| Objectif | Durée |
|---|---|
| ça démarre et ça dit NexBSD | ce soir, si #25 est vert |
| Samba + LDAP installés et démarrés | 1 à 2 jours |
| **partage lu depuis MINT** | +1 journée |
| annuaire et identités | 2 à 3 jours |
| bureau | 1 à 2 semaines |
| **un NexBSD qui remplace vraiment un serveur NetWare** | **2 à 3 semaines** |

---

# PARTIE 13 — CE QU'ON ATTEND DE TOI, ASSISTANT, DÈS LE PREMIER MESSAGE

1. **Ne me félicite pas.** Ne dis pas que le projet est impressionnant.
2. **Lis ce document, vérifie par l'API, et dis-moi où nous en sommes vraiment** — en trois
   phrases et un tableau.
3. **Donne UNE seule commande**, celle qui fait avancer le P0 en cours, avec la sortie attendue.
4. **Nomme le terminal** (🖥️ MINT ou 🐧 VM).
5. **Si tu ne sais pas, dis-le.** Si c'est impossible, dis pourquoi et propose le plus proche.
6. **Rappelle-moi le compte `n/8` à chaque fois.** C'est le seul chiffre qui compte.

**Le projet ne repart pas de zéro. Il repart d'un chiffre vrai : 0/8.**

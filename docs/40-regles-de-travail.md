# Règles de travail — la méthode du projet, consolidée

**Date :** 2026-10-27 · **Rôle :** rassembler en un seul endroit les règles que le responsable a données
et les leçons tirées de nos échecs. Ce document **n'invente rien** : chaque règle vient d'une consigne
explicite ou d'un incident consigné.

---

## 1. Règles données par le responsable (intouchables)

| # | Règle | Origine |
|---|---|---|
| R-1 | Écrire en **français**, de façon exhaustive et pédagogique | consigne permanente |
| R-2 | **Toujours nommer le terminal** : 🖥️ MINT (`omrane@omrane-Inspiron-3520`) ou 🐧 VM (`root@nexbsd`) | incident du 2026-10-27 (`cd ~/Téléchargements` tapé dans la VM) |
| R-3 | **Une seule commande à la fois**, avec la sortie attendue, puis attendre la sortie réelle | consigne permanente |
| R-4 | **Ne jamais inventer ni « arranger » un résultat** ; consigner les échecs verbatim | consigne permanente |
| R-5 | **Ne jamais oublier le nom du produit** : le produit est **NexBSD** ; `uname -s` = `FreeBSD` désigne le socle | consigne permanente |
| R-6 | Exiger les **« points sur les i »** : prouvé / supposé / impossible en l'état | consigne permanente |
| R-7 | **Objectif non négociable** : un vrai système pour PC, pas un FreeBSD modifié ; installation propre = **J5** | consigne permanente |
| R-8 | Les fichiers **GPL tiers** ne doivent **jamais** entrer dans le dépôt | consigne permanente |
| R-9 | Ne pas toucher au terminal Mint qui sert un dossier ; transferts par **bundles Drive** avec sha256 | consigne permanente |
| R-10 | **Ne pas maquiller** : un test non exécuté s'écrit `NON EXÉCUTÉ`, jamais `OK` | méga-prompt + pratique |
| R-11 | Un apport extérieur **ne change pas la route du produit** | consigne du 2026-10-26 |

## 2. Règles que nos échecs ont imposées

| # | Règle | Incident qui l'a imposée |
|---|---|---|
| M-1 | **Aucune commande de surveillance au premier plan** (pas de `while … done` sans `&`) : elle rend le terminal inutilisable | 2026-10-26, boucle d'attente de `buildkernel` |
| M-2 | **Toute opération longue en arrière-plan, avec journal** (`nohup … > log 2>&1 &`), et un compteur pour distinguer « long » de « figé » | `installkernel` (858 modules) paraissait bloqué |
| M-3 | **Vérifier l'empreinte avant d'exécuter un fichier téléchargé** | Drive renvoie une page HTML au lieu du script (2 458 o, 0 ligne) |
| M-4 | **Valider à blanc avant d'appliquer** (`pfctl -n -f`, `sh -n`) | C-22 et C-23, deux échecs propres |
| M-5 | **Ne pas écrire de mémoire** : une syntaxe « qui paraît juste » (ex. `max 20/s` en `pf`) fait perdre une session | C-23 |
| M-6 | **Lire la sortie jusqu'à sa ligne d'en-tête** (`hote :`, `uname -r`) avant de compter un succès | 11/11 sur le noyau FreeBSD au lieu de `NEXBSD_L1` (C-20) |
| M-7 | **Un script interroge la réalité** (quel hyperviseur ? quel domaine ?) avant d'agir | C-21, `scripts/31` cherchait une image QEMU inexistante |
| M-8 | **Un harnais qui se trompe est plus dangereux qu'aucun harnais** : il accuse le système à tort. Tout contrôle se recopie d'une **source déjà validée** | T-18 v1.0 : `ls -ld` au lieu de `ls -ldn`, texte de `smbclient` au lieu du code de retour |
| M-9 | **Toujours afficher le code de retour** (`echo "CODE : $?"`) : le texte peut mentir, pas le code | harnais v1.0 : « putting file » s'affiche même en cas de succès |

## 3. Format d'une session

1. **Révision** des trois sources : mur de discussion, workspace, Drive.
2. **Une** commande, avec la sortie attendue **écrite à l'avance**.
3. **Consignation verbatim** avant toute conclusion.
4. **Commit** avec un message qui dit *ce qui est prouvé*, pas ce qu'on espère.
5. **Bundle** déposé sur Drive + sha256, puis rendu public.
6. **`docs/3x-reprise`** mis à jour : la session doit être reprenable **sans conversation**.

## 4. Ce que ces règles protègent

| Risque | Règle qui protège |
|---|---|
| perdre le delta du fork | garde-fou `scripts/70` + `fork/` (nom `build` interdit) |
| croire à un succès inexistant | M-6, M-8, M-9, R-10 |
| casser le banc en croyant le protéger | M-4, M-7 |
| perdre le travail avec la conversation | R-9, bundles Drive, `docs/3x-reprise` |
| dériver vers un autre produit | R-11, ADR-0001/0011 |

**Une règle sans incident qui l'illustre est une règle décorative.** Toutes celles de la partie 2 ont coûté
quelque chose : c'est pour cela qu'elles tiennent.

---

## R-12 — Tout acquis a une DESTINATION écrite, sinon il n'existe pas

**Formulé par le responsable le 2026-10-27 :**
> *« chaque manipulation, amélioration ou n'importe quoi doit impérativement être dans la version
> finale, sinon pour quoi on fait tout ça »*

**Règle.** Aucun travail n'est terminé tant que sa destination n'est pas écrite dans
`matrices/acquis.csv`. Trois destinations légitimes, une seule interdite :

| Destination | Sens | Exemple |
|---|---|---|
| **PRODUIT** | doit se retrouver dans l'image NexBSD (via `fork/overlay/` ou la chaîne de release) | `pf.conf`, `pam.d/su`, `sshd_config` |
| **MÉTHODE** | ne va **pas** dans l'image, mais empêche de refaire une erreur | `scripts/70`, `scripts/72`, leçons C-25→C-29 |
| **PREUVE** | ne va **pas** dans l'image, mais prouve que l'image fait ce qu'elle prétend | `tests/results/`, `tests/harnais.sh` |
| ❌ **INTERDIT** | « c'est fait dans la VM, on s'en souviendra » | — c'est précisément ce que le registre empêche |

**Contrôle automatique :** `sh scripts/72-verifier-acquis.sh` échoue si une cible `PRODUIT` n'existe pas
dans le dépôt, et **affiche** ce qui est encore `OUVERT` ou `A-FAIRE` — un acquis oublié doit crier.

**Ce que la règle ne dit pas :** elle n'oblige pas à tout mettre dans l'image. Mettre `hostfwd` ou un
script de banc dans le produit serait une faute inverse. Elle oblige à **choisir et à écrire le choix**.

---

## M-10 — Un garde-fou qui crie à tort finit par être ignoré

**Incident (2026-10-27) :** le delta du fork est passé de 17 à 20 fichiers (ajout de `pf.conf`,
`sshd_config.nexbsd`, `pam.d/su`). `scripts/70` a répondu `[ECHEC] Suppression accidentelle probable`,
alors qu'il n'y avait **aucune** suppression. Si l'on avait pris l'habitude de passer outre, le jour où une
**vraie** suppression aurait lieu, personne n'aurait regardé.

**Règle :** quand la référence d'un garde-fou change **légitimement**, on met à jour **la référence avec sa
justification, le jour même**, dans le script lui-même. On ne désactive jamais le contrôle.

## M-11 — Un garde-fou n'est prouvé que s'il a déjà échoué au moins une fois

**Constat (2026-10-27) :** `scripts/72` a d'abord été testé sur un registre conforme — il a répondu
`CONFORME`. Ce n'est pas une preuve : un script qui dit toujours « tout va bien » produit exactement la
même sortie. Le registre a donc été **volontairement cassé** (une cible renommée en
`pf-AINE-QUI-N-EXISTE-PAS.conf`) :

```
  [KO]    A-09 : cible ABSENTE du depot : fork/overlay/etc/pf-AINE-QUI-N-EXISTE-PAS.conf
VERDICT : REGISTRE NON CONFORME — 0 destination(s) invalide(s), 1 cible(s) en defaut.
```

Puis restauré → `CONFORME`. **Le garde-fou détecte vraiment.**

**Règle :** tout garde-fou nouveau doit être testé **dans les deux sens** (cas conforme + cas en défaut),
et la sortie du cas en défaut est consignée. Même exigence que pour `nc` sous slirp (C-25) : une mesure qui
ne peut pas dire « non » ne dit rien du tout.

---

## R-13 — Un test réussi n'est pas un produit

**Constaté le 2026-10-27** (audit rétrospectif `docs/45`) : les tests T-04, T-04-E, T-04-F et T-04-G sont
réussis depuis quatre jours, avec preuves verbatim. Mais la **configuration** qui les rend possibles
(`slapd.conf`, `smb4.conf`, `nsswitch.conf`, `nslcd.conf`, LDIF) n'existe **que dans les scripts de banc**,
sous forme de commandes. **Aucune image ne peut être produite à partir de là.**

**Règle.** La réussite d'un test ne dispense pas d'écrire le **fichier de configuration** correspondant
dans `fork/overlay/`. Un acquis ne passe à `FERME` que si sa **cible existe dans le dépôt**, pas parce que
le test est vert.

**Corollaire opérationnel :** quand un script de banc écrit un fichier de configuration sur la cible
(`cat > /usr/local/etc/… <<'CONF'`), ce contenu doit être **extrait** vers `fork/overlay/` et le script
doit devenir un simple applicateur — sinon on maintient deux vérités qui divergeront.

---

## R-14 — Une session qui ne produit que du banc doit le dire

**Née de la remarque du responsable, 2026-10-27 :**
> *« depuis le début seulement tu ajustes sur une version de VM… j'espère que c'est la dernière fois
> comme faute grave »*

**Constat qui lui donne raison :** 25 fichiers de produit, 13 scripts de banc, **0 image produite** en
quatre jours. Tout ce qui a été **exécuté** l'a été dans une VM, parce que le poste (3,7 Go de RAM) ne
peut pas construire (ADR-0010 exige 8 Go).

**Règle.** Chaque session se termine par une ligne dans `matrices/acquis.csv`. Si **aucun** acquis n'a
progressé vers `PRODUIT` **ou** vers la **chaîne de production** (`scripts/74`, `.cirrus.yml`,
`fork/release.conf`), la session est déclarée **« session de banc »** : utile, documentée, mais **pas un
pas vers J5**. Le dire fait partie du travail.

**Corollaire.** Un test réussi dans une VM ne rapproche pas l'image. Ce qui rapproche l'image, c'est :
un fichier de configuration dans `fork/overlay/`, une pièce de la chaîne de production, ou une exécution
réelle de cette chaîne.

---

## R-15 — 2026-10-28 — Aucun mot de passe de laboratoire nulle part, ni dans le code, ni dans les preuves

**Règle.** Une valeur d'authentification, même « de laboratoire », même sur une VM jetable, **n'a rien
à faire dans le dépôt** : ni ligne active, ni commentaire, ni compte rendu. Un dépôt se copie, se
bundle, se publie.

**Pourquoi cette règle existe.** Mesuré le 2026-10-28 : les valeurs du banc figuraient **30 fois dans
10 documents** et dans **6 scripts actifs**, en plus de 4 commentaires de configuration. Le garde-fou
de `scripts/74` ne regardait que `fork/` — il disait « aucun mot de passe » depuis quatre jours, en
toute bonne foi. Un garde-fou mal cadré est pire qu'aucun garde-fou : il rassure à tort.

**Corollaires :**
1. tout script qui a besoin d'un mot de passe le reçoit par **variable obligatoire**
   (`${NEXBSD_…:?…}`), jamais par valeur par défaut — pas de retour silencieux ;
2. le garde-fou de `scripts/74` couvre `fork/` + `scripts/` + `tests/*.sh`, et ses motifs sont
   assemblés à l'exécution pour qu'il ne se détecte pas lui-même ;
3. les comptes rendus de test restent des **preuves verbatim** mais les valeurs y sont **masquées**,
   avec une note d'en-tête indiquant où se trouve l'original et son empreinte ;
4. **l'historique Git conserve ce qui a été committé.** Masquer dans la version courante ne lave pas
   les commits antérieurs. Une valeur ayant séjourné dans un dépôt doit donc être considérée comme
   **brûlée** : jamais réutilisée, même en laboratoire.

**Statut au 2026-10-28 : appliqué.** `git grep` sur tout le contenu courant → aucune occurrence.
Historique : **9 commits** contiennent encore les valeurs (assumé, voir `docs/50` §5).

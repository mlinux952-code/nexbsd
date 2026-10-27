# Est-ce que tout ce qu'on a fait ce soir sera dans NexBSD 0.1 ?

**Question du responsable, 2026-10-27 au soir :** *« tout ça, on peut le trouver dans la version
finale exécutable de NexBSD 0.1 ou non ? »*

**Réponse courte :** **oui, ça DOIT y être — mais aujourd'hui ce n'est pas encore dedans.** Ce soir, tout
a été appliqué **à la main dans une VM de laboratoire**. Un réglage tapé dans une VM n'est pas un
produit : c'est une **recette**. Le produit, c'est l'**image** qui porte ce réglage dès l'installation.
Ce document dit exactement ce qui a été fait, où cela doit atterrir, et ce qui manque pour que ce soit
vrai.

---

## 1. La distinction qui compte : la recette et le gâteau

| | Ce qu'on a ce soir | Ce que sera NexBSD 0.1 |
|---|---|---|
| Forme | une VM FreeBSD 15.1 configurée **à la main**, plus des scripts | une **image** installable, produite par le projet |
| Rejouable ? | oui, en rejouant les scripts **à la main**, dans l'ordre | oui, **automatiquement**, dès la première installation |
| Si on perd la VM ? | on recommence tout | l'image reste |
| Nom du produit à l'écran | `FreeBSD 15.1-NEXBSD-L1` + un `motd` qui parle de FreeBSD | **NexBSD**, partout |
| Statut honnête | **banc d'essai** | **produit** — à ce jour : **n'existe pas** |

**Aucune image NexBSD n'existe.** Le jalon d'installation propre sur un PC est **J5**, non atteint.
Dire « c'est dans NexBSD 0.1 » aujourd'hui serait exactement la faute que le projet interdit.

---

## 2. Ce qui a été fait ce soir, et où cela doit atterrir dans le produit

| Réglage appliqué ce soir (VM) | État dans le produit | Emplacement cible | Fait ? |
|---|---|---|---|
| 11 règles `pf` (refus par défaut **journalisé**) | ✅ **écrit** ce soir | `fork/overlay/etc/pf.conf` | ✅ fichier créé |
| SSH : clé seule, mot de passe coupé, root interdit | ✅ **écrit** ce soir | `fork/overlay/etc/ssh/sshd_config.nexbsd` | ✅ fichier créé (méthode d'insertion **à trancher**, F-2) |
| `su` exige un mot de passe (fin du passe-partout `wheel`) | ✅ **écrit** ce soir | `fork/overlay/etc/pam.d/su` | ✅ fichier créé |
| NTP armé au démarrage | ✅ **écrit** ce soir | `fork/overlay/etc/rc.conf.defaults` | ✅ |
| Identité du système (nom d'hôte `nexbsd`) | ✅ déjà au delta | `rc.conf.defaults` + `motd` | ✅ existant |
| **`/etc/motd` qui annonce encore FreeBSD** | ❌ **reste à corriger** | `fork/overlay/etc/motd` | ⚠️ le fichier existe mais **n'est pas installé** dans la VM |
| Annuaire LDAP + Samba + droits par groupes | ❌ **pas dans le delta** | chaîne d'installation « Plateforme » | ❌ à faire |
| `hostfwd` du banc (`127.0.0.1:4450`) | ❌ **spécifique au laboratoire** | **jamais** dans le produit | — (confort de banc) |

**Point capital :** les quatre fichiers créés ce soir sont des **fichiers de référence**. Ils ne sont
**pas** installés par une chaîne de release, parce que cette chaîne n'existe pas encore. Ils disent au
futur : *« voilà ce que l'image devra porter »*, avec l'origine et la preuve en commentaire.

---

## 3. Pourquoi ça ne « s'installe pas tout seul » : les trois verrous

| Verrou | Nature | Ce qu'il faut |
|---|---|---|
| **V-1. La chaîne de release** (`release.sh` + CI) | technique | construire une image à partir de l'arbre + du delta + du `overlay/`. C'est `docs/41` (Cirrus CI natif FreeBSD) |
| **V-2. L'installateur** | conception | c'est lui qui renseigne `IFACE` (F-1), pose la question SSH (ADR-0021), crée le premier compte, installe la clé de l'administrateur |
| **V-3. Les décisions non prises** | gouvernance | ADR-0021 (comment un admin obtient les droits : `su`, `doas`, `sudo` ?) ; politique de mise à jour (livrable 17) |

Aucun des trois n'est un problème de code : ce sont **des étapes du plan**, dans l'ordre de `docs/33`.

---

## 4. Ce que « NexBSD 0.1 exécutable » voudra dire, concrètement

Pour qu'on puisse honnêtement prononcer ces mots, il faudra **tout** ceci :

1. une **image** (`.img` ou `.iso`) construite par le projet, avec une **empreinte SHA256** publiée ;
2. cette image **installée sur le PC de 2011** (ou une VM neuve) **sans aucune commande manuelle** ;
3. au premier démarrage : `uname -r` = `15.1-NEXBSD-…`, `motd` = **NexBSD**, `pf` actif, harnais **24/24** ;
4. une **procédure de mise à jour** écrite (livrable 17) ;
5. le **rapport de validation** unique (livrable 12) qui liste fonctions et limites.

Tant que ces cinq points ne sont pas tous vrais, le mot juste est **« banc d'essai »**, pas « version 0.1 ».

---

## 5. Ce que cela change pour la suite immédiate

Le travail de ce soir n'est **pas** perdu : il devient le **contenu** de l'image. La prochaine marche
utile n'est donc pas un nouveau test, mais **la chaîne qui transforme ces fichiers en système** :

1. corriger `/etc/motd` **dans la VM** (défaut visible par tout utilisateur) — 1 commande ;
2. **ramener le banc à une seule commande** : `scripts/31 --reseau` + harnais 24/24 ;
3. écrire **ADR-0021** (droits d'administration) — décision à faire trancher ;
4. `release.sh` + CI (`docs/41`) → **première image**, puis J5.

C'est exactement l'ordre de `docs/43` §5. **On ne change pas de route : on remplit le moule.**

---

## 6. Addendum — le garde-fou a parlé, et il avait raison

En commitant les trois nouveaux fichiers du produit, `scripts/70-verifier-delta.sh` a répondu :

```
[ECHEC] Suppression accidentelle probable — verifier : git status --short ; git log --diff-filter=D -- fork
```

**Ce n'était pas une suppression : c'était une croissance.** Le delta est passé de **17 à 20 fichiers**
(ajout de `pf.conf`, `sshd_config.nexbsd`, `pam.d/su`), et la liste de référence du garde-fou n'avait pas
suivi.

**Décision prise :** mise à jour **motivée** de `scripts/70`, avec la raison écrite dans le script
lui-même (`17 → 20 fichiers, réglages prouvés au banc T-05/T-05a/T-21`). Après quoi :

```
VERDICT : DELTA INTACT (20 fichiers, empreintes conformes)
```

**Leçon de méthode (M-10, à ajouter à `docs/40`) :** un garde-fou qui crie **à tort** finit par être
ignoré, et un garde-fou ignoré ne protège plus rien. Quand sa référence change légitimement, il faut
**mettre à jour la référence avec sa justification**, le jour même — jamais désactiver le contrôle.

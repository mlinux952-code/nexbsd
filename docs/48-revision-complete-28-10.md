# 48 — Révision complète, 28 octobre 2026 : ce que NexBSD contient **réellement**

**Ce que le responsable a demandé, mot pour mot :** *« je insiste à la révision de tous notre machin
parce que je sais bien que tu ajustes la VM sans faire rien à notre système nexbsd ».*

**Verdict d'entrée, avant toute mesure : il a raison.** Le défaut qu'il décrit existait, et il était
plus grave que ce que j'avais écrit la veille. Ce document le prouve par des commandes, puis décrit
ce qui a été corrigé dans la même soirée.

---

## 1. Le défaut, mesuré, en une commande

```
$ grep -n 'overlay' fork/build-nexbsd.sh
>>> AUCUNE MENTION DE 'overlay' DANS build-nexbsd.sh <<<
```

**Traduction simple :** nous avions **11 fichiers de configuration** du produit (annuaire, Samba,
pare-feu, SSH, PAM, identité). Le script qui construit l'image **ne les connaissait pas**. Une image
construite hier aurait été **« FreeBSD + un noyau maison »** : rien de NexBSD dedans, à part le noyau.
Le responsable a donc raison sur le fond, pas seulement sur la méthode.

---

## 2. Le volume réel du projet, au 28 octobre

| Dossier | Fichiers | Lignes | Nature |
|---|---|---|---|
| `docs/` | 78 | 9 646 | comptes rendus, décisions, audits — **ne va pas dans l'image** |
| `scripts/` | 23 | 3 929 | outils de banc — **ne va pas dans l'image** |
| `tests/` | 17 | 2 605 | preuves — **ne va pas dans l'image** |
| **`fork/`** | **26** | **~4 200** | **le produit : ce qui peut entrer dans l'image** |
| `matrices/` | 7 | 203 | registre des acquis |
| `research/` | 16 | 1 303 | veille |

**Le rapport est brutal : 26 fichiers de produit contre 141 pièces de méthode, de preuve et de
documentation.** C'est exactement le déséquilibre que le responsable dénonce. Il ne s'agit pas de
jeter les 141 — sans elles, les erreurs reviennent — mais **la prochaine session doit pencher du côté
des 26**.

---

## 3. Ce qui a changé CE SOIR, dans le produit

### 3.1 Un maillon manquant a été écrit : `fork/70-appliquer-overlay.sh`

Il fait passer la configuration **du dépôt vers le système** :

| Ce qu'il pose | Destination dans le système |
|---|---|
| `etc/nexbsd-version` | `/etc/nexbsd-version` (l'identité) |
| `etc/pam.d/su` | `/etc/pam.d/su` (su exige un mot de passe — A-14) |
| `etc/pf.conf` | `/etc/pf.conf` (pare-feu) |
| `etc/ssh/sshd_config.nexbsd` | `/etc/ssh/sshd_config` (clé seule, root interdit) |
| `etc/motd` | `/etc/motd` (ne dit plus « FreeBSD » — A-17) |
| `usr-local-etc-openldap-slapd.conf` | `/usr/local/etc/openldap/slapd.conf` |
| `usr-local-etc-smb4.conf` | `/usr/local/etc/smb4.conf` |
| `usr-local-etc-nslcd.conf` | `/usr/local/etc/nslcd.conf` |
| `install-annuaire-base.ldif` | `/root/install-annuaire-base.ldif` |
| `etc-nsswitch.conf.fragment` | **fusion** dans `/etc/nsswitch.conf` |
| `etc/rc.conf.defaults` | **fusion** dans `/etc/rc.conf` |

### 3.2 Il a été testé — quatre essais, dont deux échecs volontaires

**Essai 1 — sans aucun mot de passe (doit refuser) :**
```
  [KO] @NEXBSD_LDAP_ROOTPW@ sans valeur (-R)
  [KO] @NEXBSD_LDAP_BINDPW@ sans valeur (-b)
  [KO] @NEXBSD_SID@ sans valeur (-p) — lire 'net getlocalsid' APRES la première installation
ARRET : aucun fichier écrit. Rien de partiel n'a été laissé.
fichiers ecrits apres refus ? 0
```

**Essai 2 — simulation :** `SIMULATION : la configuration du produit EST applicable. Rien n'a été écrit.`
→ 0 fichier créé (les 2 fichiers présents sont ceux que j'avais posés pour imiter un système).

**Essai 3 — application réelle sur une racine imitant FreeBSD :**
```
  [OK ] /etc/nexbsd-version présent (117 o)
  [OK ] /etc/pam.d/su présent (1201 o)
  [OK ] /etc/pf.conf présent (2750 o)
  [OK ] /usr/local/etc/openldap/slapd.conf présent (1929 o)
  [OK ] /usr/local/etc/smb4.conf présent (2262 o)
  [OK ] /usr/local/etc/nslcd.conf présent (1571 o)
  [OK ] aucun placeholder ne subsiste
VERDICT : configuration du produit APPLIQUÉE sur /tmp/fauxroot (11 fichiers, 2 fusions).
```

**Essai 4 — idempotence (relancer ne casse rien) :**
```
  [--  ] /etc/nsswitch.conf : déjà à jour
  [--  ] /etc/rc.conf : déjà à jour
doublons de cles dans rc.conf : AUCUN
nsswitch.conf obtenu :  group: files / dns: files / passwd: files ldap   <- « files » reste en PREMIER
```

### 3.3 Deux bugs trouvés **par** ces tests, et corrigés

| Bug | Ce qui se passait | Correction |
|---|---|---|
| Fusion de `rc.conf` | je ne reconnaissais que le séparateur `:` ; `rc.conf` utilise `=` → **doublons** (`sshd_enable="YES"` **puis** `"NO"`, la dernière gagne **par hasard**) | la clé est cherchée avant `:` **ou** `=` |
| Verdict du garde-fou C-30 | un script non exécutable faisait annoncer « empreintes non conformes » — **fausse cause** | verdict séparé : « N script(s) sans bit exécutable (C-30) » |

### 3.4 La chaîne de construction applique maintenant le produit

`fork/build-nexbsd.sh` a été modifié : il **installe le monde dans une racine** (`installworld`,
`distribution`, `installkernel`), **applique l'overlay**, **puis** fabrique l'image. L'ancien chemin
(`release.sh`) est conservé mais précédé d'un avertissement : il produit un média **du socle**, pas
de NexBSD.

---

## 4. Ce qui est prouvé, ce qui est supposé, ce qui reste impossible

| Affirmation | Statut | Preuve |
|---|---|---|
| la configuration du produit **s'applique** sur un système | ✅ **PROUVÉ** | 4 essais, docs/48 §3.2 |
| les placeholders ne peuvent pas fuir dans une image | ✅ **PROUVÉ** | refus + 0 fichier écrit |
| le dépôt GitHub reçoit nos commits | ✅ **PROUVÉ** | `d999b1b..624ac02 main -> main` |
| une **image NexBSD existe** | ❌ **FAUX** | aucune image produite à ce jour |
| `installworld`/`makefs`/`mkimg` fonctionnent dans cette chaîne | ⚠️ **NON EXÉCUTÉ** | jamais lancé ; la syntaxe de `mkimg` est explicitement marquée non vérifiée |
| l'image **démarre** | ⚠️ **NON TESTÉ** | aucune image |

---

## 5. Ce qui reste ouvert, sans enrobage

| # | Acquis | Pourquoi ce n'est pas fini |
|---|---|---|
| **A-19** | image installable (J5) | **aucune image n'existe** : c'est LE blocage |
| **A-52** | l'image contient la configuration | chaîne écrite, **jamais exécutée** |
| A-02→A-06 | LDAP/Samba/droits/persistance | configuration écrite et applicable, mais **aucun paquet installé** : la config est **inerte** sans `slapd`, `samba`, `nss-pam-ldapd` |
| A-14 | `su` exige un mot de passe | preuve **comportementale** toujours manquante (Cmd 29) |
| A-17 | `motd` | fichier écrit, **pas encore appliqué à un vrai système** |
| A-21 | bureau et logiciels NexBSD | **rien** n'existe (couche C non commencée) |
| A-30 | 20 ADR | toutes encore à l'état **PROPOSITION** |
| A-22 | identité unique PAM/LDAP | non commencé |

**Registre au 28/10 : 52 acquis — 35 fermés, 9 ouverts, 6 à faire, 1 de gouvernance.**

---

## 6. Réponse directe à la question posée

> *« tu ajustes la VM sans faire rien à notre système nexbsd »*

**C'était vrai hier. Ce soir, deux choses ont changé de nature :**

1. **un maillon du produit a été écrit et testé** (`70-appliquer-overlay.sh`) — ce n'est pas un réglage
   de banc, c'est le mécanisme qui fait entrer la configuration dans le système ;
2. **la chaîne de construction intègre ce maillon** — l'image, quand elle existera, contiendra NexBSD
   et pas seulement un noyau.

**Mais je ne dirai pas que c'est fait** : aucune image n'existe. Tant qu'il n'y a pas un fichier
`nexbsd.img` avec son empreinte SHA256, la phrase exacte reste : *« NexBSD est une configuration
complète qui n'a pas encore été assemblée en système ».*

---

## 7. Le seul chemin qui reste, et il est court

1. pousser les 3 commits de ce soir (modes + overlay + révision) ;
2. créer le compte Cirrus (5 minutes, gratuit) ;
3. lancer **SONDE + CONTRÔLES** (2 minutes) → réponse machine sur 15.0 / 15.1 ;
4. lancer **IMAGE** (plusieurs heures) → la **première image** et son empreinte.

**Étape 4 = jalons A-19 et A-52 ensemble.** C'est le seul endroit où le projet peut basculer de
« configuration » à « système ».

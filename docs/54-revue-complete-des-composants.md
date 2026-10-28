# 54 — Révision complète du 2026-10-28 : où nous en sommes, et ce que je n'ai pas fait

> **Cette révision répond à une critique du responsable, et elle est fondée :**
> *« faire une révision complète où nous sommes arrivés et pour les autres composants il y a
> beaucoup mais tu n'as pas fait rien »*
>
> Il a raison. Les cinq derniers tours de travail ont été consacrés **entièrement** à la chaîne
> de vérification (VM, CI, empreintes, diagnostic). Aucun composant du produit n'a avancé. Ce
> document en fait l'inventaire honnête, puis dit ce qui a été corrigé **dans la minute**.

---

## 1. Le chiffre qui résume tout

| | Nombre |
|---|---|
| commits dans le dépôt | **144** |
| fichiers de documentation | 58 |
| scripts de banc | 22 |
| fichiers du produit (`fork/`) | 33 |
| comptes rendus de test | 15 |
| acquis au registre | 59 |
| **images NexBSD produites** | **0** |
| **systèmes NexBSD démarrés** | **0** |

**Ce que les cinq derniers tours ont produit** : une CI qui passe au vert (deux fois), quatre
problèmes documentés (C-35 à C-38), et **zéro composant nouveau**.

**Ce qu'ils ont coûté** : ~6 heures de conversation, 8 exécutions de CI.

Ce n'était pas inutile — sans CI verte, aucune image ne peut être produite en confiance. Mais
**on a réparé le four pendant que le pain n'était pas pétri.**

---

## 2. Inventaire composant par composant

Légende : **écrit** = le fichier existe · **testé** = un test a réellement tourné et a laissé une
preuve · **dans l'image** = présent dans un système NexBSD (aucun ne l'est, aucune image n'existe).

### 2.1 Socle et construction

| Composant | Écrit | Testé où | Dans l'image | Verdict |
|---|---|---|---|---|
| Noyau `NEXBSD_L1` (delta de 5 lignes vs GENERIC) | ✅ | compilation réelle, `82dc5681…` | ❌ | **le seul binaire jamais compilé par le projet** |
| `src.conf` (options du monde) | ✅ | non testé isolément | ❌ | écrit |
| `release.conf` | ✅ | **jamais exécuté** | ❌ | à confronter à une vraie release |
| `fork/build-nexbsd.sh` (assembleur du produit) | ✅ | **jamais exécuté** | ❌ | corrigé aujourd'hui (C-39) |
| `fork/70-appliquer-overlay.sh` | ✅ | garde FreeBSD+root, testé sur Linux (refus) | ❌ | jamais appliqué dans un vrai système |
| `fork/80-installer-nexbsd.sh` (installeur) | ✅ | 4 garde-fous testés | ❌ | **jamais exécuté** |
| `scripts/74` (chaîne de production) | ✅ | simulation + garde-fous | ❌ | corrigé aujourd'hui : il ne produisait pas NexBSD |

### 2.2 Réseau façon NetWare — l'axe d'identité du projet

| Exigence | Composant | Écrit | Testé | Verdict |
|---|---|---|---|---|
| **N-01** partage SMB authentifié | `smb4.conf` | ✅ | ✅ **T-03** dans une VM FreeBSD | config au banc, jamais dans une image |
| **N-02** droits par groupe | ACL + Samba | ✅ | ✅ **T-04F** | au banc |
| **N-03** annuaire OpenLDAP | `slapd.conf` + LDIF | ✅ | ✅ **T-04** | au banc |
| **N-04** export/réimport annuaire | — | ❌ | ❌ | **non fait** |
| **N-05** mot de passe unique (Kerberos) | — | ❌ | ❌ | **non planifié** |
| **N-06** **scripts de connexion + lecteurs réseau** | — | ❌ | ❌ | **NON FAIT — c'est l'âme de NetWare** |
| **N-07** impression partagée (CUPS) | — | ❌ | ❌ | **non fait** |
| **N-08** administration unique sans terminal | — | ❌ | ❌ | **non fait** (le bureau n'est pas une console d'admin) |
| **N-09** supervision des services | — | ❌ | ❌ | **non fait** |
| **N-10** découverte réseau (mDNS) | — | ❌ | ❌ | **non fait** |
| **N-11** client NCP | — | ❌ | ❌ | **recherche seulement** (`research/ncp-ip/`) |

**Ce tableau est la réponse à votre critique.** Sur douze exigences réseau, **quatre** ont un
composant écrit et testé au banc, **sept** n'ont rien, **une** est hors périmètre. Et aucune
n'est dans une image.

### 2.3 Bureau et session

| Composant | Écrit | Testé | Verdict |
|---|---|---|---|
| `nexbsd-bureau.html` (barre, icônes, fenêtres, verrouillage) | ✅ | 17 cas **verts dans la CI, sur FreeBSD** | logique prouvée, **jamais affiché dans un X réel** |
| `nexbsd-session.sh` (X11 + openbox + WebKitGTK) | ✅ | garde FreeBSD, structure | **jamais exécuté** |
| `nexbsd-authentifier.sh` (écran d'ouverture) | ✅ | 14 cas **verts dans la CI**, sous compte ordinaire | **PAM jamais sollicité** |
| Entrée de session `.desktop` | ✅ | lisibilité | jamais essayée |

### 2.4 Sécurité et identité

| Composant | Écrit | Testé | Verdict |
|---|---|---|---|
| `pf.conf` (pare-feu) | ✅ | **T-05** au banc | jamais dans une image |
| `sshd_config.nexbsd` (clé seule, root interdit) | ✅ | **T-21** | au banc |
| `pam.d/su` (fin du passe-partout wheel) | ✅ | **T-21** | au banc |
| `nsswitch` + `nslcd` (identités de l'annuaire) | ✅ | **T-04G** | au banc |
| **A-17** motd (défaut produit visible) | ✅ le fichier | — | **A-FAIRE : rien ne prouve qu'il arrive dans l'image** |
| **A-18** comment l'administrateur obtient root | ❌ | ❌ | **question ouverte depuis le 27/10** |
| **A-22** identité unique PAM/LDAP pour les sessions | ❌ | ❌ | **non fait** |

---

## 3. Le trou le plus grave, trouvé aujourd'hui en relisant

**`scripts/74-produire-image.sh` produisait une image FreeBSD, pas NexBSD.**

La chaîne appelait `make release`. Or `release.sh` produit le média **du socle** : il n'applique
pas `fork/overlay/`. L'image aurait donc contenu :

| Dedans | Dehors |
|---|---|
| le noyau `NEXBSD_L1` | `/etc/motd` NexBSD |
| le monde compilé avec `src.conf` | `smb4.conf` (le partage) |
| | `slapd.conf` + LDIF (l'annuaire) |
| | `nsswitch` + `nslcd` (les identités) |
| | `pf.conf` (le pare-feu) |
| | `sshd_config` (la clé seule) |
| | `pam.d/su` (le mot de passe exigé) |
| | le bureau et sa session |

**Autrement dit : tous les composants écrits et testés au banc seraient restés sur le disque du
dépôt.** On aurait eu un rond vert, une image de 400 Mo, et rien dedans.

C'est la règle du projet qui l'interdit : *« ce qui n'est pas dans l'image n'est pas dans le
produit ; une configuration présente dans le dépôt que rien n'applique n'y est pas non plus. »*

**Corrigé dans la minute (C-39)** : la chaîne appelle désormais `fork/build-nexbsd.sh`, qui fait
dans le bon ordre — `buildworld` → `buildkernel NEXBSD_L1` → `installworld` + `distribution`
dans une racine → `installkernel` → **application de l'overlay** → `makefs` + `mkimg`.

Et une **étape de contrôle a été ajoutée AVANT d'annoncer quoi que ce soit** : si
`$RACINE/etc/nexbsd-version` est absent, ou s'il n'y a pas de noyau dans `boot/kernel/`, le script
**échoue** au lieu de produire une image vide de produit.

**Note importante** : cette correction n'a pas encore tourné. Elle est écrite, elle est
cohérente, elle n'est pas prouvée. Le prochain lancement de la tâche IMAGE la mettra à
l'épreuve.

---

## 4. Ce qui a été réellement prouvé, et ce qui ne l'est pas

### Prouvé (mesuré, avec preuve conservée)

1. Un noyau `NEXBSD_L1` **a été compilé** et son empreinte est consignée (`T-17`).
2. Un partage Samba authentifié par annuaire **a fonctionné** dans une VM FreeBSD (`T-03`, `T-04`, `T-04E/F/G`).
3. `pf`, `sshd` en clé seule, `pam.d/su`, `nsswitch`/`nslcd` **ont fonctionné au banc** (`T-05`, `T-21`).
4. La logique du bureau (**17 cas**) et de l'écran d'ouverture (**14 cas**) **passe sur FreeBSD dans la CI**.
5. La chaîne de vérification du projet **fonctionne dans une vraie VM FreeBSD 15.1** (exécutions #5 et #8 vertes).
6. `src.txz` de 15.1-RELEASE **a été téléchargé et son empreinte vérifiée** (`cf5762da53fd52e1…`).

### Non prouvé (et qu'aucun rond vert ne change)

1. **PAM n'a jamais vérifié un mot de passe** dans NexBSD.
2. **Aucune session graphique n'a jamais été affichée.**
3. **Aucune image NexBSD n'existe.**
4. **Aucun système NexBSD n'a jamais démarré.**
5. **L'installeur `fork/80` n'a jamais été exécuté.**
6. **Aucun composant réseau n'a jamais tourné dans une image NexBSD** — seulement dans une VM de banc.

---

## 5. Décision : ce que je fais à partir de maintenant

**Ordre de priorité, et il change.** On arrête de polir le four. Trois chantiers, dans cet ordre :

| # | Chantier | Pourquoi celui-là d'abord |
|---|---|---|
| **1** | **L'image contient le produit** (C-39, fait aujourd'hui) | sans ça, tout le reste est décoratif |
| **2** | **N-06 : scripts de connexion + lecteurs réseau** | c'est **la** fonction qui distingue NexBSD de « FreeBSD + Samba ». Un utilisateur NetWare se connecte et **voit ses lecteurs**. Rien n'existe aujourd'hui. |
| **3** | **N-08 : console d'administration** | remplacer le terminal par une interface : c'était l'objectif d'origine du projet |

**Règle que je m'impose** : à chaque tour désormais, **un composant du produit avance**, pas
seulement la tuyauterie. Si un tour ne fait que de la CI, il doit le dire et le justifier.

---

## 6. Ce qu'il faut pour que NexBSD existe vraiment

Un chemin court, honnête, sans dépendance cachée :

1. **Une image produite** par la tâche IMAGE (C-39 la rend possible) — 2 à 5 h de calcul.
2. **Cette image démarrée** dans une VM, une seule fois, pour voir `uname -a` et `/etc/motd`.
3. **L'installeur `fork/80` exécuté** sur cette image : c'est lui qui pose les paquets, lit le
   SID, initialise l'annuaire et démarre les services.
4. **N-06 écrit et testé** : les lecteurs réseau par utilisateur.
5. **La session affichée** une fois, avec un vrai mot de passe PAM.

Les étapes 1 et 2 sont à portée de main : tout est écrit, il ne manque qu'un lancement.
Les étapes 3 à 5 demandent du travail réel, et **c'est là que je dois aller**.

---

## 7. Ce que je ne promets pas

- Je ne promets pas que la construction aboutira du premier coup : c'est la première fois qu'on
  assemble un système complet, et `release.conf`, `makefs` et `mkimg` n'ont jamais tourné.
- Je ne promets pas un système utilisable avant plusieurs tours : entre une image qui démarre et
  un serveur de fichiers qui sert un poste Windows, il y a du chemin.
- Je promets une chose : **chaque affirmation sera datée, chiffrée, ou marquée « non prouvé ».**

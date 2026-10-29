# 58 — Preuve : `pkg audit` refuse d'ouvrir le bureau sur un moteur de rendu vulnérable

> **Intervenant concerné : n° 8 (cybersécurité et analyse des dépendances).**
> Dans `docs/57`, il était le seul rôle avec les mobiles à n'avoir produit **que du texte**.
> Ce document est la première **application** qu'il livre.
>
> Date : 2026-10-29 · Acquis : **A-67** · Problème fermé : **C-44**

---

## 1. Le problème, tel qu'il était écrit

`docs/51` §4, 28 octobre :

> *« `pkg audit` doit tourner au démarrage de session et **refuser** de lancer le bureau si le paquet
> est vulnérable — **à écrire, pas encore fait**. »*

`docs/57`, 29 octobre (audit des intervenants) :

> *« 20 CVE connues dans `webkit2-gtk`, jamais contrôlé. »*

Le paquet `www/webkit2-gtk` est le moteur qui affiche le bureau NexBSD. Il a corrigé **20 CVE en
mai 2026**. Les CVE d'un moteur de rendu sont presque toutes des **défauts de manipulation de
mémoire**, atteignables par une page mal formée — y compris une page locale. Un bureau qui affiche
du contenu avec un moteur troué est une porte d'exécution de code.

---

## 2. Ce qui a été écrit

**`fork/bureau/nexbsd-audit-paquets.sh`** — 118 lignes, `sh` POSIX, aucune dépendance hors `pkg`.

Il distingue **trois états**, et **seul le premier interdit le démarrage** :

| État | Signification | Décision |
|---|---|---|
| **VULNÉRABLE** | un paquet de la chaîne d'affichage est *prouvé* vulnérable | **REFUS** (code 3) |
| **INCONNU** | la base n'a pas pu être mise à jour (pas de réseau) | on continue, **mais on le crie** |
| **SANS OBJET** | `pkg` n'est pas installé (produit au stade socle) | on continue |

La liste des paquets « critiques » est explicite dans le script :
`webkit2-gtk epiphany wpewebkit gtk3 gtk4 glib libsoup libsoup3 webkitgtk`.
Ce sont ceux qui, une fois vulnérables, permettent l'exécution de code **pendant que le bureau
affiche quelque chose**. Un défaut dans `zip` n'ouvre pas la même porte : il est signalé, mais
n'empêche pas la session.

---

## 3. Les six cas, exécutés et non supposés

```
$ sh fork/bureau/nexbsd-audit-paquets.sh --simulation /tmp/audit/A.txt
  [ECHEC] PAQUET CRITIQUE VULNÉRABLE : webkit2-gtk

  ============================================================
   BUREAU REFUSÉ — un paquet qui affiche l'écran est vulnérable
  ============================================================
   Corriger (en root) :
       pkg upgrade -y webkit2-gtk
  -> code 3
```

| Cas | Entrée | Sortie obtenue | Code |
|---|---|---|---|
| **A** | `webkit2-gtk-2.48.3 is vulnerable:` | refus + commande de correction | **3** |
| **B** | `0 problem(s) in 0 installed package(s) found.` | `le bureau peut s'ouvrir` | 0 |
| **C** | `zip-3.0_2 is vulnerable:` | `hors chaîne d'affichage` → autorisé | 0 |
| **D** | `pkg` absent | `sans objet` → autorisé | 0 |
| **E** | `--forcer` hors wheel / hors FreeBSD | `dérogation refusée` | **4** |
| **F** | fichier de simulation illisible | arrêt net | 2 |

---

## 4. Le point de conception qui compte — la leçon M-10

**La tentation était d'écrire : `pkg audit` échoue ⇒ pas de bureau.** C'aurait été un faux garde-fou.

Sans réseau, `pkg audit -F` échoue **toujours**. Une machine NexBSD fraîchement installée, dans un
réseau isolé — ce qui est précisément le cas d'usage d'un serveur de fichiers d'entreprise — n'aurait
**jamais** pu ouvrir de session graphique. Le garde-fou aurait bloqué un système sain, en silence.

C'est exactement la faute **C-41** : un garde-fou trop strict (`buildworld:` cherché en dur dans le
Makefile) avait rendu rouge une construction parfaitement valide.

Donc l'état « je ne peux pas vérifier » est **traité comme un état à part**, annoncé en majuscules,
et **non bloquant** :

```
  !!  L'état de sécurité est INCONNU — le bureau s'ouvre, mais sans garantie.  !!
```

Un utilisateur informé peut décider. Un utilisateur bloqué ne peut rien.

---

## 5. Le branchement dans la session

`fork/bureau/nexbsd-session.sh` — nouvelle étape **3bis** :

```
# --- 1. préconditions ------------------------------------------------------
# --- 2. dossier de session -------------------------------------------------
# --- 3. authentification (l'écran d'ouverture) -----------------------------
# --- 3bis. audit de sécurité des paquets (acquis A-67, docs/51 §4) ---------  <-- NOUVEAU
# --- 4. gestionnaire de fenêtres ------------------------------------------
# --- 5. le bureau ---------------------------------------------------------
```

**Pourquoi cet emplacement, et pas un autre :**

- **après l'authentification** — on sait *qui* demande à ouvrir la session, donc on peut lui refuser
  la dérogation (`--forcer` exige l'appartenance à `wheel`) ;
- **avant le gestionnaire de fenêtres** — donc avant tout lancement de `epiphany`, donc avant que le
  moteur de rendu ne touche à quoi que ce soit.

**Et si le script d'audit est absent ?** Le bureau **ne s'ouvre pas**. On ne peut pas affirmer que le
moteur est sain sans l'avoir vérifié — et un garde-fou qui disparaît en silence n'est pas un
garde-fou.

---

## 6. Ce que ce travail NE prouve PAS — et il faut le dire

| Affirmation | Statut |
|---|---|
| le script existe et sa syntaxe est valide (`sh -n`) | ✅ **prouvé** |
| les 6 cas produisent le comportement voulu | ✅ **prouvé, par simulation** |
| il s'exécute correctement **sur FreeBSD 15 avec un vrai `pkg`** | ❌ **jamais essayé** |
| le format de sortie de `pkg audit` que je lis est le bon | ⚠️ **supposé** — écrit d'après la documentation de `pkg` |
| il se déclenchera au démarrage de session dans l'image | ❌ **non** : `fork/80-installer-nexbsd.sh` n'a jamais été exécuté, et le bureau n'est pas encore dans l'image |

**Le banc de test est un Linux sans `pkg`.** Les entrées des six cas sont des sorties de `pkg audit`
**écrites à la main**. C'est un test de la *logique du garde-fou*, pas de son *intégration au
système*. La distinction est importante : le jour où le produit démarrera, il faudra relancer ces six
cas sur la vraie machine, et le format réel de `pkg audit` pourra révéler un défaut de lecture.

---

## 7. Ce que cela change pour la suite

`docs/57` donnait six priorités. Celle-ci était la **n° 2** :

| Priorité | Application | État |
|---|---|---|
| 1 | démarrer l'image de l'exécution #18 | ⏳ artefact à télécharger par le responsable |
| **2** | **`pkg audit` au démarrage de session** | ✅ **fait aujourd'hui (A-67)** |
| 3 | **N-06** scripts de connexion / lecteurs réseau | ❌ **rien** — l'âme de NetWare, toujours absente |
| 4 | **N-08** console d'administration | ❌ rien |
| 5 | **A-22** identité unique PAM/LDAP | ❌ rien |
| 6 | **A-18** comment l'administrateur obtient root | ❌ rien |

**La prochaine priorité qui n'a besoin de rien d'autre pour avancer est la n° 3.**

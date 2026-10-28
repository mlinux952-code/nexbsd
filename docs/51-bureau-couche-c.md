# 51 — Le bureau NexBSD (couche C) : première pierre

**Décision du responsable (2026-10-28) :** *« je prend votre conseil et on commence »* → démarrer le
bureau pendant que Cirrus est injoignable.

**Point de départ, sans enrobage :** avant ce soir, la couche C **n'existait pas**. Zéro ligne. Le
registre le disait : *A-21 — bureau et applications NexBSD : rien n'existe*.

---

## 1. La décision de conception, et pourquoi

| Question | Choix | Raison |
|---|---|---|
| Affichage | **X11** (`xinit`), pas Wayland | les pilotes et la documentation FreeBSD 15 sont mûrs sur X11 ; Wayland exige `seatd` + un compositeur, pour un gain nul sur le PC de 2011 visé |
| Gestionnaire de fenêtres | **openbox** | il ne fournit **que** le déplacement et le redimensionnement ; tout le reste (barre, icônes, fenêtres, centre de commandes) est **notre code** |
| Moteur d'interface | **WebKitGTK** via `www/epiphany` | `www/epiphany` **v47.7 est paqueté pour FreeBSD 15 amd64** (vérifié) ; écrire notre bureau en HTML/CSS/JS coûte dix fois moins que de bâtir un toolkit natif, et c'est réparable par n'importe qui |
| Autonomie | **aucune ressource distante** | un bureau doit s'afficher sur une machine sans réseau. Vérifié : `grep` ne trouve **aucune URL, aucun `<link>`, aucun `src=`** |

**Ce que ce choix refuse :** réutiliser GNOME ou KDE comme « bureau NexBSD ». Ce serait un FreeBSD
avec un bureau emprunté — exactement ce que le responsable a interdit (*« un vrai système pour PC et
pas un modifié »*).

---

## 2. Ce qui a été écrit ce soir — trois fichiers, dans le produit

| Fichier | Rôle | Taille |
|---|---|---|
| `fork/bureau/nexbsd-bureau.html` | **le bureau** : barre supérieure, horloge, menus, icônes, fenêtres déplaçables, barre des tâches, centre de commandes | 15 724 o |
| `fork/bureau/nexbsd-session.sh` | la **session** : préconditions, `openbox`, lancement de WebKitGTK en mode application, relance 3 fois maximum puis sortie propre | — |
| `fork/overlay/usr-local-share-xsessions/nexbsd.desktop` | l'**entrée de session** : ce qui fait apparaître « NexBSD » dans un choix de session | — |

### Ce que le bureau fait réellement (et qui est testé)

- ouverture/fermeture de fenêtres, **déplacement à la souris** borné à l'écran ;
- **mise au premier plan** au clic, zèle des fenêtres géré ;
- **horloge** réelle (rafraîchie toutes les 15 s) ;
- **barre des tâches** qui reflète l'état ouvert/fermé ;
- quatre fenêtres : Centre de commandes, Partages, Terminal, Système.

### Ce qui est vérifié ce soir, par des commandes

| Contrôle | Résultat |
|---|---|
| ressources externes | ✅ **aucune** (`grep 'https\?://\|src=\|<link\|<img'` → vide) |
| syntaxe JavaScript | ✅ **valide** (`node --check` sur les 7 794 caractères extraits) |
| structure HTML | ✅ **aucune erreur**, aucune balise non fermée (analyseur Python) |
| la session refuse de tourner hors FreeBSD | ✅ testé : `ERREUR : cette session ne tourne que sur FreeBSD` (code 1) |
| le fichier `.desktop` est lisible | ✅ testé par analyseur : section `Desktop Entry`, `Name=NexBSD` |
| **le bureau s'affiche dans un vrai X** | ❌ **JAMAIS** — aucun système NexBSD, aucun serveur X |
| **openbox + epiphany fonctionnent ensemble** | ❌ **JAMAIS EXÉCUTÉ** |

**Donc la phrase exacte est :** *le bureau existe, il est autonome et syntaxiquement valide ; il n'a
jamais été affiché par un serveur graphique.*

---

## 3. Le bandeau de démonstration — une décision d'honnêteté

Le bureau affiche en permanence :

> **DONNÉES DE DÉMONSTRATION — ce bureau n'interroge encore aucun service. Les états affichés ne prouvent rien.**

C'est laid, et c'est voulu. Un tableau de bord qui affiche « annuaire : actif » sans interroger
l'annuaire est exactement le genre de mensonge que ce projet combat. Le bandeau disparaîtra **le jour
où les valeurs seront réelles** — pas avant.

De même, la fenêtre Terminal dit explicitement : *« ce terminal est une image, pas un terminal : il
n'exécute rien »*.

---

## 4. Le risque de sécurité, nommé

`www/webkit2-gtk` a un **historique de vulnérabilités** (20 CVE corrigées en mai 2026). Un bureau
bâti sur un moteur de rendu web hérite de ces vulnérabilités. Trois conséquences, à traiter **avant**
de livrer :

1. `pkg audit` doit tourner au démarrage de session et **refuser** de lancer le bureau si le paquet est
   vulnérable — à écrire, pas encore fait ;
2. le bureau n'ouvre **aucun contenu distant** (vérifié ce soir) : la surface d'attaque se limite au
   fichier local, ce qui est le cas le plus favorable ;
3. une **ADR est nécessaire** pour assumer ce choix (moteur web = risque) — elle n'existe pas encore.

---

## 5. Ce qui manque pour un bureau utilisable (prochaine étape)

| # | Manque | Pourquoi c'est indispensable |
|---|---|---|
| 1 | **les données réelles** | le bureau doit interroger `slapd`, `smbd`, `pf` — sinon il reste une maquette |
| 2 | **un terminal vrai** | lancer `xterm` comme programme séparé, dans une fenêtre du bureau |
| 3 | **un gestionnaire de fichiers** | parcourir les partages SMB montés |
| 4 | **la session dans l'image** | `nexbsd-bureau.html` doit être posé dans `/usr/local/share/nexbsd/bureau/` par l'installeur — **pas encore fait** |
| 5 | **l'authentification graphique** | aujourd'hui, le bureau s'ouvre sans rien demander. Or votre règle est : *un serveur doit demander quelque chose pour entrer*. Un bureau de système doit aussi demander qui vous êtes |

**Le point 5 est le plus important et il n'est pas traité.** Le bureau actuel n'a **aucune
authentification** : c'est un défaut au regard de votre exigence du 27 octobre.

---

## 6. Effet sur le registre

- **A-21** (bureau et applications) reste **OUVERT**, mais il passe de *« rien n'existe »* à
  *« première pierre posée : interface autonome, session écrite, jamais affichée »* ;
- **A-54** (nouveau) : *la session bureau existe et est décrite* → **OUVERT** (écrite, non exécutée) ;
- delta du produit : **27 → 30 fichiers**.

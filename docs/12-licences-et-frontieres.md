# Licences et frontières — ce qu'on peut vraiment assembler

**Version :** 1.0 — 2026-10-23
**Statut :** `[PROPOSITION]` — analyse d'ingénierie, **pas un avis juridique**
**Objet :** déterminer, composant par composant, ce qui peut entrer dans NexBSD, à quel endroit, et sous quelles obligations.

> ⚠️ Ce document n'est pas une consultation juridique. Les règles ci-dessous sont celles généralement admises pour les licences libres ; toute décision de distribution commerciale doit être validée par un professionnel.

---

## 1. La règle centrale : trois domaines, trois régimes

| Domaine | Contenu | Licences admises | Pourquoi |
|---|---|---|---|
| **NexBSD Base** | noyau, libc, userland de base, rc.d | **BSD-2 / BSD-3 / ISC / MIT / Apache-2** uniquement | doit rester entièrement permissif : c'est ce qui permet à NexBSD de rester maître de son code |
| **NexBSD Platform** | Samba, OpenLDAP, WebKitGTK, CUPS, MARS_NWE (labo) | toutes, **y compris GPL** | paquets séparés, processus séparés : le copyleft reste contenu |
| **NexBSD Apps** | coquille mobile, outil d'admin, installateur | au choix du projet | code neuf |

**Règle d'or :** *un composant copyleft ne doit jamais être lié (linked) dans un binaire de la base, ni copié dans ses fichiers sources.* Il peut être **installé** par l'utilisateur ou **empaqueté** par le projet.

Cette règle n'est pas une invention : c'est celle de FreeBSD lui-même, qui exige que les logiciels sous licences non-BSD soient « **soigneusement isolés dans l'arbre source afin qu'ils ne puissent pas contaminer les composants BSD** » (FreeBSD Licensing Policy, docs.freebsd.org).

---

## 2. Analyse composant par composant

| Composant | Licence | Peut entrer dans la **Base** ? | Peut être dans la **Plateforme** ? | Obligations si distribué dans une image NexBSD |
|---|---|---|---|---|
| **FreeBSD (code)** | BSD-2-Clause | **Oui** | — | conserver la notice de copyright et la clause de non-approbation ; **pas d'obligation de publier les modifications** |
| **OpenLDAP** | OpenLDAP Public License (permissive, type BSD) | Oui (techniquement) — mais préférer Plateforme | Oui | conserver les notices |
| **WebKitGTK** | LGPL (bibliothèque) + BSD ; port FreeBSD : GPLv2/BSD | **Non** (GPL dans le port) | **Oui** | fournir le code source des bibliothèques LGPL modifiées ; permettre leur remplacement |
| **Gaia (Firefox OS)** | **Apache-2.0** | Oui (permissive) | Oui | conserver `LICENSE` et `NOTICE`, signaler les modifications |
| **Samba** | **GPL-3.0-or-later** | **Non** | **Oui** | fournir le code source correspondant ; ne pas ajouter de restriction ; conserver notices |
| **MARS_NWE** | **GPL-2.0** | **Non** | Oui (labo isolé) | source + modifications sous GPL-2 |
| **KaiOS** | **Propriétaire** | **Non** | **Non** | rien ne peut être redistribué |
| **Gecko B2G** | MPL-2.0 | Non (non maintenu) | Non | — |

### 2.1 Piège important : GPL-2 et GPL-3 ne se mélangent pas

MARS_NWE est **GPL-2.0 (only)** ; Samba est **GPL-3.0-or-later**. Ces deux licences sont **incompatibles entre elles** : on ne peut pas les réunir dans une même œuvre dérivée. En revanche, **deux programmes distincts exécutés dans deux processus différents** ne forment pas une œuvre combinée : ils peuvent coexister sur le même système.

**Conséquence pratique :** Samba et MARS_NWE peuvent tous deux être installés sur un NexBSD, **à condition de ne jamais les lier ni les fusionner**, et en documentant clairement qu'ils sont indépendants. Comme MARS_NWE est de toute façon rejeté (absence d'IPX), le sujet est théorique — mais il faut le savoir avant d'écrire du code.

### 2.2 Piège Apache-2.0 / GPL-2

Apache-2.0 est **incompatible avec GPL-2.0** (clause brevets). Gaia (Apache) ne doit donc pas être fusionnée avec du code GPL-2. Séparée en fichiers/paquets distincts, aucun problème.

---

## 3. La frontière « processus » en pratique

| Situation | Statut | Exemple NexBSD |
|---|---|---|
| Code GPL **lié** dans un binaire de la base | ❌ interdit | lier libsmbclient dans `/bin/sh` |
| Code GPL **copié** dans un fichier de la base | ❌ interdit | copier une fonction de MARS_NWE dans le noyau |
| Code GPL **exécuté comme processus séparé**, communiquant par socket/fichier | ✅ autorisé | `smbd` à côté du noyau BSD |
| Code GPL **empaqueté** et installé par l'utilisateur | ✅ autorisé | `pkg install samba423` |
| Code GPL **inclus dans l'image NexBSD** | ✅ autorisé **avec obligations** | image `nexbsd-net` contenant Samba → fournir les sources de Samba |

**Point souvent oublié :** distribuer une **image** qui contient Samba, c'est distribuer Samba. NexBSD doit alors fournir (ou offrir) le code source correspondant, y compris ses éventuels correctifs. La solution propre : un dépôt public `nexbsd/platform-sources` + une note de licence dans l'image.

---

## 4. Marques : un sujet distinct des licences

| Élément | Règle | Source |
|---|---|---|
| **« FreeBSD »** | **Ne peut pas** faire partie du nom d'un produit dérivé. Usage descriptif (« basé sur FreeBSD ») toléré dans une notice. | FreeBSD Foundation, Trademark Usage Terms (« Do not use the FreeBSD Marks as part of your product name ») ; FAQ |
| Logo FreeBSD / Beastie | usage restreint (logo) ; Beastie appartient à M. K. McKusick | FreeBSD FAQ |
| **« NetWare », « Novell »** | marques de tiers — usage descriptif seulement, jamais dans le nom d'un produit | `[À VÉRIFIER — statut actuel des marques, cédées au fil des rachats]` |
| **« KaiOS », « Firefox », « Mozilla »** | marques de tiers | usage descriptif seulement |
| **« NexBSD »** | **antériorité non vérifiée** | `[À VÉRIFIER — recherche d'antériorité avant toute publication]` |

**Conséquence :** le nom du produit ne peut pas contenir « FreeBSD ». NexBSD est donc — c'est heureux — déjà conforme sur ce point, mais la notice devra dire : « NexBSD est basé sur FreeBSD® ; FreeBSD est une marque déposée de la FreeBSD Foundation ; NexBSD n'est ni affilié à, ni approuvé par la FreeBSD Foundation. »

---

## 5. Ce qu'il faut produire pour être en règle

| Livrable | Contenu | Quand |
|---|---|---|
| `LICENSE` | licence de la base NexBSD (proposée : BSD-2-Clause, cohérente avec FreeBSD) | dès le premier commit |
| `NOTICE` | attribution de tous les composants tiers | dès la première image |
| `SBOM` (inventaire logiciel) | liste des composants, versions, licences | dès la première image |
| `docs/licenses.md` dans l'image | où trouver les sources des composants GPL/LGPL | à chaque release |
| dépôt public des sources Plateforme | sources exactes correspondant à l'image | à chaque release |

---

## 6. Décisions proposées

1. **Base NexBSD sous BSD-2-Clause** — même licence que FreeBSD, cohérence et simplicité (ADR-0016 à ouvrir).
2. **Aucun code GPL dans la base** — vérification automatisable (recherche de `SPDX-License-Identifier: GPL` dans l'arbre).
3. **Plateforme en paquets séparés**, versionnés et signés, avec sources publiées.
4. **Pas de marque tierce dans le nom** ; notice d'attribution obligatoire dans chaque image.

## 7. Ce qui reste à vérifier

- Le statut exact des marques « NetWare » et « Novell » aujourd'hui (cessions successives).
- L'antériorité du nom « NexBSD ».
- Le régime des utilitaires Novell « Client Kit » (libération partielle annoncée, conditions floues).
- Les licences individuelles des 251 dépôts `mozilla-b2g` (seule Gaia a été vérifiée : Apache-2.0).

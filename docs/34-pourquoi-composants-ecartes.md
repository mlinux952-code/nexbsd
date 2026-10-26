# Pourquoi Firefox OS et MARS_NWE ont été écartés — causes exactes

**Date :** 2026-10-26 · **Origine :** question du responsable — *« pourquoi firefox os et mars_nwe non
appliqués, quelle est la cause exacte : les licences ? et ne plus être mis à jour ne signifie pas non
utilisable »*

**Conclusion en une ligne :** sur ces deux composants, **la licence n'a jamais été la cause du rejet**.
Les causes sont **techniques** : ils ne peuvent pas **tourner** sur notre base, et l'un d'eux ne peut même
plus **exécuter ses propres applications**. Le responsable a raison sur un point : **l'âge d'un logiciel
n'est pas en soi un motif de rejet** — ce document dit précisément quand l'âge compte et quand il ne compte pas.

---

## 1. MARS_NWE — cause exacte du rejet

| Question | Réponse |
|---|---|
| **Licence ?** | **Non.** GPL-2.0. Or ADR-0012 autorise le GPL dans la couche **Platform** en paquets séparés. La licence interdit seulement de le mettre **dans la base** — ce qui n'était pas le projet. |
| **Cause n° 1 — décisive** | MARS_NWE **exige IPX**. IPX a été **retiré du noyau FreeBSD en 11.0**. Le faire tourner imposerait un **module noyau hors arbre** → c'est une **modification du noyau**, interdite par ADR-0006 et contraire à l'objectif du responsable (« un vrai système, pas un FreeBSD modifié »). |
| **Cause n° 2** | Il **ne fait pas ce qu'on veut** : pas de NDS, pas de NetWare/IP, pas de **NCP sur IP**. Un client moderne (port **524**) ne pourrait pas lui parler, même s'il tournait. C'est une limite **du logiciel**, pas du protocole (ADR-0018). |
| **Cause n° 3** | Sécurité : **l'auteur lui-même** avertit de vulnérabilités et recommande un réseau privé ; le code manipule des fichiers en root. |
| **L'âge (dernière version 2013)** | **Facteur aggravant, pas la cause.** Le responsable a raison : un logiciel ancien peut être parfaitement utilisable. Ici, l'âge n'est retenu que parce qu'il **aggrave** les trois causes ci-dessus (personne ne corrigera la faille ni ne portera IPX). |
| **Ce qu'on en a fait** | **Conservé comme référence technique** : banc A (T-14), dans un laboratoire isolé, avec DOSBox en émulation IPX-sur-UDP. Il sert à **observer le comportement NetWare** à imiter, pas à être livré. |

**Point d'honnêteté — la condition de révision est atteinte, et nous l'avons traitée :** ADR-0004 prévoyait de
réexaminer le rejet « si un besoin réel d'interopérabilité était démontré (client existant identifié) ».
**ADR-0019 a identifié ce client** (Client for Open Enterprise Server 26.2.1, NCP sur 524). La réponse n'a
**pas** été « intégrer MARS_NWE » — impossible sans IPX — mais **ADR-0018** : viser **NCP sur UDP/TCP 524**
réimplémenté proprement. Le rejet a donc été **réexaminé** et **maintenu pour une raison technique**, pas par inertie.

---

## 2. Firefox OS (Boot to Gecko) — cause exacte du rejet

| Question | Réponse |
|---|---|
| **Licence ?** | **Non — et c'est le point le plus important à corriger.** Gecko est en **MPL-2.0** et Gaia en **Apache-2.0** : ce sont des licences **permissives** (à fichiers près pour MPL), donc **admissibles jusque dans la base**. La licence n'a **jamais** été un obstacle. |
| **Cause n° 1 — décisive** | « Gonk » = **noyau Linux + HAL Android**. Firefox OS ne peut pas démarrer sur FreeBSD. Même raison que KaiOS (ADR-0002). |
| **Cause n° 2 — décisive** | Les applications Gaia utilisent des API **supprimées de Gecko** : `mozTelephony`, `mozSms`, `mozApps`, `mozContacts`… Elles **n'existent plus**. Ce n'est donc pas « un vieux logiciel qui marche encore » : c'est **une plateforme dont la cible a disparu**. Le code Gaia ne s'exécute sur aucun moteur actuel. |
| **Cause n° 3** | Un **moteur de rendu** traite en permanence des données **hostiles** venues du réseau. Un moteur sans mises à jour de sécurité est une porte ouverte (CVE). **C'est le seul cas où « plus mis à jour » suffit à disqualifier** — et pour une raison précise : la surface d'attaque exposée à l'extérieur. |
| **L'âge (dépôts archivés le 2021-11-03)** | **Facteur aggravant**, pas la cause. La cause est l'incompatibilité noyau + la disparition des API. |
| **Ce qu'on a gardé** | Les **principes de conception** (navigation au clavier, applications Web déclaratives, manifeste et permissions). C'est écrit comme tel dans ADR-0002 et ADR-0003 : *« inspiré de », jamais « portage de »*. |
| **Ce qu'on a retenu à la place** | **WebKitGTK** : packagé sous FreeBSD (`www/webkit2-gtk` 2.46.6), maintenu en amont (2.54.1 en octobre 2026). Donc **la même idée, sur un moteur vivant et compatible**. |

---

## 3. La règle générale — quand « plus mis à jour » est un vrai motif

Le responsable a raison : **l'âge n'est pas un critère en soi**. Notre propre projet utilise des logiciels
anciens **et c'est légitime** : MARS_NWE en banc de référence, l'émulation IPX de DOSBox, des clients DOS.
La règle que nous appliquons désormais, et qui rend ces choix vérifiables :

> Un composant ancien peut être **conservé** s'il satisfait **les trois** conditions :
> **(1)** il **s'exécute** sur notre base sans la modifier ;
> **(2)** il n'est **pas exposé** à des entrées hostiles venues de l'extérieur ;
> **(3)** il reste **hors de la base** (couche Platform ou laboratoire).
>
> S'il échoue à (1), il est **inutilisable**, quel que soit son âge.
> S'il échoue à (2), l'absence de correctifs devient **disqualifiante**.
> S'il échoue seulement à (3), c'est une question de **licence et de frontière**, pas d'âge.

| Composant | (1) tourne sur notre base ? | (2) exposé ? | (3) hors base ? | Verdict |
|---|---|---|---|---|
| **MARS_NWE** | **non** (IPX absent) | oui (réseau) | oui (labo) | rejeté comme composant, **gardé comme référence** |
| **Firefox OS / Gaia** | **non** (Gonk = Linux) | oui (moteur Web) | oui | rejeté ; **idées conservées** |
| **Samba 4.23** | oui | oui mais **maintenu** | oui (Platform) | **retenu** |
| **OpenLDAP 2.6** | oui | oui mais **maintenu** | oui (Platform) | **retenu** |
| **WebKitGTK 2.46** | oui | oui mais **maintenu** | oui (Platform) | **retenu** |
| **Notre noyau `NEXBSD_L1`** | — | — | — | **dans la base** (permisif uniquement) |

---

## 4. Ce qu'il faut retenir

1. **La licence n'a écarté ni Firefox OS ni MARS_NWE.** Elle fixe seulement **où** un composant GPL peut
   vivre (Platform, jamais la base).
2. Ce qui les a écartés : **ils ne peuvent pas tourner sur notre base** (IPX retiré de FreeBSD 11 ;
   Gonk = Linux), et Firefox OS ne peut même plus **faire tourner ses propres applications**.
3. **L'âge compte dans un seul cas** : quand un composant est **exposé à des entrées hostiles** et ne reçoit
   plus de correctifs (moteur Web, service réseau public). C'est un raisonnement précis, pas un réflexe.
4. **Rien n'est enterré** : chaque rejet porte une **condition de révision**. Celle de MARS_NWE a été atteinte
   (client NCP réel identifié) et a été **traitée** — par un changement de cible (NCP sur IP), pas par une
   adoption.

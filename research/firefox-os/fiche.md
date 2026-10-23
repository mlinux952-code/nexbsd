# Fiche de recherche — Firefox OS / B2G / Gaia (donneur de composants mobiles)

**Date de vérification :** 2026-10-23
**Statut :** candidat `En étude` → **proposition : `Gaia retenu comme étude de portage (P2)`, `Gonk et Gecko-B2G abandonnés`**
**Rôle visé :** Couche C — fournir une interface mobile et un modèle applicatif Web

---

## 1. Faits vérifiés

| Point | Fait | Source |
|---|---|---|
| État du projet | **Arrêté** ; développement commercial terminé en 2016, fork KaiOS | Wikipédia |
| Dernière version | Firefox OS 2.2 (avril 2015) ; préversion 2.5 | Wikipédia |
| Dépôts | organisation **`mozilla-b2g`** sur GitHub : **251 dépôts, tous archivés** (lecture seule) depuis le 3 novembre 2021 | github.com/mozilla-b2g |
| Gaia | « DEPRECATED — Gaia is a HTML5-based Phone UI for the Boot 2 Gecko Project » ; dernière activité 5 juillet 2021 | github.com/mozilla-b2g/gaia |
| Licence Gaia | **Apache License 2.0** (fichier `LICENSE` du dépôt : « Copyright 2015, Mozilla Foundation … Apache License, Version 2.0 ») | raw.githubusercontent.com/mozilla-b2g/gaia/master/LICENSE |
| Licence B2G / Gecko | MPL 2.0 (+ noyau Linux GPLv2 pour Gonk) | Wikipédia |
| Architecture | **Gonk** = noyau Linux + HAL Android ; **Gecko** = moteur ; **Gaia** = UI HTML/CSS/JS | bocoup/gaia-notes |
| Support historique | architectures ARM, x86, MIPS | Wikipédia |

## 2. Analyse composant par composant

### 2.1 Gonk — **abandonné**
Noyau Linux + HAL Android. Incompatible par construction avec un noyau FreeBSD : ni `binder`, ni `ashmem`, ni les conventions `/dev` Android. Aucun intérêt pour NexBSD.

### 2.2 Gecko (version B2G) — **abandonné**
Le « Gecko embarquable » (B2G, XULRunner) n'existe plus : Mozilla ne distribue plus de moteur intégrable pour applications tierces, et GeckoView est spécifique à Android. Utiliser un Gecko vieux de 8-10 ans exposerait le système à des vulnérabilités non corrigées.
> **Conséquence architecturale majeure :** la couche applicative mobile de NexBSD doit reposer sur un moteur Web **maintenu et disponible sous FreeBSD**, c'est-à-dire WebKitGTK (`www/webkit2-gtk`, 2.46.6 dans les ports ; 2.54.1 en amont) ou le navigateur Firefox en mode application. Voir `research/runtime-web/fiche.md`.

### 2.3 Gaia — **étudié**
- Licence **Apache-2.0** : réutilisable, y compris modifications et redistribution, avec conservation des notices.
- Contenu : applications système écrites en HTML/CSS/JS (horloge, contacts, SMS, appareil photo, paramètres, écran d'accueil), plus un ensemble de « building blocks » CSS.
- **Problème central :** Gaia dépend massivement d'API Web propriétaires de l'époque (`mozTelephony`, `mozSms`, `mozBluetooth`, `navigator.mozApps`, permissions B2G) qui **n'existent plus** dans aucun moteur moderne. Le code ne « tournera » pas tel quel ; c'est une **référence de conception et de structure**, pas un composant déployable.

Ce qui reste exploitable sans risque :
1. Les **grilles de style** et les patterns d'interaction pour petits écrans (à réécrire en CSS moderne).
2. Le **modèle de manifeste d'application** (JSON) — à adapter.
3. L'**architecture de la couche de permissions** — à réétudier, pas à copier.

## 3. Risques

| ID | Risque | Gravité |
|---|---|---|
| F-1 | Copier du code Gaia ancien et le déclarer « fonctionnel » sans test | élevée (fausse validation) |
| F-2 | Dépendance à des API Web disparues → réécriture quasi totale | élevée |
| F-3 | Mélange de licences (Apache/MPL) dans un même livrable sans inventaire | moyenne |
| F-4 | Attirer l'attention sur des marques déposées (Firefox, Mozilla) dans la communication du projet | moyenne |

## 4. Incertitudes

- Aucune vérification de licence n'a été faite pour **l'ensemble** des 251 dépôts archivés : seule Gaia a été vérifiée (Apache-2.0). Toute autre utilisation exige une vérification individuelle.
- La qualité réelle du code Gaia sur un moteur moderne n'est pas mesurable sans une expérience ; celle-ci n'a pas été faite.

## 5. Recommandation

- **Ne pas réutiliser Gonk ni le Gecko B2G.**
- **Étudier Gaia en P2** comme source d'inspiration UI, avec pour livrable une note de portage (« ce qui est repris / réécrit / abandonné ») ; aucune intégration de code Gaia sans tests.
- Écrire dès maintenant une **spécification d'interface propre à NexBSD** (`docs/architecture.md`, Couche C) plutôt que de partir du code historique.

## 6. Sources

| # | Source | URL | Consultée le |
|---|---|---|---|
| 1 | Wikipédia — Firefox OS | https://en.wikipedia.org/wiki/Firefox_OS | 2026-10-23 |
| 2 | Organisation GitHub mozilla-b2g (251 dépôts archivés) | https://github.com/mozilla-b2g | 2026-10-23 |
| 3 | Dépôt gaia (archivé le 2021-11-03) | https://github.com/mozilla-b2g/gaia | 2026-10-23 |
| 4 | Licence Gaia (Apache-2.0) | https://raw.githubusercontent.com/mozilla-b2g/gaia/master/LICENSE | 2026-10-23 |
| 5 | bocoup/gaia-notes (architecture Gonk/Gecko/Gaia) | https://github.com/bocoup/gaia-notes | 2026-10-23 |
| 6 | ArchiveOS — B2G | https://archiveos.org/b2g/ | 2026-10-23 |

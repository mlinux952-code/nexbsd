# Fiche de recherche — Moteur d'exécution Web pour la couche mobile

**Date de vérification :** 2026-10-23
**Statut :** **nouveau candidat identifié pendant la recherche** (non prévu dans le méga-prompt)
**Rôle visé :** Couche C — exécuter les applications Web et l'interface de NexBSD

---

## 1. Pourquoi cette fiche existe

Le méga-prompt prévoit « étudier Gecko » via Firefox OS. La recherche (voir `research/firefox-os/fiche.md`) montre que :

- le Gecko embarquable de l'époque B2G n'existe plus ;
- GeckoView est spécifique à Android ;
- les API Web propriétaires de Gaia ont disparu des moteurs modernes.

Il faut donc **choisir un moteur réellement disponible sous FreeBSD**. C'est un besoin concret identifié, pas l'ajout d'un composant « parce qu'il est populaire ».

## 2. Faits vérifiés

| Point | Fait | Source |
|---|---|---|
| WebKitGTK (port FreeBSD) | `www/webkit2-gtk` **2.46.6** (mise à jour du port 4 juillet 2026) ; disponible pour FreeBSD 13/14/15/16, aarch64/amd64/armv7/i386… | FreshPorts |
| WebKitGTK amont | **2.54.1** (2 octobre 2026) ; correctifs BSD réguliers (« Partially fix the build in BSD… » en 2.52.2) | webkitgtk.org |
| Licence WebKitGTK | **GPLv2 / BSD-2-Clause** (port FreeBSD : `GPLv2 BSD2CLAUSE`) ; la bibliothèque est sous LGPL pour l'essentiel | FreshPorts ; Wikipédia |
| Firefox sous FreeBSD | suivi activement : **Firefox 149.0** et **Firefox-esr 140.9.0** dans l'arbre des ports (T1 2026) | FreeBSD status report 2026Q1 |
| Autres moteurs | Chromium 146 (ports), Electron 40.8.3 (ajouté T1 2026) | idem |
| Vulnérabilités | `webkit2-gtk` a fait l'objet d'un lot de CVE corrigées en mai 2026 (VuXML) | progressiverobot.com (source secondaire) `[À VÉRIFIER]` |

## 3. Options techniques comparées

| Option | Avantages | Inconvénients | Verdict |
|---|---|---|---|
| **WebKitGTK + GTK3/4** | bibliothèque intégrable (API C), utilisable pour une coquille applicative, disponible en paquet, supporte Wayland/X11 | build lourd (mais paquet binaire disponible), consommation mémoire notable sur 4 Go, licence GPL/LGPL à gérer | **retenu pour l'étude** |
| Firefox en mode application (`--kiosk`, `-app`) | simplicité, moteur maintenu, paquet disponible | pas une bibliothèque : difficile de contrôler la fenêtre, pas d'intégration profonde, kiosque limité | acceptable pour une démonstration rapide |
| Chromium/Electron | écosystème riche | empreinte mémoire et disque très élevées, inadaptées à 4 Go + disque mécanique ; Electron est orienté desktop | écarté pour la cible matérielle |
| Portage de Gecko | fidélité à Firefox OS | pas d'API d'intégration, dette de sécurité | **écarté** |
| Moteur minimal maison (HTML restreint) | léger | hors de portée, valeur faible | écarté |

## 4. Conséquences d'architecture

1. La couche mobile de NexBSD sera **une application native (C/C++ ou Rust) embarquant WebKitGTK**, affichant des pages Web locales — et non un « OS Web » comme B2G.
2. Le modèle applicatif doit être défini par NexBSD : manifeste JSON, permissions déclaratives, stockage local.
3. Les fonctions matérielles (téléphonie, SMS, capteurs) **ne sont pas fournies** par le moteur : elles exigeraient des ponts natifs vers des pilotes qui n'existent pas sous FreeBSD. Elles restent hors périmètre.
4. La navigation au clavier est à implémenter côté NexBSD (mapping touches → focus/actions), le moteur ne fournissant que les événements DOM.

## 5. Risques

| ID | Risque | Gravité |
|---|---|---|
| W-1 | Empreinte mémoire de WebKitGTK sur 4 Go avec services réseau actifs | moyenne à élevée |
| W-2 | Vulnérabilités fréquentes du moteur → mises à jour obligatoires | élevée |
| W-3 | Licence GPLv2/LGPL : règles de liaison à respecter si NexBSD est distribué | moyenne |
| W-4 | Confusion de communication : « NexBSD exécute des applications Firefox OS » serait faux | élevée |

## 6. Incertitudes

- Performances réelles de WebKitGTK 2.46 sur un CPU de 2011 sans accélération GPU `[À VÉRIFIER par mesure]`.
- Disponibilité et état du paquet pour FreeBSD 15.1 au moment de l'installation `[À VÉRIFIER]`.
- Pertinence de WPE (WebKit pour embarqué) sous FreeBSD : non étudiée `[À VÉRIFIER]`.

## 7. Recommandation

- **Étudier WebKitGTK comme moteur de la couche mobile** (phase 5, après le prototype serveur).
- Pour une démonstration très rapide, utiliser **Firefox en mode kiosque** avec une page locale, sans prétendre à une intégration système.
- Ne jamais affirmer qu'un composant Firefox OS est réutilisé si ce n'est pas le cas.

## 8. Sources

| # | Source | URL | Consultée le |
|---|---|---|---|
| 1 | FreshPorts — www/webkit2-gtk (2.46.6, licence) | https://www.freshports.org/www/webkit2-gtk | 2026-10-23 |
| 2 | WebKitGTK — releases (2.54.1) | https://webkitgtk.org/ | 2026-10-23 |
| 3 | FreeBSD Status Report 2026Q1 — Ports (Firefox 149, Chromium 146, Electron) | https://www.freebsd.org/status/report-2026-01-2026-03/ | 2026-10-23 |
| 4 | Wikipédia — WebKitGTK (licence) | https://www.wikidata.org/wiki/Q3566968 | 2026-10-23 |

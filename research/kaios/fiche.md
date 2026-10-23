# Fiche de recherche — KaiOS (dimension mobile)

**Date de vérification :** 2026-10-23
**Statut :** candidat `En étude` → **proposition : `Rejeté comme base système`, `Retenu comme référence d'expérience utilisateur`**
**Rôle visé :** Couche C (plateforme mobile) — initialement envisagé comme composant à réutiliser

---

## 1. Faits vérifiés

| Point | Fait | Source |
|---|---|---|
| Nature | Système mobile Linux pour téléphones à clavier (feature phones), dérivé de Firefox OS | Wikipédia (KaiOS), kaios.dev/faq |
| Éditeur | KaiOS Technologies (Hong Kong) Ltd, principal actionnaire TCL | Wikipédia |
| Modèle de source | **« Source-available », pas open source** : seuls certains composants sont publiés | kaios.dev/faq ; kaiostech.com (help center) |
| Licence | **Propriétaire** ; correctifs noyau Linux sous GPLv2 ; composants B2G sous MPL | Wikipédia ; kaios.dev/faq |
| Dernière version annoncée | **KaiOS 4.0**, mai 2025 | Wikipédia / BetaWiki |
| Plateformes | **ARM** (arm32), cible initiale | BetaWiki ; Wikipédia |
| Construction d'image | **Impossible publiquement** : bootloader, RIL, pilotes et blobs OEM non distribués | kaiostech (source code) ; FAQ communautaire r/KaiOS |
| Dépôts publics | `gecko-b2g` (fork MPL de B2G), `api-daemon` (Rust, API externe, 3.0+) sur GitHub kaiostech | kaios.dev/2024/01 |
| Alternatives communautaires | GerdaOS (ROM de modding sur KaiOS 2.5.1, Nokia 8110 4G) — **déprécié, non maintenu** | r/KaiOS (2024) |
| Architecture interne | B2G + Gecko + « Gonk » = noyau Linux + HAL Android | kaios.dev (system properties) |

## 2. Analyse : pourquoi KaiOS n'est pas réutilisable comme base

1. **Juridique.** Le système complet n'est pas sous licence libre. Seuls les composants hérités de Mozilla (Gecko/B2G, MPL) et les correctifs noyau (GPLv2) sont publiés. Tout le reste (applications système, surcouche, intégration opérateur) est propriétaire.
2. **Technique — dépendance Linux/Android.** KaiOS repose sur « Gonk » : noyau Linux + HAL Android. Le noyau FreeBSD ne fournit ni HAL Android, ni `/dev/binder`, ni les interfaces attendues (`binder`, `ashmem`, propriétés `ro.*`). Un portage équivaudrait à réécrire toute la couche d'accès matériel.
3. **Technique — image incomplète.** Même sur une cible Linux/ARM, une image complète exige bootloader, RIL et pilotes du fabricant, non publiables.
4. **Maintenance.** Le noyau Gecko utilisé est ancien (dérivé B2G 2.x) : dette de sécurité majeure si on l'exposait au réseau.

## 3. Ce qui reste réellement utile (et réutilisable)

KaiOS reste une **référence de conception** précieuse, et son ancêtre Firefox OS fournit du code sous licence permissive :

| Élément | Exploitable ? | Comment |
|---|---|---|
| Modèle d'interaction (pavé directionnel, touches logicielles, écrans 240×320) | Oui — **concepts** | spécification UX à écrire, pas du code à copier |
| Architecture « applications = pages Web » | Oui — **concept** | implémentable sur un moteur Web moderne |
| Gaia (UI HTML/CSS/JS) | Oui, sous **Apache-2.0** | étude de portage (voir `research/firefox-os/fiche.md`) |
| Applications système KaiOS | Non | propriétaires, minifiées |
| Gecko de KaiOS | Non (ancien, MPL mais non maintenu) | — |
| `api-daemon` (Rust) | `[À VÉRIFIER]` | licence à confirmer avant toute étude |

## 4. Incertitude principale

Aucune information publique ne permet d'affirmer qu'un composant KaiOS précis, sous licence compatible, remplirait une fonction de NexBSD. **Toute réutilisation doit être décidée composant par composant, après lecture de la licence dans le dépôt** — et non globalement.

## 5. Recommandation

- **Rejeter KaiOS comme base système ou comme composant embarqué.**
- **Retenir « l'expérience KaiOS » comme exigence de conception**, formulée en critères testables (cf. `matrices/fonctions.md`, lignes M-01 à M-08) : navigation 5 touches, cibles ≥ 44 px, une action principale par écran, démarrage d'application < 3 s sur matériel cible, fonctionnement hors ligne.
- Si une démonstration mobile est voulue, elle sera **développée par NexBSD** sur un moteur Web disponible sous FreeBSD, et non dérivée de KaiOS.

## 6. Sources

| # | Source | URL | Consultée le |
|---|---|---|---|
| 1 | Wikipédia — KaiOS (licence, versions, architecture) | https://en.wikipedia.org/wiki/KaiOS | 2026-10-23 |
| 2 | kaios.dev — FAQ (« Is KaiOS open source? ») | https://kaios.dev/faq/ | 2026-10-23 |
| 3 | kaios.dev — Open Source Resources | https://kaios.dev/2024/01/kaios-open-source-resources/ | 2026-10-23 |
| 4 | kaios.dev — System Properties (Gonk / HAL Android) | https://kaios.dev/2024/03/kaios-system-properties/ | 2026-10-23 |
| 5 | KaiOS Tech — Source code (limites de distribution) | https://www.kaiostech.com/help-center/source-code-2/ | 2026-10-23 |
| 6 | r/KaiOS FAQ (portage impossible) | https://www.reddit.com/r/KaiOS/comments/x93rod/ | 2026-10-23 |
| 7 | BetaWiki — KaiOS (arch arm32, versions) | https://betawiki.net/wiki/KaiOS | 2026-10-23 |

# ADR-0003 — Abandon de Gecko B2G ; moteur Web = WebKitGTK

- **Date :** 2026-10-23
- **Statut :** proposition
- **Références :** `research/firefox-os/fiche.md`, `research/runtime-web/fiche.md`

## Problème
Quel moteur exécute les applications Web de la couche mobile ?

## Faits
- Gecko B2G n'a plus d'API d'intégration pour applications tierces ; GeckoView est spécifique à Android.
- Les dépôts `mozilla-b2g` sont archivés depuis le 3 novembre 2021 ; Gaia date de 2015-2021.
- Les API Web propriétaires utilisées par Gaia (`mozTelephony`, `mozSms`, `mozApps`…) n'existent plus.
- WebKitGTK est packagé sous FreeBSD (`www/webkit2-gtk` 2.46.6), activement maintenu en amont (2.54.1 en octobre 2026).

## Décision proposée
- **Abandonner** Gecko B2G et Gonk.
- **Retenir WebKitGTK** comme moteur d'exécution de la couche C ; Firefox en mode kiosque acceptable pour une démonstration rapide uniquement.
- **Étudier Gaia** comme référence de conception (licence Apache-2.0), sans promesse de réutilisation.

## Conséquences
- NexBSD définit son propre modèle applicatif (manifeste, permissions, stockage).
- Le moteur impose des mises à jour régulières (CVE fréquentes) → politique de sécurité.
- Empreinte mémoire à mesurer (risque R-03).

## Conditions de révision
- Si WebKitGTK n'est pas exploitable sur le matériel cible.
- Si WPE (WebKit pour embarqué) s'avère disponible et plus adapté.

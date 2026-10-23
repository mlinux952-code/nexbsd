# ADR-0013 — La couche mobile est du code NexBSD sur WebKitGTK ; Gaia est une inspiration

- **Date :** 2026-10-23
- **Statut :** proposition
- **Référence :** `research/kaios/fiche.md`, `research/firefox-os/fiche.md`, `research/runtime-web/fiche.md`

## Problème
Le raisonnement initial était : « KaiOS est un peu fermé, on comble ses vides avec Firefox OS ». Ce raisonnement ne tient pas techniquement : il n'existe pas de socle KaiOS légal à compléter (aucune image constructible : blobs OEM, RIL, bootloader), et Firefox OS ne fournit pas les couches système manquantes — il est mort en 2016 et ses API Web (`mozTelephony`, `mozSms`, `mozApps`) ont disparu des moteurs actuels.

## Décision proposée
1. **Écrire la couche mobile en code propre à NexBSD** (licence au choix du projet), au-dessus de **WebKitGTK**.
2. Utiliser **Gaia (Apache-2.0)** comme **référence de conception** : structure d'écran d'accueil, patterns d'interaction petit écran, organisation des applications. Pas de dépendance à son code.
3. Ne jamais dépendre d'une API Web propriétaire disparue.
4. Ne jamais présenter NexBSD comme un portage de KaiOS ou de Firefox OS.

## Justification
- Seul WebKitGTK est à la fois maintenu et packagé sous FreeBSD.
- Les idées de KaiOS (navigation 5 touches, écrans 240×320, une action principale par écran) sont libres d'usage : ce sont des principes d'interaction.
- Le code de Gaia est disponible mais inadapté ; le réutiliser créerait une dette immédiate.

## Conséquences
- Coût de développement plus élevé qu'un simple portage — mais c'est le prix de l'autonomie.
- La couche mobile devient un **axe d'identité de NexBSD**, pas un emprunt.
- Livrable attendu : une **spécification d'interaction** écrite avant tout code (critères M-01 à M-08 de `matrices/functions.csv`).

## Conditions de révision
Si un composant Firefox OS précis, sous licence compatible, s'avère réellement réutilisable après lecture de son code et test — alors un ADR spécifique pourra l'intégrer, composant par composant.

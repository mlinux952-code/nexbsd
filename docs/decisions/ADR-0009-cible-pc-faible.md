# ADR-0009 — Le « PC faible » est la cible de conception, pas une contrainte subie

- **Date :** 2026-10-23
- **Statut :** proposition
- **Référence :** `docs/09-cible-pc-faible.md`

## Problème
Le projet a été cadré en traitant les 4 Go du PC de 2011 comme une limite du matériel de test. Le responsable du projet a précisé que **NexBSD est destiné à des PC faibles**. Ce n'est pas la même contrainte : la seconde impose des choix de conception, la première seulement une prudence de test.

## Décision proposée
1. Adopter **L1 (amd64, 2 cœurs, 1-2 Go de RAM, disque mécanique)** comme cible de référence.
2. Fixer un **budget mesurable** : ≤ 128 Mo de RAM au repos, ≤ 256 Mo avec services réseau, ≤ 2 Go d'espace disque pour l'installation de base, démarrage ≤ 60 s sur HDD.
3. **Refuser** tout composant qui fait dépasser le budget, même s'il est techniquement intéressant.
4. Séparer les images logicielles : `nexbsd-lab` (≤ 128 Mo), `nexbsd-net` (≤ 256 Mo), `nexbsd-mobile` (≤ 768 Mo, profil L2/L3).

## Justification
Un système « pour PC faible » qui exigerait 8 Go pour tourner, ou une grosse machine pour être construit, manquerait son objectif dès le départ. Fixer le budget d'abord évite de devoir tout recommencer plus tard.

## Conséquences
- **UFS par défaut**, ZFS rétrogradé en option (le cache ARC consomme la RAM).
- Pas d'environnement de bureau complet ; interface texte par défaut.
- La couche mobile devient une **image séparée**, pas la configuration par défaut.
- Chaque ajout de composant est accompagné d'une mesure de RAM.
- Les mesures deviennent un livrable obligatoire de chaque version.

## Conditions de révision
- Si les mesures montrent que le budget est intenable sur le matériel réel → réviser les chiffres **en le documentant**, pas en silence.
- Si la cible inclut des machines 32 bits (voir §3 de `docs/09-cible-pc-faible.md`, inconnue à ce jour).

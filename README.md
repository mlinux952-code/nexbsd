# NexBSD

**Projet expérimental d'architecture système** — base FreeBSD, expérience mobile inspirée de KaiOS, services réseau inspirés de NetWare.

> **Principe directeur :** concevoir avec ambition, développer avec méthode, ne déclarer comme réalisé que ce qui a été effectivement vérifié.

> **Vous reprenez ce projet ? Lisez `START-HERE.md` en premier.** Ce fichier décrit le protocole de session obligatoire (lecture de l'état, règles anti-dérive, mise à jour en fin de session). L'état réel en une page est dans `docs/ETAT.md`.

---

## État réel du projet (au 2026-10-23)

| Élément | État |
|---|---|
| Phase | **Phase 0 (cadrage) et Phase 1 (recherche/inventaire) — en cours** |
| Code source NexBSD | **Aucun.** Aucun composant NexBSD n'existe à ce jour. |
| Système installé | **Aucun.** Aucune installation n'a été réalisée. |
| Image système | **Aucune.** |
| Tests exécutés | **Aucun test d'exécution.** Seules des recherches documentaires ont été menées. |
| Livrables produits | Cadrage, fiches de recherche sourcées, matrices, registre des risques, 3 options de prototype, plan d'action, scripts de préparation (non testés sur le poste du responsable) |
| Modèle de système | **Proposition (ADR-0011)** : **fork** de l'arbre FreeBSD (arbre source possédé, images propres) — et **non** « FreeBSD + paquets » |
| Capacité de production d'image | **Aucune aujourd'hui** : nécessite une machine de construction sérieuse (profil L3, non disponible) |
| Prototype retenu | **Proposition** : « NexBSD-Lab-0 » (voir `docs/prototypes.md`) — dérisque les composants, ne produit pas le produit |
| Objectif final | **Publication grand public** (ADR-0016), conditionnée à **10 portes** vérifiables — aucune date annoncée |

**NexBSD n'est pas un système d'exploitation existant.** C'est un projet de conception en phase d'étude. Toute affirmation contraire serait fausse.

---

## Ce que le projet n'est pas

- Ce n'est **pas** un portage de KaiOS : KaiOS est propriétaire, seuls certains composants (Gecko/B2G) sont publiés sous MPL, et une image complète exige des blobs OEM non distribuables.
- Ce n'est **pas** un clone de NetWare : le code source de NetWare n'est pas public ; seules des fonctions peuvent être reproduites ou approchées.
- Ce n'est **pas** une distribution FreeBSD « rebrandée » : le modèle visé est un fork avec un delta propre documenté (ADR-0011), pas un simple renommage.
- Ce n'est **pas** un assemblage de logiciels : la base reste sous licence permissive, les composants GPL vivent dans une couche séparée (ADR-0012).

## Ce qu'il est concrètement aujourd'hui

Un dossier de conception : un cadrage, un inventaire de composants vérifiés, des matrices de licences et de compatibilité, un registre des risques et un plan d'action par étapes vérifiables.

---

## Prérequis pour reprendre le travail

- **Cible du système** : PC faible (profil L1 : amd64, 1-2 Go de RAM, disque mécanique) — cf. `docs/09-cible-pc-faible.md`. Ce n'est pas une contrainte subie, c'est un choix de conception (ADR-0009).
- **Station de préparation** : poste Linux Mint à faible capacité — sert à vérifier les images, écrire les supports USB et faire tourner des VM légères (cf. `docs/10-station-linux-mint.md`). Aucune compilation lourde (ADR-0010).
- **Matériel de test réel** : un PC de 2011, 4 Go de RAM, disque mécanique, Windows 7 installé — **le disque principal ne doit pas être modifié** (contrainte absolue, cf. `docs/hardware.md`).
- **Aucune connaissance préalable** du projet n'est requise : lire `docs/00-cadrage-phase0.md` puis `reports/session-2026-10-23.md`.
- **Outils** (à venir, pour les phases suivantes) : un support USB vierge, l'accès à un réseau local isolé, un second poste pour compiler si nécessaire.

## Limites connues (au 2026-10-23)

1. Aucune faisabilité n'est démontrée à ce stade : rien n'a été construit ni mesuré.
2. Le matériel de test n'a pas été identifié (CPU, firmware, périphériques, état du disque inconnus).
3. La dimension mobile est la plus incertaine : FreeBSD n'a **pas** d'infrastructure de gestion d'énergie aboutie, et les pilotes téléphonie/modem/senseurs sont absents ou expérimentaux.
4. La compatibilité NetWare historique (IPX/NCP) est techniquement la plus coûteuse : IPX a été retiré de FreeBSD en 11.0 et de Linux en 4.17.
5. Plusieurs points restent marqués **À VÉRIFIER** dans les fiches de recherche (versions de ports FreeBSD, licences exactes de certains composants).

## Feuille de route (résumé)

| Phase | Contenu | État |
|---|---|---|
| 0 | Cadrage, vision, périmètre, critères de réussite, cible PC faible | **Réalisé (documents)** |
| 1 | Recherche, inventaire, matrices, licences | **Réalisé (documents)** |
| 2 | Étude de faisabilité + registre des risques | **Amorcé** (risques identifiés, faisabilité non conclue) |
| 3 | Architecture détaillée, interfaces, flux | Proposé (squelette) |
| 4 | Preuve de faisabilité : prototype minimal | **Non commencé** |
| 5 | Intégration progressive | Non commencé |
| 6 | Validation (sécurité, stabilité, performance) | Non commencé |
| 7 | Distribution expérimentale | Non commencé |
| 8 | Évolution | Non commencé |

Détail et critères de sortie : `docs/roadmap.md`.

---

## Organisation du dépôt

```
nexbsd/
├── START-HERE.md              ← PROTOCOLE DE SESSION (à lire en premier)
├── README.md                  ← ce fichier : vision, état réel, limites, feuille de route
├── docs/ETAT.md               ← état du projet en une page (mis à jour à chaque session)
├── docs/
│   ├── 00-cadrage-phase0.md   cadrage, hypothèses, périmètre, critères de réussite
│   ├── 09-cible-pc-faible.md  définition de la cible L0-L3 et budget de ressources
│   ├── 10-station-linux-mint.md  procédure de la station de préparation (Mint + QEMU)
│   ├── architecture.md        couches A→F, interfaces, flux
│   ├── roadmap.md             phases et critères de sortie
│   ├── hardware.md            diagnostic non destructif du PC de test
│   ├── security.md            politique de sécurité initiale
│   ├── prototypes.md          3 options de prototype comparées + recommandation
│   ├── plan-action.md         plan d'action ordonné (Étape E)
│   ├── glossaire.md           termes techniques expliqués
│   └── decisions/             ADR — registre des décisions architecturales
├── research/                  fiches de recherche sourcées (une par candidat)
├── matrices/                  matrices composants / fonctions / licences / compatibilité + risques
├── scripts/                   diagnostic hôte, vérification d'image, écriture USB garde-fou, lanceur QEMU
├── tests/                     plans et comptes rendus de tests (vide à ce stade)
├── build/                     scripts de construction (vide à ce stade)
├── integration/               configurations d'intégration (vide à ce stade)
└── reports/                   comptes rendus de session et de version
```

## Conventions de rédaction

Chaque affirmation technique est étiquetée :

- `[FAIT]` : vérifié dans une source citée, avec URL et date de consultation.
- `[HYPOTHÈSE]` : hypothèse de travail, non vérifiée.
- `[PROPOSITION]` : choix proposé, en attente de validation par le responsable du projet.
- `[À VÉRIFIER]` : information manquante ou douteuse, à lever avant décision.
- `[DÉCISION]` : validé par le responsable du projet (aucune décision n'est validée à ce jour).

**Aucune décision n'est marquée `[DÉCISION]` sans validation explicite du responsable du projet.**

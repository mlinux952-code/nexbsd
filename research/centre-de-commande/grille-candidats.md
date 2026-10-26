# Grille de comparaison des systèmes proposés — état : **à remplir**

**Règle absolue de ce fichier :** une case ne se remplit **que** sur la base d'une **source lue** ou d'une
**mesure**. Pas de case « au feeling ». Quand on ne sait pas, on écrit **`?`** — et `?` est une réponse
honnête, pas une faiblesse.

**But de la grille :** répondre à **une** question — *lequel de ces projets apporte quelque chose à notre
problème identifié (administration multi-machines avec les identités de l'annuaire), **sans** remettre en
cause nos décisions produit ?*

---

## Critères (pondération à valider)

| # | Critère | Poids | Pourquoi |
|---|---|---|---|
| 1 | Réutilisable **sans** changer de noyau (ADR-0006) | ×3 | un projet qui exige son propre noyau est hors sujet |
| 2 | Licence compatible avec notre frontière (ADR-0012) | ×3 | GPL ⇒ Platform seulement, jamais la base |
| 3 | Apporte une réponse à **notre** question identifiée | ×3 | sinon : veille, pas chantier |
| 4 | Poids d'exécution sur PC faible (ADR-0009) | ×2 | 3,7 Go de RAM au total |
| 5 | Maturité / maintenance active | ×2 | surface d'attaque |
| 6 | Coût d'apprentissage et d'intégration | ×1 | temps produit |

## Tableau — à compléter

| Projet | Famille réelle | Licence (à vérifier) | Ce qu'il apporte **à notre question** | Verdict provisoire |
|---|---|---|---|---|
| **FreeBSD** | OS complet | BSD-2 (à vérifier par fichier) | **notre base** — noyau + userland + jail | **retenu (ADR-0001)** |
| **NetBSD** | OS complet | ? | portabilité matérielle : **utile pour la cible PC de 2011 ?** | `?` |
| **Genode** | cadre de composants | AGPL-3.0 + exception de liaison (à vérifier) | isolation stricte entre composants | `?` — licence à examiner avant tout |
| **seL4** | micro-noyau | BSD-2 (à vérifier) | isolation formellement prouvée | `?` — pas un OS PC : pilotes absents |
| **NixOS / Nix** | distribution + gestionnaire | MIT (à vérifier) | configuration **reproductible** + retour arrière | **intéressant** : recoupe notre `rollback` (couche B) |
| **OpenWrt** | distribution routeur | GPL-2.0 | configuration/supervision d'équipements réseau | **pertinent pour un adaptateur**, pas pour la base |
| **Zephyr** | OS temps réel embarqué | Apache-2.0 (à vérifier) | communication capteurs/embarqué | **hors périmètre** aujourd'hui |
| **Ansible** | automatisation | GPL-3.0 | exécution de tâches multi-machines via SSH | **candidat sérieux pour le hub** (Platform) |
| **Home Assistant** | intégration d'appareils | Apache-2.0 (à vérifier) | modèle d'intégrations hétérogènes | **référence de conception**, pas composant |
| **illumos** | OS (Solaris) | CDDL | stockage (ZFS), zones, observation | **veille** — recoupe jail/ZFS déjà présents |
| **KaiOS** | OS mobile propriétaire | propriétaire | ergonomie clavier | **rejeté** (ADR-0002), principes conservés |
| **MARS_NWE** | serveur de fichiers NetWare | GPL-2.0 | modèle fonctionnel NetWare | **référence de labo** (ADR-0004), pas composant |

## Les trois seules conclusions déjà solides

1. **Aucun de ces projets ne remplace FreeBSD comme base.** La raison n'est pas idéologique : nous avons un
   noyau compilé, démarré, avec un banc à 11/11 dessus. Toute substitution détruirait cette preuve.
2. **Deux candidats méritent une lecture réelle** : **Nix** (pour le retour arrière/reproductibilité, couche B)
   et **Ansible** (pour l'exécution de tâches multi-machines, couche D-4). Tous deux sont des **outils**, pas
   des systèmes : ils s'ajoutent **sans** toucher au noyau.
3. **Les autres relèvent de la veille.** Une veille n'est pas un chantier : on lit, on note, on n'installe pas.

## Prochaine action de ce couloir (une seule)

Lire la **licence exacte de Nix** et le **modèle d'exécution d'Ansible** (SSH sans agent, ou agent), puis
écrire **une page** : *« ce que NexBSD emprunte à Nix et à Ansible, et ce qu'il n'emprunte pas »*.
**Durée cible : 1 heure. Pas plus.** Si ça déborde, c'est que la question n'était pas la bonne.

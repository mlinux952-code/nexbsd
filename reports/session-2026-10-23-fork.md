# Compte rendu de session — S-003 (suite du 2026-10-23)

**Déclencheur :** le responsable du projet reformule une exigence fondamentale :
> « notre nexbsd est un système d'exploitation à part entière, pas un freebsd modifié avec quelques logiciels en surplus ».

**Ce qui n'a pas changé :** aucune installation, aucun test d'exécution, aucune ligne de code NexBSD. Le disque du PC de 2011 est intact.

---

## 1. Décision structurante adoptée (proposition)

Le modèle « assemblage » (FreeBSD + paquets) proposé en S-001 est **abandonné** comme modèle cible. Le modèle proposé devient le **fork M2** :

- NexBSD **possède son arbre source** (branches `nexbsd/*` sur clone de FreeBSD) ;
- il **construit** ses images (`src.conf`, `KERNCONF`, `release.sh`, puis `pkgbase`) ;
- il **signe et publie** ses versions ;
- il **assure le suivi de sécurité** par fusion régulière de l'amont ;
- son **delta propre** est petit, justifié par ADR, isolé et fusionnable.

→ `docs/11-fork-pas-surcouche.md`, **ADR-0011**.

## 2. Corrections apportées au raisonnement initial (avec les faits)

| Formulation du responsable | Statut | Correction |
|---|---|---|
| « FreeBSD est open source, on peut utiliser son code » | ✅ **exact** | licence BSD-2 : modification et redistribution autorisées, sans obligation de publier les modifications. **Mais** cela transfère au projet la responsabilité des correctifs de sécurité (R-17). |
| « KaiOS est un peu fermé, on comble les vides avec Firefox OS » | ❌ **ne tient pas** | KaiOS n'est pas « un peu » fermé : système propriétaire, **aucune image constructible** (blobs OEM, RIL, bootloader). Et il n'existe pas de « socle légal à compléter » : Firefox OS est mort en 2016, ses API Web ont disparu des moteurs actuels. On garde **les idées** (UX) et **Gaia comme référence** (Apache-2.0), pas comme dépendance. |
| « NetWare : MARS_NWE, Samba, OpenLDAP, trouver un compromis » | ⚠️ **partiellement** | MARS_NWE ne peut pas être « collé » : **GPL-2** (interdite dans la base) **et** dépendance à **IPX** (retiré de FreeBSD 11.0). Le compromis retenu : Samba + OpenLDAP fournissent les **fonctions** ; NexBSD écrit **son propre** outil d'administration ; la compatibilité NCP/IPX devient une **réimplémentation propre en espace utilisateur** (recherche P3, ADR-0014). |
| « prendre tous les bons de chaque système » | ✅ **exact, avec une règle** | Prendre **librement les idées** ; prendre le **code** seulement si licence **et** architecture le permettent. C'est la règle qui rend le projet faisable. |

## 3. Faits nouveaux vérifiés dans cette session

| Fait | Source |
|---|---|
| **HardenedBSD** : fork de FreeBSD depuis 2014, **2 fondateurs**, toujours actif en 2026, rapports de statut mensuels, 15-STABLE et 16-CURRENT | hardenedbsd.org ; DistroWatch |
| Sa méthode : « cherry-pick a few commits that smell like security » depuis FreeBSD vers sa branche | rapport août/septembre 2026 |
| Sa charge réelle : « at most two attempts at testing fixes per day », « installer image generation is still somewhat broken » | rapport mai 2026 |
| Il maintient **son propre arbre de ports** (synchronisation 6 h) et ne gère **pas** les branches trimestrielles « faute d'équipe » | GitHub HardenedBSD |
| La chaîne de fork existe nativement : `buildworld`, `buildkernel`, `SRCCONF`, `KERNCONF`, `release.sh`, et **`make packages`** (pkgbase, aperçu technologique en 15.x, appelé à devenir la norme) | FreeBSD Handbook ch. 27 ; articles releng |
| **La marque « FreeBSD » ne peut pas faire partie du nom d'un produit dérivé** | FreeBSD Foundation, Trademark Usage Terms and Conditions + FAQ |
| FreeBSD exige déjà **l'isolation des licences non-BSD** dans son propre arbre « pour ne pas contaminer les composants BSD » | FreeBSD Licensing Policy |
| Vague d'avis de sécurité FreeBSD en mai 2026 : au moins 7 (SA-26:18 à SA-26:24), dont élévations de privilèges et RCE noyau | synthèse publique des avis FreeBSD |

## 4. Nouveaux documents

**Créés :**
- `docs/11-fork-pas-surcouche.md` — le document pivot : 3 modèles comparés, test des 7 questions, chaîne technique réelle, précédent HardenedBSD, prix de la dette de sécurité, 3 domaines Base/Plateforme/Apps, chemin en 7 étapes.
- `docs/12-licences-et-frontieres.md` — ce qui peut entrer où, la règle de frontière processus, GPL-2 vs GPL-3, Apache-2 vs GPL-2, obligations de distribution d'une image, marques.
- `docs/decisions/ADR-0011` à `ADR-0015`.
- `reports/session-2026-10-23-suite.md` (S-002), `reports/session-2026-10-23-fork.md` (ce fichier).

**Modifiés :**
- `README.md` — le modèle de système devient « fork », avec la mention explicite qu'aucune image ne peut être produite aujourd'hui.
- `docs/roadmap.md` — ajout des phases **4bis** (devenir un fork) et **4ter** (pkgbase), jalons **J8** (première image construite par NexBSD) et **J9** (premier delta propre).
- `docs/architecture.md` — trois domaines de propriété + tableau de la chaîne de construction.
- `docs/plan-action.md` — les étapes existantes sont requalifiées : elles **dérisquent les composants**, elles ne produisent pas le produit.
- `docs/decisions/README.md` — registre à 15 ADR.
- `matrices/licences.csv` — **réécrit** avec une colonne « peut entrer dans NEXBSD BASE » (9 champs, vérifiés par script).
- `matrices/risques.csv` — **5 nouveaux risques** : R-17 (dette de sécurité du fork), R-18 (L3 jamais disponible), R-19 (contamination GPL), R-20 (dérive du chantier IPX/NCP), R-21 (marque FreeBSD).
- `tests/plan-tests.md` — ajout T-12 (construction de la base) et T-13 (frontière de licence, à automatiser).
- `docs/decisions/ADR-0011` — précision : **configurer** son noyau (`KERNCONF`) n'est pas **modifier** le code du noyau (ADR-0006 reste valable).

## 5. La question qui décide de tout

> **Le fork est-il assumé, avec son coût ?**

Le coût, tel que les faits le montrent :
1. **Responsabilité des correctifs de sécurité** de toute la base (plusieurs avis par mois).
2. **Publier des images** est un métier — HardenedBSD, dix ans d'expérience, admet encore des soucis d'images d'installation.
3. **Discipline de delta** : toute divergence rend les fusions futures plus coûteuses.
4. **Machine de construction** (profil L3) indispensable : `buildworld` + images + pkgbase ne se font pas sur 4 Go.

Si ces quatre points sont acceptés → M2 est le bon modèle, et le projet a une vraie trajectoire de système d'exploitation.
S'ils ne le sont pas → il faut le dire et redescendre explicitement au modèle hybride, sans jamais prétendre le contraire.

## 6. Ce qui reste incertain

- **Date ou existence du profil L3** : conditionne tout le passage en M2 (`[À VÉRIFIER auprès du responsable]`).
- **Antériorité du nom NexBSD** : non vérifiée.
- **Statut des marques NetWare/Novell** aujourd'hui : non vérifié.
- **Disponibilité de spécifications publiques NCP/IPX** : non vérifiée, conditionne ADR-0014.
- **Disponibilité d'OpenLDAP ≥ 2.6 sous FreeBSD** : toujours non vérifiée.

## 7. Prochaines actions

**Pour le responsable (décisions, aucune action matérielle) :**
1. Répondre à la question du §5 : **le fork est-il assumé ?**
2. Préciser le profil L3 : *indisponible / dans 6 mois / dans 1 an / indéterminé*.
3. Choisir l'axe d'identité prioritaire : A (budget PC faible mesuré), B (réseau façon NetWare), ou A+B (recommandé).
4. Toujours en attente : le relevé `scripts/00-diagnostic-hote.sh` sur le Mint, et la question 32 bits.

**Pour l'assistant (dès que possible) :**
5. Rédiger la **spécification d'interaction** de la couche mobile (critères M-01 à M-08) — travail utile qui ne dépend d'aucun matériel.
6. Préparer le **squelette du delta propre** : structure de `nexbsd/` dans un arbre source (`src.conf`, `KERNCONF=NEXBSD_L1`, `release.conf`), prêt à être appliqué quand L3 arrivera.
7. Rédiger la **fiche de recherche NCP/IPX** (spécifications publiques, clients disponibles) pour décider si ADR-0014 est viable.

## 8. Rappel de méthode

Cette session a produit **des décisions documentées**, pas des fonctionnalités. Le projet n'a toujours **rien construit**. Ce qui a progressé, c'est la **définition de ce que NexBSD sera** — et c'est précisément ce qui évite de construire la mauvaise chose pendant six mois.

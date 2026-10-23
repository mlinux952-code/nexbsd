# NexBSD est-il un système à part entière ? — Modèle « fork », pas « surcouche »

**Version :** 1.0 — 2026-10-23
**Statut :** `[PROPOSITION]` — ce document reformule l'ambition du responsable du projet en termes d'ingénierie et propose un modèle
**Déclencheur :** *« notre nexbsd est un système d'exploitation à part entière, pas un freebsd modifié avec quelques logiciels en surplus »*

---

## 1. Votre demande, traduite en ingénierie

Ce que vous refusez est parfaitement identifiable : **le modèle « M1 — assemblage »** (installer FreeBSD, puis ajouter des paquets). C'est effectivement la faiblesse de ma première proposition : dans ce modèle, NexBSD n'est pas un système, c'est **une configuration**.

Ce que vous demandez est un autre modèle : NexBSD **possède son arbre de code, construit ses propres images, mène ses propres versions**. C'est-à-dire un **fork**.

Et vous avez raison sur le principe juridique : le code de FreeBSD est sous licence BSD 2-clause, qui **autorise explicitement** la modification, la redistribution et même la fermeture du code dérivé. Utiliser ce code comme base de son propre système est non seulement permis, c'est **exactement ce que fait FreeBSD lui-même** (FreeBSD est un dérivé de 386BSD/4.4BSD), et ce que font GhostBSD, NomadBSD, MidnightBSD et HardenedBSD.

**Mais « à part entière » a deux sens, et il faut choisir lequel est visé.**

| Sens | Définition | Accessible ? |
|---|---|---|
| **Sens 1 — produit** | Une distribution complète : son arbre source, sa chaîne de construction, ses images signées, son cycle de versions, son identité, sa documentation. | **Oui.** C'est un travail d'ingénierie de plusieurs mois, pas de plusieurs décennies. |
| **Sens 2 — technique** | Un noyau et un userland écrits majoritairement par le projet, avec une architecture propre. | **Non**, pas dans un horizon réaliste : cela représente des centaines d'années-ingénieur (Linux ≈ 30 ans et des milliers de contributeurs). |

**Proposition de position :** viser le **sens 1 pleinement**, et le **sens 2 partiellement et progressivement** — c'est-à-dire un fork dont le *delta* propre (ce que NexBSD ajoute ou change) **grandit délibérément**, au lieu d'être un simple renommage.

---

## 2. Le test des sept questions

Un système « à part entière » répond oui à ces sept questions. C'est la définition opérationnelle que je propose d'adopter.

| # | Question | M1 assemblage | M2 fork léger | M3 fork profond |
|---|---|---|---|---|
| 1 | Le projet possède-t-il son **arbre source** (git) ? | non | **oui** | oui |
| 2 | Le projet **construit-il** lui-même son image système ? | non | **oui** | oui |
| 3 | Le projet **signe et publie** ses versions ? | non | **oui** | oui |
| 4 | Le projet décide de son **jeu de composants** (noyau, options, userland) ? | partiellement | **oui** | oui |
| 5 | Le projet **assure le suivi des failles de sécurité** de sa base ? | non (délégué à FreeBSD) | **oui (par fusion amont)** | oui (par correctifs propres) |
| 6 | Le projet a-t-il une **identité technique** (comportements, ABI, outils propres) ? | faible | moyenne | forte |
| 7 | Le projet **diverge-t-il réellement** de l'amont ? | non | peu, mais oui | beaucoup |

---

## 3. Les trois modèles, coûts et bénéfices

### M1 — Assemblage *(ce que je proposais ; rejeté par le responsable)*
FreeBSD installé + paquets + configuration NexBSD.
- **Coût :** quelques semaines.
- **Identité :** quasi nulle. N'importe qui obtient le même résultat avec un script.
- **Verdict :** ne répond pas à la demande. **Rejeté.**

### M2 — Fork léger *(recommandé comme cible)*
Le projet clone l'arbre FreeBSD, maintient ses propres branches, ses propres fichiers `src.conf` / `KERNCONF`, sa propre chaîne `release.sh` / pkgbase, et publie ses images. Le **delta propre reste petit au départ** (options de build, noyau allégé pour PC faible, réglages par défaut, identité, outillage NexBSD) mais il est **réel et versionné**.
- **Coût :** élevé mais borné. Le vrai coût n'est pas le premier build, c'est le **suivi** : à chaque avis de sécurité FreeBSD, il faut fusionner, reconstruire, tester, publier.
- **Identité :** réelle — NexBSD a son noyau configuré pour lui, son userland sans superflu, ses images, son cycle.
- **Précédent :** HardenedBSD (voir §4).
- **Verdict :** **c'est le modèle qui correspond à votre demande.**

### M3 — Fork profond
Remplacer des sous-systèmes (init, gestion de paquets, couche réseau, sécurité MAC), diverger fortement du noyau.
- **Coût :** très élevé, et croissant : chaque divergence rend les fusions amont plus douloureuses.
- **Risque :** se retrouver avec une base non maintenue en sécurité faute de temps.
- **Verdict :** **horizon lointain**, jamais un point de départ. À n'ouvrir qu'après plusieurs versions stables en M2.

---

## 4. Le précédent HardenedBSD : la preuve que c'est possible — et ce que ça coûte

Faits vérifiés (2026) :

| Fait | Source |
|---|---|
| Fork de FreeBSD, **fondé en 2014** par deux personnes (Oliver Pinter, Shawn Webb) | DistroWatch |
| **Toujours actif en 2026**, rapports de statut mensuels, 15-STABLE et 16-CURRENT | hardenedbsd.org |
| Pratique déclarée : « **cherry-pick a few commits that smell like security** » depuis la branche main de FreeBSD vers sa 15-stable | rapport août/septembre 2026 |
| Maintient **son propre arbre de ports** synchronisé toutes les 6 h avec FreeBSD ; ne gère pas les branches trimestrielles « faute d'équipe » | GitHub HardenedBSD |
| Produit ses **propres images** de release — et admet que « **installer image generation is still somewhat broken** » | rapport mai 2026 |
| Charge réelle : « **at most two attempts at testing fixes per day** », « it takes quite the number of hours to test even the smallest of changes » | rapport mai 2026 |

**Lecture :** un fork est faisable pour une équipe minuscule — **à condition d'accepter trois choses** :
1. Le delta propre doit rester **petit** et **fusionnable**.
2. Le travail principal est de la **veille et de la fusion**, pas de l'invention.
3. La publication d'images est un **métier en soi** (HardenedBSD, dix ans d'expérience, a encore des soucis d'images d'installation).

C'est exactement le profil de NexBSD aujourd'hui : une personne + un assistant. Donc M2 est possible, mais **il faut dimensionner l'ambition à cette réalité**, pas l'inverse.

---

## 5. La chaîne technique réelle d'un fork (ce que ça implique concrètement)

FreeBSD fournit tous les mécanismes nécessaires. Un fork NexBSD se construirait ainsi :

```sh
# 1. Posséder l'arbre source
git clone https://git.FreeBSD.org/src.git nexbsd-src
cd nexbsd-src && git switch -c nexbsd/15 stable/15

# 2. Décider ce qu'on est : options de construction propres
#    src.conf   → ce que contient le système (sans doc, sans debug, sans jeux d'outils inutiles)
#    KERNCONF   → noyau allégé pour PC faible
make buildworld  SRCCONF=nexbsd/src.conf
make buildkernel KERNCONF=NEXBSD_L1 SRCCONF=nexbsd/src.conf

# 3. Produire une image installable signée par le projet
sh release/release.sh -c nexbsd/release.conf

# 4. (voie moderne) produire la base sous forme de paquets : pkgbase
make packages     # → dépôt pkgbase propre à NexBSD
```

C'est le cœur du sujet : **dès l'étape 2, NexBSD n'est plus « FreeBSD avec des paquets »** — il a son propre binaire de noyau, son propre userland, sa propre image. Et `pkgbase` (aperçu technologique en FreeBSD 15, destiné à devenir la norme) permet même de **gérer la base système comme des paquets signés par NexBSD**.

**Contrainte à assumer :** cette chaîne exige une machine de construction sérieuse. C'est **précisément** le « PC fort » dont vous parlez (profil L3). D'ici là, on ne peut pas produire d'image NexBSD ; on peut seulement **préparer et valider les composants**.

---

## 6. Les trois domaines d'un NexBSD « à part entière »

Pour rester à la fois ambitieux et juridiquement propre, je propose de découper NexBSD en trois domaines, avec des règles différentes. C'est le point le plus important de ce document.

```
┌──────────────────────────────────────────────────────────────────────┐
│  NEXBSD APPS — code 100 % NexBSD (licence au choix, ex. BSD-2)       │
│  coquille mobile · outil d'administration · installateur · outils    │
├──────────────────────────────────────────────────────────────────────┤
│  NEXBSD PLATFORM — paquets épinglés, testés, signés par NexBSD       │
│  Samba (GPL-3) · OpenLDAP · WebKitGTK · CUPS                         │
│  → jamais liés dans la base ; processus et paquets séparés           │
├──────────────────────────────────────────────────────────────────────┤
│  NEXBSD BASE — arbre source possédé, construit par le projet         │
│  noyau configuré pour PC faible · userland allégé · libc · rc.d      │
│  → reste sous licence BSD-2 ; aucun code GPL n'y entre jamais        │
└──────────────────────────────────────────────────────────────────────┘
```

**Pourquoi cette séparation est indispensable :**

- **Juridiquement** : la licence BSD 2-clause de la base autorise tout, mais dès qu'on y incorpore du code GPL-2 ou GPL-3, **l'ensemble devient soumis au copyleft** — NexBSD perdrait la maîtrise de sa propre base. En gardant Samba et consorts en paquets séparés, on conserve une base entièrement sous licence permissive.
- **Techniquement** : la base reste petite (budget PC faible), les composants lourds sont optionnels et désactivables.
- **Par précédent** : FreeBSD applique **exactement** cette règle dans son propre arbre — sa politique de licence exige que « les logiciels sous licences non-BSD soient soigneusement isolés dans l'arbre source afin qu'ils ne puissent pas contaminer les composants BSD » [docs.freebsd.org — FreeBSD Licensing Policy].

Autrement dit : **NexBSD fait, pour ses composants, ce que FreeBSD fait déjà pour les siens.**

---

## 7. Le prix à payer : la dette de sécurité

C'est le point que je ne peux pas vous cacher, et c'est lui qui doit guider le dimensionnement.

- Un fork assume **la responsabilité des correctifs de sécurité de toute sa base**.
- FreeBSD publie de nombreux avis : en mai 2026, une seule vague comprenait au moins sept avis (SA-26:18 à SA-26:24 : `setcred`, `ptrace`, `cap_net`, `libcasper`, `bsdinstall`, `fusefs`…), dont des élévations de privilèges locales et une RCE noyau.
- Chaque avis impose, pour un fork : lire, évaluer l'applicabilité, fusionner, reconstruire, tester, publier, documenter.

**Conséquence de conception, non négociable : le delta doit rester petit et documenté.** Plus NexBSD s'écarte, plus chaque correctif amont devient difficile à appliquer. La règle proposée :

> **Toute divergence doit être justifiée par un ADR, isolée dans un petit nombre de fichiers, et fusionnable.**

C'est la discipline qui permet à HardenedBSD d'exister à deux personnes. Sans elle, le fork meurt en dix-huit mois.

---

## 8. Ce qui doit rendre NexBSD reconnaissable (la question la plus importante)

Un fork sans identité n'est qu'un renommage. Trois axes de différenciation sont proposés, du plus réaliste au plus ambitieux :

| Axe | Contenu | Coût | Différenciation |
|---|---|---|---|
| **A. Budget PC faible garanti** | noyau et userland allégés, empreinte mesurée et publiée à chaque version (« NexBSD tient en X Mo ») | faible à moyen | **forte** — aucun BSD ne publie ce contrat |
| **B. Couche réseau « fonctions NetWare »** | identités + droits + partages + administration unique, avec un modèle de droits plus lisible que les ACL actuelles | moyen | **forte** — c'est l'ADN du projet |
| **C. Image mobile Web** | coquille petit écran + applications Web (WebKitGTK) | élevé | moyenne — dépend d'un matériel qui n'existe pas sous FreeBSD |

**Recommandation :** construire l'identité sur **A + B**. Ce sont les deux axes réalisables sans pilotes exotiques, et ce sont ceux que personne d'autre ne fait. C reste un objectif de démonstration logicielle, pas une promesse produit.

---

## 9. Chemin proposé (ce que je remplace dans le plan)

| Étape | Ce qu'on fait | Pourquoi |
|---|---|---|
| **P0 — maintenant** | Prototype « assemblage » en VM : jail + Samba + `pf`, mesures | **ne change pas de nature** : il ne produit pas le produit, il **dérisque les composants** qui entreront ensuite dans la Plateforme NexBSD |
| **P1 — PC fort disponible** | Fork : arbre propre, `src.conf`, `KERNCONF`, premier `buildworld`/`buildkernel`, image `nexbsd-lab` signée | c'est ici que NexBSD devient un système |
| **P2** | pkgbase NexBSD : base système en paquets signés par le projet | gestion de versions propre |
| **P3** | Plateforme : Samba/OpenLDAP épinglés, testés, intégrés à l'image | le « meilleur de chaque système » |
| **P4** | Delta propre : outil d'administration NexBSD, modèle de droits façon NetWare | identité |
| **P5** | Coquille mobile | démonstration |
| **P6+** | Divergences profondes, éventuellement | horizon lointain |

**Le prototype actuel n'est donc pas jeté** : il devient l'étape de validation des briques. Ce qui change, c'est son **statut** — ce n'est plus le produit, c'est la **préparation du produit**.

---

## 10. Ce que votre raisonnement « combler les trous » donne, une fois corrigé

| Votre formulation | Correction technique | Ce qu'on garde |
|---|---|---|
| « FreeBSD est open source, on peut utiliser son code » | Exact. C'est ce que fait un fork. Mais cela transfère **la responsabilité des failles** au projet. | **Fork M2** avec delta petit et fusion amont régulière |
| « KaiOS est un peu fermé, on comble avec Firefox OS » | KaiOS n'est pas « un peu » fermé : le système complet est propriétaire et **aucune image n'est constructible** (blobs OEM, RIL). Et Firefox OS ne « comble » pas les trous de KaiOS : **il n'y a pas de socle légal à compléter**. Firefox OS est mort en 2016, ses API ont disparu. | **Les idées** de KaiOS (UX clavier, petits écrans) + **le code** de Gaia (Apache-2.0) comme référence + **WebKitGTK** comme moteur réel |
| « NetWare : MARS_NWE, Samba, OpenLDAP, trouver un compromis » | MARS_NWE ne peut pas être « collé » : GPL-2 (contaminerait la base) et il **exige IPX**, retiré de FreeBSD. Mais son code et sa documentation sont une **spécification de fait** du comportement NetWare. | Le **compromis** est : Samba + OpenLDAP fournissent les **fonctions** ; NexBSD écrit **son propre** outil d'administration façon NetWare ; la compatibilité NCP/IPX devient un **projet de recherche en espace utilisateur**, pas une intégration |
| « prendre tous les bons de chaque système » | Règle qui rend cela possible : **prendre librement les idées, prendre le code seulement quand licence + architecture le permettent.** | C'est la définition même d'un bon projet de système |

---

## 11. Décisions proposées

| ID | Décision |
|---|---|
| **ADR-0011** | Modèle cible = **fork M2** (arbre possédé, images propres, delta petit et documenté) |
| **ADR-0012** | Frontière **Base / Plateforme** : aucun code GPL dans la base ; composants GPL en paquets et processus séparés |
| **ADR-0013** | Couche mobile = **code NexBSD** sur WebKitGTK ; Gaia = inspiration |
| **ADR-0014** | Compatibilité NCP/IPX = **réimplémentation propre en espace utilisateur**, statut recherche (P3), jamais du code GPL-2 copié |
| **ADR-0015** | Identité du produit = **A (budget PC faible mesuré) + B (fonctions réseau façon NetWare)** |

## 12. Questions au responsable du projet

1. **Le fork est-il assumé, avec son coût ?** (responsabilité des correctifs de sécurité, publication d'images, discipline de fusion). Si non, il faut le dire maintenant et redescendre en M1.
2. **Quel nom pour la base ?** Rappel : la marque « FreeBSD » **ne peut pas** figurer dans le nom d'un produit dérivé [Trademark Usage Terms, FreeBSD Foundation]. « NexBSD » doit donc être vérifié séparément (antériorité).
3. **Quel axe d'identité prioritaire :** A (budget PC faible), B (réseau façon NetWare), ou les deux ?
4. **Le « PC fort » est-il une hypothèse à 3 mois, 1 an, ou indéterminée ?** Le passage en M2 en dépend entièrement.

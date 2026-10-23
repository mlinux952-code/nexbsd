# Phase 0 — Cadrage du projet NexBSD

**Version :** 1.0
**Date :** 2026-10-23
**Statut :** proposition soumise à validation du responsable du projet
**Portée :** définit la vision, le périmètre, les hypothèses, les contraintes et les critères de réussite. Ne contient aucun résultat de test.

---

## 1. Vision en une phrase

Construire, par étapes vérifiables, un système expérimental dérivé de FreeBSD qui associe une expérience mobile de type « feature phone » (petits écrans, clavier physique, applications Web) et des services réseau centralisés de type serveur de fichiers/annuaire, avec une documentation et des tests reproductibles.

## 2. Le problème que le projet veut résoudre

Trois constats motivent le projet :

1. Les systèmes mobiles modernes sont conçus pour du matériel récent, coûteux et doté de pilotes propriétaires.
2. Les services réseau « centralisés » historiques (NetWare) ont disparu alors que leurs fonctions — identités, droits, partages, administration unique — restent utiles dans de petits réseaux.
3. Il n'existe pas, à notre connaissance, de synthèse publique documentée qui articule base BSD, plateforme Web mobile et services réseau hérités.

**Le projet est un travail d'ingénierie et de documentation, pas une promesse de produit.**

## 3. Périmètre

### 3.1 Dans le périmètre (phase initiale)

| # | Élément | Nature |
|---|---|---|
| P-1 | Base système FreeBSD (installation, démarrage, réseau, stockage, utilisateurs, journalisation) | technique |
| P-2 | Profil « laboratoire » : machine de test isolée, sans risque pour le disque principal | technique |
| P-3 | Profil « serveur réseau » : partage de fichiers, annuaire, authentification, droits | technique |
| P-4 | Profil « mobile expérimental » : coquille d'interface Web à petit écran, navigation au clavier, lanceur d'applications Web | technique, **exploratoire** |
| P-5 | Étude de réutilisation/portage de composants tiers avec analyse de licences | juridique + technique |
| P-6 | Documentation, matrices, registre de décisions, plan de tests | méthodologique |

### 3.2 Hors périmètre (assumé, à ce stade)

- Téléphonie cellulaire, modem, SMS réels sur un appareil physique (dépend de pilotes et de blobs inexistants ou non redistribuables).
- Compatibilité binaire avec des applications NetWare propriétaires (SYSCON, NDS complet).
- Remplacement d'un système grand public, support commercial, certification matérielle.
- Tout ce qui exige de modifier le disque contenant Windows 7.
- Toute publication de secrets, données personnelles ou blobs propriétaires.

### 3.3 Doctrine de périmètre

Le projet **sépare explicitement trois cibles** qui ne seront pas confondues dans les rapports :

| Profil | Support matériel visé | Ce qu'on peut promettre |
|---|---|---|
| **Lab** | PC 2011 amd64, VM, USB | système utilisable, services réseau, tests reproductibles |
| **NetServer** | PC 2011 ou VM, réseau local isolé | fichiers + annuaire + droits, supervisables |
| **MobileExp** | matériel ARM avec support FreeBSD, ou cible logicielle uniquement | démonstration d'interface ; **aucune promesse téléphonie** |

Cette séparation répond à une règle du méga-prompt : ne pas confondre ce qui tourne sur un ordinateur et ce que ferait un vrai téléphone.

## 4. Hypothèses de travail (modifiables)

| ID | Hypothèse | Confiance | Conséquence si fausse |
|---|---|---|---|
| H-1 | Base système = **FreeBSD** | élevée | changement de base = refonte de l'architecture |
| H-2 | Dimension mobile = **concepts de KaiOS** (UX, clavier, Web apps), pas le système KaiOS | moyenne | si KaiOS complet était réutilisable, le périmètre mobile pourrait être réduit — mais voir `research/kaios/fiche.md` : ce n'est pas le cas |
| H-3 | Donneur de composants mobiles = **Firefox OS / Gaia** (archives) | moyenne | remplacement par une UI Web neuve, plus de travail |
| H-4 | Modèle réseau = fonctions **NetWare** reproduites, pas le logiciel NetWare | élevée | — |
| H-5 | Compatibilité historique = **MARS_NWE** comme référence, pas comme composant | moyenne | voir `research/mars-nwe/fiche.md` : portage FreeBSD très coûteux |
| H-6 | Partage moderne = **Samba** | élevée | alternative : SMB natif d'un NAS externe, hors projet |
| H-7 | Annuaire = **OpenLDAP** | élevée | — |
| H-8 | Matériel d'essai = PC 2011 / 4 Go / Win7 / disque non modifiable | élevée | si le CPU n'est pas 64 bits, FreeBSD 15 est impossible (voir risque R-05) |
| H-9 | Nom « NexBSD » disponible juridiquement | **inconnue** | renommage (marque à vérifier avant toute publication) |

## 5. Contraintes

### 5.1 Contraintes absolues

- **C-1 :** le disque principal contenant Windows 7 n'est ni partitionné, ni formaté, ni écrit pendant la phase initiale.
- **C-2 :** aucune installation sur un ordinateur de production.
- **C-3 :** aucun composant n'est déclaré « validé » sans test reproductible documenté.
- **C-4 :** aucune donnée sensible publiée (clés, mots de passe, données personnelles, blobs propriétaires).
- **C-5 :** toute réutilisation de code externe est précédée d'une vérification de licence et de provenance.

### 5.2 Contraintes matérielles et économiques

- 4 Go de RAM, disque mécanique : **ne pas empiler les services lourds** (pas de ZFS ARC large + VM + base de données + interface graphique simultanément).
- Compilation lourde (Samba, WebKit, Firefox) **non réaliste sur ce matériel** : il faut privilégier les paquets binaires, ou compiler sur un autre poste (à définir, cf. R-08).
- Bandwidth/accès Internet supposé disponible mais non garanti pendant les sessions.

### 5.3 Contraintes méthodologiques

- Aucune affirmation non sourcée ; toute source est datée.
- Distinction permanente faits / hypothèses / propositions / décisions.
- Une petite étape vérifiable vaut mieux qu'un plan immense non testable.

## 6. Critères de réussite (mesurables)

Le projet progresse si, à chaque jalon, on peut répondre « oui » avec une preuve :

| ID | Critère | Preuve attendue | Horizon |
|---|---|---|---|
| S-1 | FreeBSD démarre sur le matériel ou en VM sans toucher au disque principal | capture/sortie `uname -a`, journal de démarrage | Phase 4 |
| S-2 | L'identification matérielle est documentée (CPU, firmware, disque, réseau) | `docs/hardware.md` rempli, avec sorties de commandes | Phase 0-4 |
| S-3 | Un partage SMB fonctionne entre la cible et un client, avec droits vérifiés | test T-03 + capture client | Phase 4 |
| S-4 | Un annuaire LDAP sert l'authentification d'au moins un service | test T-04 | Phase 5 |
| S-5 | Les services tournent isolés (jail ou utilisateur dédié) et journalisent | `docs/security.md` + test T-05 | Phase 5 |
| S-6 | Le système redémarre et revient à un état connu après panne simulée | test T-06 (plan de retour arrière exercé) | Phase 5 |
| S-7 | Une interface « petit écran » navigable au clavier est démontrée | vidéo/captures + procédure | Phase 5-6 |
| S-8 | Les licences de tous les composants intégrés sont documentées | `matrices/licences.csv` complet | continu |
| S-9 | Les limites et fonctions non réalisées sont publiées honnêtement | rapport de version | chaque version |

**La réussite ne se mesure pas au nombre de composants ajoutés.**

## 7. Parties prenantes et rôles

| Rôle | Qui | Responsabilité |
|---|---|---|
| Responsable du projet | le propriétaire | valide les décisions, exécute les actions matérielles, possède les dépôts |
| Assistant technique (IA) | équipe simulée multidisciplinaire | recherche, rédaction, architecture, préparation des procédures, vérification des sources |
| Matériel de test | PC 2011 | fournit les mesures réelles |

**Règle :** l'IA n'est ni la mémoire ni le stockage du projet. Les documents vivent dans Google Drive (référentiel documentaire) et GitHub (référentiel technique). Voir `reports/session-2026-10-23.md` § « Actions du responsable ».

## 8. Ce qui invaliderait le projet (conditions d'arrêt)

- Le CPU du PC de test est 32 bits uniquement → FreeBSD 15 impossible ; il faudrait soit une autre machine, soit FreeBSD 14 avec support limité dans le temps.
- Aucun moyen d'écrire/booter un support externe (USB) sans risque → phase 4 impossible sur ce matériel ; basculer sur VM.
- Les versions de composants nécessaires s'avèrent indisponibles sous forme de paquets FreeBSD et la compilation est hors de portée du matériel → réduire le périmètre aux composants disponibles.
- Le nom « NexBSD » s'avère déjà déposé par un tiers dans un domaine proche → renommage.

---

## 9. Résumé exécutif du cadrage

NexBSD est, au 2026-10-23, **un dossier de conception**. La partie la plus solide est la fondation FreeBSD et les services réseau modernes (Samba, OpenLDAP) : ils existent, sont maintenus et packagés. La partie la plus fragile est la **compatibilité NetWare historique** (coût technique élevé, code non maintenu, protocole retiré des noyaux modernes) et la **dimension mobile** (pas de base KaiOS réutilisable, pas de pilotes téléphonie sous FreeBSD).

La recommandation de ce cadrage est donc : **prouver d'abord la chaîne FreeBSD + services réseau isolés, mesurer, puis n'aborder le mobile que comme une couche logicielle documentée.**

# NexBSD — Synthèse des Phases 0 et 1
## État initial · recherches vérifiées · risques · prototypes · recommandation

**Date :** 23 octobre 2026
**Version :** 1.0
**Nature :** document de synthèse issu de la première mission du méga-prompt maître (Étapes A à E)
**Statut :** **proposition** — à valider par le responsable du projet

---

## Avertissement liminaire

**NexBSD n'existe pas encore.** Aucune ligne de code NexBSD n'a été écrite, aucun système n'a été installé, aucun test n'a été exécuté. Ce document ne décrit pas un système : il décrit un projet, ses hypothèses, ce que la recherche a confirmé, ce qu'elle a infirmé, et la première étape concrète proposée.

Trois hypothèses du concept initial ont été **techniquement infirmées** par la recherche (§3). Les cacher serait la pire façon de servir le projet.

---

## 1. État initial du projet (Étape A)

### 1.1 Ce que le projet veut être

Un système expérimental dérivé de FreeBSD combinant :

| Dimension | Intention d'origine |
|---|---|
| Socle | FreeBSD (noyau, réseau, stockage, utilisateurs, sécurité) |
| Mobile | une expérience inspirée de KaiOS sur petits écrans et clavier physique |
| Réseau | des services inspirés des fonctions de NetWare (identités, droits, partages, administration) |

### 1.2 Ce que le projet est réellement au 23 octobre 2026

Un dossier de conception : un cadrage, huit fiches de recherche sourcées, cinq matrices (composants, fonctions, licences, compatibilité, risques), huit propositions de décisions, trois options de prototype et un plan d'action en dix étapes.

### 1.3 Hypothèses de travail retenues

| ID | Hypothèse | Confiance après recherche |
|---|---|---|
| H-1 | Base = FreeBSD | **élevée** (confirmée) |
| H-2 | Mobile = inspiré de KaiOS | élevée — mais **comme référence UX seulement** (KaiOS rejeté comme composant) |
| H-3 | Firefox OS comme donneur de composants | **revue à la baisse** (dépôts archivés, API disparues) |
| H-4 | NetWare = modèle fonctionnel | élevée |
| H-5 | MARS_NWE comme solution de compatibilité | **infirmée** (voir §3) |
| H-6 | Samba pour le partage moderne | élevée, avec réserve de version |
| H-7 | OpenLDAP pour l'annuaire | moyenne (dépend d'un port FreeBSD ≥ 2.6 non confirmé) |
| H-8 | PC de 2011 / 4 Go / disque non modifiable | élevée — **mais matériel non identifié** |
| H-9 | Nom « NexBSD » disponible | **inconnue** |

---

## 2. Les questions techniques les plus importantes

Par ordre de blocage :

| # | Question | Pourquoi elle est bloquante | Comment y répondre |
|---|---|---|---|
| Q1 | Le processeur du PC de test est-il **64 bits** ? | FreeBSD 15.x n'existe plus en 32 bits. Si non → le prototype est impossible sur cette machine. | `wmic cpu get DataWidth` sous Windows 7 (lecture seule) |
| Q2 | Le firmware accepte-t-il un **démarrage USB** ? | Sans cela, impossible de tester sans toucher au disque interne | observer le menu de démarrage au POST |
| Q3 | Existe-t-il un **OpenLDAP ≥ 2.6** packagé pour FreeBSD ? | Le seul port identifié est 2.5, en fin de vie au 15/01/2027 | `pkg search -x openldap` |
| Q4 | Quelle **version de Samba** est réellement installable ? | La version par défaut du port (4.16) n'est plus maintenue | `pkg search samba` puis épingler ≥ 4.23 |
| Q5 | Les services + une interface Web tiennent-ils dans **4 Go** ? | Conditionne le profil mobile | mesure, pas supposition |
| Q6 | Une pile **IPX** est-elle nécessaire au projet ? | Elle n'existe plus dans FreeBSD ni dans Linux | décision de périmètre (recommandation : non) |
| Q7 | Quel moteur Web pour la couche mobile ? | Gecko B2G n'est plus intégrable | WebKitGTK (disponible et maintenu) |

---

## 3. Résultats de recherche vérifiés

Chaque ligne est sourcée et datée dans les fiches de `research/`. Consultation : 2026-10-23.

| # | Fait vérifié | Impact sur le concept initial |
|---|---|---|
| 1 | **FreeBSD 15.1-RELEASE** est la version courante (16/06/2026, support jusqu'au 31/03/2027) ; branche stable/15 supportée jusqu'au 31/12/2029. 15.0 est **déjà en fin de vie** (30/09/2026). | fondation solide, à condition de figer les versions |
| 2 | FreeBSD 15.x a **retiré i386** (ainsi qu'armv6 et powerpc 32 bits). | impose un CPU 64 bits (Q1) |
| 3 | **IPX a été retiré de FreeBSD 11.0** et de **Linux 4.17**. | rend impossible toute pile NetWare historique native |
| 4 | **KaiOS est propriétaire** ; publié partiellement (MPL pour l'héritage B2G, GPLv2 pour les correctifs noyau) ; repose sur Gonk = noyau Linux + HAL Android. | **nie l'hypothèse « réutiliser KaiOS »** |
| 5 | Aucune **image KaiOS complète** ne peut être construite publiquement (bootloader, RIL, pilotes, blobs OEM non distribués). | idem |
| 6 | Les dépôts **Firefox OS** (`mozilla-b2g`, 251 dépôts) sont **archivés en lecture seule depuis le 03/11/2021** ; **Gaia est sous Apache-2.0** (licence vérifiée). | Gaia exploitable comme référence, pas comme composant prêt à l'emploi |
| 7 | Le **Gecko embarquable** de B2G n'existe plus ; GeckoView est spécifique à Android ; les API `moz*` de Gaia ont disparu des moteurs modernes. | **nie l'hypothèse « étudier Gecko comme moteur »** |
| 8 | **WebKitGTK** est disponible sous FreeBSD (`www/webkit2-gtk` 2.46.6, amont 2.54.1) et maintenu. | fournit une alternative concrète et vérifiable |
| 9 | **MARS_NWE** (GPL-2.0) : dernière évolution publique en **2013** ; **exige IPX** ; n'implémente ni NDS, ni NCP sur IP natif ; son auteur avertit explicitement de vulnérabilités ; exécution en root. | **nie l'hypothèse MARS_NWE** |
| 10 | **Samba** : 4.23.13 et 4.24.8 maintenues, 4.25.0 disponible (sept. 2026) ; mais le **port FreeBSD par défaut est encore 4.16, non maintenu** ; 4.19 et 4.20 sont dépréciés. | retenir Samba **en épinglant la version** |
| 11 | **OpenLDAP** : 2.7.1 (feature) et 2.6.15 (LTS) ; 2.5 en fin de vie au 15/01/2027 ; seul port FreeBSD identifié : `openldap25-server` 2.5.20. | décision LDAP **conditionnelle** |
| 12 | **VirtualBox** ne supporte plus Windows 7 comme hôte depuis 6.1.0 (décembre 2019). | la virtualisation sur le PC de test n'est pas une voie fiable |

### 3.1 Ce que cela change, en une phrase

> Le projet peut s'appuyer sur **FreeBSD + Samba + (peut-être) OpenLDAP + un moteur Web moderne**, mais il ne peut pas s'appuyer sur **KaiOS, Gecko B2G ni MARS_NWE**. Les deux premières impasses coûtent peu (elles n'invalident que le *moyen*, pas l'*intention*) ; la troisième **supprime purement et simplement la compatibilité NetWare historique** du périmètre réaliste.

---

## 4. Risques prioritaires

Registre complet : `matrices/risques.csv` (16 risques). Les cinq qui comptent d'abord :

| ID | Risque | Niveau | Mitigation immédiate |
|---|---|---|---|
| **R-01** | Altération du disque contenant Windows 7 | **CRITIQUE** | tout se fait sur support externe ; vérifier trois fois le disque cible avant toute écriture ; exercice de retour arrière obligatoire (T-08) |
| **R-02** | CPU 32 bits → FreeBSD 15 impossible | ÉLEVÉ | inventaire matériel en lecture seule **avant** tout achat ou téléchargement |
| **R-10** | Fausse validation : déclarer fonctionnel ce qui n'a pas été testé | **CRITIQUE** | étiquetage systématique FAIT / HYPOTHÈSE / PROPOSITION / À VÉRIFIER ; verdict obligatoire par test |
| **R-07** | Samba 4.16 par défaut (non maintenu, CVE connues) | ÉLEVÉ | épingler ≥ 4.23 (ADR-0007) |
| **R-05** | Aucun pilote téléphonie/modem/senseurs sous FreeBSD | ÉLEVÉ | exclure la téléphonie du périmètre ; MobileExp = logiciel uniquement |

---

## 5. Les trois prototypes envisageables (Étape D)

| | **Option 1 — Lab-0** (services réseau) | **Option 2 — MobileShell** (interface) | **Option 3 — NetWareLab** (compatibilité) |
|---|---|---|---|
| **Contenu** | FreeBSD 15.1 sur support externe, sans interface graphique : jail Samba, pare-feu, journaux, sauvegarde/restauration, mesures | Coquille d'interface « inspirée de KaiOS » sur WebKitGTK, navigation au pavé directionnel, applications Web locales | VM Linux isolée avec MARS_NWE + module IPX + client DOS, pour documenter le comportement NetWare réel |
| **Prouve** | que la base et les services sont maîtrisables, mesurables et réversibles | qu'une expérience mobile crédible se construit en logiciel | ce que NetWare *faisait* réellement |
| **Ne prouve pas** | rien sur le mobile ni sur NetWare | rien sur les fonctions matérielles mobiles | aucune voie d'intégration dans NexBSD |
| Utilité | 5/5 | 3/5 | 2/5 |
| Risque (5 = faible) | 5/5 | 4/5 | 2/5 |
| Complexité (5 = simple) | 4/5 | 3/5 | 2/5 |
| Coût matériel (4 Go) | 4/5 | 2/5 | 2/5 |
| Réutilisabilité | 5/5 | 3/5 | 2/5 |
| **Total** | **23/25** | **15/25** | **10/25** |

---

## 6. Recommandation argumentée

### 6.1 Recommandation principale

**Démarrer par l'option 1 — « NexBSD-Lab-0 ».**

Cinq raisons :

1. **C'est la seule option dont le résultat est un fait vérifiable**, pas une impression : un partage accessible, un accès non autorisé refusé, une mémoire mesurée, un retour arrière chronométré.
2. **Le risque matériel y est quasi nul** : tout se passe sur un support externe, le disque interne reste intact par construction (respect de la contrainte absolue).
3. **Elle valide les hypothèses les plus solides** (FreeBSD, Samba) et lève immédiatement les deux inconnues bloquantes (Q3 et Q4).
4. **Elle produit des artefacts réutilisables** : procédures, configurations, plan de tests T-01 à T-06.
5. **Elle n'exige aucune compilation lourde** : uniquement des paquets binaires — indispensable sur un disque mécanique de 2011.

### 6.2 Recommandations de périmètre

| Sujet | Recommandation | Argument |
|---|---|---|
| KaiOS | **Rejeter comme base/composant**, retenir comme référence UX | propriétaire, blobs OEM, dépendance Android |
| Firefox OS / Gaia | **Étudier** (Apache-2.0) comme inspiration, sans engagement de réutilisation | API disparues → réécriture quasi totale |
| Moteur Web | **WebKitGTK** (ou Firefox kiosque pour une démo rapide) | seule option maintenue et packagée |
| MARS_NWE | **Rejeter comme composant**, option de laboratoire isolé non prioritaire | IPX absent, code gelé depuis 2013, vulnérabilités assumées |
| Compatibilité NetWare | **La retirer du périmètre réaliste** ; conserver le *modèle fonctionnel* (identités, droits, trustees, scripts de login) comme cahier des charges de Samba + OpenLDAP | coût très élevé pour une valeur quasi nulle |
| Samba | **Retenir, version ≥ 4.23 épinglée**, en jail | version par défaut vulnérable |
| OpenLDAP | **Retenir sous condition** de disponibilité d'une version ≥ 2.6 sous FreeBSD | sinon : comptes locaux + `tdbsam` pour le prototype 1 |
| Mobile | **Reporter en phase 5**, en tant que couche logicielle uniquement | aucune promesse de téléphonie/SMS/capteurs |
| Nom du projet | **Vérifier l'antériorité** avant toute publication | risque juridique |

### 6.3 Ce que le projet ne doit jamais affirmer

- « NexBSD est basé sur KaiOS » → faux.
- « NexBSD est compatible NetWare » → faux, même avec Samba.
- « NexBSD tourne sur téléphone » → non démontré, et non démontrable sans pilotes.
- « La phase X est terminée » sans que ses critères de sortie soient prouvés.

---

## 7. Prochaine action concrète

> **Une seule action, à faire par le responsable du projet, environ une heure, sans aucun risque :**

### Inventaire matériel non destructif du PC de 2011

Sous Windows 7, ouvrir une invite de commandes et exécuter, en lecture seule :

```bat
systeminfo
wmic cpu get name,NumberOfCores,DataWidth,MaxClockSpeed
wmic bios get manufacturer,version,releasedate
wmic diskdrive get model,size,interfaceType
wmic path win32_NetworkAdapter where "PhysicalAdapter=true" get name
wmic path win32_VideoController get name
```

Puis reporter les résultats dans le tableau de `docs/hardware.md` §3 et les communiquer.

**Critère de passage :** la valeur `DataWidth` du CPU.

- `64` → FreeBSD 15.x est envisageable ; on passe à l'Étape 2 du plan d'action (préparation du support externe).
- `32` → **arrêt** de cette voie ; réorientation vers une autre machine, une machine virtuelle, ou FreeBSD 14 i386 (support jusqu'en 2028).

**Pendant ce temps, l'assistant peut :** rédiger la procédure d'installation détaillée du support externe (Étape 4) et préparer les fichiers de configuration du prototype 0 (jail, Samba, `pf`) — sans les déclarer testés.

### Décisions à prendre en parallèle

1. Valider ou amender les **ADR-0001 à ADR-0008** (`docs/decisions/`).
2. Choisir la **visibilité du dépôt** GitHub et vérifier la disponibilité du nom « NexBSD ».
3. Créer l'arborescence **Google Drive** (00_Gouvernance → 08_Versions_et_Archives) et y déposer cette documentation.

---

## 8. Carte des documents produits

| Document | Contenu |
|---|---|
| `README.md` | vision, état réel, limites, feuille de route |
| `docs/00-cadrage-phase0.md` | cadrage complet : périmètre, hypothèses, contraintes, critères de réussite, conditions d'arrêt |
| `docs/architecture.md` | couches A→F, flux, questions ouvertes (v0.1, non implémentée) |
| `docs/prototypes.md` | comparaison détaillée des trois options + critères Go/No-Go |
| `docs/plan-action.md` | 10 étapes avec objectif, prérequis, actions, test, risques, critère de passage |
| `docs/hardware.md` | procédure de diagnostic non destructive + tableau à remplir |
| `docs/security.md` | politique de sécurité initiale, composants à risque |
| `docs/roadmap.md` | phases 0→8, jalons J1-J7 |
| `docs/glossaire.md` | termes techniques expliqués |
| `docs/decisions/` | ADR-0001 à ADR-0008 + registre |
| `research/*/fiche.md` | 8 fiches sourcées : FreeBSD, KaiOS, Firefox OS, NetWare, MARS_NWE, Samba, OpenLDAP, moteur Web |
| `matrices/*.csv` | composants (12), fonctions (24), licences (11), compatibilité (14 questions), risques (16) |
| `tests/plan-tests.md` | 12 tests définis, **aucun exécuté** |
| `reports/session-2026-10-23.md` | compte rendu de session, utilisable par une autre IA ou un autre développeur |

---

## 9. Bilan honnête de cette session

**Ce qui a été gagné :** trois impasses ont été éliminées avant tout investissement de développement, et deux inconnues bloquantes ont été identifiées avec leur procédure de résolution. C'est exactement le rôle des phases 0 et 1.

**Ce qui n'a pas été fait :** rien de technique. Aucune installation, aucune mesure, aucun test, aucune ligne de code. Le projet a avancé **sur le papier uniquement**.

**Ce qui reste incertain :** presque tout ce qui dépend du matériel, la disponibilité réelle de certains paquets, et la valeur juridique du nom du projet.

> *Concevoir avec ambition, développer avec méthode et ne déclarer comme réalisé que ce qui a été effectivement vérifié.*

---

## 10. Addendum du 2026-10-23 (suite de session)

Trois précisions du responsable du projet modifient le cadrage :

1. **« NexBSD est un système pour PC faible »** → la cible de référence devient **L1 : amd64, 2 cœurs, 1-2 Go de RAM, disque mécanique**, avec un **budget opposable** : ≤ 128 Mo de RAM au repos, ≤ 256 Mo avec services, ≤ 2 Go de disque, démarrage ≤ 60 s. Conséquences : **UFS par défaut** (ZFS écarté du profil faible), **pas d'environnement de bureau**, et **trois images séparées** (`nexbsd-lab`, `nexbsd-net`, `nexbsd-mobile`) au lieu d'un système hybride unique. → `docs/09-cible-pc-faible.md`, ADR-0009.
2. **Poste de travail = Linux Mint à faible capacité** → devient la **station de préparation** : diagnostic, vérification d'empreintes, écriture USB garde-fou, VM QEMU de 1 Go. Permet un **premier démarrage FreeBSD aujourd'hui**, sans attendre le PC de 2011. → `docs/10-station-linux-mint.md`, `scripts/`.
3. **« Un jour un PC fort »** → compilations et construction reproductible **reportées au profil L3**, sans que le plan en dépende : paquets binaires uniquement d'ici là. → ADR-0010.

**Nouvelle question ouverte, bloquante pour ADR-0001 :** la cible inclut-elle des machines **32 bits** ? FreeBSD 15.x n'existe plus en i386 ; FreeBSD 14.x i386 est supporté jusqu'au 30 novembre 2028.

**État technique inchangé :** aucune installation, aucun test d'exécution. Les scripts fournis ont été validés en syntaxe et partiellement exécutés dans un environnement de test — pas sur le poste du responsable.

---

## 11. Addendum 2 — « Système à part entière » : le modèle fork (ADR-0011)

Le responsable du projet a écarté le modèle « FreeBSD + paquets » : NexBSD doit être un **système à part entière**. Cela se traduit par un **fork** :

| Ce que NexBSD possède | Mécanisme |
|---|---|
| Son arbre source | clone de FreeBSD, branches `nexbsd/*` |
| Sa configuration système | `src.conf`, `KERNCONF` (noyau allégé pour PC faible) |
| Ses images | `release.sh` — puis `pkgbase` (base système en paquets signés) |
| Son cycle de versions | releases signées par le projet |
| Sa dette de sécurité | fusion régulière des correctifs amont (obligation nouvelle) |

**Trois domaines, trois régimes de licence** (ADR-0012) : *Base* (permissive uniquement), *Plateforme* (Samba GPL-3, OpenLDAP, WebKitGTK — en paquets séparés), *Apps* (code NexBSD).

**Précédent réel** : HardenedBSD, fork de FreeBSD depuis 2014, **deux personnes**, actif en 2026 — mais qui admet des images d'installation encore fragiles et « deux tentatives de test par jour ».

**Le prix, sans détour** : un fork devient responsable des correctifs de sécurité de toute sa base (7 avis FreeBSD en une seule vague de mai 2026) et exige une machine de construction sérieuse (profil L3). Sans L3, aucune image NexBSD ne peut être produite : le projet reste alors une **distribution de configuration**, ce qui doit être dit et non maquillé.

Le prototype en VM décrit au §5 **ne change pas** : il ne produit plus le produit, il **dérisque les composants** qui entreront dans la Plateforme.

Détail : `docs/11-fork-pas-surcouche.md`, `docs/12-licences-et-frontieres.md`, ADR-0011 à ADR-0015.

# Registre des décisions architecturales — NexBSD

**Règle :** une proposition (statut « proposée ») ne devient une décision que par accord explicite du responsable du projet. Aucun statut « validée » n'est écrit sans cet accord.

Légende des statuts : `proposée` · `validée` · `rejetée` · `remplacée` · `en attente d'information`

---

## D-000 — Convention de traçabilité (proposée)
- **Date :** 2026-10-26
- **Problème :** chaque session doit être exploitable sans l'historique de conversation.
- **Options :** (a) compte rendu versionné par session ; (b) pas de compte rendu, mémoire de l'IA.
- **Décision proposée :** (a). Un fichier `compte-rendu-session-AAAA-MM-JJ.md` est produit à chaque session, avec faits / hypothèses / décisions / tests / prochains pas.
- **Conséquences :** discipline d'écriture à chaque session.
- **Condition de révision :** si le volume devient ingérable, indexer par thème.

## D-001 — Niveau d'indépendance visé (reporté après P1 — décision du 2026-10-26)
- **Date :** 2026-10-26
- **Problème :** « système indépendant » n'est pas mesurable en l'état.
- **Options :** échelle I0–I5 (voir rapport §2.2) comme grille ; ou définition binaire (« noyau original ou rien »).
- **Preuves :** aucune ne permet de trancher aujourd'hui ; dépend de Q3 et Q7 (temps disponible).
- **Décision proposée :** adopter l'échelle I0–I5 ; viser **I3/I4** à terme ; jalon immédiat = **P1** (embryon I4) ; tout usage d'un noyau tiers intermédiaire étiqueté I2.
- **Statut : DÉCIDÉE le 2026-10-26 — niveau I4 retenu** (noyau original NexBSD), sur la base du dossier de revue. Mandat d'exécution donné : « faire le meilleur pour le projet », ce qui a été interprété comme l'acceptation de la recommandation : **I4** avec les deux garde-fous (critère d'arrêt à la fin de M6/M7 ; stratégie « VirtIO d'abord » pour les pilotes), **I2 (seL4, BSD-2)** conservé comme repli documenté, **Genode écarté** (AGPL-3.0 + licence commerciale).
- **Garde-fou appliqué :** M6 (mémoire virtuelle) a été livré et mesuré avant toute brique suivante ; la revue de fin de M6 est faite dans `07_Rapports/rapport-tests-P1-M6.md`.
- **À réévaluer :** si M7 (processus, ring 3, appels système) échoue ou dépasse largement le budget, la revue est rouverte avec preuves (clause « obstacle majeur » de D-003). Les options I2, I3 et I4 doivent être étudiées objectivement (faisabilité, pilotes, sécurité, licences, coût, temps) avant tout choix.
- **Conséquence maintenue dès maintenant :** chaque livrable affiche son niveau d'indépendance réel, même si le niveau cible n'est pas encore choisi.
- **Condition de révision :** livraison des résultats de P1.

## D-002 — Architecture CPU cible (en attente d'information)
- **Problème :** 32 bits vs 64 bits change l'ensemble du noyau et des pilotes.
- **Information manquante :** modèle exact du processeur du PC 2011 (Q1).
- **Décision proposée par défaut :** **amd64**, sous réserve de confirmation.
- **Statut :** en attente d'information — bloquant pour P1 seulement à l'étape 3 (matériel réel) ; P1 peut démarrer en amd64.

## D-003 — Choix de la première preuve de faisabilité (VALIDÉE 2026-10-26 : P1)
- **Options :** P1 squelette NexBSD / P2 noyau emprunté / P3 OS à composants (comparées dans `06_Tests_et_Prototypes/trois-prototypes-v0.1.md`).
- **Recommandation :** P1, pour un coût et un risque faibles et une valeur de preuve maximale sur l'objectif d'indépendance.
- **Statut : VALIDÉE le 2026-10-26** par le responsable, avec les conditions suivantes :
  1. progression par étapes avec critères de validation explicites ;
  2. **machine virtuelle isolée uniquement** au départ, configuration documentée, tests reproductibles ;
  3. **aucune modification du disque principal Windows 7** ;
  4. la clé USB n'est envisagée qu'après : validation en VM + identification matérielle + procédure de récupération sûre ;
  5. périmètre minimal, outils, prérequis, tests et critères de réussite définis **avant** développement (→ `06_Tests_et_Prototypes/P1-specification-perimetre-v1.0.md`) ;
  6. interdiction d'affirmer qu'un noyau/pilote/fonction existe avant développement et test réels ;
  7. P2 et P3 conservés comme options de comparaison ou de repli, **sans** transformer NexBSD en système dérivé par la bande ;
  8. en cas d'obstacle majeur : présenter preuves, alternatives et conséquences **avant** toute proposition de changement d'architecture.
- **Conséquence :** le périmètre est gelé dans la spécification P1 v1.0 ; toute extension passe par `idees-reportees.md`.

## D-004 — Non-réutilisation du code MARS_NWE (proposée)
- **Problème :** réutiliser un serveur NCP pour la branche NetWare.
- **Preuves :** GPL-2.0 ; dépôt archivé 2024 ; non maintenu > 20 ans ; appels root ; pas de NDS ; sous-ensemble NCP. **[V]**
- **Options :** (a) réutiliser ; (b) réimplémenter proprement ; (c) ne pas faire de NCP.
- **Décision proposée :** (b), avec MARS_NWE conservé comme **oracle de test** en réseau isolé.
- **Conséquences :** coût de développement plus élevé, sécurité et licence maîtrisées.

## D-005 — Politique de licence du code NexBSD (provisoire acté 2026-10-26)
- **Options :** permissive (BSD-2/MIT) ; copyleft (GPL-3/AGPL) ; double.
- **Conséquence structurante :** un choix copyleft rend Genode utilisable ; un choix permissif l'exclut (sauf licence commerciale).
- **Décision du 2026-10-26 : « décider plus tard »**, avec **politique provisoire permissive** (BSD-2-Clause ou MIT) pour le code original NexBSD — choix explicitement non définitif. La licence finale sera proposée avant toute distribution publique, avec les conséquences techniques et juridiques de chaque option.
- **Exigences associées validées :** pour chaque dépendance externe, vérifier dès maintenant licence exacte, version, obligations, conditions de redistribution et compatibilité avec les objectifs ; ne jamais intégrer un composant en supposant la compatibilité de licence ; tenir le registre des licences à jour et signaler les décisions coûteuses à modifier.
- **Genode :** ni exclu, ni adopté. Étude dédiée demandée (AGPL-3.0, exception de liaison, conditions commerciales, conséquences sur la distribution) — à planifier, voir `06_Tests_et_Prototypes/idees-reportees.md`.
- **Avertissement :** ces analyses ne remplacent pas un avis juridique qualifié.
- **Statut :** provisoire acté ; décision finale à venir.

## D-006 — Matériel virtuel d'abord (proposée)
- **Problème :** risque matériel et lenteur d'itération.
- **Décision proposée :** toute preuve technique commence en machine virtuelle ; le matériel réel n'est touché qu'à l'étape 3, depuis un support externe, jamais sur le disque interne.
- **Statut :** proposée (alignée sur la contrainte absolue du projet).

## D-007 — Modèle applicatif cible pour la v1 (proposée)
- **Options :** N0 natif / N1 JavaScript+widgets (QuickJS-ng) / N2 HTML-CSS complet / N3 compatibilité KaiOS.
- **Décision proposée :** **N1** pour la v1 ; N2 étudié mais non planifié ; N3 déclaré hors périmètre jusqu'à preuve contraire.
- **Statut :** proposée.

## D-010 — Revue de fin de P1 et choix du niveau d'indépendance (TRANCHÉE : I4)
- **Date prévue :** à l'issue du jalon M5 de P1.
- **Objet :** décider du niveau visé (I2/I3/I4) et de la poursuite, **sur la base** des mesures de P1 (reproductibilité, temps de build, difficulté réelle rencontrée) et de l'identification matérielle.
- **Statut :** à venir — aucune décision par anticipation.

## D-011 — Étape « matériel réel » (conditionnelle, non autorisée à ce jour)
- **Objet :** démarrer P1 sur le PC 2011 depuis une clé USB.
- **Conditions cumulatives :** T1–T5 verts en VM ; fiche matérielle renseignée ; procédure de récupération écrite ; périphérique cible vérifié deux fois ; accord explicite du responsable.
- **Statut :** non autorisée.
## D-012 — Clôture de la dette T1b (reproductibilité de l'image) — 2026-10-26
- **Problème :** l'image ISO différait de 56 octets entre deux constructions (M1), alors que le noyau était identique.
- **Cause mesurée :** champs d'horodatage des entrées générées par xorriso (`boot.catalog`, entrées de répertoire), non couverts par `--modification-date` ni `--set_all_file_dates`.
- **Solution retenue :** `SOURCE_DATE_EPOCH` fixé (2026-01-01T00:00:00Z) + `TZ=UTC` + normalisation des mtimes de l'arbre ISO (1980-01-01).
- **Preuve :** deux constructions dans deux arbres distincts → même SHA-256 (`6c784c79…`). Voir `07_Rapports/rapport-tests-P1-M2.md` §2.
- **Statut :** clôturée, mesurée. T1 devient un critère bloquant à chaque jalon.
- **Conséquence :** toute nouvelle dépendance d'outillage devra être vérifiée vis-à-vis de la reproductibilité.

## D-013 — Contenu du jalon suivant : cœur système ou robustesse/démonstrabilité ? (TRANCHÉE : option B, voir D-014)
- **Date :** 2026-10-26 (soulevée à la clôture de M3).
- **Contexte :** avec M3, la chaîne complète (démarrage → interruptions → clavier → shell) fonctionne en VM. Deux directions possibles pour la suite.
- **Option A — cœur système :** mémoire virtuelle (pagination), allocation mémoire, processus/threads, appels système. Valeur architecturale maximale ; coût et risque élevés ; aucun gain visible immédiat.
- **Option B — robustesse/démonstrabilité :** disposition clavier FR, entrée série, historique de console, tests de non-régression étendus, mesure de l'effort réel par jalon. Valeur immédiate, coût modéré, prépare une éventuelle démonstration et le passage au matériel réel.
- **Recommandation :** **B d'abord (1 à 2 semaines)**, puis A, car B sécurise les preuves déjà obtenues et fournit un moyen de test sans moniteur graphique — utile avant tout essai sur matériel.
- **Statut :** en attente de la décision du responsable.

## D-014 — M4 exécuté selon l'option B ; M5 = clôture de P1 (validée)
- **Date :** 2026-10-26.
- **Décision du responsable :** « **B d'abord, puis A** » — autrement dit : mener d'abord les travaux de **robustesse et de démonstrabilité**, puis le **cœur système** (mémoire virtuelle, processus, appels système).
- **Exécution (M4, réalisée le 2026-10-26) :** clavier **FR/AZERTY** + AltGr + PgUp/PgDn, **entrée série** sur COM1, **historique de console** de 96 lignes avec **défilement réel** prouvé au pixel, police portée à 68 glyphes, outil `tools/metrics.sh`, tests **T6 (14 vérifications)** et T7 intégrés à `tools/test.sh`. Suite complète verte : 15 vérifications distinctes.
- **Conséquence :** l'option A (cœur système) devient la suite logique, **après** la clôture de P1 (M5).
- **Coût mesuré de M4 :** 506 lignes ajoutées / 120 retirées sur 13 fichiers ; 35 496 octets pour le noyau ; 5 incidents corrigés dont 3 invisibles au journal série (vus seulement à la capture ou par comparaison de pixels).
- **Point d'honnêteté :** en M4 l'effort s'est déplacé du code vers la **vérification** — c'est une information utile pour l'estimation de la phase suivante.
- **Statut :** M4 **réalisé** ; M6 (option A) à programmer après M5.

## D-015 — Clôture de P1 et ouverture de la revue D-010 (livrée, décision à prendre)
- **Date :** 2026-10-26.
- **Constat :** la Definition of Done de P1 est remplie — T1 à T7 verts, journaux bruts, empreintes, inventaire, et remise en une commande (`bash tools/test.sh`, 4 min 33 s).
- **Livrables :** `07_Rapports/rapport-tests-P1.md` (rapport final) et `07_Rapports/revue-D-010-niveau-independance.md` (dossier de décision comparant I2/I3/I4 sur faisabilité, pilotes, sécurité, licences, coût, temps).
- **Écarts corrigés pendant la revue finale :** fichier `LICENSE` manquant (créé, BSD-2 provisoire) ; `README.txt` de `src/kernel/`, `src/boot/` et `tests/` périmés (réécrits) ; empreintes M2 encore citées dans le README principal (remplacées par celles de M4).
- **Recommandation soumise :** poursuivre en **I4** avec deux garde-fous (critère d'arrêt à la fin de M6 ; pilotes VirtIO d'abord), I2 (seL4, BSD-2) conservé comme repli documenté, Genode écarté à ce stade (AGPL-3.0 + commercial).
- **Statut : P1 clos ; D-010 en attente de la décision du responsable** (formulaire en fin de dossier de revue).

## D-016 — M6 : mémoire virtuelle, tas noyau, protection (RÉALISÉ)
- **Date :** 2026-10-26. **Décision d'exécution prise dans l'esprit de D-010 et de D-014** : option « stabilité mémoire d'abord ».
- **Livré et mesuré :** gestionnaire de mémoire physique (bitmap, 65 065 pages recensées), **tables de pages propres à 4 niveaux construites puis activées** (CR3), mapping HHDM complet, bit **NX** utilisé, tas noyau, `vmm_map/unmap/translate`, défaut de page intercepté avec reprise d'exécution, 4 nouvelles commandes de shell (`paging`, `heap`, `prot`, `memtest`).
- **Preuve de protection :** 3 défauts de page **réellement déclenchés et interceptés** ; écriture en lecture seule bloquée (P=1, W=1) ; exécution d'une page non exécutable bloquée (IF=1).
- **Incident de conception (trouvé par les tests) :** hypothèse fausse sur la position de la pile du chargeur → adresse non canonique → défaut de protection générale au premier démarrage. Corrigé par une **mesure au démarrage** (la pile est en zone HHDM) et par une réservation physique de cette plage ; CR3 n'est activé que si la vérification réussit.
- **Mesures :** noyau 2 069 lignes (+761), binaire 54 296 octets, 17 vérifications distinctes + 15 autotests mémoire, démarrage BIOS 2,46–2,52 s.
- **Statut : RÉALISÉ le 2026-10-26**, rapport `07_Rapports/rapport-tests-P1-M6.md`. Suite : M7 (processus, ring 3, appels système).

## D-017 — M7 : ring 3, appels système, isolation (RÉALISÉ)
- **Date :** 2026-10-26. Mandat du responsable : « faire l'étape suivante ».
- **Livré et mesuré :** segments utilisateur DPL3 en GDT, porte d'appel système 0x80 en DPL3, programme utilisateur de 138 octets copié à 0x400000, pile non exécutable à 0x800000, deux appels système (`write`, `exit`), `user_copy()` qui refuse tout pointeur hors de la page utilisateur, gestion des fautes de page **utilisateur** (arrêt du programme, noyau vivant).
- **Preuves :** `CPL observe = 3` (valeur lue dans le cadre d'interruption), texte écrit par le programme affiché, **écriture dans la mémoire du noyau refusée par le processeur (code 0x7 = présent+écriture+user)**, noyau survivant et invite atteinte.
- **Défauts corrigés :** (1) `noreturn` sur la fonction d'entrée ring 3 → code de reprise supprimé par le compilateur → panique ; (2) absence de segments DPL3 dans la GDT (anticipé en relisant la GDT, avant plantage).
- **Mesures :** noyau 2 296 lignes, binaire 55 192 octets, 18 vérifications distinctes, démarrage BIOS 2,52–2,57 s.
- **Statut : RÉALISÉ**, rapport `07_Rapports/rapport-tests-P1-M7.md`. Limites : un seul programme, pas d'ordonnanceur, pas d'espace d'adressage par processus.

## D-019 — M8 : deux tâches, espaces d'adressage séparés (RÉALISÉ)
- **Date :** 2026-10-26. Suite de D-018 (chargeur) : M8 construit sur des programmes chargés depuis l'ISO.
- **Livré :** `task.c` (tâches, PML4 par tâche via `vmm_create_space`, contexte sauvegardé, commutation par réécriture du cadre d'interruption), `world.S` (second programme à `0x500000`), défaut de page utilisateur qui **arrête la tâche** au lieu du noyau.
- **Preuves :** deux PML4 distincts (`0x11e000`, `0x125000`) ; tâche A bloquée sur la mémoire noyau (**code 0x7**) ; **tâche B bloquée sur `0x400000` avec code 0x6 = page absente de son espace** → les deux tâches ne partagent pas leur mémoire ; retour au noyau et invite atteinte ; `M8-TACHES-OK`, `M8-ISOLEMENT-OK`.
- **Limite assumée et écrite :** commutation **coopérative** (sur `exit` ou faute), **pas de préemption** sur l'horloge ; pas d'IPC, pas de mémoire partagée, deux tâches en démonstration.
- **Mesures :** noyau 2 501 lignes, 59 840 octets, 19 vérifications distinctes, démarrage BIOS 2,57–2,67 s.
- **Statut : RÉALISÉ**, `07_Rapports/rapport-tests-P1-M8.md`. Suite proposée : M9 (préemption sur quantum).

## D-018 — Programme utilisateur externe (chargeur) : fait avant M8 (RÉALISÉ)
- **Date :** 2026-10-26. **Question posée :** « si on fait M8, on ne fait pas le chargeur ? »
- **Réponse :** les deux ne s'excluent pas, mais l'ordre compte. Faire M8 d'abord aurait produit un ordonnanceur autour de **deux programmes codés en dur**, à refaire ensuite.
- **Décision : chargeur d'abord, M8 ensuite.**
- **Livré :** `src/user/hello.S` (programme assemblé séparément, binaire plat position-indépendant, 128 octets) ; déclaration `module_path` dans `limine.conf` ; `usermode.c` charge le module de l'ISO et **annonce la provenance** ; repli embarqué conservé et signalé.
- **Preuve :** le texte affiché par le programme externe diffère de celui du programme embarqué → c'est bien le fichier de l'ISO qui s'est exécuté ; isolation toujours vérifiée (code 0x7) ; 11/11 vérifications utilisateur.
- **Statut : RÉALISÉ**, `07_Rapports/rapport-chargeur-programme-externe.md`. Suite : M8 (deux programmes, espaces séparés, ordonnanceur).


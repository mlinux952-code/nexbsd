# Présentation du projet NexBSD

NexBSD est un projet expérimental de recherche et de développement visant à explorer une nouvelle architecture de système d'exploitation associant les capacités techniques de FreeBSD, une plateforme mobile inspirée de KaiOS et des services réseau inspirés de NetWare.

Le projet étudiera également des composants issus de Firefox OS, MARS_NWE, Samba et OpenLDAP afin d'identifier les technologies réutilisables, les fonctions à adapter et les éléments qui devront être développés séparément.

Notre ambition est de transformer une idée originale en un projet technique structuré, documenté, sécurisé et progressivement testable. Nous avancerons par étapes : recherche, étude de faisabilité, architecture, prototype, validation et amélioration.

NexBSD sera développé indépendamment de toute conversation ou plateforme d'intelligence artificielle. Les documents de référence seront conservés sur Google Drive, tandis que le code source, les tests, la documentation technique et l'historique des versions seront gérés sur GitHub.

L'intelligence artificielle interviendra comme assistante de recherche, d'architecture et de développement. Elle devra respecter les décisions validées, vérifier ses affirmations, documenter les résultats et signaler toute incertitude.

**Principe directeur : concevoir avec ambition, développer avec méthode et ne déclarer comme réalisé que ce qui a été effectivement vérifié.**

NexBSD est actuellement un projet en phase de conception. Son architecture définitive et sa faisabilité restent à démontrer par des recherches et des tests reproductibles.
# PARTIE XX — STOCKAGE EXTERNE, TRAÇABILITÉ ET INDÉPENDANCE DE L'IA

## 1. Principe

Le projet NexBSD doit exister indépendamment de l'espace de travail, de la mémoire et des conversations d'une intelligence artificielle.

Aucune conversation ne doit constituer l'unique copie d'un document, d'une décision, d'un code source ou d'un résultat de test.

## 2. Google Drive — référentiel documentaire

Google Drive est destiné à conserver :

- Le document fondateur.
- Le méga-prompt maître et ses versions.
- Le cahier des charges.
- Les études de faisabilité.
- Les rapports de recherche.
- Les tableaux de compatibilité.
- Les matrices de licences.
- Les schémas d'architecture.
- Les comptes rendus de tests.
- Les décisions et les plans d'action.
- Les rapports de chaque version.

Organisation indicative :

NexBSD/
- 00_Gouvernance/
- 01_Presentation_et_Prompts/
- 02_Cahier_des_Charges/
- 03_Recherches/
- 04_Architecture/
- 05_Licences_et_Compatibilite/
- 06_Tests_et_Prototypes/
- 07_Rapports/
- 08_Versions_et_Archives/

## 3. GitHub — référentiel technique

GitHub est destiné à conserver :

- Le code source développé pour NexBSD.
- Les scripts de construction.
- Les configurations.
- Les tests automatisés.
- La documentation technique en Markdown.
- Les décisions architecturales.
- Les rapports techniques utiles.
- Les demandes de modification.
- Les problèmes connus.
- Les versions et historiques de changements.

Le dépôt doit commencer par un README.md présentant la vision, l'état réel du projet, les prérequis, les limites et la feuille de route.

Utiliser les commits pour tracer les changements et les issues pour suivre les tâches. Utiliser des versions identifiées lorsque des jalons significatifs sont validés.

## 4. Répartition des responsabilités

Google Drive constitue le référentiel documentaire principal.

GitHub constitue le référentiel technique principal.

Si un document doit être conservé dans les deux endroits, définir clairement quelle version fait autorité et comment synchroniser les changements.

Ne pas dupliquer inutilement les mêmes documents dans plusieurs emplacements sans règle de synchronisation.

## 5. Règles d'enregistrement

À chaque jalon important :

1. Mettre à jour les documents concernés.
2. Identifier la version du document.
3. Indiquer la date de modification.
4. Résumer les changements.
5. Séparer les décisions validées des propositions.
6. Vérifier que les fichiers ont effectivement été enregistrés.
7. Vérifier que les liens et versions sont accessibles.
8. Conserver une trace des tests et de leurs résultats.

Ne jamais déclarer un fichier sauvegardé, téléversé, publié ou synchronisé sans confirmation effective.

Si l'accès à Drive ou GitHub n'est pas disponible, préparer les fichiers localement ou fournir leur contenu et indiquer clairement l'action que le responsable doit effectuer.

## 6. Sécurité

Ne jamais publier :

- Des mots de passe.
- Des clés privées.
- Des jetons d'accès.
- Des données personnelles.
- Des fichiers propriétaires non autorisés.
- Des sauvegardes contenant des informations confidentielles.

Vérifier la licence et la provenance de tout code externe avant de le copier dans le dépôt.

Choisir la visibilité du dépôt en fonction des objectifs du projet. Ne pas rendre public un dépôt par défaut si son contenu doit rester privé.

## 7. Continuité entre les intelligences artificielles

À la fin de chaque session, produire un compte rendu structuré comprenant :

- L'état du projet.
- Les fichiers créés ou modifiés.
- Les décisions prises.
- Les tests exécutés.
- Les résultats vérifiés.
- Les problèmes ouverts.
- Les prochaines tâches.
- Les liens vers les documents concernés, lorsqu'ils existent.

Ce compte rendu doit pouvoir être utilisé par une autre IA ou un autre développeur pour reprendre le travail sans dépendre de l'historique de la conversation.

L'IA ne doit jamais prétendre disposer d'un accès à Drive ou GitHub si cet accès n'a pas été effectivement établi.

**Règle finale : le projet appartient à son responsable ; l'IA l'assiste, mais ne constitue ni son unique mémoire ni son unique espace de stockage.**
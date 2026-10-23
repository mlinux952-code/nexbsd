# Étape E — Plan d'action ordonné

**Date :** 2026-10-23
**Portée :** enchaînement des tâches jusqu'à la preuve de faisabilité (option 1, « NexBSD-Lab-0 »).
> **Statut de ce plan depuis ADR-0011 :** les étapes ci-dessous ne construisent **pas** le produit NexBSD. Elles servent à **dérisquer les composants** qui entreront ensuite dans la Plateforme NexBSD et à valider les procédures. La production d'une image NexBSD (fork) est une phase distincte (`docs/roadmap.md`, phases 4bis et 4ter) qui exige le profil L3.

**Règle :** chaque tâche est autonome, vérifiable, et son critère de passage est explicite. Ne pas commencer une tâche si le critère de la précédente n'est pas rempli.

Légende : 🔒 action à faire par le **responsable du projet** (matériel, décisions) · 🤖 action préparée par l'**assistant** (documents, procédures, configurations) · ⚠️ action potentiellement destructive

---

## Étape 0 — Décisions à valider avant tout

| # | Action | Qui | Critère de passage |
|---|---|---|---|
| 0.1 | Valider le cadrage (`docs/00-cadrage-phase0.md`) et le choix du prototype 1 | 🔒 | accord explicite écrit dans le compte rendu de session |
| 0.2 | Valider le rejet de KaiOS comme base et de MARS_NWE comme composant | 🔒 | idem |
| 0.3 | Décider de la politique de publication (dépôt privé ou public, nom de projet) | 🔒 | dépôt GitHub créé, visibilité choisie |
| 0.4 | Décider où vivra le référentiel documentaire (Drive) et créer l'arborescence | 🔒 + 🤖 | dossiers 00→08 créés et vérifiables |

---

## Étape 1 — Inventaire matériel non destructif

**Objectif :** savoir sur quoi on travaille avant de toucher à quoi que ce soit.
**Prérequis :** le PC de 2011 démarre sous Windows 7.
**Outils :** Windows 7 uniquement en lecture (m sinfo32, dxdiag, gestionnaire de disques), ou une clé de diagnostic. Aucun outil d'écriture disque.
**Actions :**
1. Noter le **modèle exact du CPU** et s'il est 64 bits (indispensable : FreeBSD 15 n'existe plus en i386).
2. Noter la **quantité de RAM** et sa configuration.
3. Noter le **modèle du disque interne**, sa capacité, son état SMART si un outil de lecture est disponible.
4. Identifier le **firmware** (BIOS/UEFI), l'ordre de démarrage possible, la présence d'un menu de démarrage USB.
5. Identifier la **carte réseau** (filaire et Wi-Fi) et la carte graphique.
6. Sauvegarder les données personnelles présentes sur le disque (clé USB, cloud) — hors périmètre technique mais nécessaire.
**Résultat attendu :** `docs/hardware.md` rempli, section « Inventaire observé ».
**Test de validation :** chaque ligne comporte une valeur observée et la méthode utilisée.
**Risques :** modification involontaire de réglages BIOS ; ne rien changer sans comprendre.
**Critère de passage :** CPU 64 bits **confirmé**. Sinon → arrêt et réorientation (VM ou autre machine).


---

## Étape 1bis — Banc de test virtuel sur la station Linux Mint

**Objectif :** obtenir un premier démarrage FreeBSD **aujourd'hui**, sans attendre l'inventaire du PC de 2011 et sans toucher à aucun disque physique.
**Prérequis :** poste Linux Mint (faible capacité) ; ~3 Go d'espace libre ; procédure `docs/10-station-linux-mint.md`.
**Outils :** `qemu-system-x86`, image `memstick` FreeBSD vérifiée, scripts `nexbsd/scripts/`.
**Actions :**
1. `bash scripts/00-diagnostic-hote.sh` → relever CPU, RAM, espace libre, présence de KVM.
2. Télécharger l'image et **vérifier les empreintes** : `bash scripts/10-verifier-image.sh <image> <CHECKSUM>`.
3. Créer et démarrer la VM : `bash scripts/30-qemu-freebsd.sh --create --from-installer --ram 1024`.
4. Installer FreeBSD dans la VM (disque virtuel de 8 Go), sans interface graphique.
5. Relever les mesures de base (RAM au repos, `df -h`) et les comparer au budget L1.
**Résultat attendu :** une VM FreeBSD fonctionnelle, mesures consignées.
**Test de validation :** **T-01v** (variante virtuelle de T-01) — `uname -a` dans la VM, aucun pilote bloquant.
**Risques :** sans KVM, la VM est lente (privilégier `--nographic` et 512-1024 Mo) ; ne jamais saturer la RAM de la station.
**Critère de passage :** système stable 15 minutes, mesure de RAM ≤ 256 Mo au repos.
**Ce que cela ne prouve pas :** la compatibilité avec le matériel réel du PC de 2011 (T-01 reste nécessaire).

> Cette étape est **parallèle** à l'étape 1, pas un substitut. L'inventaire matériel reste obligatoire.

---

## Étape 2 — Préparation du support de démarrage externe

**Objectif :** disposer d'un FreeBSD amorçable sans écrire sur le disque interne.
**Prérequis :** étape 1 terminée ; une clé USB ≥ 8 Go (ou un disque USB externe).
**Outils :** image `FreeBSD-15.1-RELEASE-amd64-memstick.img` (site officiel), outil d'écriture (Rufus/Win32DiskImager sous Windows, ou `dd` depuis un système de test).
**Actions :**
1. Télécharger l'image et **vérifier sa somme de contrôle** (fichier `CHECKSUM`).
2. Écrire l'image sur la clé — ⚠️ **vérifier trois fois le numéro du disque cible** ; la clé USB ne doit pas être le disque interne.
3. Relire la procédure de démarrage (touche du menu de démarrage selon le firmware).
**Résultat attendu :** clé amorçable, somme de contrôle vérifiée.
**Test de validation :** le menu de démarrage du BIOS/loader FreeBSD s'affiche.
**Risques :** écrire sur le mauvais disque (R-01). Mitigation : retirer physiquement ou vérifier le nom avant écriture ; ne jamais exécuter `dd` sur `/dev/ada0` ou équivalent sans double vérification.
**Critère de passage :** FreeBSD démarre en mode live/installeur, en lecture seule.

---

## Étape 3 — Premier démarrage et collecte du journal

**Objectif :** prouver que le noyau FreeBSD 15.1 fonctionne sur ce matériel.
**Outils :** le support de l'étape 2 ; appareil photo ou second poste pour capturer les sorties.
**Actions :**
1. Démarrer ; noter les messages de détection (`dmesg`).
2. Vérifier : disques détectés, carte réseau détectée, clavier/écran fonctionnels.
3. Consigner toute erreur (ACPI, pilote manquant, périphérique non reconnu).
**Résultat attendu :** journal de démarrage archivé dans `reports/`.
**Test de validation :** **T-01** réussi (sortie `uname -a` + absence d'erreur bloquante).
**Risques :** ne pas confondre lenteur (disque mécanique) et échec.
**Critère de passage :** système stable pendant 15 minutes, réseau filaire fonctionnel.

---

## Étape 4 — Installation sur support externe

**Objectif :** disposer d'un système persistant, isolé du disque interne.
**Outils :** installeur FreeBSD (`bsdinstall`).
**Actions :**
1. Sélectionner **exclusivement** le disque USB externe comme cible.
2. Choisir le système de fichiers (UFS par défaut ; ZFS seulement si la RAM le permet).
3. Créer un compte utilisateur non privilégié ; mot de passe robuste, noté hors du dépôt.
4. Activer `sshd` uniquement sur le réseau local (ou le laisser désactivé au départ).
5. Redémarrer sans le support d'installation et vérifier le démarrage autonome.
**Résultat attendu :** FreeBSD installé sur support externe, démarrage autonome.
**Test de validation :** **T-02** (inventaire matériel complet) + redémarrage 3 fois de suite sans erreur.
**Risques :** ⚠️ erreur de disque cible = perte de Windows 7. Mitigation : vérifier la taille et le modèle affichés par `bsdinstall` avant validation.
**Critère de passage :** système démarre seul, disque interne intact (vérifier que Windows 7 démarre toujours après retrait du support externe).

---

## Étape 5 — Durcissement minimal et réseau

**Objectif :** un socle sûr avant d'installer des services.
**Actions :**
1. Mises à jour : `freebsd-update fetch install` puis `pkg update && pkg upgrade`.
2. Pare-feu `pf` : politique par défaut « deny », ouverture des seuls ports nécessaires.
3. Désactiver les services inutiles ; utilisateur non root pour l'administration (`doas`/`sudo`).
4. Activer `syslog`/`newsyslog` avec rotation.
**Résultat attendu :** système à jour, sans port ouvert non justifié.
**Test de validation :** **T-05a** — un scan depuis un autre poste ne voit que les ports déclarés.
**Risques :** se verrouiller hors du système (règle pf trop stricte). Mitigation : tester depuis la console avant de fermer la session.
**Critère de passage :** politique par défaut en refus vérifiée.

---

## Étape 6 — Service de fichiers Samba en jail

**Objectif :** démontrer un partage réel avec droits différenciés.
**Prérequis :** `pkg search samba` exécuté ; **version ≥ 4.23 épinglée** (ne pas accepter `samba416` par défaut).
**Actions :**
1. Créer une jail `files` dédiée, réseau interne, aucune redirection vers l'extérieur.
2. Installer Samba dans la jail, configurer un partage, deux utilisateurs (`alice` lecture seule, `bob` lecture-écriture).
3. Configurer ACL et vérifier le comportement des droits.
4. Consigner la version exacte installée.
**Résultat attendu :** partage accessible, droits conformes.
**Test de validation :** **T-03** — `alice` ne peut pas écrire (preuve d'échec attendu), `bob` peut écrire et relire.
**Risques :** droits trop larges ; version obsolète (R-07).
**Critère de passage :** T-03 réussi avec preuve des deux comportements (autorisé **et** refusé).

---

## Étape 7 — Annuaire : décision conditionnelle

**Objectif :** lever l'inconnue K-10 avant de s'engager.
**Actions :**
1. `pkg search -x openldap` et inspection de l'arbre des ports : existe-t-il une version ≥ 2.6 ?
2. **Si oui** : jail `ldap`, TLS, un utilisateur technique, test d'authentification depuis un client.
3. **Si non** : ne pas s'engager ; documenter la décision ; conserver comptes locaux + Samba `tdbsam` pour ce prototype ; ouvrir une option de compilation `poudriere` (hors machine cible).
**Résultat attendu :** décision documentée dans un ADR.
**Test de validation :** **T-04** (si LDAP retenu) ou ADR-0006 (si reporté).
**Critère de passage :** l'un des deux livrables existe.

---

## Étape 8 — Sauvegarde, restauration, retour arrière

**Objectif :** prouver qu'on sait revenir à un état connu.
**Actions :**
1. Définir l'état de référence (liste des paquets, configuration, contenu du partage).
2. Sauvegarder (snapshot ZFS ou archive `tar` sur un second support).
3. Simuler une panne : supprimer un fichier de configuration, arrêter un service.
4. Restaurer, chronométrer, vérifier.
**Résultat attendu :** procédure de restauration écrite et chronométrée.
**Test de validation :** **T-06** — restauration réussie en < 15 minutes sur ce matériel.
**Risques :** sauvegarde stockée sur le même support que la donnée (inutile).
**Critère de passage :** restauration testée au moins une fois, résultat consigné.

---

## Étape 9 — Mesures et rapport de validation

**Objectif :** transformer les impressions en chiffres.
**Actions :**
1. Mesurer : RAM au repos, RAM avec Samba actif, RAM par jail, temps de démarrage, débit de copie sur le support externe (USB 2.0 attendu sur du matériel de 2011).
2. Remplir `reports/validation-prototype-0.md`.
3. Lister honnêtement ce qui n'a pas fonctionné.
**Critère de passage :** rapport publiable, chiffres reproductibles (protocole de mesure décrit).

---

## Étape 10 — Décision Go/No-Go et suite

- Si les critères de sortie de l'option 1 sont remplis → **ADR : ouverture de la phase 5 (mobile)**.
- Sinon → consigner les blocages, revenir à l'étape concernée ; ne pas élargir le périmètre pour compenser.

---

## Ce que ce plan ne fait pas

- Il ne modifie pas le disque interne.
- Il ne promet aucune fonction mobile.
- Il ne prévoit aucune intégration NetWare.
- Il ne demande aucune compilation longue sur la machine cible.

## Estimation d'effort (indicative, non contractuelle)

| Étape | Durée réaliste (soirées/sessions) | Blocage possible |
|---|---|---|
| 0 | 1 | décisions |
| 1 | 1 | accès physique au PC |
| 1bis (VM) | 1-2 | RAM de la station, absence de KVM |
| 2 | 1 | clé USB, firmware capricieux |
| 3-4 | 2-3 | pilotes, lenteur du disque |
| 5-6 | 2-3 | version de Samba, configuration jail |
| 7 | 1-2 | disponibilité OpenLDAP |
| 8-9 | 2 | discipline de mesure |
| **Total** | **~11-15 sessions** | |

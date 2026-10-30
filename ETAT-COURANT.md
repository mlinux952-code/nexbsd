# ETAT COURANT — NexBSD

> Fichier unique de reprise. À RÉÉCRIRE EN ENTIER à chaque étape, jamais à compléter.
> S'il contredit un autre document, c'est lui qui a raison : il est daté.
> Dernière mise à jour : 2026-10-30 21 h 16 UTC (mesuré par API, pas de mémoire).

## 1. Le seul chiffre
0 / 8 fonctions P0 terminées — matrices/functions.csv, 8 lignes P0
(S-01 S-02 S-03 S-04 S-05 S-09 N-01 N-02).

## 2. Dépôt
- HEAD prouvé : 51e151e0, poussé le 30/10 à 20:50:50Z (deux lignes identiques + API commits/main)
- Commits : 176 — aucune divergence local/distant
- Bundle le plus récent : s089 (877 573 o, sha256 131e07bd...ee99c6) — déjà poussé, ne pas le rejouer

## 3. Construction en cours
- Exécution #25, id 41108532795, sha construit 2b351e2a (antérieur à 51e151e0)
- Lancée 30/10 18:37:38Z — à 21 h 16 : in_progress, étape 8/11 « 3/4 construction », 2 h 39
- Référence : #18 = 2 h 29 ; #25 a dépassé, ce n'est pas encore une alerte
- Ligne décisive pas encore écrite (étape 10/11 pending) : gpart :  1  40  1  freebsd-boot
- Artefact le plus récent : 2026-10-29T08:25:04Z => aucune image du 30/10
- Release image-18 (29/10) : image inamorçable (C-51)

## 4. Défaut central (inchangé)
fork/80-installer-nexbsd.sh : 0 occurrence dans .github/workflows/nexbsd.yml
=> l'image ne contient ni Samba, ni OpenLDAP, ni nslcd, ni X11, ni WebKit (D-05).
Ce n'est pas du code manquant, c'est un câble non branché.

## 5. Règles de reprise (apprises, ne pas réapprendre)
- Journaux GitHub = 403 : ne raisonner que sur jobs / steps / artefacts / releases.
- api.github.com peut être limité par IP (403) : recouper par raw.githubusercontent.com.
- Une commande à la fois, avec la sortie attendue ; nommer le terminal MINT / VM.
- Aucune promesse : distinguer prouvé / supposé / impossible.
- Un rond vert de CI n'est pas un produit qui fonctionne.

## 6. Prochain pas, dans l'ordre
1. #25 terminée => lire le Summary => freebsd-boot présente : publier (tag image-25) ;
   absente ou [KO ] : on ne publie pas, on diagnostique.
2. Démarrer sous QEMU avec overlay qcow2 => un login à l'écran => S-01.
3. Câbler fork/80 dans la chaîne => D-05.
4. smbclient depuis MINT lit un fichier => N-01 (+ S-03, S-05).

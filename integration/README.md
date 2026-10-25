# Dossier `integration/` — intégration des composants au système

Exigé par la Partie XIII. **Vide par construction : rien n'a encore été intégré.**

Ce dossier accueillera, pour chaque composant retenu :
- les fichiers de configuration de référence (versions contrôlées) ;
- les scripts `rc.d` / gabarits de jail ;
- les règles `pf` et le modèle d'isolation ;
- les procédures d'installation vérifiées (avec sortie de commande) ;
- la trace des tests d'intégration exécutés et leurs résultats.

**Règle :** un fichier de ce dossier n'est recevable que s'il a été **exécuté au moins une fois** sur un système réel, avec la sortie conservée. Sinon il reste dans `fork/` à l'état de brouillon.

État au 2026-10-23 : `fork/` contient le squelette du delta de fork (`src.conf`, `NEXBSD_L1`, `release.conf`, `build-nexbsd.sh`) — **jamais exécuté**.

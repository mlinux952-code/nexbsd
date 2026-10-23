# Plan de tests — prototype 0

**Date :** 2026-10-23
**Statut :** aucun test n'a été exécuté. Ce document décrit les tests **à venir** (16 tests, T-01 → T-15).

> **Deux bancs d'essai réseau (2026-10-23, `research/ncp-ip/fiche.md`)** :
> - **Banc A** = T-14, comportement (MARS_NWE + IPX + DOSBox) — donne la **spécification**.
> - **Banc B** = T-09, protocole sur le port 524 (Client for Open Enterprise Server) — donne la **preuve de différenciation**.
> Le banc B est prioritaire : il est réalisable sans profil L3 et valide directement la cible ADR-0018.
**Règle :** chaque test est consigné avec procédure, résultat attendu, résultat observé et verdict. Un test non exécuté est noté `NON EXÉCUTÉ`, jamais « OK ».

---

| ID | Test | Objectif | Prérequis | Procédure (résumé) | Résultat attendu | Résultat observé | Verdict |
|---|---|---|---|---|---|---|---|
| T-01 | Démarrage | FreeBSD démarre sur le matériel | support externe amorçable | démarrer, attendre l'invite, exécuter `uname -a` et `dmesg` | système stable, aucun pilote bloquant | — | NON EXÉCUTÉ |
| T-01v | Démarrage en VM | FreeBSD démarre dans QEMU sur la station | image vérifiée, qemu installé | `30-qemu-freebsd.sh --create --from-installer --ram 1024` puis `uname -a` | système stable, RAM au repos ≤ 256 Mo | — | NON EXÉCUTÉ |
| T-02 | Inventaire matériel | connaître la machine | démarrage réussi | `pciconf -lv`, `dmesg`, `sysctl hw`, `ifconfig -a`, `geom disk list` | CPU amd64, disques et NIC identifiés | — | NON EXÉCUTÉ |
| T-03 | Partage SMB et droits | prouver un partage fonctionnel et des droits corrects | Samba ≥ 4.23 en jail | `alice` tente d'écrire (doit échouer) ; `bob` écrit et relit (doit réussir) | deux comportements conformes, preuves capturées | — | NON EXÉCUTÉ |
| T-04 | Annuaire | authentifier via LDAP | OpenLDAP ≥ 2.6 disponible (sinon ADR de report) | `slapd` en jail, création d'un utilisateur, authentification d'un client, refus d'accès anonyme | authentification réussie, anonyme refusé | — | NON EXÉCUTÉ |
| T-05 | Isolation et pare-feu | surface d'attaque minimale | `pf` configuré | scan depuis un autre poste (`nmap` ou équivalent) ; `jls` ; `sockstat` | seuls les ports déclarés sont ouverts | — | NON EXÉCUTÉ |
| T-05a | Fermeture par défaut | vérifier `block all` | idem | arrêter le service, rescanner | tous les ports filtrés | — | NON EXÉCUTÉ |
| T-06 | Restauration | revenir à un état connu | sauvegarde existante | supprimer un fichier de configuration, restaurer, redémarrer | service fonctionnel, durée < 15 min | — | NON EXÉCUTÉ |
| T-07 | Impression | partage d'imprimante | CUPS + Samba | publier une imprimante de test, imprimer depuis un client | document imprimé | — | NON EXÉCUTÉ |
| T-08 | Sensibilité du disque | vérifier que le disque interne est intact | après installation externe | retirer le support, démarrer Windows 7 | Windows 7 démarre normalement | — | NON EXÉCUTÉ |
| T-09 | **Banc B — protocole NCP sur 524** | prouver qu'un client NCP réel se connecte à l'implémentation NexBSD | PC de test + VM Windows isolée + **Client for Open Enterprise Server 26.2.1** (ADR-0019) + service NCP NexBSD (NCP-1→NCP-6) | (1) réseau local isolé, sans passerelle ; (2) lancer le client, viser l'adresse NexBSD port TCP **524** (+ SLP 472) ; (3) exécuter login/attach, map volume, listing, lecture puis écriture d'un fichier ; (4) capturer chaque écran et le journal NexBSD | NCP-1→NCP-3 réussis ; NCP-4→NCP-6 documentés réussis ou échoués | — | NON EXÉCUTÉ (service NCP inexistant) |
| T-14 | **Banc A — comportement NetWare observé** | documenter le comportement de référence à imiter | VM Linux isolée + module IPX hors arbre (`pasis/ipx`) + **MARS_NWE 0.99.pl23** + DOSBox (`ipxnet`, UDP 213) | monter MARS_NWE, connecter un client DOS par IPX sur UDP, exercer login/listage/écriture, relever chaque comportement visible | `docs/spec-netware-observee.md` rédigé, comportements listés sans invention | — | NON EXÉCUTÉ (compilation noyau requise, V-3) |
| T-15 | Découverte de services (esprit SAP) | un client trouve le serveur sans saisir son adresse | NexBSD avec mDNS/DNS-SD actif + poste client | annoncer le service, puis rechercher depuis un poste Windows/Linux | le service apparaît dans la liste du client en < 30 s | — | NON EXÉCUTÉ |
| T-10 | Interface petit écran | démontrer une UI navigable au clavier | phase 5 | lancer la coquille, naviguer uniquement au clavier, mesurer RAM et temps de lancement | navigation complète sans souris | — | NON EXÉCUTÉ |
| T-12 | Construction de la base | NexBSD construit sa propre image (phase 4bis) | profil L3, arbre source | `make buildworld` puis `buildkernel`, `release.sh` | image amorçable, build reproductible | — | NON EXÉCUTÉ (L3 indisponible) |
| T-13 | Frontière de licence | aucun code copyleft dans la base | arbre de base | recherche de `SPDX-License-Identifier: GPL` + revue | zéro occurrence non justifiée | — | À AUTOMATISER |
| T-11 | Reproductibilité | rejouer une construction | script de build | reconstruire depuis un état propre et comparer | résultat identique ou écarts expliqués | — | NON EXÉCUTÉ |

## Format d'un compte rendu de test

```
Test : T-xx — <nom>
Date / heure :
Version du système (uname -a) :
Procédure réellement suivie :
Résultat attendu :
Résultat observé (verbatim des sorties) :
Écarts :
Verdict : RÉUSSI / ÉCHEC / PARTIEL / NON EXÉCUTÉ
Preuves : <fichiers, captures>
```

## Mesures à relever (prototype 0)

| Mesure | Méthode | Unité |
|---|---|---|
| RAM au repos | `vmstat -h` / `top` | Mo |
| RAM avec Samba actif | idem | Mo |
| RAM par jail | `rctl` / `top` | Mo |
| Temps de démarrage | chronomètre jusqu'à l'invite | s |
| Débit de copie sur le support externe | `dd` / copie chronométrée | Mo/s |
| Empreinte disque de l'installation | `df -h` | Go |

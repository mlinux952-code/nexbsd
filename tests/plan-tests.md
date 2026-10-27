# Plan de tests — prototype 0

**Date :** 2026-10-23
**Statut : 11 tests réussis sur 20 (2026-10-27) — T-17, T-11, T-18, T-05 (pare-feu pf) et T-05a (refus par défaut prouvé depuis le Mint) RÉUSSIS.** T-01, T-03, T-04, T-04-E et T-04-F sont réussis en machine virtuelle ; les 9 autres restent `NON EXÉCUTÉ` ; T-04-G est écrit et attend son exécution.

> **Exécution du 2026-10-23 (VM QEMU, émulation pure)** : FreeBSD 15.1-RELEASE démarre (81 s jusqu'à `login:`), ~100 Mo de RAM occupés au repos, Samba 4.23.11 installé depuis les dépôts, partage authentifié accessible **depuis une autre machine** avec écriture et relecture. Détails : `tests/results/`.

> **Deux bancs d'essai réseau (2026-10-23, `research/ncp-ip/fiche.md`)** :
> - **Banc A** = T-14, comportement (MARS_NWE + IPX + DOSBox) — donne la **spécification**.
> - **Banc B** = T-09, protocole sur le port 524 (Client for Open Enterprise Server) — donne la **preuve de différenciation**.
> Le banc B est prioritaire : il est réalisable sans profil L3 et valide directement la cible ADR-0018.
**Règle :** chaque test est consigné avec procédure, résultat attendu, résultat observé et verdict. Un test non exécuté est noté `NON EXÉCUTÉ`, jamais « OK ».

---

| ID | Test | Objectif | Prérequis | Procédure (résumé) | Résultat attendu | Résultat observé | Verdict |
|---|---|---|---|---|---|---|---|
| T-01 | Démarrage | FreeBSD démarre sur le matériel | support externe amorçable | démarrer, attendre l'invite, exécuter `uname -a` et `dmesg` | système stable, aucun pilote bloquant | — | **RÉUSSI (VM)** — `tests/results/T-01-demarrage-freebsd.md` |
| T-01v | Démarrage en VM | FreeBSD démarre dans QEMU sur la station | image vérifiée, qemu installé | `30-qemu-freebsd.sh --create --from-installer --ram 1024` puis `uname -a` | système stable, RAM au repos ≤ 256 Mo | — | NON EXÉCUTÉ |
| T-02 | Inventaire matériel | connaître la machine | démarrage réussi | `pciconf -lv`, `dmesg`, `sysctl hw`, `ifconfig -a`, `geom disk list` | CPU amd64, disques et NIC identifiés | — | NON EXÉCUTÉ |
| T-03 | Partage SMB et droits | prouver un partage fonctionnel et des droits corrects | Samba ≥ 4.23 en jail | `alice` tente d'écrire (doit échouer) ; `bob` écrit et relit (doit réussir) | deux comportements conformes, preuves capturées | — | **RÉUSSI (cœur)** — `tests/results/T-03-partage-samba.md` |
| T-04 | Annuaire | authentifier via LDAP | OpenLDAP ≥ 2.6 disponible (sinon ADR de report) | `slapd` en jail, création d'un utilisateur, authentification d'un client, refus d'accès anonyme | authentification réussie, anonyme refusé | — | **REUSSI** le 2026-10-24 sur la VM du responsable — journal verbatim dans `tests/results/T-04-ldap-annuaire.md` |
| T-04-E | Annuaire + fichiers | Samba authentifie **via LDAP** | T-04 (annuaire) et T-03 (Samba) réussis | `smb4.conf` en `passdb backend = ldapsam`, `smbpasswd -a`, `smbclient` | `pdbedit` voit le compte, `sambaSID` présent dans l'annuaire, `smbclient` réussit | `scripts/62`, `tests/results/T-04E-samba-ldap.md` | **RÉUSSI le 2026-10-24** (essai 3) — `sambaSID` dans l'annuaire, `smbclient` authentifié et partage lu. Réserve : rejouabilité du script v3 non encore démontrée |
| T-04-F | Droits par **groupes de l'annuaire** | prouver qu'un compte qui n'existe que dans l'annuaire est authentifié et que ses droits viennent de son groupe | T-04-E réussi | `ldapsam:trusted = yes`, groupes `bureau`/`stagiaires` dans LDAP, `[commun]` en 2770 root:2001, `[public]` en lecture seule | `omrane` écrit et son fichier porte uid/gid de l'annuaire ; `sara` est **refusée** dans `[commun]` et lit `[public]` | `scripts/63`, `tests/results/T-04F-droits-groupes.md` | **RÉUSSI le 2026-10-24** (essai 2) — `omrane` écrit dans `[commun]`, `sara` y est refusée ; compte créé uniquement dans l'annuaire. Réserve : sortie intégrale non recopiée |
| T-04-G | **Persistance** | prouver que le banc revient seul après un redémarrage, données et droits compris | T-04, T-04-E, T-04-F réussis | deux phases (`avant` / `apres`) autour d'un `reboot` : services armés, comptage LDAP, fichier témoin, écriture d'`omrane` et refus de `sara` après coupure | 11 contrôles réussis, aucune commande manuelle après le redémarrage | `scripts/64`, `tests/results/T-04G-persistance.md` | **RÉUSSI le 2026-10-25 (11/11)** — trois services reviennent seuls, annuaire et droits intacts, `omrane` écrit et `sara` reste refusée après redémarrage. Cause de l'échec initial : **C-14** (NSS absent), clos |
| T-16 | **Identité du banc** | le système porte le nom **NexBSD** (nom d'hôte, accueil, invite) sans rien casser | T-04-G réussi | `scripts/66` : nom d'hôte, `/etc/motd`, vérification que annuaire/NSS/Samba restent opérationnels | l'invite affiche `root@nexbsd`, les services répondent | `scripts/66`, `tests/results/T-16-identite-banc.md`, `docs/26` | **ÉTAGE 1 APPLIQUÉ (2026-10-25)** — compte rendu à reporter ; les étages 2 et 3 relèvent de T-17 et de la campagne `docs/28` |
| T-17 | **Noyau propre (étage 2)** | le banc démarre sur un noyau **construit par le projet** | T-04-G réussi, disque de construction 30 Go, VM à 2048 Mo, **ADR-0020** | `scripts/67` (sources `src.txz` + empreinte SHA256 + régénération vérifiée de `NEXBSD_L1`) → `scripts/68 --lancer` (2 à 6 h) → `scripts/69` → `reboot` | `uname -i` = `NEXBSD_L1` ; `uname -r` = `15.1-NEXBSD-L1` ; le banc rejoue **11/11** | `15.1-NEXBSD-L1` / `NEXBSD_L1` / banc **11/11** | **RÉUSSI (2026-10-26)** — compilé (1470 s, sha256 `82dc5681…`), installé (`/boot/kernel.NEXBSD_L1`, 858 modules, 158 Mo), démarré durablement, **banc T-04-G 11/11 sur ce noyau** (`hote : FreeBSD 15.1-NEXBSD-L1`) |
| T-05 | Isolation et pare-feu | surface d'attaque minimale | `pf` configuré | `pfctl -n -f` puis activation, **harnais rejoué sous filtrage** | 11 règles, refus par défaut, banc toujours 24/24 | `pf` actif, 11 règles, **harnais 24/24 sous filtrage** | **RÉUSSI (2026-10-27)** — `tests/results/T-05-pare-feu.md` |
| T-05a | **Fermeture par défaut** | vérifier que les ports **fermés** le sont vraiment | `pf` actif, redirection slirp `127.0.0.1:4450 → VM:445` | depuis le Mint : `smbclient //127.0.0.1/commun -p 4450` (doit passer) puis tentative vers un port non déclaré (8080) ; relever `pflog` | port déclaré joignable, port non déclaré **injoignable + journalisé** | 4 fichiers listés via `smbclient` ; 8 SYN vers `10.0.2.15:8080` tous bloqués, trace `rule 0/0(match): block in on vtnet0` dans `pflog0` | **RÉUSSI (2026-10-27)** — `tests/results/T-05a-accessibilite-depuis-mint.md` |
| T-06 | Restauration | revenir à un état connu | sauvegarde existante | supprimer un fichier de configuration, restaurer, redémarrer | service fonctionnel, durée < 15 min | — | NON EXÉCUTÉ |
| T-07 | Impression | partage d'imprimante | CUPS + Samba | publier une imprimante de test, imprimer depuis un client | document imprimé | — | NON EXÉCUTÉ |
| T-08 | Sensibilité du disque | vérifier que le disque interne est intact | après installation externe | retirer le support, démarrer Windows 7 | Windows 7 démarre normalement | — | NON EXÉCUTÉ |
| T-09 | **Banc B — protocole NCP sur 524** | prouver qu'un client NCP réel se connecte à l'implémentation NexBSD | PC de test + VM Windows isolée + **Client for Open Enterprise Server 26.2.1** (ADR-0019) + service NCP NexBSD (NCP-1→NCP-6) | (1) réseau local isolé, sans passerelle ; (2) lancer le client, viser l'adresse NexBSD port TCP **524** (+ SLP 472) ; (3) exécuter login/attach, map volume, listing, lecture puis écriture d'un fichier ; (4) capturer chaque écran et le journal NexBSD | NCP-1→NCP-3 réussis ; NCP-4→NCP-6 documentés réussis ou échoués | — | NON EXÉCUTÉ (service NCP inexistant) |
| T-14 | **Banc A — comportement NetWare observé** | documenter le comportement de référence à imiter | VM Linux isolée + module IPX hors arbre (`pasis/ipx`) + **MARS_NWE 0.99.pl23** + DOSBox (`ipxnet`, UDP 213) | monter MARS_NWE, connecter un client DOS par IPX sur UDP, exercer login/listage/écriture, relever chaque comportement visible | `docs/spec-netware-observee.md` rédigé, comportements listés sans invention | — | NON EXÉCUTÉ (compilation noyau requise, V-3) |
| T-15 | Découverte de services (esprit SAP) | un client trouve le serveur sans saisir son adresse | NexBSD avec mDNS/DNS-SD actif + poste client | annoncer le service, puis rechercher depuis un poste Windows/Linux | le service apparaît dans la liste du client en < 30 s | — | NON EXÉCUTÉ |
| T-10 | Interface petit écran | démontrer une UI navigable au clavier | phase 5 | lancer la coquille, naviguer uniquement au clavier, mesurer RAM et temps de lancement | navigation complète sans souris | — | NON EXÉCUTÉ |
| T-12 | Construction de la base | NexBSD construit sa propre image (phase 4bis) | profil L3, arbre source | `make buildworld` puis `buildkernel`, `release.sh` | image amorçable, build reproductible | — | NON EXÉCUTÉ (L3 indisponible) |
| T-13 | Frontière de licence | aucun code copyleft dans la base | arbre de base | recherche de `SPDX-License-Identifier: GPL` + revue | zéro occurrence non justifiée | — | À AUTOMATISER |
| T-11 | Reproductibilité | rejouer une construction | script de build | reconstruire depuis un état propre (`/build/obj2`) et comparer | résultat identique ou écarts expliqués | empreintes **identiques** (`82dc5681…`), 0 erreur, 6533 s | **RÉUSSI (2026-10-26)** — `tests/results/T-11-reproductibilite.md` |

## Harnais de tests automatisé (`tests/harnais.sh`)

**Créé le 2026-10-26** pour répondre au manque n° 2 de l'audit croisé (`docs/32`) : jusqu'ici, tous les
tests étaient des **protocoles manuels** recopiés à la main.

| Caractéristique | Valeur |
|---|---|
| Empreinte du fichier | **`ef46576c2fa67b485a587135e757553693dbb0f9c31b8336d8bec42618513c8d`** (v1.1, 267 lignes) — v1.0 : `bbf5d8de…` |
| Usage | `sh harnais.sh` (passe complète) · `sh harnais.sh --lecture` (sans écriture) · `--aide` |
| Contrôles | identité (5) · services (4) · annuaire (4) · NSS (3) · droits disque (2) · configuration Samba (3) · service réel (3) |
| Verdict | compteurs `OK` / `KO` / `ATT` + **code de retour** (0 = tout passe, 1 = au moins un échec) |
| Règle R-10 | un contrôle non applicable est compté **`ATT`**, jamais `OK` ; un outil absent est **`KO`** avec la raison |
| Prérequis | aucun : pas de redémarrage, pas d'installation ; écrit seulement dans `/tmp` |

**Résultat : v1.1 → `HARNAIS : REUSSI (24/24)`, code de retour 0** (2026-10-26T22:19:32Z).
**Historique :** v1.0 → **ECHEC 22/24** ; les 2 echecs etaient des **defauts du harnais** (`ls -ld` au lieu de
`ls -ldn` ; texte de `smbclient` au lieu du code de retour), pas du systeme. Compte rendu : `tests/results/T-18-harnais.md`.

---

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

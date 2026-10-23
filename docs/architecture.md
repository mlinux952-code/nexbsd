# Architecture cible — proposition

**Version :** 0.1 (squelette)
**Date :** 2026-10-23
**Statut :** `[PROPOSITION]` — aucune couche n'est implémentée. Ce document décrit une intention, pas un système existant.

---

## 1. Vue d'ensemble

```
┌──────────────────────────────────────────────────────────────────────┐
│ COUCHE E — Applications et administration                            │
│  outil d'admin · paramètres réseau · comptes · diagnostic · doc      │
├──────────────────────────────────────────────────────────────────────┤
│ COUCHE D — Services réseau                                          │
│  D-1 fichiers/impression (Samba, CUPS)                               │
│  D-2 annuaire et identités (OpenLDAP, éventuellement Kerberos)       │
│  D-3 protocoles historiques (REJETÉ — hors périmètre, labo isolé)   │
│  D-4 administration réseau · D-5 supervision et journaux             │
├──────────────────────────────────────────────────────────────────────┤
│ COUCHE C — Plateforme mobile (expérimentale, logicielle)             │
│  coquille UI · lanceur d'applications Web · navigation clavier       │
│  moteur Web (WebKitGTK) · permissions applicatives                   │
│  [non implémentée]                                                   │
├──────────────────────────────────────────────────────────────────────┤
│ COUCHE B — Services d'intégration                                    │
│  configuration · validation · journalisation · santé des services    │
│  scripts rc.d · isolation (jails) · interfaces entre modules         │
├──────────────────────────────────────────────────────────────────────┤
│ COUCHE A — Base système : FreeBSD 15.x (amd64) · UFS par défaut      │
│  noyau · pilotes · mémoire/processus · FS · réseau · comptes         │
└──────────────────────────────────────────────────────────────────────┘

           Cibles séparées :  [Lab]     [NetServer]     [MobileExp]
```

## 1bis. Les trois domaines de propriété (ADR-0011, ADR-0012)

```
NEXBSD APPS      code 100 % NexBSD        licence au choix (BSD-2 proposée)
NEXBSD PLATFORM  paquets séparés          GPL admis · sources publiées
NEXBSD BASE      arbre possédé, construit  licence permissive uniquement
                 par le projet
```

La base est **construite par le projet** (`src.conf`, `KERNCONF`, `release.sh`, `pkgbase`), pas installée depuis une image FreeBSD. Les composants GPL ne montent jamais dans la base (§ `docs/12-licences-et-frontieres.md`).

## 2. Rôle de chaque couche

### Couche A — Base système
**Fournie par FreeBSD, non modifiée.** Responsabilités : démarrage, noyau, pilotes, gestion mémoire/processus, systèmes de fichiers, réseau TCP/IP, comptes, sécurité de base, jail/bhyve.

Règle : **aucune modification du noyau** tant qu'une fonction n'est pas démontrée impossible avec les mécanismes existants.

### Couche B — Services d'intégration
C'est ici que NexBSD apporte sa valeur ajoutée, et **uniquement par du code/configuration propre** :

| Module | Rôle | Justification |
|---|---|---|
| `config` | format de configuration unique, validé avant application | évite les dérives entre services |
| `deps` | déclaration des dépendances entre services (démarrage ordonné) | évite les courses au démarrage |
| `health` | vérification de l'état réel de chaque service (pas seulement « processus vivant ») | nécessaire pour un retour arrière fiable |
| `log` | convention de journalisation (identifiant de service, rotation) | diagnostic |
| `isolation` | définition et gestion des jails et de leurs privilèges | sécurité |
| `rc` | scripts de démarrage FreeBSD (`rc.d`) | intégration native |
| `rollback` | retour à un état connu (snapshot/archive) | critère de réussite S-6 |

**Anti-pattern explicitement interdit :** créer une couche d'abstraction « générique » sans problème identifié. Chaque module ci-dessus doit résoudre un besoin listé dans `matrices/functions.csv`.

### Couche C — Plateforme mobile
**État : conceptuelle.** Décisions structurantes déjà prises par la recherche :

- le socle est un **moteur Web maintenu** (WebKitGTK), pas Gecko B2G ni Gonk ;
- les applications sont des **pages Web locales** avec manifeste et permissions déclaratives ;
- la navigation est **clavier/pavé directionnel**, pas tactile ;
- **aucune fonction téléphonie/SMS/capteurs** n'est promise (R-05).

Composants à concevoir : `shell` (écran d'accueil), `launcher`, `keynav` (mapping des touches), `permissions`, `settings`, `notifications` (P3).

### Couche D — Services réseau
- **D-1** Samba (fichiers), CUPS (impression) — *retenus, sous réserve de version*.
- **D-2** OpenLDAP — *retenu sous condition de disponibilité d'une version ≥ 2.6 sous FreeBSD*.
- **D-3** compatibilité NetWare historique — **rejetée** comme composant ; sujet de laboratoire isolé uniquement.
- **D-4** administration : interface NexBSD (à créer).
- **D-5** supervision : syslog/newsyslog + un superviseur léger.

### Couche E — Applications et administration
Outil d'administration unique (à concevoir), paramètres réseau, gestion des comptes, diagnostic, documentation accessible depuis le système.

### Couche F — Distribution et maintenance
Construction reproductible, génération d'images de test, mises à jour, sauvegarde/restauration, documentation des versions, procédure de retour arrière.

## 3. Flux de communication (intentions)

| Flux | De → Vers | Protocole / mécanisme | Notes de sécurité |
|---|---|---|---|
| Client SMB | poste client → jail `files` | TCP 445 (SMB3) | jail + `pf` ; pas d'exposition Internet |
| Authentification | Samba → annuaire | LDAP(S) / `tdbsam` local | LDAP en TLS ou socket Unix ; jamais en clair sur le LAN |
| Supervision | services → journal | syslog local | journaux protégés en écriture |
| Administration | outil d'admin → services | socket local / API restreinte | comptes dédiés, action journalisée |
| Applications Web | moteur Web → fichiers locaux | `file://` ou serveur local | permissions par application |
| Interface → système | shell → services | commandes privilégiées minimales | élévation explicite et journalisée |

## 4. Profils de cible

| Profil | Base | Services | UI | Statut |
|---|---|---|---|---|
| **`nexbsd-lab`** | FreeBSD 15.x, support externe | sshd, journaux | aucune | cible du prototype 1 — budget ≤ 128 Mo de RAM |
| **`nexbsd-net`** | FreeBSD 15.x, support externe ou VM | Samba, annuaire, sauvegarde | administration | phase 5 — budget ≤ 256 Mo |
| **`nexbsd-mobile`** | FreeBSD 15.x + moteur Web | local uniquement | coquille petit écran | phase 5+, logiciel seulement — budget ≤ 768 Mo |

Les trois images partagent la même base ; aucune n'embarque les autres. Cela découle d'ADR-0009 : un système pour PC faible ne peut pas être « tout à la fois » par défaut.

## 4bis. Chaîne de construction (cible, non opérationnelle)

| Étape | Commande / mécanisme | Prérequis |
|---|---|---|
| Source | `git clone https://git.FreeBSD.org/src.git` + branche `nexbsd/*` | projet |
| Configuration | `src.conf` (contenu) + `KERNCONF=NEXBSD_L1` (noyau allégé) | ADR-0009 |
| Construction | `make buildworld` / `make buildkernel` | profil **L3** |
| Image | `release/release.sh -c nexbsd/release.conf` | L3 |
| Base en paquets | `make packages` → dépôt `pkgbase` NexBSD | L3 |
| Plateforme | paquets épinglés + sources + notices | ADR-0012 |

**Aucune de ces étapes n'est exécutable aujourd'hui** (ADR-0010).

## 5. Décisions d'architecture déjà justifiées

| ID | Décision | Justification | Réf. |
|---|---|---|---|
| ADR-0001 | Base = FreeBSD 15.x amd64 | support long, licence permissive, écosystème serveur | ADR-0001 |
| ADR-0002 | KaiOS n'est ni base ni composant | propriétaire, blobs OEM, dépendance Linux/Android | ADR-0002 |
| ADR-0003 | Gecko B2G abandonné ; moteur Web = WebKitGTK | pas d'API d'intégration, dette de sécurité | ADR-0003 |
| ADR-0004 | MARS_NWE rejeté comme composant | IPX absent, code non maintenu, sécurité | ADR-0004 |
| ADR-0005 | Services isolés en jails, `pf` en refus par défaut | réduction de la surface d'attaque | ADR-0005 |
| ADR-0006 | Aucun noyau modifié en phase initiale | coût/bénéfice ; aucune fonction identifiée ne l'exige | ADR-0006 |
| ADR-0007 | Samba épinglé ≥ 4.23 | version par défaut non maintenue = risque de sécurité | ADR-0007 |
| ADR-0008 | Distinction stricte des 3 profils de cible | évite de promettre du mobile avec un PC de bureau | ADR-0008 |
| ADR-0011 | **Fork, pas surcouche** : arbre possédé, images propres | seule réponse à « système à part entière » | ADR-0011 |
| ADR-0012 | Base permissive / Plateforme copyleft | préserve la maîtrise du code de base | ADR-0012 |
| ADR-0013 | Mobile = code NexBSD sur WebKitGTK | Gaia inadapté, API disparues | ADR-0013 |
| ADR-0014 | IPX/NCP réimplémentés en espace utilisateur | seul chemin viable et licite | ADR-0014 |
| ADR-0015 | Identité = budget mesuré + réseau façon NetWare | différenciation réaliste | ADR-0015 |

## 6. Questions d'architecture ouvertes

1. ~~UFS ou ZFS ?~~ **tranché par ADR-0009 : UFS par défaut**, ZFS en option documentée pour les profils disposant de plus de RAM.
2. Un seul jail multi-services ou un jail par service ? (4 Go de RAM contraignent)
3. Annuaire : OpenLDAP seul, ou Samba AD ? (AD simplifie l'intégration Windows mais coûte cher en RAM)
4. Format de configuration propre à NexBSD : fichier unique, ou configuration par service versionnée ?
5. Comment exposer l'administration sans créer une surface d'attaque réseau supplémentaire ?

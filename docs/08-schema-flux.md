# Schéma des flux entre modules

**Version :** 1.0 — 2026-10-23
**Statut :** `[PROPOSITION]` — aucun de ces flux n'est implémenté ni testé.

---

## 1. Vue d'ensemble

```
                          ┌─────────────────────────────────────┐
   Réseau local isolé     │  NEXBSD — profil nexbsd-net         │
   (jamais Internet)      │                                     │
                          │   ┌───────────────────────────────┐ │
   ┌──────────┐  SMB3     │   │ jail « files »                │ │
   │ Client   │◄─────────►│   │  smbd (Samba >= 4.23)         │ │
   │ Windows/ │  TCP 445  │   └───────┬───────────────┬───────┘ │
   │ Linux/   │           │           │ (1) LDAP(S)   │ (2)     │
   │ macOS    │           │           ▼               ▼         │
   └──────────┘           │   ┌───────────────┐  ┌────────────┐ │
                          │   │ jail « ldap » │  │ volumes    │ │
   ┌──────────┐  NCP      │   │  slapd        │  │ (UFS)      │ │
   │ Client   │◄─────────►│   │  (OpenLDAP)   │  └────────────┘ │
   │ NCP      │  TCP/UDP  │   └───────┬───────┘                 │
   │ (test)   │    524    │           │ (3)                     │
   └──────────┘           │           ▼                         │
                          │   ┌───────────────────────────────┐ │
   ┌──────────┐  admin    │   │ outil d'administration NexBSD │ │
   │ Admin    │◄─────────►│   │  (N-08, à écrire)             │ │
   │ (local)  │ socket    │   └───────────┬───────────────────┘ │
   └──────────┘  local    │               │ (4)                 │
                          │               ▼                     │
                          │   ┌───────────────────────────────┐ │
                          │   │ Couche B — intégration        │ │
                          │   │ config · health · log · rc.d  │ │
                          │   │ isolation · rollback         │ │
                          │   └───────────┬───────────────────┘ │
                          │               │ (5)                 │
                          │               ▼                     │
                          │   ┌───────────────────────────────┐ │
                          │   │ Couche A — FreeBSD 15.x (UFS) │ │
                          │   │ noyau · réseau · pf · users   │ │
                          │   └───────────────────────────────┘ │
                          └─────────────────────────────────────┘
```

## 2. Description des flux

| # | Flux | Transport | Sécurité exigée | Test |
|---|---|---|---|---|
| 1 | Samba → annuaire (authentification, identités) | LDAP(S) sur socket interne de la jail | TLS ou socket Unix ; **jamais LDAP en clair sur le LAN** | T-04 |
| 2 | Samba → volumes de fichiers | UFS local, ACL | droits minimal, partages en lecture seule par défaut | T-03 |
| 3 | Outil d'admin → annuaire | LDAP(S) | compte technique dédié, journalisé | T-04 |
| 4 | Outil d'admin → services (état, démarrage) | socket local / commandes privilégiées minimales | élévation explicite, action journalisée | T-08 |
| 5 | Couche B → base système | `rc.d`, `pf`, `jail(8)` | configuration validée avant application | T-05 |
| 6 | Client SMB → Samba | TCP 445 (SMB3) | jail + `pf` en refus par défaut ; pas d'Internet | T-03 |
| 7 | Client NCP → implémentation NexBSD (à venir) | TCP/UDP **524** (+ SLP 472) | banc de test isolé uniquement | T-09 |
| 8 | Tous services → journaux | syslog local | journaux en écriture restreinte, rotation | T-05 |

## 3. Frontières

| Frontière | Ce qui la traverse | Ce qui ne la traverse jamais |
|---|---|---|
| Internet ↔ NexBSD | **rien** | aucun service (règle R-13) |
| LAN ↔ jail | les ports déclarés uniquement | accès direct aux volumes, shell |
| jail ↔ jail | sockets explicitement autorisés | accès fichiers arbitraire |
| Base (permissive) ↔ Plateforme (GPL) | **paquets et processus séparés**, jamais de lien | code GPL lié ou copié (ADR-0012) |
| Utilisateur ↔ système | élévation explicite et journalisée | root par défaut |

## 4. Ce que ce schéma ne dit pas

- Aucun débit, aucune latence : **aucune mesure n'a été faite**.
- Aucun de ces flux n'existe : le schéma décrit une **intention architecturale**.
- L'implémentation NCP (flux 7) est un **chantier de recherche** (ADR-0018/0019), pas une fonctionnalité acquise.

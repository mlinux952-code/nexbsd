# Registre des décisions architecturales (ADR)

| ID | Sujet | Statut | Date |
|---|---|---|---|
| [ADR-0001](ADR-0001-base-freebsd.md) | Base système = FreeBSD 15.x amd64 | proposition | 2026-10-23 |
| [ADR-0002](ADR-0002-kaios-rejete.md) | KaiOS rejeté comme base/composant | proposition | 2026-10-23 |
| [ADR-0003](ADR-0003-moteur-web.md) | Gecko B2G abandonné ; WebKitGTK retenu | proposition | 2026-10-23 |
| [ADR-0004](ADR-0004-mars-nwe-rejete.md) | MARS_NWE rejeté comme composant | proposition | 2026-10-23 |
| [ADR-0005](ADR-0005-isolation.md) | Jails + `pf` en refus par défaut | proposition | 2026-10-23 |
| [ADR-0006](ADR-0006-pas-de-noyau-modifie.md) | Aucune modification du noyau en phase initiale | proposition | 2026-10-23 |
| [ADR-0007](ADR-0007-samba-version.md) | Samba épinglé ≥ 4.23 | proposition | 2026-10-23 |
| [ADR-0008](ADR-0008-profils-separes.md) | Trois profils de cible séparés | proposition | 2026-10-23 |
| [ADR-0009](ADR-0009-cible-pc-faible.md) | Le PC faible est la cible de conception (budget de ressources) | proposition | 2026-10-23 |
| [ADR-0010](ADR-0010-pas-de-compilation-sur-poste-faible.md) | Aucune compilation lourde sur postes faibles ; report au profil L3 | proposition | 2026-10-23 |
| [ADR-0011](ADR-0011-fork-pas-surcouche.md) | **NexBSD est un fork (arbre possédé), pas une surcouche** | proposition | 2026-10-23 |
| [ADR-0012](ADR-0012-frontiere-base-plateforme.md) | Frontière stricte Base / Plateforme : aucun GPL dans la base | proposition | 2026-10-23 |
| [ADR-0013](ADR-0013-mobile-code-propre.md) | Couche mobile = code NexBSD sur WebKitGTK ; Gaia = inspiration | proposition | 2026-10-23 |
| [ADR-0014](ADR-0014-ipx-ncp-reecriture.md) | IPX/NCP : réimplémentation propre en espace utilisateur (recherche) | proposition | 2026-10-23 |
| [ADR-0015](ADR-0015-identite-produit.md) | Identité = budget PC faible mesuré + fonctions réseau | proposition | 2026-10-23 |
| [ADR-0016](ADR-0016-publication-grand-public.md) | Objectif de publication grand public, conditionné à 10 portes | proposition | 2026-10-23 |
| [ADR-0017](ADR-0017-reseau-axe-prioritaire.md) | **Le réseau est l'axe prioritaire ; les 4 composants ont chacun un rôle** | proposition | 2026-10-23 |
| [ADR-0018](ADR-0018-ncp-sur-ip.md) | Cible protocolaire = NCP sur UDP/TCP 524 (révise ADR-0014) | proposition | 2026-10-23 |
| [ADR-0019](ADR-0019-client-test-ncp.md) | Client de test NCP = Client for Open Enterprise Server (usage externe) | proposition | 2026-10-23 |

**Aucune décision n'est validée à ce jour.** Le passage à `accepté` exige une validation explicite du responsable du projet, consignée dans un compte rendu de session.

## Format d'un ADR

- Problème
- Options étudiées
- Avantages / inconvénients
- Décision (proposée, puis validée)
- Justification
- Conséquences
- Conditions de révision

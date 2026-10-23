# Fiche de recherche — OpenLDAP (annuaire centralisé)

**Date de vérification :** 2026-10-23
**Statut :** candidat `En étude` → **proposition : `Retenu pour prototype`**
**Rôle visé :** Couche D-2 (annuaire, identités, groupes, contrôle d'accès)

---

## 1. Faits vérifiés

| Point | Fait | Source |
|---|---|---|
| Version *feature release* courante | **OpenLDAP 2.7.1** (8 septembre 2026) ; 2.7.0 le 6 août 2026 | ftp.openldap.org ; openldap.org |
| Version **LTS** | **2.6.15** (8 septembre 2026) ; 2.6 promu LTS depuis janvier 2025, durée de vie prévue ~5 ans | openldap.org ; openldap-announce |
| Ancienne LTS | 2.5 : fin de vie, correctifs critiques jusqu'au **15 janvier 2027** | annonce officielle |
| Licence | **OpenLDAP Public License** (licence permissive de type BSD, propre au projet) | Wikipédia |
| Port FreeBSD vérifié | `net/openldap25-server` 2.5.20 (mainteneur `delphij@`) | FreshPorts |
| Port FreeBSD 2.6/2.7 | **non trouvé lors de la vérification** | `[À VÉRIFIER]` |
| Fonctions | `slapd`, `lloadd` (répartition de charge), overlays (ppolicy, syncprov, accesslog), réplication syncrepl | openldap.org (roadmap, changes) |
| Incident notable | Symas a **retiré ses paquets 2.6.15** le 17 septembre 2026 après des rapports de corruption mémoire de `slapd` avec `syncprov`/`accesslog` (ITS#10591, ITS#10597) | GitHub intechcore/openldap (rapport tiers) `[À VÉRIFIER — source secondaire]` |

## 2. Points favorables

- Standard de fait pour un annuaire LDAP libre ; licence permissive (facile à intégrer dans une architecture mixte).
- Modèle de données éprouvé : utilisateurs, groupes, politiques de mot de passe (ppolicy), ACL fines, TLS.
- S'intègre à Samba (authentification), à la plupart des systèmes d'exploitation et des applications.
- Réplication disponible (syncrepl) si le projet grandit.

## 3. Risques et points de vigilance

| ID | Risque | Gravité | Mitigation |
|---|---|---|---|
| LD-1 | **Aucun port 2.6/2.7 confirmé sous FreeBSD** : risque de devoir compiler ou d'utiliser une version 2.5 bientôt en fin de vie | **élevée** | vérifier `pkg search openldap` et la branche ports au 2026Q4 avant décision ; prévoir compilation `poudriere` hors machine cible si nécessaire |
| LD-2 | Incident de corruption mémoire signalé sur 2.6.15 (overlays syncprov/accesslog) | moyenne | ne pas utiliser ces overlays en production ; préférer 2.6.13/2.6.16+ ou 2.7.x selon disponibilité `[À VÉRIFIER]` |
| LD-3 | Complexité opérationnelle (schémas, ACL, sauvegardes) sous-estimée par un non-spécialiste | moyenne | procédures pas à pas dans `docs/`, tests de restauration obligatoires |
| LD-4 | Exposition réseau non chiffrée (LDAP simple = mots de passe en clair) | **élevée** | imposer `slapd` sur localhost/jail + TLS ou LDAPI ; jamais de LDAP clair sur le LAN |
| LD-5 | Confusion avec un annuaire Windows complet (AD) | moyenne | documenter les écarts de modèle (pas de GPO, pas de Kerberos intégré par défaut) |

## 4. Incertitudes

- Version réellement installable sous FreeBSD 15.1 aujourd'hui `[À VÉRIFIER — bloquant pour l'étape S1]`.
- Comportement mémoire de `slapd` sur 4 Go avec MDB `[À VÉRIFIER par mesure]`.
- Périmètre exact des options de compilation du port FreeBSD `[À VÉRIFIER]`.

## 5. Recommandation

**Retenir OpenLDAP**, sous conditions :

1. Vérifier d'abord la version disponible sous FreeBSD (`pkg search -x openldap`) ; si seule 2.5 est disponible et qu'aucun port 2.6 n'existe, **ne pas s'engager** sur LDAP avant d'avoir un plan de compilation ou une décision alternative (par exemple : comptes locaux FreeBSD + Samba `tdbsam` pour le prototype 1, LDAP en prototype 2).
2. Utiliser la version **LTS 2.6.x** de préférence à la 2.7 (feature release) pour un projet expérimental.
3. Déployer en jail, écoute restreinte, TLS obligatoire si accès distant.
4. Ne jamais stocker de mots de passe en clair ni de secrets dans le dépôt.

## 6. Sources

| # | Source | URL | Consultée le |
|---|---|---|---|
| 1 | OpenLDAP Download (2.7.1 feature, 2.6.15 LTS) | https://ftp.openldap.org/software/download/ | 2026-10-23 |
| 2 | OpenLDAP Release Road Map | https://www.openldap.org/software/roadmap.html | 2026-10-23 |
| 3 | OpenLDAP — Changes 2.7.1 | https://www.openldap.org/software/release/changes.html | 2026-10-23 |
| 4 | Annonce LTS 2.6 / fin de vie 2.5 | https://www.mail-archive.com/openldap-announce@openldap.org/msg00125.html | 2026-10-23 |
| 5 | FreshPorts — net/openldap25-server | https://www.freshports.org/net/openldap25-server/ | 2026-10-23 |
| 6 | Wikipédia — OpenLDAP (licence) | https://en.wikipedia.org/wiki/OpenLDAP | 2026-10-23 |
| 7 | Rapport tiers — retrait des paquets 2.6.15 (ITS#10591/10597) | https://github.com/intechcore/openldap/releases | 2026-10-23 |

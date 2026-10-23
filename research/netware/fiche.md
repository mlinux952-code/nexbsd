# Fiche de recherche — NetWare (modèle fonctionnel des services réseau)

**Date de vérification :** 2026-10-23
**Statut :** modèle de référence → **proposition : `Retenu comme modèle fonctionnel`, `Rejeté comme composant logiciel`**
**Rôle visé :** Couche D — identités, droits, partages, impression, administration centralisée

---

## 1. Faits vérifiés / établis

| Point | Fait | Source |
|---|---|---|
| Code source | NetWare est un logiciel **propriétaire** de Novell ; le code source n'est pas public | constat général, cohérent avec l'historique Novell/Micro Focus |
| Protocoles historiques | **IPX/SPX** (transport), **NCP** (NetWare Core Protocol), SAP (découverte de services), RIP (routage IPX), bindery (annuaire NetWare 2/3), **NDS** (annuaire hiérarchique NetWare 4+) | documentation MARS_NWE, zx.net.nz |
| Successeur commercial | Novell Open Enterprise Server (services fichiers/annuaire sur Linux) — non étudié ici `[À VÉRIFIER]` | — |
| IPX dans les noyaux modernes | **retiré de Linux 4.17** (2018) et **retiré de FreeBSD 11.0** (2016) | README MARS_NWE ; release notes FreeBSD 11.0 |
| Clients | clients DOS/Windows 3.x historiques (Client32 v2.71, 1999) ; clients Mac nécessitant NDS | README MARS_NWE |

## 2. Fonctions à reproduire — et ce qu'elles veulent dire aujourd'hui

| # | Fonction NetWare historique | Équivalent moderne disponible sous FreeBSD | Écart |
|---|---|---|---|
| N-1 | Volumes et partages hiérarchiques | Samba (SMB3), ZFS/UFS | mineur (sémantique des chemins, pas des droits) |
| N-2 | Droits par répertoire/fichier + « trustees » (héritage) | ACL POSIX/ZFS + ACL Samba | **moyen** : le modèle NetWare est plus simple et plus lisible |
| N-3 | Bindery (utilisateurs, groupes, objets) | OpenLDAP | moyen (modèle de données différent) |
| N-4 | NDS (annuaire hiérarchique, réplication) | OpenLDAP + syncrepl | moyen à élevé |
| N-5 | Authentification unique au réseau | Kerberos/LDAP (via Samba AD ou MIT Kerberos) | **élevé** : la « single sign-on » NetWare est très intégrée au poste client |
| N-6 | Scripts de login (mapping de lecteurs, imprimantes) | GPO Samba / scripts de connexion | moyen |
| N-7 | Services d'impression partagés | CUPS + CUPS/Samba | faible |
| N-8 | Administration centralisée (SYSCON) | outil d'administration NexBSD (à créer) | **élevé** : rien d'équivalent clé en main |
| N-9 | Supervision et journaux | syslog/rsyslog, `newsyslog`, monit | faible |
| N-10 | Découverte de services (SAP) | mDNS/DNS-SD | conceptuellement proche, protocole différent |
| N-11 | **Compatibilité NCP/IPX avec clients existants** | **Aucune** sous FreeBSD (IPX retiré) | **rédhibitoire sans travail lourd** |

## 3. Conclusion structurante

Il faut distinguer deux choses que le concept initial mélange :

- **(a) Le modèle fonctionnel** — « des identités, des droits, des partages, une administration unique » : parfaitement atteignable avec Samba + OpenLDAP + outillage propre. C'est ce que NexBSD doit viser.
- **(b) La compatibilité protocolaire historique** — parler NCP sur IPX à un client DOS/Windows 3.11 : **impossible nativement sous FreeBSD**, coûteux et risqué ailleurs.

> **Une solution qui partage des fichiers avec Windows n'est pas « compatible NetWare ».** NexBSD ne doit jamais employer cette expression pour désigner Samba.

## 4. Risques

| ID | Risque | Gravité |
|---|---|---|
| NW-1 | Confusion marketing/technique entre modèle fonctionnel et compatibilité protocolaire | élevée |
| NW-2 | Investir dans IPX/NCP alors que le parc de clients historiques est quasi inexistant | élevée |
| NW-3 | Exposer un service historique non maintenu sur un réseau non isolé | critique (sécurité) |
| NW-4 | Réimplémenter NCP à partir de spécifications non libres sans analyse juridique | moyenne |

## 5. Recommandation

1. **Retenir le modèle fonctionnel** (tableau §2, lignes N-1 à N-10) comme cahier des charges de la Couche D.
2. **Reporter sine die** la compatibilité NCP/IPX ; la traiter uniquement comme sujet de recherche en laboratoire isolé (voir `research/mars-nwe/fiche.md`).
3. Ne jamais qualifier Samba de « compatible NetWare » ; utiliser « services de fichiers inspirés des fonctions NetWare ».
4. Vérifier les questions de marque avant toute communication (NetWare et Novell sont des marques de tiers).

## 6. Incertitudes

- L'état exact de la documentation publique des protocoles NCP/IPX (disponibilité de spécifications) n'a pas été vérifié `[À VÉRIFIER]` — nécessaire avant toute velléité de réimplémentation.
- L'existence éventuelle de clients NetWare encore utilisés en production n'a pas été mesurée ; sans utilisateurs réels, la priorité de N-11 est nulle.

## 7. Sources

| # | Source | URL | Consultée le |
|---|---|---|---|
| 1 | MARS_NWE README (protocoles, clients, dépendances) | https://github.com/davidrg/mars_nwe | 2026-10-23 |
| 2 | zx.net.nz — MARS_NWE notes (NCP, NDS, NetWare/IP) | https://www.zx.net.nz/netware/server/mars.shtml | 2026-10-23 |
| 3 | FreeBSD 11.0 Release Notes (retrait IPX) | https://www.freebsd.org/releases/11.0R/relnotes/ | 2026-10-23 |
| 4 | Wikipédia — IPX/SPX (retrait Linux 4.17) | https://en.wikipedia.org/wiki/IPX/SPX | 2026-10-23 |

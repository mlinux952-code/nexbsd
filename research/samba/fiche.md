# Fiche de recherche — Samba (partage de fichiers et d'imprimantes)

**Date de vérification :** 2026-10-23
**Statut :** candidat `En étude` → **proposition : `Retenu pour prototype`** (avec réserve de version)
**Rôle visé :** Couche D-1 (services modernes de fichiers et d'impression)

---

## 1. Faits vérifiés

| Point | Fait | Source |
|---|---|---|
| Dernière version stable | **Samba 4.25.0** (24 septembre 2026) ; séries maintenues : 4.24.8 (12 oct. 2026), 4.23.13 (1er oct. 2026) | samba.org/samba/history |
| Séries maintenues | 4.23 et 4.24 ; **4.22 en fin de vie** (annoncée avec 4.23.13) | linuxcompatible.org ; samba.org |
| Licence | **GPL-3.0-or-later** (port FreeBSD : `GPLv3+`) | FreshPorts net/samba419 |
| Ports FreeBSD existants | `samba416` (**défaut**), `samba419` (déprécié), `samba420` (déprécié), `samba422`, `samba423` | FreshPorts / cgit ports |
| Statut des versions anciennes | `samba419` et `samba420` marqués **DEPRECATED** (« Discontinued upstream ») | FreshPorts |
| Version par défaut du port | encore **4.16** dans `Mk/bsd.default-versions.mk` (constat 2025) ; 4.16 **n'est plus maintenu en amont** | forums.freebsd.org ; NetFence (juillet 2026) |
| Sécurité | vagues de CVE : 4.23.11 (3 août 2026) corrige 5 CVE ; 4.23.13 corrige 7 bugs dont une lecture hors bornes | linuxcompatible.org |
| Fonctions | SMB2/SMB3, partages fichiers, impression, AD DC, intégration annuaire, VFS | samba.org |
| Changements 4.24 | chiffrement renforcé, PKINIT key trust, mapping de certificats, `vfs_streams_xattr` | linuxteck.com (à confirmer sur les notes officielles) |

## 2. Points favorables

- Fonctionne et est packagé sous FreeBSD depuis des décennies ; maintenu par une équipe de ports dédiée (`samba@FreeBSD.org`).
- SMB3 : chiffrement en transit, signature, ACL riches — de quoi construire une Couche D crédible.
- Interopère avec Windows, macOS, Linux et Android/iOS (via applications SMB).
- Peut servir d'annuaire (AD DC) ou s'adosser à OpenLDAP — deux scénarios à comparer.

## 3. Risques vérifiés

| ID | Risque | Gravité | Mitigation |
|---|---|---|---|
| SM-1 | Le port par défaut (`samba416`) correspond à une version **non maintenue** → vulnérabilités connues (cf. CVE-2023-42670, CVE-2018-14628 citées par NetFence) | **élevée** | installer explicitement `net/samba423` (ou 4.25 quand le port existera), ne jamais se fier au paquet `samba` par défaut |
| SM-2 | Samba est un logiciel **GPLv3** : toute redistribution d'un système l'incluant doit respecter les obligations GPLv3 (code source, notices, pas de restriction additionnelle) | moyenne | séparer Samba du code propre NexBSD ; inventaire SBOM |
| SM-3 | Surface d'attaque large (démon réseau exposé) | élevée | jail dédiée, `pf`, pas d'exposition Internet, comptes dédiés |
| SM-4 | Consommation mémoire sur 4 Go avec d'autres services | moyenne | mesurer (test T-03), limiter les processus, éviter AD DC complet sur cette machine |
| SM-5 | Confusion « Samba = NetWare » | élevée (technique) | cf. `research/netware/fiche.md` §3 |

## 4. Incertitudes

- Existence et version exacte d'un port `samba424`/`samba425` dans l'arbre des ports au 2026Q4 `[À VÉRIFIER]`.
- Comportement de Samba 4.23 sous FreeBSD 15.1 sur disque mécanique (performance) `[À VÉRIFIER par mesure]`.
- Le support AD DC complet sur 4 Go de RAM est douteux ; à mesurer avant toute promesse `[À VÉRIFIER]`.

## 5. Recommandation

**Retenir Samba** comme service de fichiers principal du prototype, avec quatre règles :

1. **Épingler explicitement la version** (≥ 4.23) et la consigner dans `matrices/components.csv`.
2. Déployer en **jail dédiée**, utilisateur non privilégié, aucun accès Internet.
3. Démarrer en **serveur de fichiers simple** (pas de DC Active Directory) pour le premier prototype.
4. Documenter la licence GPLv3 dans la matrice des licences et prévoir la fourniture des sources correspondantes en cas de redistribution.

## 6. Sources

| # | Source | URL | Consultée le |
|---|---|---|---|
| 1 | Samba Release History (4.25.0, 4.24.8, 4.23.13) | https://www.samba.org/samba/history/ | 2026-10-23 |
| 2 | Samba Latest News | https://www.samba.org/samba/latest_news.html | 2026-10-23 |
| 3 | FreshPorts — net/samba419 (licence GPLv3+, déprécié) | https://www.freshports.org/net/samba419 | 2026-10-23 |
| 4 | FreshPorts — net/samba420 (déprécié) | https://www.freshports.org/net/samba420 | 2026-10-23 |
| 5 | NetFence — Samba on FreeBSD (versions disponibles, CVE) | https://www.netfence.it/sub/sambaonfreebsd/ | 2026-10-23 |
| 6 | linuxcompatible.org — 4.23.13 (fin de vie 4.22) | https://www.linuxcompatible.org/story/samba-42313-release-7-bug-fixes-as-422-series-hits-endoflife | 2026-10-23 |

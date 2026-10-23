# Fiche de recherche — MARS_NWE (candidat de compatibilité NetWare historique)

**Date de vérification :** 2026-10-23
**Statut :** candidat `En étude` → **proposition : `Rejeté comme composant intégré`, `Retenu comme référence technique en laboratoire isolé`**
**Rôle visé :** Couche D-3 (compatibilité protocoles historiques)

---

## 1. Faits vérifiés

| Point | Fait | Source |
|---|---|---|
| Nature | Émulateur de serveur NetWare pour Linux, par Martin Stover | README davidrg/mars_nwe |
| Licence | **GPL-2.0** (dépôt et emballages de distribution) | github.com/davidrg/mars_nwe ; Repology |
| Dernière version de l'auteur | **0.99.pl20, 1er septembre 2000** | README |
| Versions suivantes | pl21 (Koan Software, ~2003), pl22 (2012), pl23 (**5 novembre 2013**) | README |
| Activité publique depuis | **aucune activité significative depuis 2013** | README |
| Fonctions | services **fichiers**, **bindery**, **impression**, **routage IPX (RIP/SAP)** | README |
| Limites | sous-ensemble des appels NCP d'un serveur NetWare 3.11 ; **pas de NDS** ; **pas de NetWare/IP ni NCP sur IP natif** → **IPX obligatoire** | zx.net.nz |
| Dépendance critique | **module noyau IPX hors arbre** requis pour Linux > 4.17 (`github.com/pasis/ipx`) | README |
| Sécurité | avertissement explicite de l'auteur du dépôt : « **THERE WILL BE SECURITY VULNERABILITIES** » ; appels fichiers en **root** depuis pl9 pour gérer les trustees ; usage recommandé : **réseau privé uniquement** | README |
| Contournement de SYSCON | pas d'équivalent ; utilitaires Novell nécessitent une licence NetWare 3 | README |

## 2. Analyse de portabilité vers FreeBSD

| Verrou | Détail | Coût |
|---|---|---|
| **Absence d'IPX** | FreeBSD a retiré IPX en 11.0. MARS_NWE n'ouvre pas de sockets IPX génériques : il s'appuie sur la pile IPX du noyau pour émettre/recevoir. Sans pile, rien ne fonctionne. | **Élevé** : soit réintroduire une pile IPX noyau (code mort depuis 10 ans, MPSAFE à maintenir), soit implémenter IPX en espace utilisateur via `bpf`/sockets bruts — travail de développement significatif et hors périmètre d'un projet de documentation |
| **API Linux** | code écrit pour Linux années 90 : `sys/ioctl` spécifiques, gestion `gdbm`, scripts SysV | Moyen |
| **Sécurité** | exécution root + code non maintenu + protocole non authentifié par défaut | **Critique** |
| **Maintenance** | personne ne maintient ; licence GPL-2.0 implique redistribution des modifications | Élevé (charge) |
| **Valeur** | clients visés : DOS/Windows 3.11, OS/2 — population quasi inexistante | Faible |

**Conclusion : un portage de MARS_NWE vers FreeBSD n'est pas raisonnable dans le périmètre actuel du projet.** Le rapport coût/valeur est très défavorable, et il contredirait la politique de sécurité (PARTIE XI du méga-prompt).

## 3. Ce qui reste utile

| Usage | Faisabilité | Valeur |
|---|---|---|
| **Laboratoire de référence** : une VM Linux (Debian/Ubuntu) + module IPX hors arbre + un client DOS dans 86Box/DOSBox, sur un réseau **isolé sans passerelle** | réalisable, coût modéré | documenter précisément *ce que fait réellement* un serveur NetWare (bindery, trustees, scripts de login), et servir de banc de comparaison pour l'outillage NexBSD |
| **Lecture du code** comme spécification de fait des appels NCP | réalisable | nourrit la spécification fonctionnelle (Couche D) |
| **Réutilisation du code** dans NexBSD | **non recommandée** | licence GPL-2.0 + sécurité + non-maintenance |

## 4. Décision proposée

- Statut **`Rejeté comme composant intégré`**.
- Statut **`Référence technique`** : une expérience de laboratoire isolée peut être planifiée en P3, uniquement si le responsable du projet la juge instructive.
- **Interdiction** : ne jamais connecter un tel laboratoire au réseau domestique/Internet ; ne jamais stocker de données réelles sur un volume MARS_NWE.

## 5. Incertitudes

- Le fonctionnement effectif de MARS_NWE 0.99.pl23 avec le module IPX moderne n'a **pas été testé par nous** `[À VÉRIFIER par expérience]`.
- La disponibilité d'un client DOS utilisable dans un émulateur n'a pas été vérifiée `[À VÉRIFIER]`.
- Les droits de redistribution des utilitaires Novell « Client Kit » ne sont pas clairs `[À VÉRIFIER — juridique]`.

## 6. Sources

| # | Source | URL | Consultée le |
|---|---|---|---|
| 1 | README du dépôt davidrg/mars_nwe (statut, limites, sécurité, module IPX) | https://github.com/davidrg/mars_nwe | 2026-10-23 |
| 2 | zx.net.nz — MARS_NWE Notes (NCP partiel, pas de NDS, IPX requis) | https://www.zx.net.nz/netware/server/mars.shtml | 2026-10-23 |
| 3 | Repology — mars-nwe (licence GPL, versions pl23/pl25) | https://repology.org/project/mars-nwe/versions | 2026-10-23 |
| 4 | Site historique (dernière version 0.99.pl20, 2000) | http://www.compu-art.de/mars_nwe/ | 2026-10-23 |
| 5 | Module IPX hors arbre pour Linux > 4.17 | https://github.com/pasis/ipx | 2026-10-23 |

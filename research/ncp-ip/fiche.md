# Fiche de recherche — NCP sur IP : viabilité du chemin protocolaire

**Date de vérification :** 2026-10-23
**Statut :** `RECHERCHE` — répond aux questions V-1, V-2, V-3 soulevées dans `docs/14-reseau-netware.md` §6
**Conclusion :** **le chemin protocolaire est VIABLE et testable.** Un client NCP réel, maintenu et gratuit, existe en 2026.

---

## 1. Les trois questions posées

| # | Question | Réponse (2026-10-23) |
|---|---|---|
| **V-1** | Existe-t-il un client NCP sur port 524 utilisable pour tester ? | **OUI** — voir §2. C'est la découverte majeure de cette fiche. |
| **V-2** | La documentation publique des NCP est-elle suffisante ? | **PARTIELLEMENT** — documentation développeur Novell publiée, complétude à établir (§3). |
| **V-3** | Le montage MARS_NWE + IPX + DOSBox est-il faisable ? | **PROBABLEMENT OUI** — modules tiers maintenus, émulation IPX-sur-UDP existante (§4). |

---

## 2. V-1 : le client de test — **il existe, et il est actuel**

| Point | Fait vérifié | Source |
|---|---|---|
| Produit | **Client for Open Enterprise Server** (ex-« Novell Client »), édité par **OpenText** (qui a absorbé Micro Focus) | novell.com/documentation/windows_client ; marketplace.opentext.com |
| Versions publiées | **26.2.1 (11 août 2026)**, 25.4.1 (17 février 2026), 2 SP7, documentation 25.3 | marketplace.opentext.com |
| Protocole | « The Client supports Micro Focus's **traditional NCP protocol** » | novell.com (doc client) |
| Évolutions récentes | NCP Encryption avec **TLS 1.3** sur Windows 11+ | marketplace.opentext.com |
| Port | NCP = **524/tcp et udp** ; SLP = 472 | support.microfocus.com (ports NetWare 6.5), communauté OpenText |
| Mise à jour 2026 | Le client est **maintenu** (versions datées de 2025-2026) | marketplace.opentext.com |

**Ce que cela change :** il est possible de valider une implémentation NCP avec un **client authentique et à jour**, sur une machine Windows. On n'est plus dans le « on ne pourra jamais tester ».

**Limites et précautions :**
- Le client est **propriétaire** (téléchargement gratuit, code fermé). Il est utilisé **uniquement comme outil de test externe**, jamais intégré, jamais distribué avec NexBSD. Cela ne pose pas de problème de licence : c'est un banc de mesure, pas un composant.
- Il exige une machine **Windows** — à prévoir dans le laboratoire (une VM Windows suffit).
- La version 26.x cible des Windows récents ; la version compatible Windows 7 (Client 2 SP4/SP5) existe mais est ancienne. `[À VÉRIFIER : version exacte compatible avec la cible du laboratoire]`.

---

## 3. V-2 : la documentation des NCP

| Point | Fait vérifié | Source |
|---|---|---|
| Novell a publié un **SDK « NetWare Core Protocols »** listant les NCP par numéro et leur sémantique | oui | beta.novell.com/developer/ndk/netware_core_protocols.html ; novell.com/documentation/developer/ncp/ |
| NCP sur TCP/IP : **port 524**, TCP et UDP ; dépend de **SLP** pour la résolution de noms | oui | Wikipédia (NCP) ; doc Novell « NetWare Over TCP/IP » |
| NCP sur IPX : type de paquet **17**, socket client **0x4003**, socket serveur **0x0451** | oui | HandWiki / Wikipédia (NCP) |
| Le protocole est **documenté fonctionnellement** (chaque NCP = une opération : créer, supprimer, lister, droits, bindery…) | oui | doc NDK, doc ZENworks (« an NCP exists for every service ») |
| Complétude de la documentation pour une réimplémentation complète | **INCONNUE** | `[À VÉRIFIER]` — la sémantique fine (structures exactes, codes d'erreur) n'est pas garantie |

**Conséquence :** on peut viser un **sous-ensemble** documenté (login, attach, map, lecture/écriture, bindery) sans prétendre à l'exhaustivité. Le risque n'est pas « on ne sait rien », c'est « on ne sait pas tout ».

---

## 4. V-3 : le laboratoire MARS_NWE

| Brique | Disponibilité vérifiée | Source |
|---|---|---|
| MARS_NWE 0.99.pl23 | sources GPL-2, cmake | github.com/davidrg/mars_nwe |
| Module IPX pour Linux ≥ 4.18 | `pasis/ipx` (+ `pasis/ipx-utils`) | github.com/pasis/ipx |
| Module ncpfs hors arbre (client Linux) | `EnzephaloN/ncpfs-module` (DKMS) | github.com/EnzephaloN/ncpfs-module |
| ncpfs dans le noyau Linux | **retiré en 4.17** ; paquet retiré de Debian | man7.org filesystems(5) ; Debian #466150 |
| Client DOS dans un émulateur | **DOSBox émule IPX sur UDP** (`ipxnet startserver`/`connect`, port 213) | DOSBoxWiki, manuel DOSBox, DOSBox-X |
| Passerelle IPX réel ↔ DOSBox | `ipxgw` | github.com/ksalin/ipxgw |

**Conclusion :** le montage est faisable, avec deux réserves :
1. il faut **compiler un module noyau hors arbre** (IPX) — donc une VM Linux, pas le poste faible ;
2. le client ncpfs est **IPX-only** : il ne servira pas à tester NCP sur 524. Pour le port 524, c'est le client OpenText (§2) qui sert.

---

## 5. Ce que cela permet, concrètement : deux bancs distincts

### Banc A — « comportement NetWare » (IPX, laboratoire isolé)
```
VM Linux (isolée, sans passerelle)
  ├── module IPX (pasis/ipx) + MARS_NWE 0.99.pl23
  └── DOSBox + client DOS ──(IPX sur UDP 213)──┘
But : observer login, trustees, scripts de connexion, arborescence SYS:
Livrable : docs/spec-netware-observee.md
```

### Banc B — « protocole NCP sur IP » (port 524)
```
VM Windows
  └── Client for Open Enterprise Server 26.x
        │ NCP sur TCP/UDP 524 (+ SLP 472)
        ▼
  NexBSD (à venir) implémentant un sous-ensemble NCP
But : prouver qu'un client réel dialogue avec notre implémentation
Livrable : rapport de test T-09
```

**Le banc B est le vrai jalon de différenciation** : c'est lui qui rendra crédible l'affirmation « NexBSD parle NCP ». Et il est **accessible sans attendre L3** (une VM Windows + un client gratuit suffisent), même si l'implémentation, elle, demandera du travail.

---

## 6. Périmètre proposé pour le sous-ensemble NCP (borné)

| # | Opération | Pourquoi | Difficulté estimée |
|---|---|---|---|
| NCP-1 | `login` / `attach` au serveur | porte d'entrée de tout client | moyenne |
| NCP-2 | `map` d'un volume (connexion de lecteur) | sans cela, aucun usage réel | moyenne |
| NCP-3 | lecture / écriture de fichier | cœur du service de fichiers | élevée (Burst Mode) |
| NCP-4 | listing de répertoire | usage courant | moyenne |
| NCP-5 | droits de fichier (trustees, lecture) | identité du modèle NetWare | moyenne |
| NCP-6 | bindery simple (utilisateurs, groupes) | sans NDS | moyenne |
| — | impression, NDS/eDirectory, Burst Mode complet, chiffrement NCP | **hors périmètre initial** | — |

**Règle de dérive (R-20) :** si NCP-1 à NCP-3 ne fonctionnent pas dans un délai raisonnable, le chantier est **suspendu et documenté**, pas étendu.

---

## 7. Décision proposée (ADR-0019)

1. **Le chemin protocolaire est maintenu en P3**, avec une cible claire : un sous-ensemble NCP-1→NCP-6 sur UDP/TCP 524.
2. **Client de test officiel : Client for Open Enterprise Server (OpenText)**, utilisé **uniquement** comme outil externe de validation, jamais distribué ni intégré.
3. **Deux bancs d'essai distincts** (IPX pour le comportement, port 524 pour le protocole).
4. **Aucune promesse publique** de compatibilité avant un rapport de test réussi avec le client réel.

## 8. Sources

| # | Source | URL | Consultée le |
|---|---|---|---|
| 1 | Client for Open Enterprise Server (versions 26.2.1, 25.4.1) | https://marketplace.opentext.com/appdelivery/content/client-for-open-enterprise-server | 2026-10-23 |
| 2 | Documentation Client for OES (protocole NCP) | https://www.novell.com/documentation/windows_client/ | 2026-10-23 |
| 3 | Ports NetWare 6.5 (NCP 524) | https://support.microfocus.com/kb/doc.php?id=3666976 | 2026-10-23 |
| 4 | Wikipédia — NetWare Core Protocol (port 524, SLP) | https://en.wikipedia.org/wiki/NetWare_Core_Protocol | 2026-10-23 |
| 5 | SDK NetWare Core Protocols (Novell) | https://beta.novell.com/developer/ndk/netware_core_protocols.html | 2026-10-23 |
| 6 | ncpfs retiré du noyau Linux 4.17 | https://man7.org/linux/man-pages/man5/fs.5.html | 2026-10-23 |
| 7 | Module IPX hors arbre (Linux ≥ 4.18) | https://github.com/pasis/ipx | 2026-10-23 |
| 8 | Module ncpfs hors arbre | https://github.com/EnzephaloN/ncpfs-module | 2026-10-23 |
| 9 | DOSBox — IPX sur UDP | http://www.dosbox.com/wiki/IPX | 2026-10-23 |
| 10 | MARS_NWE | https://github.com/davidrg/mars_nwe | 2026-10-23 |

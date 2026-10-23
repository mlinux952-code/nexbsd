# Compte rendu de session — S-005

**Date :** 2026-10-23
**Déclencheur :** inquiétude du responsable du projet : *« on va utiliser NetWare, MARS_NWE, Samba et OpenLDAP, ce sont les composants du réseau — ou tu vas abandonner notre projet ? »*

**Réponse : aucun des quatre n'est abandonné. Le réseau est confirmé comme axe prioritaire.**

---

## 1. Ce qui a été clarifié

| Composant | Statut | Rôle |
|---|---|---|
| **NetWare** | conservé | modèle fonctionnel de référence : identités, droits, trustees, partages, administration unique |
| **Samba** | conservé | fichiers et impression (Plateforme, >= 4.23) |
| **OpenLDAP** | conservé | annuaire et identités (Plateforme, >= 2.6 sous condition) |
| **MARS_NWE** | conservé | banc d'essai et source de spécification (laboratoire isolé) — jamais brique embarquée (GPL-2 + IPX) |

→ `docs/14-reseau-netware.md`, **ADR-0017**.

## 2. Correction importante apportée à une conclusion antérieure

J'avais écrit que la compatibilité NetWare était impossible sans IPX. **C'était incomplet.**

| Fait vérifié | Source |
|---|---|
| Depuis **NetWare 5, NCP s'exécute nativement sur TCP/IP**, port **524** (TCP et UDP) | Wikipédia (NCP, IPX/SPX), doc Novell « NetWare Over TCP/IP » |
| IPX n'est qu'un transport parmi deux, pas une condition d'existence de NCP | idem |
| Novell a publié une documentation des NCP (numéros, sémantique) | novell.com/documentation/developer, beta.novell.com/developer/ndk |
| **DOSBox émule IPX sur UDP** (`ipxnet startserver` / `connect`, port 213) → client DOS testable sans matériel spécial | DOSBoxWiki, manuel DOSBox, DOSBox-X |
| `ipxgw` relie un réseau IPX réel à des DOSBox | github.com/ksalin/ipxgw |

**Conséquence :** la cible protocolaire devient **NCP sur UDP/TCP 524** (ADR-0018), ce qui supprime la nécessité d'écrire une pile IPX et la contradiction avec ADR-0006. IPX ne sert plus que dans le laboratoire, via DOSBox.

## 3. Les trois chemins du réseau (aucun n'annule l'autre)

1. **Fonctions** (P0/P1, maintenant) : Samba + OpenLDAP + outil d'administration NexBSD.
2. **Référence** (P2) : laboratoire MARS_NWE + DOSBox → produire `docs/spec-netware-observee.md`.
3. **Protocole** (P3, recherche) : réimplémentation NCP sur UDP/TCP 524, en code NexBSD.

## 4. Livrables de la session

**Créés :** `docs/14-reseau-netware.md` · `docs/INDEX-DOCUMENTS.md` (index complet) · `docs/decisions/ADR-0017-reseau-axe-prioritaire.md` · `docs/decisions/ADR-0018-ncp-sur-ip.md` · ce compte rendu.
**Mis à jour :** `docs/ETAT.md` (v5, 18 ADR) · `docs/decisions/README.md` · `README.md` · `matrices/functions.csv` (renommée N-xx pour le réseau, 28 lignes) · `matrices/compatibilite.csv` (K-13/K-14 sur NCP sur IP) · `matrices/risques.csv` (R-24) · `matrices/README.md`.

## 5. Correction technique effectuée

Les matrices `compatibilite.csv`, `functions.csv` et `risques.csv` contenaient des virgules non échappées : elles se seraient mal ouvertes dans un tableur. **Réécrites avec un échappement correct et vérifiées par analyseur CSV** : 5/5 fichiers à nombre de colonnes constant.

## 6. Prochaine action (une seule)

> **Produire `research/ncp-ip/fiche.md`** : disponibilité d'un client NCP sur port 524 (V-1), complétude de la documentation publique des NCP (V-2), faisabilité du montage MARS_NWE + DOSBox (V-3).
>
> Aucun matériel requis. Cette fiche détermine si le chemin protocolaire (ADR-0018) est viable ou doit être suspendu — et donc si NexBSD pourra un jour parler NCP, ou seulement en fournir les fonctions.

## 7. Décisions toujours attendues du responsable

- **Q3 :** le fork est-il assumé, avec son coût ?
- **Q4 :** quand le profil L3 (« PC fort ») sera-t-il disponible ?

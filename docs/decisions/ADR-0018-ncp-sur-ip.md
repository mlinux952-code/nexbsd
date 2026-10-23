# ADR-0018 — Réviser ADR-0014 : la cible protocolaire est NCP sur UDP/TCP 524, pas IPX

- **Date :** 2026-10-23
- **Statut :** proposition
- **Référence :** `docs/14-reseau-netware.md` §2
- **Révise :** ADR-0014 (qui présentait IPX comme une dépendance inévitable)

## Problème
ADR-0014 concluait que toute compatibilité NetWare exigeait une pile IPX, absente de FreeBSD depuis la version 11.0 — ce qui rendait le sujet très coûteux. Cette conclusion était **incomplète**.

## Faits vérifiés (nouveaux)
- **Depuis NetWare 5, NCP s'exécute nativement sur TCP/IP**, port **524** (TCP et UDP), sans IPX.
- IPX n'est qu'**un** transport possible de NCP, pas une condition d'existence du protocole.
- MARS_NWE n'implémente ni NetWare/IP ni NCP sur IP : c'est **sa** limite, pas celle du protocole.
- Novell a publié une documentation des NCP (numéros et sémantique) via son SDK développeur.

## Décision proposée
1. La réimplémentation propre visée (si le chemin 3 est engagé) cible **NCP sur UDP/TCP 524**.
2. **Aucune pile IPX n'est écrite, ni dans le noyau ni en espace utilisateur.**
3. IPX n'est utilisé que **dans le laboratoire**, via l'émulation IPX-sur-UDP de DOSBox, pour dialoguer avec MARS_NWE.
4. Le statut reste **recherche P3** : aucun engagement de délai, aucune promesse de compatibilité avant test avec un client réel.

## Justification
- Supprime la contradiction avec ADR-0006 (pas de modification du noyau).
- Supprime la dépendance à un protocole retiré des systèmes modernes.
- Rend le sujet **borné** : implémenter un protocole documenté en espace utilisateur, sur un transport existant (UDP/TCP).
- Réduit le coût d'un facteur important par rapport à une pile IPX complète.

## Conséquences
- Le risque R-20 (dérive du chantier IPX/NCP) est réduit mais pas nul : le périmètre doit rester borné (login, attach, map, lecture/écriture, bindery simple).
- Un **client de test** est indispensable pour valider ; sans client réel, la preuve serait faible (V-1 à vérifier).
- Le laboratoire (chemin 2) devient la source des structures de données, sans copier de code GPL.

## Conditions de révision
- Si aucun client NCP sur port 524 n'est disponible pour tester : le chantier reste théorique et doit être suspendu plutôt que simulé.
- Si la documentation publique des NCP s'avère insuffisante : abandon documenté.

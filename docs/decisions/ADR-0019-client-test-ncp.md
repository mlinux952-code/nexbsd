# ADR-0019 — Client de test NCP : Client for Open Enterprise Server (usage externe uniquement)

- **Date :** 2026-10-23
- **Statut :** proposition
- **Référence :** `research/ncp-ip/fiche.md`
- **Complète :** ADR-0018 (NCP sur UDP/TCP 524)

## Problème
Implémenter NCP n'a de valeur que si l'on peut le tester contre un client réel. La question V-1 (« existe-t-il un client utilisable ? ») conditionnait tout le chemin protocolaire.

## Faits vérifiés
- **Client for Open Enterprise Server** (OpenText, ex-Novell Client) : versions **26.2.1 (août 2026)**, 25.4.1 (février 2026). « The Client supports Micro Focus's traditional **NCP** protocol. »
- NCP sur **TCP et UDP port 524** ; SLP sur 472.
- Le client est **propriétaire**, téléchargeable gratuitement, disponible sur le marketplace OpenText.
- Alternative libre côté Linux : `ncpfs` (retiré du noyau en 4.17, maintenu hors arbre) — mais **IPX uniquement**, donc inutilisable pour tester le port 524.

## Décision proposée
1. Utiliser le **Client for Open Enterprise Server** comme **client de référence** pour valider notre implémentation NCP.
2. Usage **strictement externe** : jamais intégré, jamais redistribué avec NexBSD, jamais requis par le système. C'est un **banc de mesure**, pas un composant.
3. Le banc de test est une **VM Windows** isolée, réseau sans passerelle.
4. Aucun test NCP n'est déclaré réussi sans capture d'écran/sortie du client réel.

## Justification
- Sans client réel, une implémentation NCP n'est pas vérifiable : on ne peut que « croire » qu'elle marche, ce qui est interdit par la règle R-10.
- Le client étant gratuit et maintenu, le coût est nul et la pérennité meilleure qu'avec un client DOS de 1999.
- L'utilisation d'un logiciel propriétaire comme **outil de test** ne crée aucune obligation de licence sur NexBSD (aucune distribution, aucun lien).

## Conséquences
- Le laboratoire doit prévoir une **VM Windows** (licence à vérifier par le responsable).
- `docs/14-reseau-netware.md` §6 V-1 passe de « inconnu » à « résolu ».
- Le rapport de test T-09 devient réalisable : il compare notre sous-ensemble NCP à un client authentique.

## Conditions de révision
- Si le client OpenText n'est plus disponible ou n'est plus compatible avec les Windows accessibles : se rabattre sur le banc IPX + DOSBox (comportement seulement, pas protocole).

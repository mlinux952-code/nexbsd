# ADR-0014 — Compatibilité NCP/IPX : réimplémentation propre en espace utilisateur (recherche)

- **Date :** 2026-10-23
- **Statut :** proposition — **statut recherche, P3, non engagé**
- **Référence :** `research/netware/fiche.md`, `research/mars-nwe/fiche.md`
- **Complète :** ADR-0004 (MARS_NWE rejeté comme composant)

## Problème
Le responsable du projet veut conserver la dimension NetWare. MARS_NWE ne peut pas être intégré : GPL-2 (interdite dans la base, cf. ADR-0012) et surtout **dépendance à IPX**, protocole retiré de FreeBSD 11.0 et de Linux 4.17.

## Options examinées
1. Réintroduire une pile IPX **dans le noyau** → contredit ADR-0006, code mort depuis dix ans, maintenance prohibitive. **Rejeté.**
2. Utiliser MARS_NWE tel quel → impossible (IPX) et interdit dans la base (GPL-2). **Rejeté.**
3. **Réimplémenter IPX (transport) et un sous-ensemble de NCP (applicatif) en espace utilisateur**, en code propre à NexBSD, au-dessus de sockets bruts/BPF. → **Retenu comme sujet de recherche.**
4. S'en tenir au modèle fonctionnel avec Samba + OpenLDAP. → **Retenu pour le produit**, la compatibilité protocolaire restant optionnelle.

## Décision proposée
- **N'exécuter aucune bibliothèque GPL dans la base** ; ne copier aucun code de MARS_NWE.
- Ouvrir un **chantier de recherche** (P3) : « IPX/NCP en espace utilisateur », avec pour cible minimale documentée : login, attach, map de lecteur, lecture/écriture, bindery simple — c'est-à-dire de quoi servir un client DOS/Windows 3.11 dans un laboratoire.
- Ce chantier **ne bloque rien** : s'il n'aboutit pas, NexBSD reste cohérent (« fonctions réseau inspirées de NetWare », sans compatibilité protocolaire).

## Justification
- C'est le seul chemin techniquement viable ET juridiquement propre.
- Il transforme un rejet en **axe d'identité** : personne ne fait cela aujourd'hui.
- Le coût est réel mais borné : implémentation d'un protocole documenté, sans modification du noyau.

## Conséquences
- Risque de dérapage : ce chantier peut absorber des années s'il n'est pas strictement borné.
- Nécessite une documentation du protocole `[À VÉRIFIER : disponibilité de spécifications publiques NCP/IPX]`.
- Aucune promesse de compatibilité ne doit être publiée avant test avec un client réel.

## Conditions de révision
- Abandon si les spécifications publiques sont insuffisantes.
- Abandon si aucun client réel n'est disponible pour tester.
- Promotion en P1 si un utilisateur justifie le besoin (client existant identifié).

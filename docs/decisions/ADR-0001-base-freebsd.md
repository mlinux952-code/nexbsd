# ADR-0001 — FreeBSD 15.x comme base système

- **Date :** 2026-10-23
- **Statut :** proposition (en attente de validation du responsable)
- **Décideur :** responsable du projet

## Problème
Quelle base système pour NexBSD ?

## Options étudiées
1. FreeBSD 15.x (amd64)
2. NetBSD / OpenBSD
3. Noyau Linux + assemblage (approche distribution)
4. Développement d'un noyau propre

## Avantages / inconvénients
- **FreeBSD** : licence BSD 2-clause permissive, réseau mature, jails, bhyve, ports fournis (Samba, OpenLDAP), documentation de référence, support jusqu'au 31/12/2029 pour stable/15. Inconvénients : pas de pile IPX (retirée en 11.0), gestion d'énergie insuffisante pour le mobile, Wi-Fi dépendant du matériel.
- **NetBSD/OpenBSD** : excellente portabilité matérielle, mais écosystème serveur (Samba/OpenLDAP/jails) moins riche et moins documenté pour ce besoin.
- **Linux assemblé** : reviendrait à refaire une distribution ; aucun apport par rapport à la cible visée ; éloigne du concept « BSD ».
- **Noyau propre** : hors de portée (plusieurs dizaines d'années-homme).

## Décision proposée
Retenir **FreeBSD 15.1-RELEASE amd64**, version figée et documentée à chaque étape, sans modification du noyau.

## Justification
Meilleur rapport entre licence permissive, écosystème serveur packagé, support long et documentation ; le projet peut produire un prototype réel sans écrire de noyau.

## Conséquences
- IPX/NCP impossible nativement → ADR-0004.
- Mobile : la couche C devra être logicielle (ADR-0003, ADR-0008).
- Toute compilation lourde est à éviter (R-09) : usage de `pkg`.

## Conditions de révision
- Si le CPU du PC de test n'est pas 64 bits.
- Si une fonction indispensable s'avère impossible sans travail noyau.
- Si le support de stable/15 était réduit.

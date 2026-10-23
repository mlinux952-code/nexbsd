# ADR-0010 — Aucune compilation lourde sur les postes faibles ; report explicite au profil L3

- **Date :** 2026-10-23
- **Statut :** proposition

## Problème
Le responsable du projet dispose d'un poste Linux Mint **à faible capacité** comme station de travail, et le PC de test a 4 Go de RAM avec un disque mécanique. Samba, WebKitGTK, Firefox et a fortiori une chaîne de construction complète ne peuvent pas y être compilés dans des conditions raisonnables. Un jour, un PC plus puissant (« L3 ») sera disponible, mais il ne faut pas fonder le plan sur une ressource qui n'existe pas encore.

## Décision proposée
1. **Paquets binaires uniquement** sur les postes faibles (Mint et PC de 2011).
2. La compilation, la construction d'images reproductibles et `poudriere` sont **reportés au profil L3**, dont la disponibilité est une **hypothèse non acquise**.
3. La station Mint sert à : diagnostiquer, télécharger, **vérifier les empreintes**, écrire des supports USB, faire tourner des **VM QEMU légères** (1 Go, mode texte).
4. Aucun livrable du projet ne doit **dépendre** de l'existence de L3 avant sa disponibilité effective.

## Justification
Cohérent avec ADR-0009 (si NexBSD exige une grosse machine pour être construit, il manque sa cible) ; évite de bloquer le projet sur un matériel non disponible ; les paquets FreeBSD couvrent le besoin du prototype 0.

## Conséquences
- Les versions de composants sont contraintes par ce qui est **packagé** (d'où l'inconnue OpenLDAP ≥ 2.6, cf. ADR-0004 et `research/openldap/fiche.md`).
- Si un composant indispensable n'est pas packagé, les options sont : l'accepter en version packagée, le reporter, ou attendre L3 — **jamais** compiler sur le poste faible.
- Quand L3 arrive : ouvrir un ADR de révision (poudriere, images reproductibles, tests lourds).

## Conditions de révision
Mise à disposition effective d'un PC puissant, avec spécifications relevées et documentées.

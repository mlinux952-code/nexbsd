# Couloir de recherche — Centre de commande NexBSD

**Ouvert le :** 2026-10-26 · **Statut :** couloir de **recherche** (documents uniquement)
**Règle fondatrice :** **zéro temps produit**. Ce couloir ne bloque aucune commande, ne touche aucune
machine, n'introduit aucun composant. Il ne produit que des **documents**.

**Pourquoi un second couloir ?** Le projet applique déjà cette règle pour le noyau écrit depuis zéro
(`research/noyau-propre/`, `docs/31`). Le responsable a demandé le 2026-10-26 d'ouvrir le même espace pour
les systèmes jugés intéressants (NetBSD, Genode, seL4, NixOS, OpenWrt, Zephyr, Ansible, Home Assistant,
illumos) et pour l'idée de **centre de commande multi-machines**. C'est légitime **à condition** que ce
couloir reste un couloir.

## Ce qui est autorisé ici

- écrire des **spécifications**, des grilles comparatives, des questions ouvertes ;
- **lire** de la documentation publique ;
- produire des **prototypes jetables** sous `banc/` (jamais installés sur la VM du produit) ;
- répondre à une seule question à la fois, avec une **source** ou une **mesure**.

## Ce qui est interdit ici

- installer quoi que ce soit sur la VM `nexbsd` ;
- modifier le dépôt produit (`fork/`, `scripts/`, `docs/` hors mention) ;
- retarder **T-11**, le harnais, `pf`, le client réel ou l'image ;
- écrire du code qui aurait l'air d'un composant du produit.

## Le critère qui protège ce couloir

> Un document de recherche n'a de valeur que s'il **répond à une question qu'on se pose vraiment**.
> Chercher sans question identifiée est la façon la plus élégante de ne pas construire de système.

**Question identifiée aujourd'hui (la seule) :** *comment NexBSD peut-il administrer plusieurs machines
hétérogènes avec les identités et les droits de son annuaire, sans introduire de composant lourd ?*

Toute étude qui ne sert pas cette question est **refusée**.

## Contenu

| Fichier | Objet |
|---|---|
| `specification-v0.1.md` | le principe P-CC mis en forme : couches, adaptateurs, identité, refus explicite, journal |
| `grille-candidats.md` | grille de comparaison des systèmes proposés — **cases à remplir, jamais inventées** |
| `questions-ouvertes.md` | ce qui manque pour décider, classé par ordre de coût |

## Ce que ce couloir ne fera pas

Il ne transformera pas NexBSD en « système qui fusionne dix systèmes ». Il cherchera, pour **une** question
précise, **la** réponse la moins coûteuse compatible avec nos décisions déjà prises (ADR-0001 base FreeBSD,
ADR-0006 pas de noyau modifié, ADR-0012 frontière des licences).

# ADR-0005 — Isolation des services en jails et pare-feu en refus par défaut

- **Date :** 2026-10-23
- **Statut :** proposition

## Problème
Comment limiter la surface d'attaque d'un système qui expose des services réseau ?

## Décision proposée
1. Chaque service exposé tourne dans une **jail** dédiée, sous un compte non privilégié.
2. `pf` applique une politique `block all` par défaut ; seuls les ports nécessaires sont ouverts sur le réseau local.
3. Aucune redirection vers Internet, aucun service exposé publiquement.
4. Les protocoles historiques sont interdits hors laboratoire sans passerelle.

## Justification
Mesure la moins coûteuse et la plus vérifiable ; compatible avec 4 Go de RAM (jails partagent le noyau).

## Conséquences
- Configuration réseau des jails à documenter (interfaces, routage).
- Tests T-05 obligatoires (scan externe).
- Un jail par service peut être coûteux en RAM si les services se multiplient : à réévaluer en phase 5.

## Conditions de révision
Si le nombre de services rend l'isolation trop coûteuse sur le matériel cible.

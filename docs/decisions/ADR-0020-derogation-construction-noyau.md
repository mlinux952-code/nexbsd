# ADR-0020 — Dérogation encadrée : une construction de noyau sur le poste du responsable

- **Date :** 2026-10-25 (session S-018)
- **Statut :** proposition (elle engage une révision de l'ADR-0010)
- **Référence :** révise partiellement **ADR-0010** (« aucune compilation lourde sur les postes faibles »)
- **Déclencheur :** le responsable refuse, à juste titre, que le projet s'arrête à « un FreeBSD modifié ». Un système à part entière exige **une construction issue de notre arbre**. L'ADR-0010 interdisait toute compilation : il faut donc, ou renoncer à l'objectif, ou encadrer une exception.

## Problème

L'ADR-0010 reporte **toute** compilation au profil **L3** (machine puissante) dont l'existence n'est pas acquise
(problème **P-03**). Le projet est donc bloqué : le delta `build/fork/` est écrit depuis la session S-010 et
**n'a jamais été compilé**. Une configuration de noyau non compilée n'est pas une preuve : c'est un brouillon.

## Mesure du poste (verbatim, 2026-10-25)

```
Mem:           3.7Gi       2.9Gi       603Mi       317Mi       726Mi       787Mi
Échange:       3.9Gi       775Mi       3.2Gi
4            (nproc)
/dev/sda3          117G     44G   67G  40% /
Model name:  Intel(R) Core(TM) i3-3110M CPU @ 2.40GHz      (2 cœurs / 4 fils)
```

Conséquence chiffrée : **le poste n'est pas L3 et ne le sera pas**. Il a 3,7 Go de RAM (787 Mo disponibles au
moment de la mesure) et 67 Go de disque libre, pour 2 cœurs réels.

## Décision proposée

1. **Dérogation unique et bornée** : autoriser **une seule** opération lourde sur ce poste —
   la **construction du noyau** `NEXBSD_L1` (`make buildkernel`), dans la VM du banc.
2. La dérogation **ne couvre pas** `buildworld`, `release.sh`, `poudriere` ni la construction de l'image :
   celles-ci restent soumises à l'ADR-0010 et devront se faire sur une ressource de profil L3 ou en
   intégration continue (`docs/27` §4, voie B).
3. La dérogation est **soumise à garde-fous mesurés** (script `scripts/68`) : RAM ≥ 1 800 Mo dans la VM,
   ≥ 6 Go libres dans `/usr/obj`, parallélisme **plafonné** par la RAM (`-j2` maximum), journal de
   construction conservé dans le dépôt (`tests/results/`, extrait).
4. La dérogation **expire** dès que la construction est terminée : elle n'est pas un changement de politique.
   Toute construction ultérieure repasse par une nouvelle décision.
5. **Disque de construction séparé** (30 Go ajoutés à la VM) : le disque système du banc n'est pas touché,
   ce qui garantit que l'échec d'une construction ne détruit pas un banc validé (T-04-G, 11/11).

## Justification

- Renoncer à compiler, c'est renoncer à l'objectif ; l'ADR-0010 a été écrit pour **protéger** le projet, pas
  pour l'empêcher d'exister.
- Un noyau, contrairement à un monde complet, tient dans 2 Go de RAM et 6 Go de disque : c'est **mesurable**
  et c'est **borné**.
- La construction d'un noyau produit une preuve vérifiable en une ligne : `uname -i` = `NEXBSD_L1`.

## Conséquences

- Le poste sera lent pendant 2 à 6 h ; le responsable ne doit pas s'en servir pour autre chose (navigateur
  fermé) pendant la construction.
- Le banc passe d'un noyau fourni à un **noyau construit par le projet** : c'est le premier acte de
  possession du système.
- Le risque d'échec (swap, panne de courant, OOM) est réel : la construction est **reprenable** (`make`
  reprend où il s'est arrêté) et journalisée.
- Si elle échoue, l'échec est consigné **verbatim** et l'ADR-0010 reprend son plein effet.

## Conditions de révision

Arrivée effective d'une machine de profil L3, **ou** adoption de l'intégration continue (voie B de `docs/27`)
qui rend cette dérogation inutile.

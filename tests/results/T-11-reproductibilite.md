# T-11 — Reproductibilité de la construction du noyau

**Date :** 2026-10-26 (soir) · **Verdict : RÉUSSI — empreintes identiques, à l'octet près**

---

## 1. Question posée

Le noyau `NEXBSD_L1` a été construit une première fois le 2026-10-26 et installé. Mais une **seule**
construction ne prouve rien sur la fiabilité de la recette : elle peut être un coup de chance.

**Question :** reconstruire le noyau dans un **répertoire d'objets neuf** donne-t-il **le même fichier** ?
Si oui, la construction est **déterministe** : n'importe qui, avec la même source et la même configuration,
obtient le même binaire — et peut donc **vérifier** nos affirmations sans nous croire.

## 2. Protocole

| Élément | Première construction | Seconde construction |
|---|---|---|
| Répertoire d'objets | `/build/obj` | **`/build/obj2`** (neuf, vide) |
| Source | `/build/src` (`releng/15.1`, `REVISION=96841ea08dcf`) | identique, non modifiée |
| Configuration | `KERNCONF=NEXBSD_L1` | identique |
| Identité de version | `BRANCH_OVERRIDE=NEXBSD-L1` | identique |
| Commande | `make -j2 buildkernel` | identique |
| Résultat installé ? | oui (`/boot/kernel.NEXBSD_L1`) | **non** — construction de comparaison, jamais installée |

## 3. Résultat — sortie verbatim

```
root@nexbsd:/build/src # while ! grep -qE "built in|Error code" /build/logs/reproductibilite-1.log; do sleep 60; done; tail -3 /build/logs/reproductibilite-1.log; sha256 -q /build/obj2/build/src/amd64.amd64/sys/NEXBSD_L1/kernel; echo "reference : 82dc5681397b06fab69171daf6e910d6a380b058ee63341a83c77f770b94c87c"
--------------------------------------------------------------
>>> Kernel(s)  NEXBSD_L1 built in 6533 seconds, ncpu: 2, make -j2
--------------------------------------------------------------
82dc5681397b06fab69171daf6e910d6a380b058ee63341a83c77f770b94c87c
reference : 82dc5681397b06fab69171daf6e910d6a380b058ee63341a83c77f770b94c87c
```

| Mesure | Valeur |
|---|---|
| Empreinte de la 2ᵉ construction | **`82dc5681397b06fab69171daf6e910d6a380b058ee63341a83c77f770b94c87c`** |
| Empreinte de la 1ʳᵉ construction | **`82dc5681397b06fab69171daf6e910d6a380b058ee63341a83c77f770b94c87c`** |
| Différence | **aucune — identiques caractère pour caractère** |
| Erreurs | **0** |
| Durée de la construction complète | **6533 secondes** = **1 h 49 min** (2 vCPU) |

## 4. Verdict

**RÉUSSI.** La construction du noyau NexBSD est **reproductible**.

## 5. Pourquoi c'était plausible — et pourquoi il fallait le prouver quand même

Trois mécanismes doutaient qu'on y arrive :

1. **`BRANCH_OVERRIDE=NEXBSD-L1`** remplace le champ de version où la date de compilation s'inscrit
   habituellement → la chaîne `@(#)FreeBSD 15.1-NEXBSD-L1 NEXBSD_L1` ne contient **aucune date**.
2. **`-ffile-prefix-map`** : le compilateur remplace les chemins réels (`/build/obj2/...`) par des chemins
   fixes (`/usr/obj/usr/src/...`). Les deux répertoires différents sont donc **effacés** du binaire.
3. **Source et configuration identiques**, jamais touchées entre les deux constructions.

Ces trois points rendaient le succès possible. **Ils ne le prouvaient pas** : l'ordre de liaison, les octets
de remplissage et le `ctfmerge` auraient pu diverger. C'est la mesure — pas le raisonnement — qui tranche.

## 6. Note d'honnêteté sur une durée

La première construction avait affiché `built in 1470 seconds`. **Ce chiffre ne représente pas une
construction complète** : elle avait été interrompue et **reprise** le lendemain, la majorité des objets
étant déjà produits. La durée réelle d'une construction **à froid** sur cette VM est celle mesurée ici :
**6533 s ≈ 1 h 49 min** pour 2 vCPU. Toute planification (notamment en intégration continue) doit utiliser
**cette** valeur, pas l'autre.

## 7. Ce que cela change dans le projet

| Avant | Après |
|---|---|
| « voici notre noyau, empreinte `82dc5681…` » — **une** construction, donc confiance | « toute reconstruction donne **exactement** ce binaire » — **preuve** |
| Non-conformité n° 1 de l'audit croisé (`docs/32`) : **ouverte** | **close** |
| La voie d'intégration continue pour l'image (condition C de `docs/33`) reposait sur un espoir | elle repose désormais sur un **fait mesuré** : un build en CI produira le binaire attendu |

## 8. Ce que cela ne prouve pas

- **Que la CI produira ce binaire** : cela dépend de la version du compilateur, du système hôte et de
  l'horloge ; la reproductibilité **entre deux machines différentes** reste à mesurer (autre test).
- **Que le noyau est bon** : il démarre et le banc passe 11/11 (T-17), ce sont d'autres preuves.
- **Que `world` est reproductible** : seul le **noyau** est mesuré ici.

**Réserves consignées, non dissimulées.**

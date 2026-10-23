# Matrices

Cinq matrices au format CSV (séparateur virgule, UTF-8, importables dans Google Sheets ou LibreOffice).

| Fichier | Contenu | Volumétrie |
|---|---|---|
| `components.csv` | inventaire des composants : rôle, source, version, licence, maintenance, compatibilité FreeBSD, statut, priorité | 13 lignes |
| `functions.csv` | fonctions attendues par couche (S = système, N = réseau, C = couche mobile, F = distribution) : besoin, candidat, risque, test prévu, priorité, état | 28 lignes |
| `licences.csv` | licences vérifiées, obligations, risque juridique, statut de vérification | 11 lignes |
| `compatibilite.csv` | questions de compatibilité et réponse actuelle (OUI / NON / INCONNU) avec confiance | 15 lignes |
| `risques.csv` | registre des risques : probabilité, impact, niveau, mitigation, statut | 24 lignes |

## Conventions

- **Statuts de composant** : `Candidat` → `En étude` → `Prototype` → `Validé partiellement` → `Validé pour un usage défini` → `Rejeté`.
- **Priorités** : `P0` indispensable au prototype minimal · `P1` première version utilisable · `P2` amélioration ultérieure · `P3` recherche avancée ou expérimental.
- **Aucun statut `Validé` n'est attribué sans test reproductible documenté.**
- Les champs `A VERIFIER` signalent une information manquante ou non fiable.

## Mise à jour

À chaque session : mettre à jour la date de vérification, les versions, et ajouter une ligne au registre des risques si un risque nouveau apparaît. Ne jamais supprimer une ligne de risque : la marquer `clos` avec la justification.

## Qualité des fichiers

Les cinq CSV sont écrits avec un échappement correct des virgules (champs entre guillemets) et vérifiés par un analyseur CSV : **nombre de colonnes constant** sur toutes les lignes. Ils s'ouvrent directement dans Google Sheets ou LibreOffice.

Vérification rapide :

```bash
python3 -c "import csv,glob; [print(f, sorted({len(r) for r in csv.reader(open(f,encoding='utf-8'))})) for f in sorted(glob.glob('matrices/*.csv'))]"
```

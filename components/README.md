# Dossier `components/` — fiches de composants

Exigé par la Partie XIII du méga-prompt. **Aucune fiche n'existe encore.**
La vue d'ensemble est dans `matrices/components.csv` (13 composants).

## Modèle d'une fiche (`components/NN-nom.md`)

```
# Composant — <nom>
- Rôle dans NexBSD : <une phrase>
- Version retenue : <version> (source + date de consultation)
- Licence : <licence> — admissible en base ? oui/non (ADR-0012)
- Origine du code : <URL exacte>
- Dépendances : <liste>
- Empreinte prévue : RAM / disque (estimation, non mesurée)
- Emplacement : base / jail / option
- État : proposé · en évaluation · intégré · écarté (avec justification)
- Test associé : <T-xx>
- Décision liée : <ADR-xxxx>
```

## Priorité de rédaction

1. `01-samba.md` — cœur fonctionnel (N-01, N-02, N-06, N-07)
2. `02-openldap.md` — annuaire (N-03…N-05)
3. `03-ncp-nexbsd.md` — implémentation NCP (recherche)
4. `04-webkitgtk.md` — profil mobile/interface
5. les autres au fil de l'intégration

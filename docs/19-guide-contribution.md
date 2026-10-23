# Guide de contribution

**Version :** 1.0 — 2026-10-23
**Rôle :** livrable 19 du méga-prompt. Destiné à toute personne — humain ou IA — rejoignant le projet.

---

## 1. Avant tout : lire dans cet ordre

1. `START-HERE.md` — le protocole de session (obligatoire)
2. `docs/ETAT.md` — l'état réel en une page
3. `reports/` — le dernier compte rendu
4. `docs/15-conformite-mega-prompt.md` — ce qui est fait, partiel, absent

**NexBSD n'a aujourd'hui ni code, ni image, ni système installé.** Toute contribution qui suppose le contraire part d'une erreur.

## 2. Les cinq règles d'une contribution acceptable

1. **Étiqueter** chaque affirmation : `[FAIT]` (source + date) · `[HYPOTHÈSE]` · `[PROPOSITION]` · `[À VÉRIFIER]` · `[DÉCISION]`.
2. **Ne jamais** écrire « fonctionne », « testé », « validé » sans sortie de commande ou capture.
3. **Ne pas rouvrir** une idée close (`START-HERE.md` §4) sans le fait nouveau qui la justifie.
4. **Vérifier la licence** de tout code ou texte importé, et l'inscrire dans `matrices/licences.csv`.
5. **Mettre à jour** `docs/ETAT.md`, le `CHANGELOG.md` et un compte rendu dans `reports/`.

## 3. Ce qui est accepté volontiers aujourd'hui

| Contribution | Pourquoi elle est utile maintenant |
|---|---|
| Correction factuelle (version, licence, URL cassée) | la recherche est la seule partie du projet en production |
| Vérification d'une question ouverte (`docs/ETAT.md` §4) | plusieurs bloquent des décisions |
| Procédure testée sur du matériel réel (FreeBSD qui démarre, Samba qui partage) | c'est ce qui manque le plus |
| Traduction / clarification de la documentation | le projet est en français, mais devra être bilingue |
| Relecture critique des décisions (ADR) | un désaccord argumenté vaut mieux qu'un accord poli |

## 4. Ce qui est refusé

- Ajouter un composant « parce qu'il est populaire » (Partie III du méga-prompt).
- Toute contribution qui ferait entrer du code copyleft dans la base (ADR-0012) — vérifié par `scripts/40`.
- Toute promesse de date, de performance ou de compatibilité non mesurée.
- Toute proposition qui dépasse le budget PC faible (ADR-0009) sans image séparée.
- Toute publication de secret, clé, donnée personnelle ou blob propriétaire.

## 5. Format d'une proposition de décision (ADR)

Créer `docs/decisions/ADR-00NN-titre-court.md` contenant : problème · options · avantages/inconvénients · décision proposée · justification · conséquences · conditions de révision. Puis ajouter la ligne au registre `docs/decisions/README.md`.

**Une décision n'est `acceptée` que si le responsable du projet la valide explicitement.** Sans cela, elle reste `proposition`.

## 6. Format d'un compte rendu de session

Voir `reports/session-2026-10-23.md` comme modèle. Minimum : état, décisions, fichiers créés/modifiés (vérifiés par `ls`), résultats vérifiés, non vérifiés, problèmes, prochaine action.

## 7. Style

- Français, phrases courtes, pas de jargon non expliqué (`docs/glossaire.md`).
- Tableaux dès qu'il y a trois éléments comparables.
- Une affirmation = une source, ou une étiquette.
- « Je ne sais pas » est une réponse acceptable et souvent la meilleure.

## 8. Ce qui appartient au responsable du projet

Les décisions structurantes (base, modèle de système, nom, publication), les actions matérielles, les dépôts (Drive, GitHub) et les secrets. **L'assistant ne décide rien seul et ne publie rien.**

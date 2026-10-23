# Vision du projet NexBSD

**Version :** 1.0 — 2026-10-23 — `[PROPOSITION]` **à valider par le responsable du projet** (livrable 1).

---

## 1. En une phrase

> **NexBSD veut rendre utilisable, sur des PC anciens et faibles, un système d'exploitation libre moderne qui apporte nativement les services de réseau local d'un serveur d'entreprise — fichiers, impression, comptes, droits — là où l'on n'installe aujourd'hui rien du tout.**

## 2. Le problème concret

Des millions de PC de 2008-2014 dorment dans des placards : 2 Go de RAM, un disque mécanique, un processeur 64 bits d'entrée de gamme. Windows n'y est plus maintenu ; les distributions Linux « grand public » y sont devenues lourdes ; les NAS du commerce coûtent plus cher que ces machines et ne font pas ce qu'on veut.

En parallèle, une compétence a disparu du monde des petites structures : **partager des fichiers avec des comptes et des droits, sur un réseau local, sans Internet, sans abonnement, sans administrateur spécialisé.** C'est exactement ce que faisait NetWare dans les années 1990, et ce que personne ne propose plus sous une forme simple et libre.

## 3. Ce que NexBSD apporte

| Apport | Pour qui | Différence réelle |
|---|---|---|
| Un système complet installable sur du matériel faible | particuliers, écoles, associations | pas une « distribution de plus » : un système construit, signé, nommé |
| Le **réseau local comme fonction première**, pas comme option | petites structures sans informaticien | fichiers + comptes + droits + impression en un seul geste |
| Une **compatibilité NCP** (le protocole NetWare) | héritage de parcs existants | personne ne maintient plus de serveur NCP libre ; ADR-0018/0019 |
| Zéro dépendance au cloud | contextes à faible connectivité | tout fonctionne hors ligne, par conception |
| Sobriété comme critère d'ingénierie, pas comme argument marketing | matériel de récupération | budget mémoire chiffré et vérifié (ADR-0009) |

## 4. Ce que NexBSD n'est pas

- Pas un FreeBSD avec des paquets en plus (ADR-0011 : fork, arbre propre, images signées).
- Pas un système pour téléphone : aucun appareil cible viable n'existe aujourd'hui (ADR-0008).
- Pas un NAS clé en main vendu avec du matériel.
- Pas une résurrection de NetWare : c'est un système moderne qui **parle** un protocole hérité.
- Pas un fork de KaiOS ni de Firefox OS (dépôts archivés, composants propriétaires).

## 5. Les trois principes non négociables

1. **Ne rien affirmer qui ne soit vérifié.** La crédibilité du projet tient à la distinction constante entre fait, hypothèse et proposition.
2. **Sobriété d'abord.** Toute fonctionnalité est jugée sur son coût en mémoire, en disque et en complexité d'administration.
3. **Frontière de licences respectée.** Base permissive, plateforme copyleft isolée (ADR-0012) : ce qui permet un jour de publier sans piège juridique.

## 6. Où en est le projet (2026-10-23)

**Phase de conception.** Aucun code, aucune image, aucun système installé. Ce qui existe : 9 fiches de recherche sourcées, 19 ADR, 5 matrices, un plan d'action, un plan de tests, une architecture cible, un squelette de delta de fork. Voir `docs/15-conformite-mega-prompt.md` pour l'audit exact.

## 7. La question à laquelle le responsable doit répondre

**Le projet vise-t-il d'abord l'usage domestique simple, ou la petite structure avec comptes et droits ?** Les deux sont techniquement proches, mais l'effort d'administration et le niveau de support diffèrent. Cette réponse conditionne la priorité entre les fonctions N-01 à N-11 et le calendrier de publication.

## 8. Ce que la vision n'engage pas

Ni date, ni version, ni promesse de compatibilité. Une vision n'est pas un plan de livraison : voir `docs/roadmap.md` et `docs/plan-action.md`, dont chaque jalon dépend de tests réels.

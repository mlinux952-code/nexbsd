# Contribution extérieure n° 2 — le « centre de commande multi-machines »

**Date :** 2026-10-26 · **Origine :** document transmis par le responsable, rédigé par une autre session.
**Objet :** NexBSD comme *plateforme* administrant plusieurs mondes (PC, serveurs, routeurs, embarqué),
avec une liste de systèmes à étudier et une architecture en couches.

**Verdict en une ligne :** **une idée à retenir et à insérer dans notre architecture existante ; une
recommandation à écarter ; et une cohérence rassurante à constater.** Rien ici ne change la route du produit.

---

## 1. Ce qui est retenu — et pourquoi ce n'est pas nouveau chez nous

Le document propose un **« NexBSD Command Hub »** : inventaire des machines, commandes unifiées, adaptateurs
par catégorie (PC / réseau / embarqué), couche de sécurité et journal d'audit.

**Constat en relisant notre propre architecture (`docs/architecture.md`) : cette idée y est déjà.**

| Leur proposition | Où c'est déjà écrit chez nous |
|---|---|
| « Services NexBSD : identités, fichiers, impression, sauvegardes » | **Couche D** : Samba, CUPS, OpenLDAP, supervision |
| « Couche de sécurité : identités, autorisations, audit, isolation » | **Couche B** : `isolation`, `log`, `health` + `docs/security.md` |
| « Console d'administration » | **Couche D-4** : « administration : interface NexBSD (à créer) » |
| « Outil d'administration unique » | **Couche E** : « outil d'administration unique (à concevoir) » |
| « Traduire une commande vers l'interface adaptée à la cible » | **Couche B** : `config`, `deps`, `health`, `rollback` |
| « Ne pas prétendre avoir exécuté ce qui a échoué » | **règle R-10 du projet** : on ne maquille jamais un résultat |

**Conclusion :** la contribution **ne crée pas un axe nouveau**, elle **nomme et structure** ce que notre
architecture prévoyait déjà comme « Couche D-4 / Couche E ». C'est utile — cela donne un nom et un récit à
quelque chose qui restait abstrait — mais ce n'est **pas** une bifurcation.

**Ce que j'en retiens concrètement (adopté) :**

1. **La règle d'architecture**, formulée parfaitement : *« une commande commune ne signifie pas que toutes
   les machines utilisent le même système »*. À inscrire comme principe (§3 ci-dessous).
2. **Le refus de mentir par omission** : si une opération est impossible sur une cible, le système doit
   **expliquer pourquoi**, pas feindre le succès. C'est notre règle d'honnêteté appliquée au produit.
3. **Le principe des adaptateurs hors noyau** : la gestion multi-machines est une couche **haute**, jamais
   dans le noyau. Cohérent avec ADR-0006.

## 2. Ce qui est écarté — avec les raisons

| Recommandation du document | Décision | Raison |
|---|---|---|
| *« FreeBSD ne doit pas être imposé comme noyau de base, il reste une option parmi d'autres »* | **Écarté** | ADR-0001 et ADR-0011 sont la référence produit. Et surtout : **nous avons la preuve** — un noyau compilé, démarré, et un banc à **11/11** dessus. Changer de base maintenant détruirait cette preuve pour une hypothèse. Le couloir *recherche* (`research/noyau-propre/`) couvre l'exploration, sans toucher au produit. |
| Liste de 10 systèmes à étudier (NetBSD, Genode, seL4, NixOS, OpenWrt, Zephyr, Ansible, Home Assistant, illumos…) | **Réduit à de la veille documentaire** | Une étude comparative de 10 systèmes coûterait des semaines et ne produirait **aucune ligne de système**. Nous ne sommes pas en phase d'exploration (phase 1, terminée) mais en phase de **construction** (4bis). |
| « Le centre de commande peut fonctionner avant que le noyau soit terminé » | **Écarté comme priorité** | C'est vrai techniquement mais faux stratégiquement **pour nous** : notre noyau **est** terminé, et il nous manque l'**image installable**. Construire un hub d'administration sur un système qu'on ne sait pas installer serait une démonstration, pas un produit. |
| « Étape D — poursuivre le prototype P1 » | **Déjà fait, ailleurs** | Le noyau propre extérieur est isolé dans `research/noyau-propre/`, avec la règle « zéro temps produit avant J5 ». |

## 3. Principe inscrit au projet (adopté)

> **Principe du centre de commande (P-CC).** NexBSD vise **un point d'administration unique** pour des
> machines hétérogènes — c'est l'esprit NetWare (un serveur, des postes, un administrateur), et c'est notre
> axe prioritaire (ADR-0017). Mais :
> 1. la gestion multi-machines est une **couche haute** (D-4/E), **jamais** dans la base ni dans le noyau ;
> 2. chaque cible passe par un **adaptateur** explicite (SSH, API, protocole documenté) ;
> 3. une opération impossible est **annoncée impossible**, avec la raison — jamais simulée ;
> 4. toute action est **journalisée et attribuable** à une identité de l'annuaire.
>
> **Ordre :** ce principe ne devient un chantier **qu'après** l'image installable (condition C de `docs/33`).
> D'ici là, il guide la conception, il ne consomme pas de temps.

## 4. Ce que cette contribution révèle de notre côté

Une remarque utile, à garder : le document insiste sur le fait que **le caractère distinctif de NexBSD ne
viendra pas du noyau** mais de ce qu'on met dessus. C'est exact, et c'est cohérent avec notre échelle
d'indépendance I0→I5 : le noyau nous a fait passer de I1 à **I2** — il ne fait pas le produit.

Notre différenciation, telle qu'elle est déjà décidée : **le modèle NetWare** (identités, droits, trustees,
administration centrale) réalisé sur des briques modernes. Le « centre de commande » en est la
**généralisation** aux machines : c'est une bonne formulation, pas une nouvelle direction.

## 5. Décision

1. **Rien ne change dans la route du produit** : T-11 → harnais → `pf` → client réel → image.
2. **Le principe P-CC est adopté** et inscrit dans `docs/architecture.md` (couche D-4).
3. **La liste des 10 systèmes reste une veille**, pas un chantier ; aucune étude comparative n'est lancée.
4. **La proposition « FreeBSD n'est qu'une option » est rejetée**, avec la preuve à l'appui.
5. Consigné ici pour que la trace existe : apport extérieur **examiné**, **partiellement adopté**,
   **partiellement écarté**, sans effet sur le plan.

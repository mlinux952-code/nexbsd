# 49 — Route A, étape par étape : combien de temps, et sur combien de jours

**Question du responsable (2026-10-28) :** *« on commence 1, 2 et 3 ; si image nous pouvons faire sur
plusieurs jours comme nous avons fait le noyau, sinon il faut planifier un jour complet ».*

---

## 1. Réponse courte

| Étape | Durée réelle | Votre présence nécessaire ? |
|---|---|---|
| **1. Compte Cirrus** | 5 à 10 minutes | **oui**, dans le navigateur (je ne peux pas le créer à votre place) |
| **2. SONDE + CONTRÔLES** | ~3 minutes | non, on regarde ensemble le résultat |
| **3. IMAGE** | **2 heures maximum, en UNE seule exécution** | **non** — la machine travaille sans vous |

**Donc : pas besoin de bloquer un jour complet.** L'étape 3 tourne toute seule ; vous pouvez dormir,
aller travailler, et lire le résultat au retour. **Ce qui n'est pas possible, c'est de l'étaler sur
plusieurs jours** — et c'est une limite de la plateforme, pas un choix de ma part (§3).

---

## 2. Trois faits vérifiés aujourd'hui qui changent le plan

### Fait 1 — mon `.cirrus.yml` était INVALIDE
J'avais écrit `timeout_in: 300m`. Cirrus plafonne les tâches **gratuites** à **2 heures**.
Une valeur au-delà est refusée. Corrigé : `120m`, le maximum autorisé.

### Fait 2 — le gratuit est limité à 50 crédits par mois
`50 compute credits` ≈ **10 000 minutes-CPU** pour du Linux. Une tâche de 8 cœurs pendant 2 h =
**960 minutes-CPU**. Le quota devrait tenir, mais **la conversion exacte pour FreeBSD n'est pas
documentée** : on la mesurera. Si le quota est épuisé, les tâches suivantes du mois sont bloquées —
il faudra donc **réussir en peu d'essais**, pas tâtonner.

### Fait 3 — le gratuit ne vaut que pour un dépôt PUBLIC
Cirrus : gratuit pour les dépôts **publics** ; dépôt **privé** = **10 $/mois** (ou crédits achetés).
**Nous ne savons pas si `mlinux952-code/nexbsd` est public.** Un `git fetch` anonyme avait renvoyé
404 le 23/10, ce qui suggère **privé** — mais ce n'est pas une preuve. C'est la première chose à
mesurer (commande §4), parce que cela décide entre **0 €** et **10 $/mois**.

---

## 3. Pourquoi ce n'est PAS une construction « sur plusieurs jours »

Dans la VM, une compilation interrompue **reprenait** : le disque restait, `/usr/obj` aussi. On a pu
étaler la construction du noyau sur plusieurs soirées.

En CI, c'est l'inverse : **la machine est détruite à la fin de la tâche**. Rien ne survit, sauf ce qui
est explicitement déposé en artefact. Donc :

- **une exécution = 2 h de travail continu** ; si elle est coupée, tout est perdu ;
- découper en plusieurs tâches est **théoriquement** possible (artefacts entre tâches), mais les
  volumes en jeu (une arborescence `/usr/obj` fait plusieurs Go) dépassent très probablement les
  limites de cache du gratuit — **non vérifié, donc pas promis** ;
- la stratégie honnête : **mesurer d'abord** si les 2 h suffisent (`date -u` avant/après chaque étape,
  déjà instrumenté dans `.cirrus.yml`), puis découper **seulement si nécessaire**, avec des chiffres.

**Estimation, à confirmer par exécution** : notre `src.conf` retire jeux, exemples et documentation,
ce qui raccourcit nettement `buildworld`. Ordre de grandeur sur 8 cœurs : `buildworld` 45–70 min,
`buildkernel` 15–25 min, `installworld`+`distribution` 10–15 min, média 5 min → **1 h 15 à 1 h 55**.
**C'est serré contre la limite de 2 h.** Le risque est réel et je ne le cache pas.

---

## 4. La décision à prendre, et ce qu'elle coûte

| Situation du dépôt | Conséquence | Coût |
|---|---|---|
| **public** | Cirrus gratuit, quota 50 crédits/mois | **0 €** |
| **privé** | plan personnel Cirrus | **10 $/mois** |

⚠️ Rendre le dépôt public signifie que **le code de NexBSD devient visible de tous**. Ce n'est pas une
décision technique, c'est une décision qui vous appartient — je ne la prends pas à votre place.
(Vérification utile : notre dépôt **ne contient aucun code GPL tiers**, seulement des fichiers de
configuration et des scripts écrits par nous. La frontière de licence reste respectée.)

---

## 5. Ordre d'exécution retenu

1. **mesurer** la visibilité du dépôt et l'état du distant (commande unique, lecture seule) ;
2. **1** — créer le compte Cirrus, autoriser le dépôt ;
3. **2** — lancer SONDE + CONTRÔLES : 3 minutes, aucune construction, et **enfin une réponse machine**
   sur la version 15.0 / 15.1 ;
4. **3** — lancer IMAGE : 2 h maximum, sans vous.

**L'étape 3 ne se lance qu'après l'étape 2.** Raison : si la version d'image est fausse, l'étape 3
échouerait au bout de quelques secondes — mais si elle échoue **au bout de 40 minutes**, on aura
consommé du quota pour rien.

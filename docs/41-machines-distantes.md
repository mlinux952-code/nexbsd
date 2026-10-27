# Utiliser des machines distantes — ce qui est possible, ce qui est à éviter

**Date :** 2026-10-27 · **Origine :** idée du responsable — *« sur Internet il y a des PC en ligne qu'on peut
utiliser pour plusieurs tâches concernant notre système »*

**Réponse en une ligne :** **oui pour l'intégration continue (CI) et les offres gratuites d'hébergeurs
sérieux ; non pour les « PC en ligne » anonymes.** Et il y a une raison technique très concrète de s'y
intéresser : c'est le seul chemin réaliste vers **l'image installable** (condition C).

---

## 1. Pourquoi cela nous intéresse vraiment

Notre blocage n° 1 n'est pas le talent, c'est **la RAM du poste** : 3,7 Go, dont 1,5 Go pour la VM.

| Tâche | Ici | Sur une machine distante |
|---|---|---|
| `buildkernel` | **1 h 49** (2 vCPU) ✅ déjà fait deux fois | 15 à 25 min sur 4 à 8 vCPU |
| `buildworld` + `release.sh` (image) | **impossible** (place et RAM) | **faisable** |
| Rejouer T-11 (reproductibilité) | 1 h 49 par essai | quelques essais dans la journée |
| Banc NexBSD (annuaire, SMB, pf) | ✅ la VM locale suffit | inutile de déporter : les preuves doivent venir de **notre** machine |

**Conclusion :** on ne déporte **pas** le banc (les preuves doivent être locales), on déporte **la
construction**. C'est exactement la « voie B » déjà écrite dans `docs/27`.

## 2. Les options sérieuses, classées

| Option | Ce qu'elle offre | Adapté à quoi | Limites à vérifier |
|---|---|---|---|
| **Cirrus CI** | **FreeBSD est un système de première classe** (le projet FreeBSD lui-même l'utilise). Offre gratuite pour les projets libres | **construire noyau/world et image en FreeBSD natif** — c'est l'option la plus directe | quotas de minutes et conditions d'offre gratuite à **vérifier à la source** avant de s'engager |
| **GitHub Actions** | 2 000 min/mois (dépôt privé), illimité en dépôt public ; exécuteurs Linux/Windows/macOS ; des actions communautaires lancent **FreeBSD dans QEMU** | automatiser nos scripts, rejouer le harnais sur une VM, produire des artefacts | **pas d'exécuteur FreeBSD natif** ; une VM dans une VM est plus lente ; les minutes gratuites se consomment vite avec des builds d'1 h |
| **Oracle Cloud « Always Free »** | ARM Ampere (jusqu'à 4 cœurs, 24 Go de RAM) + stockage ; carte bancaire demandée | faire tourner une **VM FreeBSD amd64** et y construire l'image | c'est de l'**ARM** : notre cible est **amd64** → il faut une machine amd64 ou une compilation croisée ; conditions et disponibilité à vérifier |
| **Serveur personnel / vieux PC dédié** | contrôle total, aucune limite d'usage, aucune donnée chez un tiers | **la meilleure option à terme** si un second PC est disponible | coût matériel, consommation électrique |
| **Google Colab** | GPU gratuit | expériences ponctuelles (calcul, pas FreeBSD) | sessions éphémères, pas de FreeBSD, conditions d'usage strictes |

## 3. Ce qui est à éviter — et pourquoi, sans détour

Les sites de « **PC en ligne gratuit** », « navigateur distant », « bureau à distance gratuit » :

| Risque | Réalité |
|---|---|
| **Usage frauduleux par des tiers** | ces services sont massivement utilisés pour du spam, du minage, des attaques. **Votre adresse IP et votre compte** peuvent être associés à ces usages |
| **Vol d'identifiants** | vous tapez un mot de passe dans une machine que vous ne contrôlez pas ; rien ne garantit qu'elle ne l'enregistre pas |
| **Violation de conditions d'utilisation** | presque tous interdisent l'usage prolongé, le calcul intensif ou l'hébergement |
| **Aucune traçabilité** | nos preuves doivent être **reproductibles et attribuables** ; une machine anonyme ne produit pas de preuve acceptable |
| **Fuite de données du projet** | le dépôt contient l'annuaire de test, les configurations, les journaux |

**Règle proposée (à valider par le responsable) :** nous n'utilisons que des plateformes **nommées, avec
des conditions écrites et un compte personnel** — jamais un service anonyme de mise à disposition de
machines.

## 4. Ce que cela changerait pour NexBSD — et ce que cela ne changerait pas

**Ce que la CI apporte :**
1. **l'image installable** (condition C de `docs/33`), seule voie vers J5 ;
2. **plusieurs constructions par jour** au lieu d'une ;
3. une **preuve de reproductibilité entre machines** — la seule qui manque encore à T-11 (nous avons prouvé
   deux constructions **sur la même machine**).

**Ce que la CI n'apporte pas :**
- elle ne remplace ni le banc, ni les preuves locales, ni le test avec un **client réel** ;
- elle ne rend pas NexBSD installable **par elle-même** : il faut d'abord écrire `release.sh` et la recette
  de construction de l'image.

## 5. Ordre proposé (inchangé, mais conforté)

1. **T-05a** — test de refus du pare-feu depuis le Mint *(prochaine étape, locale)* ;
2. **client réel** — le Mint accède aux partages *(preuve manquante la plus importante)* ;
3. **`release.sh`** — écrire la recette de l'image, même si elle ne peut pas encore tourner ici ;
4. **puis** porter cette recette en CI (Cirrus en premier candidat, GitHub Actions en second) ;
5. **vérifier** que l'image produite en CI donne les **mêmes empreintes** que nos constructions locales.

**Point d'honnêteté :** les quotas, tarifs et conditions des offres gratuites **changent souvent**. Ce
document décrit une **orientation**, pas un engagement contractuel : chaque option devra être vérifiée à la
source au moment de l'utiliser, et la sortie consignée.

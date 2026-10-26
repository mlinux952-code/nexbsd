# Réutilisation bornée de Gaia et MARS_NWE — ce qui est possible, à quel prix

**Date :** 2026-10-26 · **Origine :** proposition du responsable — *« si dans les couches supérieures, avec de
l'intelligence et des modifications pour devenir modernes, on pouvait utiliser Firefox OS / MARS_NWE ? On
essaie peut-être 2 composants qui peuvent être utiles. »*

**Réponse en une ligne :** **oui pour les *applications* de Gaia, non pour la *plateforme* Gaia ;
non pour MARS_NWE comme composant, oui pour son usage en laboratoire.** Deux expériences bornées sont
proposées, avec critère d'arrêt explicite. **Aucune ne touche la base, aucune ne bloque le chemin de l'image.**

---

## 1. Pourquoi on ne peut pas « moderniser » la plateforme Gaia

La tentation est légitime : le code est là, sous Apache-2.0. Mais ce qu'il faudrait modifier n'est pas
cosmétique, c'est **structurel** :

| Ce qu'il faudrait changer | Réalité |
|---|---|
| « Gonk » (noyau Linux + HAL Android) | il faudrait réécrire **toute** la couche matérielle pour FreeBSD |
| API privilégiées `mozTelephony`, `mozSms`, `mozApps`, `mozContacts`… | **supprimées de Gecko** ; les réimplémenter = écrire nous-mêmes les services correspondants (téléphonie, SMS) — or **R-05 dit qu'on ne promet pas ces fonctions** |
| Moteur Gecko | il n'existe plus d'API d'intégration tierce ; on a déjà choisi **WebKitGTK** (ADR-0003) |

**La règle qui tranche :** moderniser Gaia = réécrire Gaia. Ce n'est pas de la réutilisation, c'est un
développement neuf qui porterait un nom trompeur. **On ne le fait pas.**

## 2. Mais les **applications** Gaia, elles, sont réutilisables

C'est la vraie trouvaille de votre idée, et je la retiens.

Une application Gaia est une **page HTML/CSS/JS**. Beaucoup d'entre elles **n'utilisent aucune API
privilégiée** : calculatrice, horloge, calendrier (affichage), lecteur de musique, galerie, carnet.
Or **notre architecture prévoit exactement cela** : couche C = applications Web locales, moteur WebKitGTK,
navigation au clavier.

| Avantage | Détail |
|---|---|
| Licence | **Apache-2.0** → utilisable, y compris dans une image de release, avec notice |
| Dépendance système | **aucune** : ce sont des pages Web |
| Compatibilité | les API Web standard (DOM, CSS, JS) n'ont pas disparu ; seules les API `moz*` ont disparu |
| Gain | la couche **C** de NexBSD a aujourd'hui **zéro ligne**. Gaia est un **gisement** de code existant |

## 3. Proposition : **deux expériences bornées**, chacune avec un critère d'arrêt

### Expérience E-1 — Porter **une** application Gaia triviale (sonde)

| | |
|---|---|
| Objet | la **calculatrice** de Gaia (logique JS pure, aucune API privilégiée) |
| Où | `platform/apps/calculatrice/` — **hors de la base**, couche App |
| Comment | la charger dans WebKitGTK, corriger les appels obsolètes, vérifier qu'elle fonctionne **au clavier** |
| Critère de réussite | l'application s'ouvre, calcule, se pilote **entièrement au clavier** |
| **Critère d'arrêt** | si le portage dépasse **2 heures**, on arrête et **on écrit la nôtre** (une calculatrice = 200 lignes) |
| Ce que ça prouve | que le modèle « application Web locale sur WebKitGTK » **fonctionne** — c'est le préalable de T-10 |
| Licence | Apache-2.0 conservée dans un fichier `LICENCE-GAIA.txt` |

### Expérience E-2 — Fabriquer la **spécification NetWare** avec le banc MARS_NWE

| | |
|---|---|
| Objet | monter le banc A (MARS_NWE + DOSBox + IPX-sur-UDP) **en laboratoire isolé** |
| Où | hors du produit, hors de la base, machine isolée sans passerelle |
| But | **observer et écrire** le comportement NetWare à imiter : login, attach, map de lecteur, droits, scripts |
| Livrable | `docs/spec-netware-observee.md` — **notre** description, pas du code copié |
| **Ce que ça n'est pas** | ce n'est **pas** une intégration de MARS_NWE dans NexBSD : il exige IPX, absent de FreeBSD |
| Règle juridique | **on observe le comportement, on ne copie aucun code** (GPL-2) — c'est déjà ADR-0014, chemin 2 |
| Critère d'arrêt | abandon si le montage du banc dépasse **une session** ou si DOSBox ne s'émule pas correctement |

## 4. Ce qui reste **exclu**, et pourquoi

| Exclu | Raison |
|---|---|
| Gaia comme **plateforme** | Gonk = noyau Linux — impossible sur FreeBSD |
| Applications Gaia utilisant `moz*` | leurs API n'existent plus ; les porter = écrire des services téléphonie/SMS qu'on ne promet pas |
| MARS_NWE comme **composant** | exige IPX, retiré de FreeBSD 11.0 → imposerait un module noyau (ADR-0006) |
| Copier du code MARS_NWE dans notre implémentation NCP | contamination GPL-2 ; on utilise la **documentation publique Novell** (ADR-0018) |

## 5. Priorité — et ordre

Ces deux expériences sont classées **P3** (recherche), comme le chantier NCP. Elles **ne passent pas avant** :

1. **T-11** — reproductibilité du noyau *(en cours)* ;
2. harnais de tests automatisé ;
3. image produite par le projet (condition C de `docs/33`).

**Mais E-1 a une valeur particulière** : elle coûte ~2 heures et elle donne à NexBSD sa **première
application**. C'est la première fois qu'on écrirait du **code produit** plutôt que de la configuration.
Elle est donc **la première candidate** dès que les trois étapes ci-dessus sont faites.

## 6. Ce que cela change à notre discours

On ne dira jamais « NexBSD utilise Firefox OS ». On dira :

> « La couche applicative de NexBSD reprend des applications **Apache-2.0** issues du projet Gaia,
> exécutées sur **WebKitGTK**, sans la plateforme Gonk. »

C'est exact, c'est vérifiable, et ça respecte la règle : **« inspiré de », jamais « portage de »**.

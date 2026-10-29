# ADR-0021 — NexBSD immuable : racine en lecture seule et environnements de démarrage

- **Date :** 2026-10-29
- **Statut :** **PROPOSITION** — non acceptée. Elle engage une modification de l'architecture de
  distribution et **doit être tranchée par le responsable** (règles R-10/R-11 : aucune idée n'entre
  dans le produit sans décision écrite).
- **Déclencheur :** une affiche « Immutable Linux Distributions » envoyée par le responsable le
  2026-10-29 (`docs/62` §6). **Aucune des quinze distributions citées ne peut héberger NexBSD** —
  elles sont toutes Linux. Mais **le principe**, lui, est transposable, et FreeBSD en fournit déjà
  les pièces.
- **Ne révise aucune ADR existante.**

## Problème

Un serveur de fichiers d'entreprise change **très rarement** : sa configuration est décidée à
l'installation, puis elle ne bouge plus pendant des années. Or, dans l'état actuel du projet,
**rien n'empêche** un service compromis d'écrire dans le système :

- remplacer `/usr/local/sbin/smbd` par un binaire porteur d'une porte dérobée **qui survit au
  redémarrage** ;
- modifier `pf.conf` pour ouvrir un port ;
- ajouter une ligne dans `/etc/master.passwd` ;
- poser un script dans `/usr/local/etc/rc.d/` qui se relance à chaque démarrage.

Un attaquant qui obtient l'exécution de code via une faille Samba (par exemple une CVE de
`webkit2-gtk` **n'est pas nécessaire** : Samba suffit) dispose aujourd'hui d'une **prise permanente**.
Notre `pkg audit` (A-67) ne voit rien : il vérifie les **versions**, pas les **fichiers**.

## Décision proposée

Rendre le système NexBSD **immuable** en s'appuyant **exclusivement** sur des primitives FreeBSD,
sans inventer de mécanisme :

1. **Racine en lecture seule.** Le système de fichiers racine est monté depuis un jeu de données ZFS
   positionné `readonly=on` après l'installation. Rien ne peut y écrire, **y compris root**.
2. **Environnements de démarrage (`bectl`).** Une mise à jour ne modifie pas l'existant : elle crée
   un **nouvel** environnement. Si le démarrage échoue, **retour arrière en une commande**, atomique.
3. **`kern.securelevel` ≥ 1** après démarrage : interdit le chargement de modules noyau et la
   modification des règles de pare-feu par un processus, même root.
4. **`/etc` sur un jeu de données séparé**, petit et inspectable, où vivent **uniquement** les
   fichiers de configuration du produit (ceux de `fork/overlay/`).
5. **Les données vivent ailleurs** : `/var/samba`, les dossiers personnels et l'annuaire sont sur
   leurs propres jeux de données, **inscriptibles normalement**. La séparation système / données est
   le cœur du dispositif.
6. **Un mode « administrateur » explicite** : `nexbsd-mode-modification` remonte la racine en
   écriture **le temps d'une opération déclarée**, et la remet en lecture seule à la sortie. Toute
   modification devient **un acte volontaire et tracé**, jamais un effet de bord.

## Conséquences

### Ce que cela apporte

| Bénéfice | Détail |
|---|---|
| **Pas de persistance** | un service compromis ne laisse **rien** derrière lui : au redémarrage, le système est identique à ce qu'il était |
| **Réparation par remplacement** | au lieu de chercher ce qui a été modifié, l'administrateur **restaure** un environnement connu |
| **Traçabilité** | toute modification du système est un acte déclaré, pas une écriture silencieuse |
| **Reproductibilité** | deux NexBSD installés depuis la même image ont la même racine, à l'octet près |
| **Cohérence avec NetWare** | NetWare était réputé difficile à altérer ; c'est un argument de vente, pas un détail |

### Ce que cela coûte — et il faut le dire

| Coût | Détail |
|---|---|
| **Aucune protection contre l'exécution** | un Samba compromis **tourne quand même** et peut lire les fichiers qu'il sert. L'immuabilité empêche la **persistance**, pas l'**exploitation** |
| **Complexité d'installation** | la séparation en jeux de données doit être faite par `fork/80-installer-nexbsd.sh`, **qui n'a jamais tourné** |
| **Un mode « modification » à écrire** | et un mode de modification mal fait annule tout le bénéfice |
| **Contrainte pour l'administrateur** | il ne peut plus « bricoler » — c'est voulu, mais cela doit être **expliqué**, sinon il sera contourné |
| **Le noyau doit être configuré** | `NEXBSD_L1` doit embarquer ZFS et `bectl` ; à vérifier dans l'exécution suivante |
| **Rien n'est prouvé** | aucun test ne valide cette ADR aujourd'hui. Elle est une **intention**, pas un acquis |

### Ce qu'elle **n'est pas**

Ce n'est **pas** une réponse à la question « comment obtenir root » (**A-18**, toujours ouverte).
Ce n'est **pas** non plus un substitut au chiffrement des données au repos, ni à la sauvegarde.

## Alternatives examinées

| Alternative | Verdict |
|---|---|
| **Rester en racine inscriptible** (statu quo) | ❌ aucune protection contre la persistance |
| **UFS en lecture seule** (`ro` dans `fstab`) | ⚠️ possible, mais **sans environnement de démarrage** : le retour arrière demande un autre média. ZFS + `bectl` est meilleur là où ZFS est disponible |
| **Jails seules** | ⚠️ utile et **complémentaire**, mais ne protège pas le système hôte |
| **`kern.securelevel=2`** | ⚠️ trop strict pour un serveur qui monte des partages ; proposé à **1** |
| **Copier les distributions immuables Linux** | ❌ impossible : aucune ne tourne sur FreeBSD |

## Décision demandée au responsable

Trois choix, à formuler explicitement :

1. **OUI** — l'immuabilité entre dans le périmètre du produit (elle devient une exigence, avec un
   numéro, et son implémentation passe par `fork/80`).
2. **PLUS TARD** — le principe est accepté mais reporté après que l'image ait démarré (recommandé :
   **on ne complexifie pas un système qui n'a jamais booté**).
3. **NON** — NexBSD reste modifiable, avec le risque de persistance assumé et documenté.

**Recommandation de l'assistant : choix 2.** Une racine en lecture seule sur un système dont on ne
sait pas encore s'il démarre, c'est ajouter une variable à une équation non résolue.

## État

- Aucun fichier de cette ADR n'est implémenté. **Aucun.**
- Aucune exécution n'a été lancée ce soir (le téléchargement de l'artefact #18 était en cours).
- Acquis associé : **A-72** (proposition écrite, non appliquée).

# 52 — Bascule de Cirrus vers GitHub Actions (2026-10-28, nuit)

**Contexte.** Cirrus CI **injoignable** : `cirrus-ci.com`, `api.cirrus-ci.com` et `cirrus-ci.org`
renvoient tous `HTTP 000` avec `unexpected eof while reading` pendant la poignée de main TLS,
**depuis deux réseaux indépendants** (Tunis et atelier). `github.com` répond `200` au même instant.
Ce n'est ni notre réseau, ni nos machines : le service est éteint.

**Conséquence :** on ne peut pas produire une image sur un service qui ne répond pas. Bascule décidée.

---

## 1. L'alternative retenue, et pourquoi elle est MEILLEURE

`vmactions/freebsd-vm@v1` : lance une **vraie machine virtuelle FreeBSD** (QEMU/KVM) à l'intérieur
d'un job `ubuntu-latest` de GitHub Actions.

| Critère | Cirrus (éteint) | **GitHub Actions + VM FreeBSD** |
|---|---|---|
| Disponibilité | ❌ injoignable | ✅ `github.com` répond |
| Durée max par tâche | **2 h** | **5 à 6 h** |
| Coût, dépôt public | 50 crédits/mois | **illimité, gratuit** |
| Coût, dépôt privé | 10 $/mois | 2 000 min/mois incluses |
| FreeBSD | natif | **VM invitée** (KVM accélère le x86_64) |
| Image produite | artefacts | artefacts, **90 jours** |

**Le gain décisif : la durée.** Notre estimation de `buildworld` + `release` était de 1 h 15 à 1 h 55,
**serrée contre la limite de 2 h** de Cirrus. Avec 5 h 50, la contrainte disparaît presque.

---

## 2. Ce que la bascule coûte, dit franchement

| Coût | Détail |
|---|---|
| FreeBSD n'est plus natif | il tourne dans une VM sur un hôte Linux. Pour `buildworld` x86_64 c'est acceptable ; pour de l'**émulation aarch64** ce serait ~20× plus lent (constaté par d'autres projets, pas par nous) |
| Démarrage de VM | 1 à 3 min de surcoût **par tâche** |
| **Espace disque** | un runner a ~14 Go libres ; `buildworld` en réclame 25-30. D'où l'étape qui supprime les outils préinstallés inutiles (SDK Android, .NET, Haskell, images Docker). **Le contrôle échoue AVANT la compilation** si l'espace manque — on ne veut pas découvrir ça après 40 minutes |
| Version d'image | `release: "15.0"` : la version exacte des images de l'action **n'est pas vérifiée par nous**. Notre cible est 15.1. La tâche **SONDE** le dira |

---

## 3. Ce qui a été écrit : `.github/workflows/nexbsd.yml`

Quatre tâches, YAML **validé** :

| Tâche | Durée | But |
|---|---|---|
| **CONTRÔLES** | ~5 min | `scripts/70` (delta), `scripts/72` (registre), `scripts/74 --simulation` — dans une vraie VM FreeBSD |
| **BUREAU** | ~5 min | les **31 cas de test** du bureau (17 session + 14 authentification) sur FreeBSD |
| **IMAGE** | ≤ 5 h 50 | **déclenchement manuel** : libération d'espace, contrôle des 20 Go, production, dépôt de l'artefact |
| **SONDE** | ~5 min | quelle version FreeBSD l'action démarre réellement (`continue-on-error` : elle rapporte, elle ne doit pas réussir) |

**Le fichier `.cirrus.yml` n'est PAS supprimé** : il reste la référence d'une exécution **native**, à
réactiver si Cirrus revient. Il est simplement inutilisable aujourd'hui.

---

## 4. Ce qui reste à faire côté responsable (2 minutes)

1. **rendre le dépôt public** (décision déjà prise le 28/10) → Actions **illimité et gratuit** ;
2. ouvrir `https://github.com/mlinux952-code/nexbsd/actions` et vérifier que les workflows sont
   **activés** (GitHub demande parfois un clic « I understand my workflows, go ahead and enable them ») ;
3. lancer la tâche **CONTRÔLES** (bouton *Run workflow* ou simplement le prochain push).

**Aucune carte bancaire, aucun compte supplémentaire.** C'est le même compte GitHub que celui qui
reçoit déjà nos `push`.

---

## 5. État de vérité

| Affirmation | Statut |
|---|---|
| `.github/workflows/nexbsd.yml` est un YAML valide | ✅ **vérifié** (analyseur Python) |
| l'action `vmactions/freebsd-vm` existe et lance FreeBSD 15 | ✅ **documenté** par plusieurs sources indépendantes |
| KVM fonctionne sur `ubuntu-latest` | ✅ rapporté par d'autres projets (virtualisation imbriquée) |
| **notre workflow a tourné** | ✅ **2 exécutions, toutes deux ROUGES** (voir plus bas) |
| **la VM FreeBSD démarre** | ✅ **PROUVÉ à l'exécution #2** (étapes « Starting VM », « Syncing source code to VM ») |
| **les contrôles passent dans la VM** | ❌ **pas encore** — cause trouvée (C-34), correctif non testé |
| **une image a été produite** | ❌ **JAMAIS** |

### 5 bis. Exécution #2 — le progrès est mesurable

| | Exécution #1 | Exécution #2 |
|---|---|---|
| durée | 1 min 04 s | 38 s et 53 s |
| la VM démarre ? | **non** | **oui** |
| message | `ssh exited with code 1` | `ssh exited with code 1`, mais **après** le démarrage |
| cause | `ubuntu-latest` migré vers Ubuntu 26 | **git absent du système de base FreeBSD** (C-34) |

`git` n'est pas livré avec FreeBSD. Nos garde-fous comptaient les fichiers avec `git ls-files` :
dans la VM ils trouvaient **0 fichier sur 33** et accusaient à tort une suppression. Correctif :
compter le disque quand git n'est pas là, **et dire lequel des deux modes est employé**.

**Fichier `.cirrus.yml` supprimé** : Cirrus est mort (HTTP 000), et il contenait un mot de passe
de laboratoire en clair, interdit par R-15 dans un dépôt public.

**On ne saura qu'en lançant.** La première exécution de CONTRÔLES coûte ~5 minutes et ne construit
rien : c'est le meilleur moyen de savoir si la bascule tient, avant de payer une heure de calcul.

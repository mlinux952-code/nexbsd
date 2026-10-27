# Sortir de la VM — la chaîne qui produit une image, et pas un réglage de plus

**Date :** 2026-10-27 (soir, S-021, après la remarque du responsable)
**Sa phrase, conservée telle quelle :** *« depuis le début seulement tu ajustes sur une version de VM…
j'espère que c'est la dernière fois comme faute grave »*.
**Rôle de ce document :** établir les faits, nommer la cause, et décrire la sortie — avec ses limites.

---

## 1. Les faits, sans arrondi

| Question | Réponse mesurée le 2026-10-27 |
|---|---|
| Fichiers de **produit** (`fork/`) | **25** |
| Scripts de **banc** (`scripts/60`→`71`) | 13 |
| **Images NexBSD produites depuis le 23 octobre** | **0** |
| `fork/build-nexbsd.sh` | écrit, **jamais exécuté** ; refuse de démarrer sous 8 Go de RAM |
| `fork/release.conf` | écrit, **jamais exécuté** |
| RAM du poste | **3,7 Go** (minimum du profil L3 : 8 Go, ADR-0010) |
| Tout ce qui a été **exécuté** | **dans une VM** (FreeBSD 15.1 + noyau `NEXBSD_L1`) |

**Conclusion, sans détour : le responsable a raison.** Le socle et les preuves sont réels — le noyau est
compilé depuis les sources officielles, l'annuaire authentifie, le pare-feu refuse et journalise, l'accès
distant fonctionne par clé — mais **rien de tout cela n'est encore un système installable**. Ce sont des
propriétés vérifiées *dans une machine virtuelle configurée à la main*.

## 2. La cause n'est pas la méthode, c'est la machine

Le projet a passé quatre jours à prouver des propriétés **parce qu'il ne pouvait pas produire**. Le
verrou est unique et chiffré :

```
poste : 3,7 Go de RAM, 4 threads, 20 Go libres
buildworld + buildkernel + release : >= 8 Go de RAM, >= 30 Go libres, plusieurs heures
```

Tant que ce verrou n'est pas levé, chaque session produit nécessairement **du savoir** (des tests, des
leçons, des fichiers de configuration) et **pas de l'artefact**. Ce n'était pas une faute de jugement
isolée : c'était la conséquence mécanique d'une décision (ADR-0010) jamais rendue exécutable.

## 3. La sortie : une chaîne de production, exécutable ailleurs que sur le poste

Deux pièces ont été écrites ce soir, et **elles ne s'ajoutent pas à la pile des réglages** :

| Pièce | Rôle | État |
|---|---|---|
| **`scripts/74-produire-image.sh`** | la chaîne complète : vérifier le delta, vérifier l'empreinte de `src.txz`, extraire, appliquer le delta, `buildworld` + `buildkernel`, `release`, **manifeste d'empreintes**, vérification que l'image porte bien le `motd` NexBSD | **écrit, testé en `--simulation`** ; production réelle non exécutée |
| **`.cirrus.yml`** | la même chaîne, exécutée sur une machine FreeBSD **natif** en CI, avec dépôt de l'artefact | **écrit, YAML validé** ; **jamais exécuté** (aucun compte CI) |

### Ce que la simulation a réellement vérifié (sortie réelle)

```
----- 1. le delta du produit est-il complet ? -----
  [OK]    les 13 pieces du delta sont presentes
----- 2. aucun secret de laboratoire ne doit partir dans une image -----
  [OK]    aucun mot de passe en clair dans le delta
----- 3. cette machine peut-elle construire ? (profil L3, ADR-0010) -----
  ...     hôte = Linux : la construction exige un hôte FreeBSD
  [KO]    espace insuffisant
----- 5. bilan de simulation -----
  [KO]    cette machine NE PEUT PAS construire — c'est exactement pour cela que la CI existe
SIMULATION : le delta est complet et propre. Rien n'a été construit.
```

**Ce que cela prouve :** le delta est complet et ne contient aucun secret ; la machine, elle, ne peut pas
construire — et le script le dit au lieu de l'espérer.

## 4. Trois garde-fous de la chaîne (et un faux positif corrigé)

1. **Empreinte de `src.txz`** : `cf5762da…5a89e1`, relevée le 2026-10-25. Si elle diffère, **arrêt**.
2. **Secrets** : le script refuse de produire une image si un mot de passe de laboratoire subsiste dans
   `fork/`. **Premier essai : faux positif** — il criait sur mes propres commentaires de documentation.
   Corrigé pour ignorer les lignes `#` et `;`. *Un garde-fou qui crie à tort sera ignoré (M-10).*
3. **Capacité de la machine** : le script mesure RAM et disque avant de lancer quoi que ce soit, et il
   **refuse** plutôt que d'échouer après deux heures à mi-parcours.

## 5. Ce que cette chaîne ne fait PAS encore — dit franchement

| Manque | Conséquence |
|---|---|
| **Aucune exécution réelle** | `buildworld`/`release` n'ont jamais tourné. Le script peut contenir des erreurs que seule une exécution révélera (règle M-3 : ne jamais déclarer un script « bon » sans l'avoir vu tourner) |
| **`image_family: freebsd-15-1`** dans `.cirrus.yml` **non vérifiée** | le nom de l'image dans le catalogue Cirrus doit être contrôlé avant la première exécution |
| **Les `@PLACEHOLDERS@`** (`@NEXBSD_SID@`, `@NEXBSD_LDAP_ROOTPW@`…) | la chaîne produit une image **sans** identité configurée : c'est le rôle d'un **installeur** (A-19), qui n'existe pas |
| **L'overlay n'est pas encore copié dans l'arbre par `release.sh`** | la chaîne de production **construit** ; elle n'**intègre** pas encore nos fichiers `fork/overlay/`. Étape suivante explicite |

**Point 4 surtout :** dire « on produit une image » serait faux tant que l'overlay n'est pas intégré. La
chaîne actuelle produit une image **du socle**, avec `src.conf` et le noyau NexBSD. C'est un progrès réel,
pas une fin.

## 6. La règle qui empêche que cela se reproduise

**R-14 (ajoutée à `docs/40`) :** *une session qui ne produit que des réglages de banc doit le dire et le
justifier.* Concrètement : chaque session se termine par une ligne dans `matrices/acquis.csv` ; si aucun
acquis n'a progressé vers `PRODUIT` ou vers la **chaîne de production**, la session est déclarée
« session de banc » — utile, mais pas un pas vers J5.

## 7. Ce qu'il faut décider maintenant, et qui ne dépend pas de moi

Deux routes, une seule à choisir :

| Route | Coût | Délai |
|---|---|---|
| **A. CI Cirrus** (compte gratuit) | créer le compte, brancher le dépôt GitHub, vérifier `image_family`, lancer une première fois | **la prochaine étape utile** — aucune dépense |
| **B. Machine FreeBSD ≥ 8 Go** (PC plus puissant, serveur loué, VPS FreeBSD) | argent ou matériel | dépend du budget |

Sans l'une des deux, le projet continuera à produire des preuves — jamais une image. **C'est un choix,
pas une fatalité.**

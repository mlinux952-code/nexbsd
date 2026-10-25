# Révision totale — état réel de NexBSD au 2026-10-25 (fin de S-018)

**Version :** 1.0 · **Rôle :** audit **contradictoire** du projet : ce qui existe, ce qui est **prouvé**, ce qui est
seulement **écrit**, et ce qui reste à faire. Demandé par le responsable : *« faire une révision totale puis
continuer »*.
**Règle de ce document :** chaque affirmation doit être **vérifiable par une commande**. Ce qui n'est pas
vérifiable n'est pas affirmé. Aucun chiffre n'est arrondi en notre faveur.

---

## 1. Le projet en cinq lignes

NexBSD est un projet de **système pour PC faibles** (2 Go de RAM visés, PC de 2011), dont le **cœur est le
réseau façon NetWare** (identités centrales, droits par groupes, partages, administration unique) et dont le
modèle est celui d'un **fork de FreeBSD** : arbre source possédé, noyau propre, image propre, nom propre.
**Un banc d'essai fonctionne** sur la machine du responsable (VM FreeBSD 15.1 sur un portable 3,7 Go de RAM).
**Aucune image NexBSD n'existe** et le PC de 2011 n'est pas installé. Le produit reste à construire ; c'est
précisément ce que la campagne en cours attaque.

---

## 2. Chiffres mesurés (au commit `88a256e`)

| Élément | Valeur | Commande de vérification |
|---|---|---|
| Commits dans le dépôt | **58** | `git rev-list --count HEAD` |
| Fichiers suivis | **136** | `git ls-files \| wc -l` |
| Documents `docs/` | **57** (+ racine) | `ls docs/*.md docs/*/*.md \| wc -l` |
| Scripts | **18** | `ls scripts/*.sh \| wc -l` |
| Comptes rendus de tests | **8** | `ls tests/results/*.md \| wc -l` |
| Tests du plan | **20** | `tests/plan-tests.md` |
| Tests **réussis** | **6** | T-01, T-03, T-04, T-04-E, T-04-F, T-04-G |
| ADR | **20** | `ls docs/decisions/ADR-*.md` |
| ADR validées par le responsable | **0** | toutes à l'état `proposition` |
| Noyaux NexBSD construits | **0** | `docs/28` (campagne en cours) |
| Images NexBSD produites | **0** | — |
| Installations sur matériel réel | **0** | le PC de 2011 est intact |

---

## 3. Ce qui est réellement prouvé — et par quelle preuve

| Affirmation | Preuve | Verdict |
|---|---|---|
| FreeBSD 15.1 démarre en VM sur la station | `tests/results/T-01` | **prouvé** |
| Samba partage un volume authentifié, avec écriture et relecture | `T-03` | **prouvé** |
| OpenLDAP sert un annuaire d'identités | `T-04` | **prouvé** |
| Samba **et** OpenLDAP authentifient **ensemble** | `T-04-E` | **prouvé** (après 2 échecs consignés) |
| Les droits par groupe (2770, refus de `sara`) sont appliqués | `T-04-F` | **prouvé** |
| Le banc **revient seul** après redémarrage, en **11 contrôles sur 11** | `T-04-G`, essai 2 | **prouvé** |
| Le banc porte le nom NexBSD et l'invite `root@nexbsd` | `scripts/66`, T-16 | **appliqué** (compte rendu à reporter) |
| Les sources de la version installée sont épinglées et vérifiables | `docs/28` §4, SHA256 | **prouvé** |
| La configuration `NEXBSD_L1` est régénérable **à l'octet près** | régénération comparée, `14c86800…eb301` | **prouvé** (essai interne du 2026-10-25) |
| Le noyau NexBSD compile | — | **non prouvé** (c'est la campagne en cours) |
| NexBSD s'installe sur un PC | — | **non prouvé, non tenté** |

**Ce qui n'a jamais été fait, et qu'il ne faut pas laisser croire :** aucune compilation n'a jamais abouti dans
ce projet ; aucune image n'a jamais été produite ; le PC de 2011 n'a jamais reçu le produit ; aucun test n'a
été exécuté sur du matériel réel.

---

## 4. Le delta possédé : petit, vérifié, jamais compilé

`fork/` (17 fichiers) contient **tout** ce que NexBSD ajoute à FreeBSD :

| Fichier | Delta réel |
|---|---|
| `sys/amd64/conf/NEXBSD_L1` | `ident NEXBSD_L1` + **4 périphériques retirés** = **5 lignes** sur 393 |
| `src.conf` | 8 options de construction, chacune **vérifiée** dans `src.conf.5` 15.1 |
| `release.conf` | identité d'image, `KERNCONF=NEXBSD_L1`, `BRANCH_OVERRIDE=NEXBSD-L1` |
| `overlay/etc/{motd,nexbsd-version,rc.conf.defaults}` | identité et services au premier démarrage |
| `patches/0001-identite-version.patch` | ferait dire `uname -s` = NexBSD — **non appliqué** (risque documenté) |
| `tools/generer-kernel-conf.sh` | génération contrôlée du noyau depuis `GENERIC` |

**Point dur, dit franchement :** ce delta est **crédible mais modeste**. Il prouve la méthode, pas l'ampleur.
Un fork qui se respecte grandit son delta **délibérément** (ADR-0011) : c'est prévu, mais ça n'a pas commencé.

---

## 5. Le matériel : la contrainte qui commande tout

| Ressource | Mesure (2026-10-25) | Conséquence |
|---|---|---|
| RAM du poste | **3,7 Go** (787 Mo libres) | VM plafonnée à **2 048 Mo** ; pas de monde complet |
| Cœurs | 2 physiques / 4 fils | `-j2` maximum |
| Disque libre | **67 Go** | suffisant pour noyau **et** monde (30 Go) |
| Hyperviseur | **KVM disponible** (`/dev/kvm`, `virsh`, `qemu-system-x86_64`) | la VM tourne à pleine vitesse |
| VM gérée par libvirt système | **non** (liste `qemu:///system` vide) | la VM est lancée autrement : à identifier avant agrandissement |

**Décision de cadrage du responsable (2026-10-25) :** on teste **sur une VM**, sur un PC médiocre ; un jour
NexBSD s'installera **proprement sur un autre PC quelconque**. C'est cohérent avec ADR-0009/0010 et cela
devient le critère final : **« une image, un PC, une clé USB, et le système s'installe seul »**.

---

## 6. Les trois étages, et où nous en sommes

| Étage | Ce qu'il produit | État au 2026-10-25 | Preuve attendue |
|---|---|---|---|
| **1. Identité visible** | nom d'hôte, motd, invite | **APPLIQUÉ** | `root@nexbsd:~ #` (verbatim obtenu) |
| **2. Noyau propre** | `NEXBSD_L1` compilé par le projet | **EN CAMPAGNE** (ADR-0020, scripts 67→69) | `uname -i` = `NEXBSD_L1`, `uname -r` = `15.1-NEXBSD-L1` |
| **3. Image propre** | `release.sh` → image amorçable | **NON COMMENCÉ** — hors de portée du poste | installation sur VM neuve, puis sur un PC |

---

## 7. Risques ouverts (ce qui peut encore faire échouer le projet)

| # | Risque | Effet | Réponse actuelle |
|---|---|---|---|
| P-03 | pas de machine puissante (L3) | pas d'image produite sur le poste | ADR-0020 pour le noyau ; **intégration continue** pour l'image |
| R-1 | construction tuée par manque de RAM (2 Go, swap) | 2 à 6 h perdues, mais **reprenable** | `-j2` plafonné, 2 Go d'échange, journal |
| R-2 | noyau compilé mais non amorçable | banc hors service quelques minutes | noyau d'origine **renommé**, pas effacé ; retour par le chargeur |
| R-3 | dérive documentaire (décrire ce qui n'existe pas) | perte de confiance, erreurs en chaîne (cf. **C-16**) | chaque affirmation doit avoir une commande de vérification |
| R-4 | objectif dilué en tests de banc sans fin | le produit n'existe jamais | jalon fixé : **noyau d'abord, image ensuite** |
| R-5 | aucune ADR validée par le responsable | décisions techniques qui ne sont pas des décisions | les choix structurants sont posés, numérotés, à entériner |

---

## 8. Feuille de route révisée — jusqu'à l'installation sur un vrai PC

| # | Jalon | Critère de réussite (vérifiable) | Blocage |
|---|---|---|---|
| **J1** | Noyau propre | `uname -i` = `NEXBSD_L1` **et** banc 11/11 sur ce noyau | RAM du poste (franchissable) |
| **J2** | `uname -s` = `NexBSD` | patch d'identité appliqué **après** J1, avec risque consigné | décision à prendre |
| **J3** | Monde propre (`src.conf`) | `buildworld` réussi, image sans jeux/exemples/tests | **intégration continue** (obligatoire) |
| **J4** | Image installable | `release.sh` → image démarrable en VM neuve | CI |
| **J5** | Installation réelle | le PC de 2011 (ou n'importe quel PC) démarre sur clé USB et s'installe | matériel + J4 |
| **J6** | Banc d'identités **dans le produit** | scripts 60→69 regroupés en `components/identites/`, une commande | J4 |
| **J7** | Différenciation NetWare | client NCP réel (T-09) | service NCP inexistant |

**Ordre non négociable :** J1 → J2 → J3 → J4 → J5. Sauter J1 pour « aller plus vite vers l'image » a déjà été
refusé : sans noyau propre, il n'y a rien à mettre dans l'image.

---

## 9. Ce que je ne promets pas

- Je ne promets **pas** une image NexBSD installable ce soir : le poste ne construit pas un monde complet.
- Je ne promets **pas** que la première construction du noyau aboutira : elle peut échouer (swap, OOM), et
  l'échec sera publié verbatim.
- Je ne promets **pas** un système « écrit de zéro » : c'est un **fork**, et c'est ce que nous assumons.
- Je promets **une** chose : à la fin de l'étage 2, le noyau qui tourne sur le banc sera **compilé par le
  projet**, avec une provenance vérifiable à l'octet près. C'est le premier acte de possession du système.

---

## 10. Prochaine action, unique

Identifier **comment** la VM du banc est lancée (libvirt en session ? QEMU direct par `scripts/30`/`31` ?
virt-manager ?), puis l'agrandir : **2 048 Mo de RAM** et **30 Go de disque de construction**.
Rien ne se lance avant cette identification : la commande d'agrandissement n'est pas la même selon le cas,
et deviner ici ferait perdre une soirée de construction.

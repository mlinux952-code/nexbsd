# De FreeBSD à NexBSD — la feuille de route du vrai système

**Version :** 1.0 — 2026-10-25 (session S-017)
**Déclencheur :** remarque du responsable, justifiée : *« vous avez fait un FreeBSD customisé… je veux un système à part entière »*.
**Rôle :** dire exactement ce qui sépare le banc actuel d'un système autonome, et par quelles étapes **vérifiables** on y passe.

---

## 1. Le constat, sans complaisance

| Question | Réponse honnête au 2026-10-25 |
|---|---|
| Le banc fonctionne-t-il ? | **oui** — 6 tests réussis, identités et droits persistants |
| Est-ce NexBSD ? | **non** — le socle est une **FreeBSD 15.1 d'origine**, non modifiée ; nous avons ajouté des **services** |
| Qu'est-ce qui manque pour être « un système à part entière » ? | **notre propre noyau, notre propre userland, notre propre image** — c'est-à-dire une **construction** issue de **notre** arbre source |

Autrement dit : nous avons prouvé qu'un serveur d'identités façon NetWare **fonctionne sur FreeBSD**. Nous n'avons pas encore fait **NexBSD**.

## 2. Le delta du fork existe déjà — et il a été retrouvé ce jour

Le projet disposait d'un delta écrit en session S-010 (`fork/`, 17 fichiers). **Il avait été supprimé
par erreur** au commit `25ae838` (S-012, un commit sans rapport), et la documentation continuait d'en parler
comme s'il existait. Il est **restauré** (voir registre **C-16**). Contenu retrouvé :

| Fichier | Rôle | État |
|---|---|---|
| `sys/amd64/conf/NEXBSD_L1` | configuration du noyau NexBSD (`ident NEXBSD_L1`), dérivée de GENERIC | générée, **jamais compilée** |
| `sys/amd64/conf/NEXBSD_L1.rapport` | chaque ligne retirée et sa justification | produit |
| `src.conf` | options du monde, **vérifiées** dans `src.conf.5` 15.1 | jamais utilisé |
| `release.conf` | identité d'image, `KERNCONF=NEXBSD_L1`, `BRANCH_OVERRIDE=NEXBSD-L1` | jamais exécuté |
| `overlay/etc/{motd,nexbsd-version,rc.conf.defaults}` | identité et services au premier démarrage | non intégré |
| `patches/0001-identite-version.patch` | ferait dire `uname -s` = « NexBSD » | **non appliqué**, risque documenté |

## 3. Les trois étages, et ce que chacun prouve réellement

| Étage | Ce que l'on produit | Ce que cela prouve | Blocage réel |
|---|---|---|---|
| **1. Identité visible** | nom d'hôte, accueil, invite | le produit a un nom | **aucun** — fait (`scripts/66`, T-16) |
| **2. Noyau propre** | `NEXBSD_L1` compilé et installé ; `uname -i` = `NEXBSD_L1`, `uname -r` = `15.1-NEXBSD-L1` | **le système exécute un noyau que le projet a construit**, au lieu de celui de FreeBSD | **capacité de construction** (RAM/disque/temps) |
| **3. Image propre** | `release.sh` produit une image amorçable NexBSD (monde + noyau + overlay) | NexBSD **s'installe** — ce n'est plus un FreeBSD modifié à la main | capacité de construction **et** validation en VM |

**Point capital, vérifié dans `newvers.sh` 15.1 :** le levier `BRANCH_OVERRIDE` est **prévu par l'amont**.
Il suffit donc de **construire** avec `release.conf` pour que `uname -r` réponde `15.1-NEXBSD-L1`, **sans
modifier une seule ligne du code FreeBSD**. L'étage 2 est donc atteignable **sans risque juridique ni
technique**, et c'est la première fois que le système s'annoncera comme NexBSD.

## 4. Ce que la construction exige (chiffres, pas impressions)

| Ressource | `buildkernel NEXBSD_L1` | `buildworld` + `release.sh` |
|---|---|---|
| Arbre source (`git clone --depth 1 -b releng/15.1`) | ≈ 1,5 Go | ≈ 1,5 Go |
| Espace objet + sortie | ≈ 4 à 8 Go | ≈ 20 à 30 Go |
| RAM | ≥ 2 Go (4 Go conseillé) | ≥ 4 Go (8 Go conseillé) |
| Temps (2 cœurs, i3-3110M) | ≈ 1 à 3 h | ≈ 8 à 20 h |

Le banc actuel (VM de 1,5 Go de RAM, disque 6 Go) **ne peut pas** construire. Trois voies possibles :

| Voie | Avantages | Limites |
|---|---|---|
| **A. Machine du responsable** | tout reste local, aucune dépendance externe | disk/RAM à mesurer ; longue ; la VM doit être agrandie |
| **B. Intégration continue (GitHub Actions, VM FreeBSD)** | 4 cœurs, 16 Go de RAM, gratuit, **reproductible**, l'image est téléchargeable ; GitHub est déjà notre référentiel technique (Partie XX) | disque limité (~14 Go) : suffisant pour un **noyau**, juste pour un monde complet ; suppose un compte et un dépôt (déjà en place) |
| **C. Emprunter une machine** | rapide | dépend d'un tiers, non reproductible → **déconseillé** |

**Recommandation :** voie **B** pour l'étage 2 (noyau), puis **A ou B** pour l'étage 3 selon la mesure du poste.

## 5. Séquence immédiate

1. **Mesurer** le poste (RAM, cœurs, disque libre) — une commande, voir `docs/28`.
2. **Étage 2** : construire `NEXBSD_L1`, l'installer sur le banc, vérifier `uname -i` et `uname -r`.
   Critère de réussite : le banc **démarre** sur un noyau construit par le projet.
3. **Étage 3** : `buildworld` + `release.sh` avec `src.conf`/`release.conf`/overlay → image, testée en VM.
4. Alors seulement, le livrable 11 « prototype minimal » passe de *amorcé* à **fait**.

## 6. Décision à prendre par le responsable

L'ADR-0010 (« aucune compilation lourde hors profil L3 ») et le problème **P-03** (profil L3 indisponible)
bloquent aujourd'hui les étages 2 et 3. Les franchir suppose de **réviser ADR-0010** : accepter une
construction lourde **une fois**, sur le poste ou en intégration continue, pour produire la première image.

C'est une décision de direction de projet, pas une décision technique. Elle est posée ici, numérotée,
et attend une réponse explicite du responsable.

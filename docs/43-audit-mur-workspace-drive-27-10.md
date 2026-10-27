# Où nous sommes — audit du 2026-10-27 au soir (mur, workspace, Drive)

**Demandé par :** le responsable — *« quand tu vérifies le mur, le workspace et le Drive, où nous sommes du
projet ? »*
**Méthode :** trois vérifications **réelles**, exécutées ce soir : lecture de `docs/15` (mur), comptage dans
le dépôt (workspace), interrogation de l'API Drive (liste des fichiers du dossier). **Aucun chiffre de
mémoire.**

---

## 1. LE MUR (méga-prompt maître, Partie XIV — 20 livrables)

**Bilan : 12 faits · 6 partiels · 2 non faits** (`docs/15` v1.3).

| État | Livrables |
|---|---|
| ✅ **faits (12)** | 4 composants · 5 licences · 6 compatibilités · 7 architecture · 8 flux · **10 plan de tests (22 tests, 13 exécutés)** · 13 registre des problèmes · **16 politique de sécurité (mesures prouvées)** · 18 historique · 19 contribution · 14 guide de construction (exécuté 2 fois) · 1 document fondateur |
| 🟡 **partiels (6)** | 2 cahier des charges (pas de narratif unique) · 3 faisabilité (conclusion impossible sans matériel) · **9 diagnostic matériel (aucune mesure sur le PC de 2011)** · 11 prototype (réel mais **non packagé**) · 12 rapport de tests (**pas de rapport de validation unique**) · 15 guide d'installation · 17 procédure de mise à jour |
| ❌ **non faits (2)** | 20 rapport final (par nature) · et l'**image installable**, qui n'est pas un livrable du mur mais un **jalon du projet (J5)** |

**Ce qui a changé ce soir au mur :** livrables **10**, **11**, **12** et **16** ne reposent plus sur des
intentions mais sur des **sorties de console** — un client extérieur a lu des fichiers à travers le pare-feu,
un port fermé a été prouvé fermé et journalisé, l'administration passe par une **clé**, l'horloge est
**synchronisée**.

**Ce qui n'a pas bougé, et qu'il faut dire aussi fort :**
- livrable **9** : **aucune** mesure sur le PC de 2011 → c'est le seul verrou **externe** ;
- **aucune image installable** : le prototype n'est pas encore un produit ;
- **bureau et applications NexBSD : zéro ligne** ;
- `/etc/motd` annonce encore **FreeBSD** (défaut produit relevé ce soir, non corrigé).

---

## 2. LE WORKSPACE (vérifié par commandes, pas par mémoire)

| Élément | Valeur mesurée ce soir |
|---|---|
| commits | **114** (départ : 57 il y a deux jours) |
| documents (`docs/*.md`) | **47** |
| comptes rendus de tests (`tests/results/*.md`) | **15** |
| scripts | **21** |
| couloirs de recherche (`research/`) | **11** |
| taille du dépôt | **7,1 Mo** (workspace total 11 Mo — après nettoyage de 41 Mo → 9,3 Mo le 27/10) |
| tests réussis | **13 / 22** |
| derniers commits | `599b594` (docs/15 v1.3) · `2d7ce64` (T-21) · `49505b1` (T-21 addendum clé) · `e12c79a` (T-20) · `a7d16dc` (T-19) · `99755be` (`scripts/31` v3) · `71331ec` (C-27) · `f6ce8e4` (T-05a) |

**Cohérence du workspace :** aucun document ne déclare un test réussi sans que le compte rendu correspondant
existe dans `tests/results/`. Vérification faite : 15 comptes rendus pour 13 tests déclarés réussis — les deux
de plus étant T-19 (validation **à blanc**, explicitement marquée comme telle) et l'addendum de T-21.

---

## 3. LE DRIVE (référentiel documentaire — interrogé directement)

**Dossier `NexBSD` : 32 fichiers.** Contenu exact de la dernière génération :

| Fichier | Date | Taille |
|---|---|---|
| `nexbsd-depot-2026-10-27-s043.bundle` | 27/10 20:07 | 546 718 o |
| `nexbsd-depot-2026-10-27-s042.bundle` | 27/10 20:02 | 542 243 o |
| `nexbsd-depot-2026-10-27-s041.bundle` | 27/10 19:20 | 528 506 o |
| `nexbsd-depot-2026-10-27-s040.bundle` | 27/10 19:05 | 517 491 o |
| `nexbsd-depot-2026-10-26-s038.bundle` | 26/10 22:20 | 502 823 o |
| … série continue **s017 → s043** | 25/10 → 27/10 | 356 487 → 546 718 o |
| scripts de banc | `pf71-v1.2.sh`, `pf71-v1.3.sh`, `harnais.sh`, `harnais-v1.1.sh`, `71-pare-feu-pf.sh` | 8,7 → 10,2 Ko |

**Trois réserves d'honnêteté sur le Drive :**
1. **Le rangement de la Partie XX n'est toujours pas appliqué** (`00_Gouvernance/`, `02_Cahier_des_Charges/`…) :
   tout est **à plat** dans un seul dossier.
2. **Le bundle le plus récent (s043) est antérieur aux tests T-20 et T-21** : la soirée s'est poursuivie après
   le dernier instantané. → **s044 créé et déposé en clôture de cet audit.**
3. **GitHub : état inconnu.** Aucune sortie `git push` n'a jamais été observée ; je ne peux donc **rien
   affirmer** sur le dépôt distant. C'est une réserve que je maintiens depuis `docs/15` v1.1.

---

## 4. RÉPONSE EN UNE PHRASE

**Le cœur serveur de NexBSD est debout, prouvé et maintenant administrable à distance** (identités,
droits, partages, pare-feu à refus par défaut journalisé, horloge, SSH par clé, sur notre propre noyau) —
**mais ce n'est pas encore un produit installable** : il manque l'image (J5), le bureau, les applications,
l'identité unique côté session, et **la mesure du matériel réel**.

---

## 5. LES TROIS PROCHAINES MARCHES (inchangées dans l'ordre, révisées dans le détail)

1. **Durcir SSH** (`PasswordAuthentication no`, `PermitRootLogin no`) — **désormais sans risque** : la clé est
   prouvée. Puis corriger `/etc/motd` (le produit doit dire **NexBSD**).
2. **Ramener le banc à une commande** : `scripts/31 --reseau` + harnais 24/24 → base de `release.sh`.
3. **Image installable** (J5) — avec, au préalable, le **diagnostic matériel** du PC de 2011 (livrable 9),
   qui reste le seul verrou que je ne peux pas lever à votre place.

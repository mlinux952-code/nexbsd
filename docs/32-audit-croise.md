# Audit croisé — notre travail jugé avec la grille du collègue

**Version :** 1.0 — 2026-10-26 (session S-019)
**Méthode :** on applique à **notre** dépôt les exigences de preuve du travail extérieur P1
(`docs/31`, `research/noyau-propre/`). Chaque critère reçoit un verdict **sans complaisance** et, si nécessaire,
une **action corrective**. Un audit qui ne trouve rien est un audit inutile.

---

## 1. Échelle d'indépendance adoptée (I0→I5)

| Niveau | Définition |
|---|---|
| **I0** | système installé tel quel, non modifié |
| **I1** | + paquets ajoutés (aucune construction) |
| **I2** | **noyau tiers recompilé par nous**, avec **notre** configuration et **notre** identité de version |
| **I3** | + **userland recompilé par nous** (`src.conf`) et **image produite par nous** (`release.sh`) |
| **I4** | **noyau original écrit par nous** |
| **I5** | tout original (noyau, userland, pilotes, outils) |

**Position de NexBSD au 2026-10-26, prouvée :**

| Élément | Niveau | Preuve |
|---|---|---|
| Banc d'identités (T-04-G 11/11) | **I1** | services rendus, mais sur un socle non reconstruit |
| Noyau `NEXBSD_L1` compilé | **I2** | `Kernel(s) NEXBSD_L1 built in 1470 seconds`, `15.1-NEXBSD-L1`, sha256 `82dc5681…` |
| Après J3/J4 (monde + image) | visé **I3** | à faire en intégration continue |
| Couloir recherche P1 | **I4** | noyau original, mais sans réseau/disque/FS/comptes |

**Conséquence d'affichage :** tout livrable doit désormais porter son niveau. `ETAT.md` et le README l'affichent.

---

## 2. Audit, critère par critère

| # | Critère du collègue | Notre état réel | Verdict | Action |
|---|---|---|---|---|
| 1 | Aucune affirmation sans test réel | Règle appliquée depuis le début ; deux corrections publiques (C-17, C-18) ; chaque résultat consigné verbatim | **CONFORME** | — |
| 2 | Preuve brute citée mot à mot | `tests/results/` contient les sorties collées, y compris les échecs | **CONFORME** | — |
| 3 | **Reproductibilité par empreintes de sortie** | **Nous n'avons jamais reconstruit deux fois pour comparer.** Nous savons identifier un binaire (sha256), pas encore prouver qu'il est reproductible | **NON CONFORME** | **T-11** : reconstruire `NEXBSD_L1` depuis un état propre et comparer les sha256 ; écrire l'écart éventuel. À planifier (≈25 min de calcul) |
| 4 | Harnais de test automatisé (leur `tools/test.sh` lance des dizaines de vérifications) | Nos tests sont des **protocoles manuels** exécutés à la main, un par un | **NON CONFORME** | Créer `tests/harnais.sh` pour les vérifications répétables (T-04-G, T-17) au lieu de protocoles à recopier |
| 5 | Isolement : VM uniquement, matériel jamais touché | Respecté : VM libvirt, disque système intact, PC de 2011 jamais modifié | **CONFORME** | — |
| 6 | Licence vérifiée par composant | `docs/12` existe, `scripts/40` contrôle la frontière ; mais **pas de matrice à jour fusionnée** avec leurs 21 composants | **PARTIEL** | Fusionner leur matrice de licences dans `matrices/` |
| 7 | Registre de décisions à jour, statuts honnêtes | 20 ADR, **toutes en `proposition`**, aucune validée par le responsable | **PARTIEL** | Faire acter par le responsable les ADR structurantes (0001, 0009, 0010, 0011, 0017, 0020) |
| 8 | Niveau d'indépendance affiché sur chaque livrable | N'était pas fait avant cet audit | **CORRIGÉ** | §1 + `ETAT.md` v17 |
| 9 | Journal de construction complet conservé | Phase 1 : 45 253 lignes ✔ · **phase de reprise : tronquée** (redirection altérée au transport) | **PARTIEL** | Journal corrigé dans la prochaine construction ; la règle est consignée dans `T-17` |
| 10 | Retour arrière documenté et testable | `docs/28` §7 + `docs/30` §3 : `set kernel="kernel"` au chargeur, noyau d'origine jamais effacé | **CONFORME** | — |
| 11 | Séparation recherche / produit | Clarifiée ce jour (`docs/31`) : couloir recherche sans temps du produit avant J5 | **CONFORME** | — |
| 12 | Chaîne de provenance complète (source → configuration → binaire) | `src.txz` (sha256 `cf5762da…`) → `GENERIC` (`02491b53…`) → `NEXBSD_L1` (`14c86800…`) → noyau (`82dc5681…`) | **CONFORME — c'est notre point fort** | — |

**Bilan : 7 conformes · 4 partiels · 2 non conformes** (reproductibilité, harnais automatisé).

---

## 3. Ce que le collègue fait mieux que nous, et que nous adoptons

1. **Reproductibilité mesurée** (T1a/T1b chez eux : deux constructions, mêmes empreintes). Chez nous : à créer.
2. **Harnais automatisé** : un seul script qui rejoue tous les tests et rend un **verdict global** avec code de
   sortie. Chez nous : des protocoles écrits, exécutés à la main.
3. **Verdict par test dans un tableau unique** (`OK` / échec), plus lisible que nos récits d'essais.
4. **Un niveau d'indépendance affiché** sur chaque livrable, pas seulement à la fin.

## 4. Ce que nous faisons mieux qu'eux, et qu'il faut garder

1. **Le service réel** : annuaire + Samba + droits qui **fonctionnent ensemble** et **revivent après
   redémarrage** (11/11). Leur noyau ne sert encore aucun fichier.
2. **Chaîne de provenance outillée** : empreintes épinglées, refus de compiler une archive non vérifiée.
3. **Garde-fou anti-perte de delta** (`scripts/70`), né de deux incidents réels (C-16, C-18).
4. **Documentation de reprise sans conversation** (`docs/25`, `docs/30`).

---

## 5. Actions correctives, dans l'ordre

| # | Action | Critère de réussite |
|---|---|---|
| 1 | **Terminer J1** : installer le noyau, redémarrer, rejouer `scripts/64` | `uname -i` = `NEXBSD_L1` et **11/11** |
| 2 | **`tests/harnais.sh`** : rejouer T-04-G et T-17 sans recopier de protocole | un seul code de sortie, verdict global |
| 3 | **T-11 reproductibilité** : seconde construction, comparaison sha256 | empreintes identiques ou écarts expliqués |
| 4 | Fusionner la matrice de licences du collègue | `matrices/` à jour, 21 composants |
| 5 | Faire acter les 6 ADR structurantes par le responsable | statuts `validée` ou `rejetée`, jamais vides |

---

## 6. Verdict de l'audit

**Le travail est correct, la route est la bonne, et deux exigences de rigueur nous manquent encore.**
Nous savons **prouver d'où vient notre noyau** (ce que beaucoup de projets ne savent pas faire) ; nous ne savons
pas encore **prouver qu'il est reproductible**, et nos tests ne sont pas automatisés. Ce sont des manques de
**forme de preuve**, pas de fond : ils se corrigent en deux séances, et ils sont maintenant écrits noir sur blanc.

---

## Mise à jour du 2026-10-26 au soir — non-conformité n° 1 **CLOSE**

| Critère | Statut | Preuve |
|---|---|---|
| **Reproductibilité mesurée** | **NON CONFORME → CONFORME** | `tests/results/T-11-reproductibilite.md` : deuxième construction à froid (`/build/obj2`, 6533 s) donne **exactement** `82dc5681397b06fab69171daf6e910d6a380b058ee63341a83c77f770b94c87c`, identique à la première |

**Décompte révisé : 8 conformes · 3 partiels · 1 non conforme** (le harnais automatisé restait le dernier manque).

### Mise à jour (même soir) — harnais **écrit**, en attente d'exécution

`tests/harnais.sh` a été écrit le 2026-10-26 (261 lignes, sha256 `bbf5d8de…66f2`) : 24 contrôles en une passe,
verdict global et **code de retour**, aucun redémarrage nécessaire. Le critère « harnais automatisé » passe
donc de **non conforme** à **partiel** : il manque **l'exécution** sur la VM et la sortie verbatim.
**Décompte : 8 conformes · 4 partiels · 0 non conforme.**

### Mise à jour (2026-10-26, 22:19 UTC) — harnais **exécuté et réussi**

`sh harnais.sh` → **`HARNAIS : REUSSI (24/24 obligatoires)`**, **code de retour 0**, en ~30 secondes.
Le critère « harnais automatisé » passe de *partiel* à **CONFORME**. **Décompte final : 9 conformes · 3 partiels · 0 non conforme.**
Le collègue avait raison de pointer ce manque : il est désormais comblé, avec une mesure, pas une intention.

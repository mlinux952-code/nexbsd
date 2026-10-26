# Revue générale — où en est NexBSD au 2026-10-26

**Objet :** répondre à la demande du responsable : *« révise tous : mur de discussion, workspace, Drive —
où sommes-nous dans l'aboutissement de notre système, avec toutes les caractéristiques d'un système
de cette combinaison d'ingrédients ? »*

**Méthode :** trois sources confrontées, pas une seule.
1. **Le fil de discussion** (ce qui a été demandé et décidé, y compris les corrections).
2. **Le workspace** = le dépôt `/home/user/nexbsd`, **83 commits** avant ce document, arbre propre.
3. **Google Drive** = les instantanés `.bundle` (s035 à venir avec ce document).

**Règle de lecture :** une case ne passe à « FAIT » que si elle est **prouvée par une sortie collée**.
Tout le reste est « partiel » ou « absent ». Aucune case n'est arrondie vers le haut.

---

## 1. Les quatre étages — et nous sommes à l'étage 2

| Étage | Ce que cela veut dire | État au 2026-10-26 | Preuve |
|---|---|---|---|
| **1 — Identité** | le banc porte le nom NexBSD (hôte, accueil, invite) sans rien casser | **FAIT** | T-16, invite `root@nexbsd` |
| **2 — Noyau propre** | le banc tourne sur un noyau **compilé par le projet**, annoncé sous notre nom de version | **FAIT ce soir** | `uname -i` = `NEXBSD_L1`, `uname -r` = `15.1-NEXBSD-L1`, `kern.version` = `FreeBSD 15.1-NEXBSD-L1 NEXBSD_L1` |
| **3 — Image propre** | une image **produite par le projet** qui s'installe sur un PC nu | **ABSENT** — hors de portée du poste (4 Go de RAM) ; voie CI à ouvrir | — |
| **4 — Autonomie** | NexBSD produit ses propres paquets (base comprise : `pkgbase`), et se met à jour seul | **ABSENT** | — |

**Traduction franche :** NexBSD est aujourd'hui **un banc d'essai sur noyau propre**. Ce n'est **pas encore
un système installable**. L'écart entre les deux n'est plus une intuition : c'est l'étage 3, et il est chiffré
ci-dessous (§4).

---

## 2. La matrice des ingrédients — ce qui fait un « vrai système »

Chaque ligne = un ingrédient nécessaire pour qu'un système de cette famille existe. Colonne « état » :
**FAIT** (prouvé), **PARTIEL** (existe, non prouvé ou incomplet), **ABSENT**.

| # | Ingrédient | Où il en est | État |
|---|---|---|---|
| 1 | **Noyau** compilé par le projet | `NEXBSD_L1`, 28 912 376 o, sha256 `82dc5681…`, 1470 s de compilation | **FAIT** |
| 2 | **Noyau démarré** sur le matériel cible | démarrage réussi, 858 modules installés (158 Mo), `/boot/kernel` d'origine intact | **FAIT** |
| 3 | **Identité système** (`uname`, `kern.ident`, version) | `NEXBSD_L1` / `15.1-NEXBSD-L1` — aucune ligne de FreeBSD modifiée (`BRANCH_OVERRIDE`) | **FAIT** |
| 4 | **Monde utilisateur** (binaires de base) | c'est encore le monde utilisateur **FreeBSD 15.1** intégral | **ABSENT en tant que NexBSD** |
| 5 | **Démarrage / init / rc** | `rc.d` de FreeBSD, services armés (`slapd`, `samba_server`) et vérifiés | **PARTIEL** (fonctionne, mais hérité) |
| 6 | **Annuaire d'identités** (OpenLDAP) | 10 entrées, SID cohérent, `slapd` armé au démarrage | **FAIT** (banc) |
| 7 | **Identités Unix dérivées de l'annuaire** (NSS + PAM) | `bureau` 2001, `stagiaires` 2002 résolus après redémarrage (C-14 clos) | **FAIT** (banc) |
| 8 | **Partage de fichiers + droits** (Samba) | `[commun]` `root:2001 2770`, `drwxrws---`, `ldapsam:trusted = yes`, `netbios name = NEXBSDFS` | **FAIT** (banc) |
| 9 | **Persistance après coupure** | **T-04-G 11/11 le 2026-10-25** ; rejeu **sur notre noyau** en cours ce soir | **FAIT** (à re-prouver sur `NEXBSD_L1`) |
| 10 | **Client réel non-FreeBSD** (Windows / Linux) | tous les essais SMB ont été faits par `smbclient` **depuis la VM elle-même** | **ABSENT** — jamais testé depuis un vrai poste client |
| 11 | **Réseau / découverte de services** (esprit SAP) | T-15 non exécuté, mDNS/DNS-SD non configuré | **ABSENT** |
| 12 | **Isolation / pare-feu** | T-05, T-05a non exécutés, `pf` non configuré | **ABSENT** |
| 13 | **Impression partagée** | T-07 non exécuté, CUPS non installé | **ABSENT** |
| 14 | **Sauvegarde / restauration** | T-06 non exécuté, aucune procédure de restauration exercée | **ABSENT** |
| 15 | **Installateur** (installer sur un PC nu) | l'installateur utilisé est celui de FreeBSD ; aucune image NexBSD | **ABSENT** |
| 16 | **Image système produite par le projet** | `release.sh` impossible sur le poste (4 Go de RAM) → voie CI identifiée (`docs/27`, voie B) | **ABSENT** |
| 17 | **Dépôt de paquets NexBSD** (`pkgbase`) | rien ; FreeBSD 15 fournit des paquets **FreeBSD** (cf. C-19) | **ABSENT** |
| 18 | **Interface petit écran** (WebKit, phase 5) | ADR-0003 tranché, aucun prototype | **ABSENT** |
| 19 | **Chemin NCP** (la différenciation NetWare) | ADR-0019 tranché (client NCP réel gratuit), banc B non monté, service NCP inexistant | **ABSENT** |
| 20 | **Mesure de consommation** (objectif ≤ 128 Mo) | ≈ 100 Mo au repos sur système nu en VM ; **jamais mesuré avec annuaire + Samba actifs** | **PARTIEL** |
| 21 | **Reproductibilité** des sorties | **deux constructions a froid comparees le 2026-10-26 : empreintes IDENTIQUES** (`82dc5681…`), 6533 s | **FAIT** |
| 22 | **Harnais de tests automatisé** | tests = protocoles manuels à recopier (non conforme `docs/32`) | **PARTIEL** |
| 23 | **Matériel réel** (le PC de 2011) | disque interne **intact**, aucune installation réelle ; tout est fait en VM | **ABSENT** |
| 24 | **Traçabilité licences** | frontière documentée (`docs/12`), `samba.schema` GPL tenu hors dépôt, `scripts/40` de contrôle | **FAIT** (à automatiser : T-13) |

**Décompte sans complaisance (mis à jour le 2026-10-26 au soir) : 10 FAIT · 4 PARTIEL · 10 ABSENT.**

---

## 3. Les preuves qui existent déjà (verbatim, pas résumées)

| Preuve | Sortie |
|---|---|
| Noyau compilé | `>>> Kernel(s) NEXBSD_L1 built in 1470 seconds, ncpu: 2, make -j2` — `code de retour : 0` |
| Noyau installé | `>>> Install kernel(s) NEXBSD_L1 completed in 24 seconds` — `0` erreur, **858** modules, **158 Mo** |
| Noyau démarré | `15.1-NEXBSD-L1` · `NEXBSD_L1` · `FreeBSD 15.1-NEXBSD-L1 NEXBSD_L1` |
| Banc | **11 / 11** (T-04-G, 2026-10-25) · 10 entrées d'annuaire · `omrane` écrit, `sara` refusée |
| Provenance | `src.txz cf5762da…` → `GENERIC 02491b53…` → `NEXBSD_L1 14c86800…` → noyau `82dc5681…` |

---

## 4. Ce qui manque pour pouvoir dire « NexBSD est un système »

Six conditions, dans l'ordre où elles doivent être satisfaites. Tant qu'une seule manque, nous sommes un banc.

| # | Condition | Pourquoi elle est indispensable | Faisable sur le poste actuel ? |
|---|---|---|---|
| **A** | Le banc complet (annuaire + droits + persistance) tient **sur notre noyau** | sinon l'étage 2 n'a pas de sens | **✅ FAIT le 2026-10-26 à 19:54 UTC — 11/11, en-tête `FreeBSD 15.1-NEXBSD-L1`** |
| **B** | Un **vrai poste client** (Windows ou Linux Mint) accède aux partages | un partage prouvé par lui-même ne prouve rien du réseau | **oui** (Mint est là, réseau QEMU à monter) |
| **C** | Une **image produite par le projet** démarre et s'installe | c'est la définition même d'un système distribué | **non** → voie CI (`docs/27` voie B) |
| **D** | Le système **se met à jour seul** (dépôt de paquets NexBSD) | sans cela, chaque mise à jour est manuelle : ce n'est pas un système | non → après C |
| **E** | **Restauration** exercée (T-06) | un système sans retour arrière n'est pas déployable | oui, après A |
| **F** | Installation sur le **PC de 2011** (J5) | c'est la cible réelle et la contrainte de poids | non tant que C n'existe pas |

---

## 5. Trajectoire : les six prochaines étapes, dans l'ordre

| Ordre | Étape | Critère de réussite | Durée estimée |
|---|---|---|---|
| **1** | **Finir J1** : rejouer `scripts/64` sur `NEXBSD_L1` | **11/11** avec `uname -r` = `15.1-NEXBSD-L1` dans la sortie | 15 min (un redémarrage) |
| **2** | **T-11 — reproductibilité** (non conformité n° 1 de l'audit croisé) | deux `sha256` de `kernel` identiques, ou écarts expliqués | ~25 min de calcul |
| **3** | **Harnais `tests/harnais.sh`** (non conformité n° 2) | un seul appel rend un verdict global et un code de sortie | 1 h de rédaction |
| **4** | **T-05 / T-05a — pare-feu `pf`** | seuls les ports déclarés sont ouverts, prouvé par scan | 1 h |
| **5** | **Client réel** : Mint accède à `[commun]` depuis le réseau QEMU | écriture/lecture depuis Mint, refus pour un compte hors groupe | 1 à 2 h |
| **6** | **Voie CI pour l'image** (condition C) | une image `NexBSD` produite ailleurs que sur le poste | plusieurs sessions |

**Ce qui n'est PAS dans cette liste, volontairement :** l'interface petit écran et le chemin NCP. Ils viennent
après qu'un système installable existe ; les mettre maintenant serait construire un toit sans murs.

---

## 6. Sauvegardes — état réel

| Support | État |
|---|---|
| Dépôt local | **83 commits**, arbre propre, delta `fork/` 17 fichiers vérifié par `scripts/70` |
| Google Drive | instantanés `.bundle` de **s029 à s035** (s031, s033, s034 publics) — dossier `08_Versions_et_Archives` |
| GitHub | dépôt `mlinux952-code/nexbsd` — **en retard** : la poussée est manuelle par le responsable |
| Machine du responsable (`~/Projets/nexbsd`) | **en retard de plusieurs commits** — un `git pull` du bundle s035 est nécessaire |

**Point d'honnêteté :** le dépôt GitHub n'a **jamais** été vérifié par une sortie `git push` collée. Tout ce qui
n'est pas dans un `.bundle` du Drive n'existe, en pratique, que sur cette machine-ci.

---

## 7. Les points sur les i

**Prouvé :**
- un noyau **compilé dans ce projet** démarre, s'identifie `NEXBSD_L1` / `15.1-NEXBSD-L1`, avec 858 modules ;
- le banc NetWare-logique (annuaire, identités, droits, partages) fonctionne et **revient seul après coupure** ;
- la chaîne de provenance est complète, chaque maillon avec son empreinte ;
- FreeBSD d'origine est **intact** et le retour arrière est immédiat.

**Supposé (et signalé comme tel) :**
- le banc rejouera 11/11 sur le nouveau noyau — **c'est précisément ce que nous testons maintenant** ;
- l'image serait constructible en CI — identifié, **jamais essayé** ;
- la consommation tiendra sous 128 Mo avec les services actifs — **non mesuré**.

**Impossible en l'état :**
- construire `world` + image sur ce poste (4 Go de RAM, 921 Mo libres sur la racine) ;
- installer sur le PC de 2011 sans image ;
- parler NCP sans service NCP (T-09) et sans banc A (T-14).

---

## 8. Décision de la session

1. **J1 se termine ce soir** : redémarrage + `scripts/64 apres` → verdict 11/11 sur `NEXBSD_L1`.
2. Ensuite, dans l'ordre : **T-11** (reproductibilité), puis **harnais**, puis **`pf`**, puis **client Mint**.
3. Le document `docs/32-audit-croise.md` reste la référence des manques ; ce document-ci est la **carte**
   qui dit où mène chacun d'eux.
4. **Rien de l'apport extérieur (`research/noyau-propre/`) n'entre dans la route du produit** avant J5.

*Fichier produit le 2026-10-26 à Tunis. Toute affirmation de ce document renvoie à une preuve du dépôt.*

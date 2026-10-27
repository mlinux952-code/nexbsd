# Audit rétrospectif — du 23 au 27 octobre 2026 : tout ce qui a été fait, et où ça a atterri

**Demande du responsable, 2026-10-27 :** *« ne pas ce soir seulement, c'est chaque soir, du début à la
fin — hier, aujourd'hui et demain. C'est pour ça que je te dis de vérifier toujours. »*

**Objet :** reprendre **l'historique complet** (119 commits, sessions S-001 → S-021) et répondre à une
seule question, pour **chaque** production : *où est-elle aujourd'hui, et sera-t-elle dans la version
finale ?* Aucun jugement de valeur : seulement des faits, et les trous qu'ils révèlent.

**Méthode :** `git log --reverse` (historique réel), lecture des scripts, `matrices/acquis.csv`
(50 acquis), `scripts/72-verifier-acquis.sh` (contrôle automatique).

---

## 1. Ce que l'historique contient, jour par jour

| Date | Sessions | Ce qui a été produit | Où c'est aujourd'hui | Verdict |
|---|---|---|---|---|
| **23/10** | S-001 → S-013 | cadrage, cahier des charges, 5 matrices CSV, 20 ADR, delta du socle (`fork/`), étude de faisabilité (score 1,5/5), **T-01** et **T-03** réussis, script VM, protocole T-04 | `docs/`, `matrices/`, `docs/decisions/`, `fork/`, `tests/results/` | ✅ **conservé**, sauf le delta qui fut perdu **deux fois** (C-16/C-18) puis restauré et **protégé par `scripts/70`** |
| **24/10** | S-013 → S-014 | **T-04** (annuaire), **T-04-E** (Samba via `ldapsam`), **T-04-F** (droits par groupes), scripts `60`→`64`, registre C-10→C-13 | `tests/results/`, `scripts/` | ⚠️ **preuves conservées**, mais la **configuration** (slapd, smb4.conf, LDIF) n'existe **que dans les scripts** |
| **25/10** | S-015 → S-019 | **T-04-G** (persistance 11/11), **C-14** (NSS/nslcd, script `65`), **T-16** (identité), campagne de construction du noyau (scripts `67`/`68`/`69`), audit contradictoire (`docs/32`), échelle I0-I5, révision totale (`docs/29`) | `scripts/`, `tests/results/`, `docs/` | ⚠️ même remarque : `nsswitch.conf` et `nslcd.conf` **uniquement dans un script** |
| **26/10** | S-019 | **noyau `NEXBSD_L1` compilé** (1470 s), installé (`/boot/kernel.NEXBSD_L1`, 858 modules), **T-17**, **T-11** (reproductibilité : empreintes identiques) | `fork/`, `tests/results/` | ✅ **dans le produit** : le delta est la partie la plus solide du système |
| **27/10 (jour)** | S-020 | révision du méga-prompt (`docs/15` v1.2), `docs/40` (R-1→R-11 + M-1→M-9), `docs/41` (CI), nettoyage workspace 41 → 9,3 Mo, **T-05** (pare-feu actif, harnais 24/24) | `docs/`, `tests/results/` | ✅ conservé |
| **27/10 (soir)** | S-021 | **T-05a** (refus prouvé depuis une autre machine), **T-19** (réseau du banc rejouable), **T-20** (horloge), **T-21** (SSH par clé), durcissement `su`, `docs/42`/`43`/`44`, **registre des acquis** + `scripts/72` | `tests/results/`, `fork/overlay/`, `matrices/`, `docs/` | ✅ conservé **et** écrit dans le delta |

---

## 2. LE TROU QUE CET AUDIT RÉVÈLE (et que ce soir seul, je n'avais pas vu)

**La plateforme d'identité — le cœur du produit — n'existe nulle part sous forme de fichiers de
configuration.** Elle n'existe que sous forme de **commandes** à l'intérieur de scripts de test :

| Fichier nécessaire au produit | Où son contenu vit réellement aujourd'hui | Existe dans `fork/overlay/` ? |
|---|---|---|
| `/usr/local/etc/openldap/slapd.conf` | heredoc dans `scripts/60` (l. 44) et `scripts/62` (l. 106) | ❌ **non** |
| `/usr/local/etc/smb4.conf` | heredoc dans `scripts/62` (l. 29) et `scripts/63` (l. 47) | ❌ **non** |
| `/etc/nsswitch.conf` | `scripts/65` (l. 28) | ❌ **non** |
| `/usr/local/etc/nslcd.conf` | `scripts/65` (l. 29) — **contient un secret** | ❌ **non** |
| annuaire de base (comptes, groupes, SID) | LDIF dans `scripts/60` (l. 83) et `scripts/63` (l. 118-181) | ❌ **non** |
| services armés (`slapd`, `nslcd`, `samba_server`) | `sysrc` dispersés dans `scripts/60`, `62`, `65` | ⚠️ partiellement (`rc.conf.defaults` : Samba oui, slapd/nslcd **non**) |

**Conséquence, dite sans détour :** si la VM disparaissait ce soir, on pourrait **rejouer les tests**
(les scripts existent) mais on ne pourrait **pas produire l'image** sans réécrire ces fichiers. Le
produit n'a pas encore sa configuration d'identité : il a une **procédure de laboratoire** qui la
fabrique à la volée.

C'est exactement ce que votre phrase vise : *« sinon pour quoi on fait tout ça »*. Tout ça, aujourd'hui,
tient dans des scripts de banc. Il faut l'en sortir.

---

## 3. Le registre, étendu à tout l'historique

`matrices/acquis.csv` est passé de **22 à 50 acquis** :

| Destination | Nombre | Sens |
|---|---|---|
| **PRODUIT** | 24 | doit être dans l'image |
| **MÉTHODE** | 7 | empêche de refaire une erreur |
| **PREUVE** | 18 | prouve que le produit fait ce qu'il prétend |
| **GOUVERNANCE** | 1 | une décision écrite engage la suite |

**Et `scripts/72` vérifie désormais quatre choses :**
1. chaque acquis a une destination **connue** (test « destination inconnue ») ;
2. chaque cible `PRODUIT` **existe réellement** dans le dépôt ;
3. ce qui est `OUVERT` ou `A-FAIRE` est **affiché** (un acquis oublié doit crier) ;
4. **aucune preuve sans destination** : chaque fichier de `tests/results/` doit être référencé.

**Résultat du contrôle, ce soir :**

```
  ...     acquis enregistres      : 50
  ...     destines au PRODUIT     : 24
  ...     destines a la METHODE   : 7
  ...     destines a la PREUVE    : 18
  ...     destines a la GOUVERNANCE : 1
----- 4. aucune preuve sans destination -----
  [OK]    les 15 comptes rendus sont references
VERDICT : REGISTRE CONFORME
```

**Et le contrôle a été prouvé dans les deux sens** (M-11), en créant une preuve orpheline :

```
  [KO]    compte rendu NON reference dans le registre : T-99-preuve-orpheline.md
VERDICT : REGISTRE NON CONFORME — 0 destination(s) invalide(s), 0 cible(s) en defaut, 1 preuve(s) non referencee(s).
```

---

## 4. Les 11 acquis encore ouverts ou à faire (la liste de travail, pas une plainte)

| # | Acquis | Statut |
|---|---|---|
| A-23 | `slapd.conf` du produit | A-FAIRE |
| A-24 | `smb4.conf` du produit | A-FAIRE |
| A-25 | `nsswitch.conf` du produit | A-FAIRE |
| A-26 | `nslcd.conf` du produit | A-FAIRE |
| A-27 | annuaire de base (LDIF) du produit | A-FAIRE |
| A-28 | `slapd`/`nslcd` armés au démarrage | OUVERT (`rc.conf.defaults` incomplet) |
| A-17 | `motd` annonce encore FreeBSD | A-FAIRE |
| A-18 | décision : comment un admin obtient `root` (ADR-0021) | A-FAIRE |
| A-19 | chaîne de release + image (J5) | A-FAIRE |
| A-20 | diagnostic matériel du PC de 2011 | A-FAIRE |
| A-30 | 20 ADR encore à l'état « proposition » | OUVERT |

**Deux de ces dix lignes (A-23 à A-27) sont la même tâche** : *sortir la configuration d'identité des
scripts de banc et la poser dans `fork/overlay/`*. C'est la prochaine marche la plus utile du projet,
avant même le `motd` : sans elle, il n'y a pas de serveur à installer.

---

## 5. Ce que cet audit change dans la façon de travailler

| Règle | Origine | Effet |
|---|---|---|
| **R-12** — tout acquis a une destination écrite | votre exigence du 27/10 | plus rien ne peut rester « dans la VM » |
| **M-10** — un garde-fou qui crie à tort sera ignoré | `scripts/70` a crié sur une croissance légitime | on met à jour sa référence avec justification, le jour même |
| **M-11** — un garde-fou n'est prouvé que s'il a déjà crié | `scripts/72` d'abord testé sur un cas conforme | tout garde-fou est testé dans les **deux sens** |
| **R-13 (nouvelle)** — un test n'est pas un produit | cet audit | un script de banc qui réussit ne prouve pas que l'image existera |

---

## 6. Réponse en une ligne

**Rien de ce qui a été fait depuis le 23 octobre n'est perdu — 50 acquis sont tracés, 15 preuves
référencées, 20 fichiers de delta protégés par un garde-fou — mais 11 acquis ne sont pas encore dans le
produit, dont les cinq fichiers de configuration de l'annuaire et des partages, qui n'existent
aujourd'hui que comme commandes à l'intérieur de scripts de test.**

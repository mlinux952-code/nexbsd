# Registre des problèmes connus

**Version :** 1.0 — 2026-10-23
**Rôle :** livrable 13 du méga-prompt. Trace des **problèmes** (≠ risques) : ce qui est cassé, manquant, contradictoire ou bloquant.
**Règle :** un problème ne se supprime pas, il se **clôt** avec sa justification.

Légende gravité : 🔴 bloquant · 🟠 majeur · 🟡 mineur
Légende statut : **ouvert** · **contourné** · **clos**

---

## 1. Problèmes ouverts

| # | Problème | Gravité | Impact | Statut | Suite |
|---|---|---|---|---|---|
| P-01 | **Aucune identification du matériel du PC de 2011** (CPU ? 64 bits ? firmware ?) | 🔴 | bloque T-01/T-02, donc le prototype | ouvert | exécuter `docs/hardware.md` §2 |
| P-02 | **Aucun test d'exécution n'a été réalisé** (0/15 tests) | 🔴 | interdit toute conclusion de faisabilité | ouvert | lancer la VM (plan-action étape 1bis) |
| P-03 | **Profil L3 (« PC fort ») indisponible** | 🟠 | empêche `buildworld`, donc toute image NexBSD | ouvert | décision du responsable (Q4) |
| P-04 | Aucune installation FreeBSD, même en VM | 🟠 | livrables 11, 12, 15 bloqués | ouvert | plan-action étape 1bis |
| P-05 | OpenLDAP ≥ 2.6 : disponibilité sous FreeBSD non vérifiée | 🟠 | bloque la décision annuaire (N-03) | ouvert | `pkg search -x openldap` |
| P-06 | Antériorité du nom « NexBSD » non vérifiée | 🟠 | bloque la publication (porte G1) | ouvert | recherche d'antériorité |
| P-07 | Statut actuel des marques NetWare/Novell non vérifié | 🟡 | risque juridique de communication | ouvert | recherche |
| P-08 | Document fondateur unique non rédigé/signé (livrable 1) | 🟡 | traçabilité de la vision | ouvert | rédaction (sans matériel) |
| P-09 | Étude de faisabilité sans conclusion (livrable 3) | 🟠 | ne peut être écrite sans test | ouvert | après P-02 |
| P-10 | Le script `20-ecrire-usb.sh` n'a **jamais** été exécuté sur un périphérique réel | 🟠 | risque de destruction si bug | ouvert | relire + tester avec une clé sacrifiable |
| P-11 | Le script `30-qemu-freebsd.sh` n'a jamais lancé de VM (QEMU absent de l'environnement de test) | 🟡 | première exécution non validée | ouvert | tester sur le Mint |
| P-12 | `build/fork/*` jamais compilé (ni `src.conf` ni `KERN_CONF`) | 🟡 | valeurs peut-être inopérantes | ouvert | après P-03 |
| P-13 | **Dépôt GitHub inexistant** (aucun connecteur GitHub disponible) ; Drive fait le 2026-10-23 | 🔴 | pas d'historique distant ni de travail à plusieurs ; subsiste une copie datée sur Drive | **partiellement résolu** | action du responsable : `docs/20-depots-et-sauvegardes.md` §3 |
| P-14 | Le client NCP de test exige une **VM Windows** (licence à vérifier) | 🟡 | bloque le banc B | ouvert | décision du responsable |

## 2. Problèmes clos

| # | Problème | Résolution | Date |
|---|---|---|---|
| C-01 | Modèle d'assemblage « FreeBSD + paquets » inapte à produire un système | remplacé par le modèle fork M2 (ADR-0011) | 2026-10-23 |
| C-02 | `scripts/10-verifier-image.sh` ne reconnaissait pas les en-têtes en majuscules | correction + 3 cas de test exécutés | 2026-10-23 |
| C-03 | `scripts/40-…` : exemptions non appliquées (motif relatif mal compris) | documenté + test corrigé | 2026-10-23 |
| C-04 | 3 matrices CSV avec virgules non échappées (illisibles dans un tableur) | réécrites, vérifiées par analyseur CSV | 2026-10-23 |
| C-05 | Conclusion erronée « NCP impossible sans IPX » | corrigée : NCP sur UDP/TCP 524 depuis NetWare 5 (ADR-0018) | 2026-10-23 |
| C-06 | « Aucun client NCP testable » (inquiétude V-1) | Client for Open Enterprise Server 26.2.1 identifié (ADR-0019) | 2026-10-23 |
| C-07 | **Aucune sauvegarde hors de l'espace de travail** | dépôt Git local (1 commit) + archives + téléversement Google Drive vérifié par l'API (S-007) | 2026-10-23 |
| C-09 | **Mode terminal QEMU imposé par erreur sur la station du responsable** (une session perdue) | cause : l'environnement de l'assistant n'a pas d'écran, ce n'est pas une contrainte de la station ; remplacé par `virt-manager` en session utilisateur (`docs/23-banc-sur-mint.md` §4 ter) | 2026-10-23 |
| C-08 | Livrable 2 (cahier des charges fonctionnel) absent | `docs/02-cahier-des-charges-fonctionnel.md` : 33 exigences avec critères d'acceptation | 2026-10-23 |

## 3. Contradictions détectées entre documents

| # | Contradiction | Résolution |
|---|---|---|
| X-01 | `ETAT.md` v4 annonçait encore « 16 ADR » après l'ajout de 0017/0018 | corrigé en v5 puis v6 |
| X-02 | `ETAT.md` §3 titrait « les 16 ADR » avec une liste de 18 | corrigé |
| X-03 | `ADR-0014` présentait IPX comme inévitable | révisé par ADR-0018, mention croisée ajoutée |

**Aucune contradiction ouverte à ce jour.** Toute nouvelle contradiction doit être inscrite ici avant d'être résolue.

## 4. Ce que ce registre ne contient pas

- Les **risques** (événements possibles) : voir `matrices/risques.csv` (R-01→R-24).
- Les **fonctions non implémentées** : voir `matrices/functions.csv` (état « À faire / À étudier »).

---

## C-10 — Le paquet FreeBSD `samba423` ne fournit pas `samba.schema`

**Constaté :** 2026-10-24, essai 1 de T-04-E. `samba.schema` introuvable dans `/usr/local/etc/openldap/schema/`, `/usr/local/share/examples/samba*/`. Vérification dans le `pkg-plist` du port `net/samba423` : **aucun fichier `.schema` n'est livré**.

**Conséquence :** `passdb backend = ldapsam` échoue à l'initialisation (`Invalid DN syntax` sur `sambaDomainName=…`), car les attributs Samba sont inconnus de l'annuaire.

**Solution retenue :** téléchargement du schéma depuis le dépôt officiel Samba (`examples/LDAP/samba.schema`, HEAD) avec **empreinte SHA256 épinglée**, dans la VM de laboratoire uniquement. Le fichier étant sous **GPL-3.0+**, il n'entre **jamais** dans le dépôt NexBSD (frontière de licences, `docs/12`).

**Correctif :** `scripts/62-banc-T04E-samba-ldap.sh` version 2.

**Statut :** corrigé, à revalider (essai 2).

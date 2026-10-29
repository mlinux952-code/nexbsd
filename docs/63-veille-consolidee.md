# 63 — Veille consolidée : ce que les 7 images du responsable ont réellement rapporté au produit

> **Contexte :** entre le 29/10 au soir, le responsable a envoyé **7 affiches** trouvées sur Facebook
> et a demandé, à chaque fois, si elles pouvaient servir. **Six** ont été instruites (`docs/60`, `61`,
> `62`). Une **huitième** a été annoncée puis **n'est pas arrivée** — le message ne portait aucun
> fichier, et le dossier `/home/user/uploads/` n'a reçu aucun nouvel élément depuis 20 h 10.
>
> Ce document fait le tri final : **ce qui reste d'actionnable après tous les refus**. Car l'essentiel
> d'une veille n'est pas la liste des choses vues, c'est la **courte liste des choses retenues**.

---

## 1. Les 7 images, et où chacune a été instruite

| Image | Sujet | Instruction |
|---|---|---|
| 1 | **Networking Protocols** (19 protocoles) | `docs/60` — 17 ports exacts sur 19, décision pour chacun des 19 |
| 2 | **Free Remote Desktop Tools** (couleurs) | `docs/61` — 5 lignes ne sont que des clients, 4 refusés |
| 3 | **Free Remote Desktop Tools** (noir) | `docs/61` — **doublon** de la 2 |
| 4 | **12 Password Cracking Tools** | `docs/62` §2 — aucun dans le produit ; a produit `scripts/75` |
| 5 | **Cybersecurity AI Tools** | `docs/62` §3 — 2 retenus sur 8 |
| 6 | **Immutable Linux Distributions** | `docs/62` §6 → **ADR-0021** |
| 7 | **Cybersecurity Tools** (Kali) | `docs/62` §4 — aucun dans le produit ; 2 sont nos instruments |
| **8** | **annoncée, jamais reçue** | ⏳ **rien** |

---

## 2. Ce qui **reste** : 9 éléments, la seule partie qui compte

Sur environ **90 outils** cités par les affiches, **9 ont survécu** au tri. Voici la liste complète,
et elle est courte — c'est normal, et c'est bon signe.

| # | Élément retenu | Vient de | Destination | État |
|---|---|---|---|---|
| 1 | **NTP (port 123)** est une **dépendance obligatoire de N-05** — Kerberos refuse une horloge décalée de plus de 5 min | Affiche 1 | **exigence N-05** | ⚠️ constaté, à écrire dans `docs/02` |
| 2 | **Kerberos (88)** et **StartTLS sur 389** pour le mot de passe unique | Affiche 1 | **N-05** | ❌ non commencé |
| 3 | **IPP/CUPS (631)** pour l'impression | Affiche 1 | **N-07** | ❌ non commencé |
| 4 | **mDNS (5353)** pour la découverte du serveur | Affiche 1 | **N-10** | ❌ non commencé |
| 5 | **SNMP v3 (161/162)** pour la supervision — *v3 seulement, jamais v1/v2c* | Affiche 1 | **N-09** | ❌ non commencé |
| 6 | **xrdp** : bureau distant par RDP, réutilise `nexbsd-session` déjà écrit | Affiches 2-3 | **N-08** / **C-47** | 📝 décidé (`docs/61`), non installé |
| 7 | **Suricata** et **osquery** : candidats pour la supervision | Affiche 5 | **N-09** | 📝 candidats |
| 8 | **Racine immuable + `bectl` + `securelevel`** | Affiche 6 | **ADR-0021** | 📝 proposition, non acceptée |
| 9 | **`scripts/75`** — 21 contrôles de durcissement, étape CI 4/4 | Affiche 4 | **produit** | ✅ **fait le 29/10** |

**Une seule ligne sur neuf est terminée.** Les huit autres sont des **travaux nommés** — ce qui est
déjà beaucoup plus qu'avant les affiches, où plusieurs n'étaient même pas identifiés.

---

## 3. Ce que les affiches ont fait **découvrir** malgré elles

Trois choses que personne n'avait notées, et qui sont plus importantes que leur contenu :

### a) Une dépendance cachée d'architecture

**NTP → N-05.** Kerberos refuse une horloge décalée de plus de cinq minutes. Donc **le mot de passe
unique ne peut pas fonctionner sans NTP**, et NTP n'était pas listé comme prérequis. Une affiche
« pour débutants » a révélé un défaut de notre plan.

### b) Une règle décorative dans notre propre pare-feu

En lisant `pf.conf` à côté de l'affiche 1 : `set skip on lo0` rend la ligne
`pass in on lo0 … port 389` **inopérante**. Le commentaire attribuait la protection de l'annuaire à
une règle qui ne s'évalue jamais. **C-46.** Comportement inchangé, explication corrigée.

### c) Aucune politique de mot de passe dans le produit

En retournant la question des casseurs de mots de passe : **`login.conf` n'existe pas**, donc **rien
n'empêche un compte d'annuaire d'avoir le mot de passe `a`**. **C-48**, gravité 🔴.

**Ces trois découvertes ne viennent d'aucun des outils cités.** Elles viennent d'avoir **confronté**
les affiches au dépôt au lieu de les admirer.

---

## 4. La méthode, désormais fixe — et elle vaut pour les images à venir

Quand une affiche arrive, quatre questions, dans cet ordre :

1. **Est-ce que ça existe pour FreeBSD ?** (sinon, c'est réglé en dix secondes)
2. **Est-ce un client ou un serveur ?** (l'affiche 2 mélangeait les deux)
3. **Est-ce dans le produit, pour nous tester, ou hors périmètre ?** (trois seaux, jamais deux)
4. **Qu'est-ce que ça révèle de nos propres défauts ?** — c'est la seule question qui a produit
   quelque chose ce soir.

**Et la règle qui en découle :** une image n'entre dans le dépôt que si elle change **un fichier**.
Si elle ne produit qu'un commentaire, elle reste dans la conversation.

---

## 5. Ce qui serait **plus utile** que des affiches

Pour la suite de la veille, quatre sources valent dix affiches :

| Source | Pourquoi |
|---|---|
| **Les avis de sécurité de FreeBSD** (`vuXML`, `pkg audit -F`) | c'est la liste **réelle** des failles qui nous concernent, et `scripts/75` s'y branchera |
| **La documentation de Samba** (`smb.conf(5)`) | nos partages y sont décrits paramètre par paramètre |
| **Le manuel de NetWare / `MARS_NWE`** | **la référence de ce que nous remplaçons** — c'est la seule chose qu'aucune affiche ne donnera jamais |
| **Les ports FreeBSD** (`freshports.org`) | dit en une ligne si un outil existe chez nous — la question n° 1 de la méthode |

---

## 6. État, sans embellissement

- **7 images reçues, 6 instruites, 1 en doublon.**
- **1 livraison de code** (`scripts/75`, étape CI 4/4, 17 protections vérifiées).
- **2 défauts du produit trouvés** (C-46, C-48) — dont un grave.
- **1 dépendance d'architecture révélée** (NTP → N-05).
- **1 proposition d'architecture** (ADR-0021), **non acceptée**, **non appliquée**.
- **8 travaux nommés** qui n'existaient pas avant.
- **0 image de NexBSD démarrée.** Le produit attend toujours son premier souffle.

**Acquis : A-73** — veille consolidée, avec la liste fermée des 9 éléments retenus.

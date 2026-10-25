# Identité et nommage — « FreeBSD » dans les sorties d'écran, et pourquoi

**Version :** 1.0 — 2026-10-25 (session S-017)
**Rôle :** lever une ambiguïté réelle, signalée par le responsable : l'invite de la VM affiche
`root@freebsd` alors que le projet s'appelle **NexBSD**. Ce document dit ce qui est vrai aujourd'hui,
ce qui est visé, et par quel chemin on passe de l'un à l'autre.

**Règle de lecture :** toute sortie d'écran portant le mot `freebsd` décrit **l'état du socle actuel**,
jamais le nom du produit.

---

## 1. La distinction que le projet a lui-même posée

Le méga-prompt (Partie IV) et `docs/22-delta-nexbsd.md` séparent deux choses :

| Couche | Nature | Existe aujourd'hui ? |
|---|---|---|
| **Socle** | base système, obtenue par **fork** de FreeBSD (ADR-0011) : arbre source possédé, noyau `NEXBSD_L1`, `src.conf`, `release.conf`, patch d'identité | **écrite, jamais compilée** — aucune image produite |
| **Produit** | identité, services réseau façon NetWare, interface, administration | partiellement : les services d'identités fonctionnent sur le banc (T-04 → T-04-G) |

## 2. Ce qui tourne réellement sur le banc, ce jour

Le banc exécute une **FreeBSD 15.1-RELEASE d'origine**, image officielle, installée sans aucune
modification du code source. Donc :

```
root@freebsd:~ # uname -sr
FreeBSD 15.1-RELEASE
```

**L'invite dit la vérité.** Elle n'est pas un oubli de nommage : elle décrit ce qui est en train de
tourner. Renommer l'hôte ne transforme pas FreeBSD en NexBSD — ce serait exactement le genre de
déclaration que le projet interdit (« ne déclarer comme réalisé que ce qui a été vérifié »).

## 3. Les trois étages de l'identité, du plus facile au plus lourd

| Étage | Ce que cela change | Faisable sur ce banc ? |
|---|---|---|
| **1. Identité visible** — nom d'hôte, message d'accueil, invite | l'écran affiche **NexBSD** ; l'invite devient `root@nexbsd:~ #` | ✅ **oui, aujourd'hui** — `scripts/66`, sans compilation |
| **2. Chaîne de version** — `uname -r`, `freebsd-version`, bannière du noyau | le système **s'annonce** NexBSD au niveau du noyau (patch `0001-identite-version.patch`, écrit, jamais appliqué) | ❌ non — exige un **arbre source** et un profil de construction **L3** (P-03) |
| **3. Image propre** — `release.sh` produit une image amorçable signée NexBSD | un support d'installation NexBSD | ❌ non — dépend de l'étage 2 |

**Conclusion honnête :** à l'issue de l'étage 1, le banc **s'appelle** NexBSD sans être encore NexBSD.
C'est un progrès réel et vérifiable, mais pas la naissance du système. L'étage 1 ne doit jamais être
présenté comme l'étage 3.

## 4. Pourquoi l'étage 1 a quand même de la valeur

- Il rend le banc **reconnaissable** : plus de confusion entre le socle et le produit, y compris dans les
  journaux de tests, les captures et les comptes rendus.
- Il installe la **discipline de nommage** qui devra exister dans l'image finale : nom d'hôte, message
  d'accueil, identification des services.
- Il vérifie une chose concrète : **renommer l'hôte ne casse pas les services** (Samba utilise son propre
  `netbios name = NEXBSDFS`, indépendant du nom d'hôte). C'est une vérification, pas une décoration.

## 5. Rappel permanent à conserver

> **Le produit s'appelle NexBSD.**
> Toute occurrence de « freebsd » dans une sortie d'écran, un `uname`, un nom d'hôte ou un journal
> désigne **l'état actuel du socle** (FreeBSD 15.1 stock), **pas la cible**.
> La cible est une image NexBSD produite par le projet, à l'étage 3.

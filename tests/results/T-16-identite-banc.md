# T-16 — Identité du banc : le système porte le nom NexBSD — **À EXÉCUTER**

**Protocole :** `scripts/66-identite-nexbsd.sh` — **étage 1** (identité visible).
**Prérequis :** T-04-G réussi (banc complet et persistant).
**Banc :** VM `nexbsd-test`, socle FreeBSD 15.1-RELEASE **d'origine**.

## 1. Le problème que ce test traite

Le responsable a signalé, à juste titre, que l'invite affichait `root@freebsd` alors que le projet
s'appelle **NexBSD**. Cette remarque n'est pas cosmétique : elle pointe la confusion entre le **socle**
(FreeBSD, aujourd'hui non modifié) et le **produit** (NexBSD). Voir `docs/26-identite-et-nommage.md`.

## 2. Ce que le test démontre — et ce qu'il ne démontre pas

| Démontré | Non démontré |
|---|---|
| le banc **s'appelle** NexBSD : nom d'hôte, message d'accueil, invite | que le système **est** NexBSD (la chaîne de version reste FreeBSD) |
| le renommage **ne casse rien** : annuaire, NSS, Samba toujours opérationnels | l'étage 2 (patch d'identité du noyau) et l'étage 3 (image propre), qui exigent un arbre source et le profil L3 |

## 3. Procédure

```
fetch -o /tmp/ident.sh http://10.0.2.2:8000/66-identite-nexbsd.sh
sh /tmp/ident.sh
```

Puis vérifier de visu : l'invite doit devenir `root@nexbsd:~ #` après reconnexion.

## 4. Journal d'exécution

### Essai 1 — à exécuter

_(vide)_

## 5. Verdict

**NON EXÉCUTÉ** — protocole écrit le 2026-10-25, syntaxe vérifiée.

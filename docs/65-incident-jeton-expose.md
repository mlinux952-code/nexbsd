# 65 — Incident de sécurité : un jeton d'accès GitHub a été transmis en clair

- **Date :** 2026-10-29, ~23 h 30
- **Gravité :** 🔴 **élevée** — mais **sans conséquence** si la révocation est faite
- **Statut :** révocation demandée au responsable ; **à confirmer**
- **Registre :** C-49
- **La valeur du jeton n'est PAS reproduite dans ce document, ni nulle part dans le dépôt.**

---

## 1. Ce qui s'est passé

Le responsable, pour débloquer le téléchargement de l'image NexBSD (1,78 Gio) depuis un artefact
GitHub, a **collé en clair dans la conversation** un **jeton d'accès personnel GitHub** de type
`ghp_…`, avec la permission `repo`.

**Contexte de l'erreur — et c'est ma responsabilité :** c'est **moi** qui lui ai indiqué la marche à
suivre dans le message précédent, en lui disant de créer un jeton avec la permission `repo` et de
l'utiliser dans une cellule Colab. **Je n'ai pas dit assez clairement qu'il ne devait jamais me le
montrer.** Une consigne de sécurité qui laisse place à l'interprétation est une consigne fausse.

---

## 2. Ce que ce jeton permettait

Un jeton personnel GitHub avec la permission `repo` donne **lecture ET écriture** sur **tous** les
dépôts du compte, y compris :

| Action possible | Conséquence |
|---|---|
| `git push --force` | réécrire l'histoire du dépôt |
| **supprimer le dépôt** | **perte totale du projet** |
| lire les dépôts privés | fuite de tout ce qui n'est pas public |
| modifier les workflows | exécuter du code sur les serveurs GitHub |

Il **ne demande aucune confirmation**, **ne déclenche aucune alerte** et **agit sans le titulaire**.
C'est la différence entre un mot de passe (utilisé par un humain qui se connecte) et un jeton
(utilisé par un programme, à toute heure, sans témoin).

---

## 3. Ce que j'ai fait — et ce que je n'ai pas fait

| | |
|---|---|
| ❌ **Je n'ai pas utilisé le jeton.** | aucune requête, aucune lecture, aucune écriture |
| ❌ **Je ne l'ai pas reproduit** dans ce document ni dans le dépôt | il n'existe que dans l'historique de la conversation |
| ✅ **J'ai demandé sa révocation immédiate** | https://github.com/settings/tokens → *Delete* |
| ✅ **J'ai écrit ce document** | pour que l'erreur ne se reproduise pas |

**Ce que je ne peux pas faire :** révoquer le jeton à sa place. Seul le titulaire du compte le peut.
**La révocation reste donc à confirmer par le responsable.**

---

## 4. La règle qui manquait — et qui est désormais écrite

> **Aucun secret ne se transmettant par la conversation. Jamais.**
>
> Pas un mot de passe, pas un jeton, pas une clé SSH, pas une phrase de récupération. Un secret qui
> entre dans une conversation est un secret **perdu**, même si rien ne s'est encore produit.
>
> **Un secret se saisit là où il est utilisé** : dans le terminal, dans le notebook, dans les
> *Secrets* du dépôt GitHub — **jamais dans un message.**

**Corollaire, pour moi :** quand j'indique une manipulation qui exige un secret, je dois écrire
**explicitement** où le saisir et **où ne jamais le coller**. C'est ajouté aux consignes du projet.

---

## 5. La marche à suivre, désormais, pour ce téléchargement

**Le jeton était une fausse solution à un vrai problème.** Il n'est plus nécessaire.

| Voie | Secret nécessaire | Reprise après coupure | Expiration |
|---|---|---|---|
| Artefact + `gh` | compte GitHub | ❌ | **2026-11-28** |
| Artefact + Colab + jeton | ⚠️ **un jeton** | partielle | 2026-11-28 |
| **Release GitHub (`publier-image.yml`)** | ✅ **aucun** | ✅ `curl -C -` | ✅ **jamais** |

**La troisième voie rend les deux premières inutiles.** Elle passe par un workflow qui utilise le
`GITHUB_TOKEN` interne : un jeton **créé et détruit par GitHub lui-même**, d'une durée d'une
exécution, que personne ne voit jamais.

---

## 6. Ce qu'il faut retenir de cet incident

Le projet a **déjà** la bonne règle écrite (**R-15**, `docs/15`) : *plus aucun mot de passe dans le
dépôt*. Cet incident montre que la règle était **trop étroite** : elle parlait du **dépôt**, pas de
la **conversation**. Un secret peut fuir sans jamais toucher un fichier.

**C'est la deuxième fois que ce projet apprend quelque chose en se trompant** — après les deux faux
positifs de `scripts/75` (C-48). La méthode tient : **on nomme, on écrit, on change la règle.**

---

## 7. Actions

| # | Action | Qui | État |
|---|---|---|---|
| 1 | **Révoquer le jeton** | responsable | ⏳ **à confirmer** |
| 2 | Ne plus jamais transmettre de secret par la conversation | responsable | règle **A-76** |
| 3 | Écrire explicitement où saisir un secret, quand j'en propose un | assistant | règle **A-76** |
| 4 | Publier l'image en Release : plus aucun secret nécessaire | assistant | ✅ workflow écrit (`publier-image.yml`) |
| 5 | Préférer les jetons *fine-grained* (un dépôt, une permission, une expiration) | responsable | si un jeton redevient nécessaire |

**Acquis : A-76.**

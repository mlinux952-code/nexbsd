# Règles de travail — la méthode du projet, consolidée

**Date :** 2026-10-27 · **Rôle :** rassembler en un seul endroit les règles que le responsable a données
et les leçons tirées de nos échecs. Ce document **n'invente rien** : chaque règle vient d'une consigne
explicite ou d'un incident consigné.

---

## 1. Règles données par le responsable (intouchables)

| # | Règle | Origine |
|---|---|---|
| R-1 | Écrire en **français**, de façon exhaustive et pédagogique | consigne permanente |
| R-2 | **Toujours nommer le terminal** : 🖥️ MINT (`omrane@omrane-Inspiron-3520`) ou 🐧 VM (`root@nexbsd`) | incident du 2026-10-27 (`cd ~/Téléchargements` tapé dans la VM) |
| R-3 | **Une seule commande à la fois**, avec la sortie attendue, puis attendre la sortie réelle | consigne permanente |
| R-4 | **Ne jamais inventer ni « arranger » un résultat** ; consigner les échecs verbatim | consigne permanente |
| R-5 | **Ne jamais oublier le nom du produit** : le produit est **NexBSD** ; `uname -s` = `FreeBSD` désigne le socle | consigne permanente |
| R-6 | Exiger les **« points sur les i »** : prouvé / supposé / impossible en l'état | consigne permanente |
| R-7 | **Objectif non négociable** : un vrai système pour PC, pas un FreeBSD modifié ; installation propre = **J5** | consigne permanente |
| R-8 | Les fichiers **GPL tiers** ne doivent **jamais** entrer dans le dépôt | consigne permanente |
| R-9 | Ne pas toucher au terminal Mint qui sert un dossier ; transferts par **bundles Drive** avec sha256 | consigne permanente |
| R-10 | **Ne pas maquiller** : un test non exécuté s'écrit `NON EXÉCUTÉ`, jamais `OK` | méga-prompt + pratique |
| R-11 | Un apport extérieur **ne change pas la route du produit** | consigne du 2026-10-26 |

## 2. Règles que nos échecs ont imposées

| # | Règle | Incident qui l'a imposée |
|---|---|---|
| M-1 | **Aucune commande de surveillance au premier plan** (pas de `while … done` sans `&`) : elle rend le terminal inutilisable | 2026-10-26, boucle d'attente de `buildkernel` |
| M-2 | **Toute opération longue en arrière-plan, avec journal** (`nohup … > log 2>&1 &`), et un compteur pour distinguer « long » de « figé » | `installkernel` (858 modules) paraissait bloqué |
| M-3 | **Vérifier l'empreinte avant d'exécuter un fichier téléchargé** | Drive renvoie une page HTML au lieu du script (2 458 o, 0 ligne) |
| M-4 | **Valider à blanc avant d'appliquer** (`pfctl -n -f`, `sh -n`) | C-22 et C-23, deux échecs propres |
| M-5 | **Ne pas écrire de mémoire** : une syntaxe « qui paraît juste » (ex. `max 20/s` en `pf`) fait perdre une session | C-23 |
| M-6 | **Lire la sortie jusqu'à sa ligne d'en-tête** (`hote :`, `uname -r`) avant de compter un succès | 11/11 sur le noyau FreeBSD au lieu de `NEXBSD_L1` (C-20) |
| M-7 | **Un script interroge la réalité** (quel hyperviseur ? quel domaine ?) avant d'agir | C-21, `scripts/31` cherchait une image QEMU inexistante |
| M-8 | **Un harnais qui se trompe est plus dangereux qu'aucun harnais** : il accuse le système à tort. Tout contrôle se recopie d'une **source déjà validée** | T-18 v1.0 : `ls -ld` au lieu de `ls -ldn`, texte de `smbclient` au lieu du code de retour |
| M-9 | **Toujours afficher le code de retour** (`echo "CODE : $?"`) : le texte peut mentir, pas le code | harnais v1.0 : « putting file » s'affiche même en cas de succès |

## 3. Format d'une session

1. **Révision** des trois sources : mur de discussion, workspace, Drive.
2. **Une** commande, avec la sortie attendue **écrite à l'avance**.
3. **Consignation verbatim** avant toute conclusion.
4. **Commit** avec un message qui dit *ce qui est prouvé*, pas ce qu'on espère.
5. **Bundle** déposé sur Drive + sha256, puis rendu public.
6. **`docs/3x-reprise`** mis à jour : la session doit être reprenable **sans conversation**.

## 4. Ce que ces règles protègent

| Risque | Règle qui protège |
|---|---|
| perdre le delta du fork | garde-fou `scripts/70` + `fork/` (nom `build` interdit) |
| croire à un succès inexistant | M-6, M-8, M-9, R-10 |
| casser le banc en croyant le protéger | M-4, M-7 |
| perdre le travail avec la conversation | R-9, bundles Drive, `docs/3x-reprise` |
| dériver vers un autre produit | R-11, ADR-0001/0011 |

**Une règle sans incident qui l'illustre est une règle décorative.** Toutes celles de la partie 2 ont coûté
quelque chose : c'est pour cela qu'elles tiennent.

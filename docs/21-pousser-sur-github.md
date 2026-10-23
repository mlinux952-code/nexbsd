# Pousser NexBSD sur GitHub — dépannage pas à pas

**Version :** 1.0 — 2026-10-23
**Rôle :** transformer les erreurs réelles rencontrées le 2026-10-23 en une procédure qui marche, sur une machine Linux Mint vierge.

---

## 1. Les quatre erreurs observées, et leur cause exacte

| Erreur affichée | Cause réelle | Ce n'est pas |
|---|---|---|
| `fatal: le dépôt 'nexbsd-depot-…-s007.bundle' n'existe pas` | le fichier **n'est pas dans le dossier courant** (`~`) : il est dans le dossier de téléchargement, ou pas encore téléchargé depuis Drive | un fichier corrompu |
| `bash: cd: nexbsd: Aucun fichier ou dossier` | conséquence de la ligne précédente : le clonage n'a jamais eu lieu, donc le dossier n'existe pas | un problème de droits |
| `fatal: votre branche actuelle 'main' ne contient encore aucun commit` | les commandes suivantes ont tourné **dans un autre dépôt** (le dossier personnel est déjà un dépôt Git), pas dans NexBSD | une branche mal nommée |
| `error: la distante origin existe déjà` + `impossible de pousser vers …/orbis-hybrid-os.git` | ce dépôt-là avait **déjà** un `origin` pointant vers un autre projet | un bug de GitHub |

**Diagnostic d'ensemble :** les commandes ont été collées **d'un bloc**, y compris celles qui échouent, dans le mauvais répertoire. Résultat : `git remote add` et `git push` ont agi sur un dépôt **étranger** (`orbis-hybrid-os`), pas sur NexBSD. Rien n'a été cassé, mais rien n'a été poussé.

**Règle à retenir :** une commande à la fois, et on **regarde la sortie** avant de passer à la suivante. Si une ligne échoue, **on s'arrête**.

---

## 2. Procédure correcte, dans l'ordre (une ligne = une étape)

### Étape 1 — télécharger le bundle depuis Drive
Dans le dossier Drive **« NexBSD »**, télécharger `nexbsd-depot-2026-10-23-s007.bundle`.
Il atterrit presque toujours dans `~/Téléchargements`.

Vérifier qu'il est là :
```bash
ls -lh ~/Téléchargements/nexbsd-depot-2026-10-23-s007.bundle
```
Attendu : une ligne d'environ **207 Ko**. Si « No such file », le téléchargement n'a pas eu lieu — ne pas continuer.

### Étape 2 — vérifier l'intégrité (30 secondes, évite des heures)
```bash
cd ~/Téléchargements
sha256sum nexbsd-depot-2026-10-23-s007.bundle
```
Attendu, au caractère près :
```
39eecae5e5186610d097ee0e2867602e3b69a4eeb011f834334a3c3d6115e3b8
```

### Étape 3 — installer le dépôt avec le script (il refuse les cas dangereux)
```bash
sh scripts/51-installer-depot-github.sh \
   ~/Téléchargements/nexbsd-depot-2026-10-23-s007.bundle \
   git@github.com:mlinux952-code/nexbsd.git \
   ~/Projets/nexbsd main
```
*(adapter le chemin du script et l'URL)*

Le script : vérifie que le bundle existe, **refuse** d'écrire dans un dossier existant, clone, **retire** le `origin` qui pointe vers le fichier bundle, renomme `master` → `main`, ajoute votre `origin`, teste la clé SSH. Il **ne pousse pas**.

### Étape 4 — créer le dépôt sur GitHub (interface web)
**New repository** → nom `nexbsd` → **Private** → **ne rien initialiser** (ni README, ni .gitignore, ni licence).
Un dépôt initialisé à la main **refusera** le push avec `fetch first` : c'est l'erreur suivante la plus fréquente.

### Étape 5 — pousser
```bash
cd ~/Projets/nexbsd
git push -u origin main
```

### Étape 6 — vérifier
```bash
git log --oneline          # 6129316 puis 5e7c789
git remote -v              # origin = votre dépôt nexbsd, pas orbis-hybrid-os
```

---

## 3. Si la clé SSH n'est pas configurée

```bash
ssh -T git@github.com
```
- `Hi <compte>! You've successfully authenticated` → tout va bien.
- `Permission denied (publickey)` → il faut créer et déclarer une clé :
```bash
ssh-keygen -t ed25519 -C "nexbsd-$(hostname)"     # accepter le chemin par défaut, mettre une phrase de passe
cat ~/.ssh/id_ed25519.pub                          # copier cette ligne
```
Puis GitHub → **Settings → SSH and GPG keys → New SSH key** → coller → enregistrer.
**Ne jamais** coller la clé privée (`id_ed25519`, sans `.pub`) nulle part.

### 3 bis. Cas observé le 2026-10-23 (vérifié sur la machine du responsable)

Symptôme exact, après un clone et un `remote add` corrects :
```
git@github.com: Permission denied (publickey).
fatal: Impossible de lire le dépôt distant.
```
**Cause :** aucune clé SSH publique n'est déclarée sur le compte GitHub. Le message n'a **rien** à voir avec le dépôt, son nom ou ses droits : Git n'a même pas pu s'authentifier.

Séquence de correction :
```bash
ls -l ~/.ssh                            # une clé existe-t-elle déjà ?
ssh-keygen -t ed25519 -C "nexbsd-mint"  # sinon : accepter le chemin par défaut
cat ~/.ssh/id_ed25519.pub               # copier TOUTE la ligne, en une fois
```
Puis GitHub → **Settings → SSH and GPG keys → New SSH key** → coller → **Add SSH key**.
Vérifier :
```bash
ssh -T git@github.com
```
Attendu : `Hi <compte>! You've successfully authenticated, but GitHub does not provide shell access.`

**Piège des comptes multiples :** une clé SSH est rattachée à **un seul** compte. Si la réponse est `Hi emailaymenomrane-cloud!` alors que le dépôt appartient à `mlinux952-code`, le push échouera avec `Repository not found` — la clé est sur le mauvais compte.

**Clé protégée par une phrase de passe :** `ssh-agent` la redemandera à chaque session. Pour éviter la répétition :
```bash
eval "$(ssh-agent -s)" && ssh-add ~/.ssh/id_ed25519
```
Sur Mint avec GNOME, le trousseau le fait généralement tout seul.

*Alternative HTTPS :* un mot de passe ne fonctionne plus ; il faut un **jeton personnel** (Settings → Developer settings → Personal access tokens), utilisé comme mot de passe. Le jeton ne doit jamais être écrit dans un fichier du projet.
```bash
git remote set-url origin https://github.com/mlinux952-code/nexbsd.git
git push -u origin main     # identifiant = compte GitHub, mot de passe = jeton
```

---

### 3 ter. « Key is invalid. You must supply a key in OpenSSH public key format »

Message vu sur GitHub au moment de coller la clé. Les causes possibles, par fréquence :

| # | Cause | Comment le reconnaître |
|---|---|---|
| 1 | on a copié la **clé privée** (`id_ed25519`) au lieu de la publique (`id_ed25519.pub`) | la ligne commence par `-----BEGIN OPENSSH PRIVATE KEY-----` |
| 2 | le fichier n'existe pas et `cat` a échoué : c'est autre chose qui a été copié | `ls -l ~/.ssh` ne montre pas `id_ed25519.pub` |
| 3 | la copie est **coupée** ou contient un retour à la ligne au milieu | la ligne est incomplète, ou n'a pas de seconde partie `AAAA…` |
| 4 | on a collé une **empreinte** (`SHA256:…`) ou la sortie de `ssh-keygen -l` | ça commence par `256 SHA256:` ou par un nombre |
| 5 | espaces ou caractères parasites ajoutés par le terminal | la ligne contient des espaces au début |

**Diagnostic en trois commandes** (la sortie dit tout) :
```bash
ls -l ~/.ssh
head -c 40 ~/.ssh/id_ed25519.pub ; echo
ssh-keygen -l -f ~/.ssh/id_ed25519.pub
```
- ligne 2 doit commencer par **`ssh-ed25519 AAAA`** ;
- ligne 3 doit afficher une empreinte **et le commentaire** (`nexbsd-mint`). Si elle affiche « is not a public key file », le fichier n'est pas le bon.

**Copie fiable** (évite les coupures du copier-coller à la souris) :
```bash
sudo apt install -y xclip
xclip -selection clipboard < ~/.ssh/id_ed25519.pub
```
ou, sans installer quoi que ce soit, ouvrir le fichier dans un éditeur de texte et faire Ctrl+A puis Ctrl+C :
```bash
gedit ~/.ssh/id_ed25519.pub
```
La clé publique est **une seule ligne**, de la forme `ssh-ed25519 AAAAC3Nza… nexbsd-mint`.

**Si aucune clé n'existe :** `ssh-keygen -t ed25519 -C "nexbsd-mint"` puis Entrée (le `.pub` est créé en même temps).

**Plan B immédiat, sans aucune clé :** le jeton HTTPS (§3 bis). C'est la voie la plus rapide si les clés résistent.

---

### 3 quater. Cas du 2026-10-23 : aucune clé n'existait + noms de fichiers modifiés par le terminal

Deux constats tirés de la sortie réelle :

```
~/.ssh  →  known_hosts, known_hosts.old        (aucune clé : ni privée, ni publique)
head: impossible d'ouvrir '.../id_[ed25519.pub](http://ed25519.pub)'
```

1. **Aucune clé n'existait.** Le message « Key is invalid » de GitHub venait de là : rien de valide n'avait été collé.
2. **Le terminal (ou le presse-papiers) a réécrit `id_ed25519.pub` en lien Markdown** `id_[ed25519.pub](http://ed25519.pub)`. Toute commande collée contenant ce nom échoue.

**Parade :** éviter les noms exacts dans les commandes, utiliser des jokers.

```bash
ssh-keygen -t ed25519 -C "nexbsd-mint"   # Entrée, Entrée, Entrée (chemin par défaut, sans phrase)
ls -l ~/.ssh                             # doit montrer id_ed25519 et id_ed25519.pub
cat ~/.ssh/*.pub                         # le joker évite d'écrire le nom complet
xclip -selection clipboard < ~/.ssh/*.pub
```

**Règle pratique :** si les commandes collées contiennent des noms de fichiers et que le terminal les affiche comme des liens, **taper la commande à la main** ou utiliser `*.pub`.

---

### 3 quinquies. « Key is invalid » alors que la clé générée est correcte

Séquence réelle du 2026-10-23 : clé créée (`id_ed25519.pub`, 93 octets, empreinte `SHA256:QMjZ5F8h8kpIkT7ww0nweb7ADYHb2ef4/zykdb5rhI0`), `cat` affiche une ligne `ssh-ed25519` parfaitement valide, et GitHub refuse quand même.

Conclusion : **le problème n'est pas la clé, c'est ce qui arrive dans la page GitHub.** Trois causes restantes :

1. **le presse-papiers ne contient pas ce qu'on croit** (xclip n'a pas pris, ou autre chose a écrasé le presse-papiers depuis) ;
2. **le collage atterrit dans le mauvais champ** (le champ « Title » au lieu de la zone « Key », ou la page *GPG keys* au lieu de *SSH keys*) ;
3. **du texte parasite accompagne la clé** (invite de commande, retour à la ligne, guillemets).

**Contrôle du presse-papiers — la commande qui tranche :**
```bash
xclip -selection clipboard -o | diff - ~/.ssh/*.pub && echo "PRESSE-PAPIERS IDENTIQUE AU FICHIER"
```
- `PRESSE-PAPIERS IDENTIQUE AU FICHIER` → le contenu est bon, le problème est côté page GitHub (cause 2 ou 3).
- une différence s'affiche → le presse-papiers est mauvais (cause 1) : recommencer le `xclip`.

**Cause observée juste après :** le `diff` a montré que le presse-papiers contenait **la commande elle-même** (`xclip -selection clipboard -o | diff - …`), et non la clé — le texte avait été recopié depuis la conversation. Conséquence : recharger le presse-papiers **à partir du fichier** avant tout collage, et ne coller sur GitHub que la ligne `ssh-ed25519 …`.

**Contrôle du collage :** coller d'abord dans `gedit` (éditeur de texte), vérifier qu'il y a **une seule ligne** sans blanc au début, puis recopier de là vers GitHub.

**Contrôle après ajout :** dans *Settings → SSH and GPG keys*, GitHub affiche l'empreinte de la clé. Elle doit être **`SHA256:QMjZ5F8h8kpIkT7ww0nweb7ADYHb2ef4/zykdb5rhI0`** (… ou celle de la clé réellement ajoutée). Si l'empreinte diffère, ce n'est pas cette clé qui a été enregistrée.

**Quand arrêter d'essayer les clés :** après deux échecs de collage, passer au **jeton HTTPS** (§3 bis, plan B). Le résultat est identique et cela ne dépend d'aucun presse-papiers.

---

## 4. Cas particuliers

| Situation | Solution |
|---|---|
| le dépôt distant existe déjà avec un README | `git push -u origin main --force-with-lease` **seulement** si le contenu distant est vide d'intérêt ; sinon `git pull --rebase origin main` puis push |
| message « `src refspec master does not match any` » | la branche locale ne s'appelle pas `master` : `git branch` pour voir le nom réel, puis pousser ce nom |
| message « `origin already exists` » | `git remote -v` pour voir où il pointe ; si c'est un autre projet, **on n'est pas dans le bon dossier** — revenir à l'étape 3 |
| `Permission denied (publickey)` | aucune clé déclarée sur GitHub → §3 bis |
| `Repository not found` alors que la clé marche | dépôt pas encore créé, ou clé rattachée à un **autre compte** → §3 bis |
| `! [rejected] main -> main (fetch first)` | le dépôt distant a un commit (README coché à la création) → `git pull --rebase origin main` puis pousser |
| vous voulez pousser dans `orbis-hybrid-os` | **ne pas le faire sans décision** : ce dépôt a son propre historique. Voir la question posée au responsable |

---

## 5. Ce qui a été réellement testé

- `scripts/51-installer-depot-github.sh` : exécuté sur **3 cas** — bundle absent (refus), destination existante (refus), cas nominal (clone + renommage + remote) ; le clone nominal a été poussé vers un **dépôt local factice**, avec succès.
- **Non testé :** l'authentification réelle auprès de GitHub (aucun accès réseau à GitHub depuis l'environnement de travail). Le script se contente d'avertir si la clé SSH n'est pas reconnue.

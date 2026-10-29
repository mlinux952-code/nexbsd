# 59 — Preuve : les lecteurs réseau arrivent tout seuls à la connexion (N-06)

> **Intervenant concerné : n° 5 (protocoles réseau et systèmes de fichiers).**
> Exigence : **EF-N-06** de `docs/02` — *« les lecteurs réseau se connectent automatiquement selon
> l'utilisateur (esprit script de connexion) ; un poste client voit ses lecteurs après connexion,
> sans action manuelle »*.
> Date : 2026-10-29 · Acquis : **A-68** · Problème fermé : **C-45**

---

## 1. Pourquoi c'est la pièce la plus importante du projet

NetWare n'a pas gagné parce qu'il stockait des fichiers. Il a gagné parce qu'**un utilisateur
s'asseyait devant n'importe quel poste, tapait son nom, et retrouvait ses lecteurs**. `H:` son
dossier, `P:` le commun, `S:` son projet. Aucune manipulation. C'était en 1983.

NexBSD est un **remplacement de NetWare**. Jusqu'à aujourd'hui, il savait : authentifier (PAM),
partager des fichiers (Samba), annoncer un annuaire (OpenLDAP), afficher un bureau. Il ne savait
**pas** faire la seule chose que les utilisateurs de NetWare ont réellement vue de leur vie :
**leurs lecteurs apparaître**.

C'était la priorité **n° 3** de `docs/57` et le plus gros trou fonctionnel du produit.

---

## 2. Ce qui est livré — trois fichiers

| Fichier | Rôle |
|---|---|
| `fork/netware/nexbsd-script-connexion.sh` | l'interpréteur : lit le script, branche les lecteurs |
| `fork/netware/script-connexion.systeme` | le script **système** réel du produit (H:, P:, blocs par service) |
| `fork/netware/tester-script-connexion.sh` | **27 cas** de test, exécutés au banc |

### Le langage — celui de NetWare, volontairement borné

```netware
; un commentaire, comme en NetWare
WRITE "  Bienvenue sur NexBSD, %NOM_COMPLET%."
MAP H: \\%SERVEUR%\utilisateurs\%UTILISATEUR%
MAP ROOT P: \\%SERVEUR%\commun%
IF MEMBER OF "comptabilite"
        MAP C: \\%SERVEUR%\comptabilite%
ENDIF
# /usr/local/bin/nexbsd-quota --verifier
INCLUDE poste-local.inc
EXIT
```

Variables développées : `%UTILISATEUR%`, `%NOM_COMPLET%`, `%JOUR%`, `%MOIS%`, `%HEURE%`,
`%SERVEUR%`, `%GROUPE%`.

### Le script système livré, en clair

Tout utilisateur reçoit :

- **H:** → `\\serveur\utilisateurs\<son nom>` — son dossier personnel, **sur le serveur**, donc
  retrouvé depuis n'importe quel poste. C'est la promesse de NetWare, littéralement.
- **P:** → `\\serveur\commun` — le partage commun.

Puis, selon le groupe : **C:** comptabilité, **D:** direction. Un utilisateur qui n'est membre
d'aucun de ces groupes ne reçoit que H et P — vérifié par test.

---

## 3. Les 27 cas, exécutés — et un vrai défaut trouvé

Le banc place un **faux `mount_smbfs`** en tête de `PATH` : il enregistre les appels au lieu de
monter. On teste donc la **logique** du script de connexion, pas le noyau.

| # | Cas | Résultat |
|---|---|---|
| 1 | script système réel, en simulation | 2 lecteurs, aucune commande inconnue |
| 2 | `IF MEMBER OF "comptabilite"` | C branché, D absent |
| 3 | non-membre | seulement H et P |
| 4 | commentaire `;` ignoré, `EXIT` arrête | conforme |
| 5 | lettre `1:` invalide | refusée et signalée |
| 6 | `MAP H: pas-un-unc` | chemin invalide refusé |
| 7 | commande `BOGUS` | signalée, pas ignorée |
| 8 | `IF` sans `ENDIF` | « ENDIF manquant » |
| 9 | **sans mot de passe** | montage **refusé**, aucun appel réel |
| 10 | mot de passe en 0600 | montage tenté, `~/.nsmbrc` en `-rw-------` |
| 11 | mot de passe en 0644 | **refusé** : « n'est pas privé » |
| 12 | lecteur déjà branché | aucun nouvel appel (idempotent) |
| 13 | `INCLUDE` | le script inclus ajoute son lecteur |
| 14 | aucun script trouvé | signalé, session utilisable |

**Total exécuté : 27 · conformes : 27 · en échec : 0**

### Le défaut que le test a trouvé

Le premier passage a donné **2 échecs**. Le plus grave :

```
[ECHEC] l'appel porte le bon UNC (attendu '1', obtenu '0')
MOUNT -N -f 0600 //omrane@nexbsd/utilisateurs/%UTILISATEUR% /home/.../Lecteurs/H
```

**`%UTILISATEUR%` n'était pas développé dans `MAP`.** Le lecteur H aurait pointé vers un dossier
littéralement nommé `%UTILISATEUR%`. Le script se serait exécuté **sans la moindre erreur**, et
**chaque utilisateur aurait reçu le même lecteur, vide**.

C'est le type de défaut qui ne se voit pas : tout est vert, rien ne marche. Il a été trouvé parce
qu'un test vérifiait **le contenu de l'appel**, pas seulement son nombre. Corrigé au bon endroit
(développement des variables **dans** `monter()`), pas contourné dans le script de données.

---

## 4. La question honnête du mot de passe

Monter un partage SMB exige le mot de passe de l'utilisateur. Trois choix possibles :

| Solution | Verdict |
|---|---|
| redemander le mot de passe à chaque lecteur | ❌ insupportable — 4 fenêtres à chaque connexion |
| stocker le mot de passe en clair dans un fichier permanent | ❌ inacceptable |
| **fichier 0600 le temps de la session, → `~/.nsmbrc`, effacé à la sortie** | ✅ **retenu** |

`~/.nsmbrc` est le mécanisme **officiel** de FreeBSD : `mount_smbfs -N` le lit sans rien demander.
Le script **refuse** un fichier de mot de passe qui ne serait pas en 0600 — vérifié par test (cas 11).

**Ce qu'il faut dire tout haut :** pendant la session, le mot de passe existe en clair dans un
fichier que seul son propriétaire peut lire. Ce n'est pas parfait. **Kerberos serait meilleur** ;
il n'est pas en place. C'est néanmoins la première brique de **N-05 (mot de passe unique)** :
**un** mot de passe saisi, **plusieurs** services servis — au lieu de quatre.

---

## 5. Ce que ce travail NE prouve PAS

| Affirmation | Statut |
|---|---|
| l'interpréteur fonctionne, 27 cas conformes | ✅ **prouvé au banc** |
| le langage accepte la syntaxe NetWare prévue | ✅ **prouvé** |
| un lecteur SMB se monte réellement sur FreeBSD | ❌ **jamais** — le `mount_smbfs` était faux |
| Samba sert réellement `\\nexbsd\utilisateurs\...` | ❌ **non** : `fork/80` n'a jamais tourné, les partages n'existent pas encore |
| le script est appelé automatiquement à l'ouverture de session | ❌ **pas encore branché** dans `nexbsd-session.sh` |
| N-11 (client NCP natif) | ❌ **non commencé** — on passe par SMB, pas par NCP |

**Le chemin réel reste à faire :** brancher ce script dans la session, créer les partages dans
Samba, et faire un vrai montage sur une vraie machine NexBSD. Tant que ce n'est pas fait, on peut
dire : *« NexBSD sait lire un script de connexion et décider des lecteurs ; il ne les a jamais
branchés pour de vrai. »*

---

## 6. Effet sur les priorités de `docs/57`

| Priorité | Application | État |
|---|---|---|
| 1 | démarrer l'image de l'exécution #18 | ⏳ artefact à télécharger par le responsable |
| 2 | `pkg audit` au démarrage de session | ✅ **A-67** (29/10) |
| **3** | **N-06 lecteurs réseau / scripts de connexion** | ✅ **A-68 (29/10)** — logique livrée, câblage à faire |
| 4 | N-08 console d'administration | ❌ rien |
| 5 | A-22 identité unique PAM/LDAP | ❌ rien |
| 6 | A-18 comment l'administrateur obtient root | ❌ rien |

**Prochain pas logique :** brancher le script de connexion dans `nexbsd-session.sh` **et** créer les
partages correspondants dans `smb4.conf`, pour que le script système ne décrive pas un serveur qui
n'existe pas.

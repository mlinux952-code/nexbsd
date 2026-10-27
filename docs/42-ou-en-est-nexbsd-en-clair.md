# Où en est NexBSD — en clair, sans jargon

**Date :** 2026-10-27 · **Pour :** le responsable du projet · **But :** répondre à une seule question :
*« est-ce qu'on construit vraiment quelque chose, ou est-ce qu'on parle dans le vide ? »*

La réponse courte : **on construit.** Ce document explique **ce que le système sait faire aujourd'hui**,
en français simple, avec les preuves qui vont avec. Rien n'est ici déclaré s'il n'a pas été observé.

---

## 1. Ce que NexBSD est censé faire (rappel, en une image)

Un serveur, chez vous ou dans une petite structure, sur un PC modeste, qui **remplace un serveur de fichiers
type NetWare** :

- **un seul compte** pour toutes les machines du réseau ;
- **des droits** par groupe : certains lisent, certains écrivent, d'autres ne voient rien ;
- **des partages** de fichiers accessibles depuis Windows, Linux, Mac ;
- **un seul endroit** pour administrer tout le monde ;
- le tout sur une machine **fermée par défaut** : ce qui n'est pas ouvert n'existe pas.

## 2. Ce que le système sait faire AUJOURD'HUI (prouvé, pas supposé)

| Ce qu'un utilisateur ferait | Est-ce que ça marche ? | Preuve (test) |
|---|---|---|
| Démarrer la machine | ✅ oui | T-01 |
| Démarrer sur un **noyau compilé par le projet** (`NEXBSD_L1`), reproductible à l'octet près | ✅ oui | T-17, T-11 |
| Installer un serveur de fichiers et le configurer | ✅ oui | T-03 |
| Avoir un **annuaire de comptes** (un seul identifiant pour tout) | ✅ oui | T-04 |
| **Authentifier par l'annuaire** les accès aux fichiers | ✅ oui | T-04-E |
| **Appliquer des droits par groupe** (untel écrit, unetelle est refusée) | ✅ oui | T-04-F |
| **Survivre à un redémarrage** sans intervention (tout revient seul) | ✅ oui | T-04-G |
| **Refuser par défaut** ce qui n'est pas autorisé, et le **journaliser** | ✅ oui | T-05, **T-05a** |
| Se faire **joindre par une autre machine** du réseau, à travers le pare-feu | ✅ oui | **T-05a (27/10)** |
| Avoir un **bureau** (interface graphique) | ❌ non — console texte nue | — |
| Avoir des **applications NexBSD** | ❌ non — aucune ligne écrite | — |
| **S'installer sur n'importe quel PC** | ❌ non — pas encore d'image installable | jalon J5 |

**Bilan :** 11 tests réussis sur 20. Le **cœur serveur est debout et prouvé** ; le **côté utilisateur
(bureau, logiciels) n'est pas commencé** ; l'**image installable** n'existe pas encore.

## 3. La preuve du 27 octobre, expliquée simplement

Ce jour-là, trois choses ont été démontrées, et ce sont exactement les trois promesses du produit :

1. **« Une autre machine peut entrer. »**
Votre Mint a demandé le partage de fichiers à NexBSD. NexBSD a répondu, et le Mint a vu 4 fichiers.

2. **« Mais elle doit montrer patte blanche. »**
Sans le bon compte, NexBSD refuse. Avec le compte `omrane`, il vérifie dans son **annuaire**, puis accorde.

3. **« Et ce qui n'est pas ouvert reste fermé. »**
On a frappé **8 fois** à une porte non prévue (le port 8080). Les 8 fois, NexBSD a **jeté** la demande
**sans répondre**, et l'a **noté dans son journal** :

```
rule 0/0(match): block in on vtnet0: 10.0.2.2.59622 > 10.0.2.15.8080: Flags [S]
```

Traduction : *« paquet venu de l'extérieur, vers le port 8080 : bloqué »*. Ce n'est pas nous qui l'écrivons,
c'est le noyau. Et le même jour, sur le port 445 (autorisé), un vrai client a lu de vrais fichiers — donc
la différence entre « autorisé » et « bloqué » est bien le **pare-feu**, pas autre chose.

## 4. Pourquoi c'est important pour la suite (le chemin vers votre rêve)

Vous avez demandé : *« un jour, NexBSD installé sur un serveur, contrôlant plusieurs machines ? »*
Ce que le 27 octobre a prouvé, c'est **la brique centrale de ce rêve** :

```
un compte  ->  un annuaire  ->  des droits  ->  appliqués sur le réseau  ->  derrière un pare-feu
```

Un serveur qui « contrôle plusieurs machines », c'est **exactement** ça : les machines ne connaissent pas
les mots de passe, c'est **l'annuaire** qui les connaît. Cette brique existe et fonctionne.

Ce qui manque n'est pas de la magie, c'est du travail de finition :

| Manque | Pourquoi c'est nécessaire | Difficulté |
|---|---|---|
| Une **image installable** (clé USB → PC) | sans elle, NexBSD n'est pas un système, c'est un laboratoire | moyenne, mais demande un PC assez fort pour compiler (jalon J5) |
| Le **bureau** et des **logiciels NexBSD** | sans eux, on a un serveur, pas un système grand public | grosse (non commencée) |
| Le **durcissement** (SSH, réglages réseau, isolement des services) | un serveur ouvert = un serveur perdu | moyenne, bien encadrée |
| Les **mises à jour** et la **sauvegarde** | un serveur qui ne se met pas à jour devient une faille | à concevoir |
| L'**heure synchronisée** | indispensable pour la sécurité des comptes | petite, à faire vite |

## 5. Ce qui n'est PAS fait, et qu'on ne prétendra jamais fait

- **Aucune image NexBSD n'existe.** Le système tourne dans une machine virtuelle, sur le socle FreeBSD.
- **Aucun code propre à NexBSD dans l'espace utilisateur** (le noyau compilé, lui, existe).
- **Aucun jalon « installation propre sur un PC »** n'est atteint.
- **Les 20 tests** ne sont réussis qu'à **11**.
- Le dépôt **GitHub n'a jamais été vérifié par une sortie `git push`** : on ne sait pas ce qu'il contient.

## 6. La règle qui nous protège

> **On ne déclare réalisé que ce qui a été vérifié — et on écrit les échecs aussi.**

C'est pour cela que ce projet avance lentement mais ne recule pas : chaque étape laisse une trace
(`tests/results/`), y compris les erreurs (registre `docs/16`, incidents C-1 à C-26). Un journal qui ne
montrerait que des succès ne vaudrait rien.

## 7. Les trois prochaines marches (décidées)

1. Rendre la preuve du 27 octobre **rejouable automatiquement** (redirection réseau dans `scripts/31`).
2. **Remettre les horloges à l'heure** (écart de 22 minutes constaté).
3. **Durcir** : accès SSH par clé, réglages réseau, isolement des services (jails).

Ensuite : un client SMB depuis une **seconde machine physique**, puis `release.sh` et l'intégration
continue, puis l'**image installable** — le vrai début du produit.

# Compte rendu de session — S-009 : **premiers tests réels**

**Date :** 2026-10-23, 20h40 → 21h30
**Consigne :** « lire le mur, le workspace, Drive et GitHub, puis essayer sur une VM si possible, jusqu'à obtenir un vrai NexBSD sans bug et la version 0.1 »

---

## 1. Réponse directe à la consigne

**Oui, une VM a été montée — et pour la première fois du projet, des tests ont réellement été exécutés.**

| Ce qui a été fait | Statut |
|---|---|
| Lire le mur, le workspace, l'état des dépôts | ✅ |
| Se procurer FreeBSD | ✅ image officielle **15.1-RELEASE**, SHA256 vérifié |
| Faire démarrer FreeBSD | ✅ **T-01 réussi** (4 démarrages) |
| Installer Samba | ✅ **samba423-4.23.11_3** depuis les dépôts officiels |
| Partager un répertoire et y accéder **depuis une autre machine** | ✅ **T-03 réussi** (écriture + relecture) |
| Obtenir « NexBSD 0.1 sans bug » | ❌ **pas encore — et il faut le dire clairement** |

**Pourquoi la version 0.1 n'existe pas encore :** une image NexBSD ne peut pas être construite ici. Il faut `buildworld` + `buildkernel`, c'est-à-dire ~40 Go de disque, plusieurs heures de CPU et 8 Go de RAM minimum. L'hôte de travail a **2 vCPU, 1,9 Gio de RAM et aucune accélération KVM**. Ce que nous avons testé est donc **FreeBSD nu + les briques**, pas NexBSD. C'est exactement le profil « L3 » absent (Q4).

## 2. Résultats mesurés (aucune estimation)

| Mesure | Valeur réelle |
|---|---|
| Démarrage jusqu'à `login:` | **81 s** (émulation TCG, 1 vCPU) |
| RAM occupée **au repos** | **≈ 100 Mo** sur 746 Mo vus par le noyau |
| Objectif ENF-01 (≤ 128 Mo) | **atteignable** sur système nu |
| Dépôts FreeBSD | 38 288 paquets (ports) + 509 (base) |
| Samba disponible | **4.23.11_3** et **4.24.7_1** ; `samba416` (non maintenu) **toujours présent** → ADR-0007 justifiée |
| OpenLDAP disponible | **2.6.15_1** (LTS) et **2.7.1** → **question Q6 / vérification V-4 résolue : OUI** |
| Installation de Samba | 80 paquets, 104 Mio téléchargés, ≈ 4 min 30 |

## 3. Le test qui compte

Une machine **Debian, hors de la VM**, a listé le partage, y a **écrit un fichier**, et ce fichier a été **relu dans la VM** avec un contenu identique. C'est la démonstration que la chaîne « FreeBSD + Samba + réseau » fonctionne de bout en bout. Détails et verbatim : `tests/results/T-03-partage-samba.md`.

## 4. Ce qui a échoué — et ce que ça nous apprend

| Problème | Cause | Enseignement pour NexBSD |
|---|---|---|
| `NT_STATUS_ACCESS_DENIED` à l'écriture | dossier appartenant à root, `read only = no` ne suffit pas | l'outil d'administration (N-08) doit poser les droits corrects à la création d'un partage |
| `NT_STATUS_CONNECTION_RESET` | `smbd` non démarré après redémarrage | le service doit être activé au boot par défaut, pas en `onestart` |
| Console série inaccessible au départ | la VM sort sur l'écran vidéo, pas sur le port série | recette retenue : basculer la console au menu du chargeur (touche 5) |
| Un mot de passe root a fini par être demandé sans qu'on sache pourquoi | saisie à l'aveugle sur une console série, sans vérifier l'invite | **ne jamais taper sur une console sans lire ce qui est affiché** ; la VM reste un bac à sable, elle a été remise à zéro |

Aucun de ces incidents n'a touché un disque réel : tout s'est passé dans un overlay qcow2, l'image d'origine est intacte.

## 5. Fichiers produits

`tests/results/T-01-demarrage-freebsd.md`, `tests/results/T-03-partage-samba.md`, `scripts/31-lancer-vm-freebsd.sh` (recette de lancement, garde-fous testés), mise à jour de `tests/plan-tests.md`, `matrices/compatibilite.csv` (K-01, K-09, K-10 ; doublon K-15 corrigé en K-16), `matrices/components.csv`, `docs/ETAT.md` v9, `docs/etude-faisabilite.md`.

## 6. Ce qui reste vrai et ne doit pas être embelli

- **2 tests sur 16** sont exécutés. Quatorze restent `NON EXÉCUTÉ`.
- Le PC de 2011 **n'est toujours pas identifié** (Q1). T-02 reste à faire, et c'est lui qui tranche.
- Aucune image NexBSD, aucun code NexBSD, aucune signature.
- Les performances ne sont **pas** mesurées sur le matériel cible ; 81 s en émulation n'annonce rien du HDD de 2011.

## 7. Prochaine action

Deux actions, dans cet ordre :

1. **Relever le matériel du PC de 2011** (`docs/hardware.md` §2, en lecture seule) — toujours le seul verrou qui débloque tout le reste.
2. **Poursuivre la VM** : installer `openldap26-server` et faire authentifier Samba par l'annuaire (T-04) — c'est faisable ici, sans L3, et ça valide la deuxième brique de l'axe réseau.

La version 0.1 reste conditionnée au **profil L3** (Q4) : c'est la seule question qui bloque réellement la construction d'images.

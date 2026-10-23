# Politique de sécurité initiale

**Date :** 2026-10-23 — **Statut :** proposition, à appliquer dès la première installation

## 1. Principes

1. **Réseau isolé par défaut.** Aucun service NexBSD n'est exposé à Internet, ni pendant les tests ni après. Le PC de test est sur un réseau local de laboratoire, derrière un pare-feu en refus par défaut.
2. **Moindre privilège.** Chaque service tourne sous un compte dédié, dans une jail, avec les seuls accès nécessaires.
3. **Pas de secret dans le dépôt.** Aucun mot de passe, clé privée, jeton ou donnée personnelle dans les documents, les scripts ou l'historique Git.
4. **Rien n'est « validé » sans test.** Une mesure de sécurité non testée est une intention.
5. **Traçabilité.** Toute action d'administration significative est journalisée.

## 2. Mesures concrètes

| Domaine | Mesure | Vérification |
|---|---|---|
| Pare-feu | `pf` en `block all` puis ouverture explicite | test T-05a : scan externe |
| Services | un jail par service exposé ; pas de service sous root | `jls`, `ps -aux` consignés |
| Mots de passe | mots de passe robustes, hachage système par défaut, aucun partage de compte | revue de configuration |
| Communications | SMB3 avec signature/chiffrement ; LDAP en TLS ou via socket Unix | captures/config |
| Annuaire | `slapd` non exposé, ACL restrictives, pas d'anonyme en écriture | test d'accès anonyme refusé |
| Journaux | `syslog` local, rotation, permissions restrictives | inspection |
| Mises à jour | `freebsd-update` + `pkg upgrade` avant chaque campagne de tests | date consignée |
| Sauvegardes | sur support distinct, restauration testée | T-06 |
| Protocoles historiques | **interdits** hors laboratoire isolé sans passerelle | revue de périmètre |
| Blobs / firmwares | jamais redistribués ; provenance documentée | inventaire |

## 3. Interdictions

- Exposer Samba, LDAP ou MARS_NWE à Internet.
- Utiliser un protocole non authentifié sur un réseau partagé.
- Exécuter MARS_NWE (ou tout code non maintenu en root) sur une machine contenant des données réelles.
- Désactiver une protection (pare-feu, SIP, antivirus du poste Windows) sans justification écrite et sans mesure compensatoire.
- Stocker des données personnelles sur les volumes de test.

## 4. Composants à risque — traitement

| Composant | Risque | Traitement |
|---|---|---|
| Samba 4.16 (défaut du port) | version non maintenue, CVE connues | interdit : installer explicitement ≥ 4.23 |
| MARS_NWE | code non maintenu, root, protocole sans authentification moderne | interdit hors laboratoire isolé |
| Moteur Web (WebKitGTK) | CVE fréquentes | mises à jour systématiques, pas de contenu non fiable |
| OpenLDAP 2.5 | fin de vie 2027-01-15 | ne pas démarrer un nouveau déploiement dessus |
| Code Firefox OS / Gaia | non maintenu depuis 2021 | étude seulement, jamais exécuté en production |

## 5. Réponse à incident (procédure minimale)

1. Isoler la machine (débrancher le réseau).
2. Consigner l'heure, les symptômes, les journaux disponibles.
3. Revenir à l'état de référence sauvegardé (T-06) plutôt que « réparer » à l'aveugle.
4. Documenter dans `reports/` et mettre à jour le registre des risques.

## 6. Ce qui n'est pas couvert à ce stade

Sécurité physique, chiffrement du disque de test, authentification multi-facteurs, audit formel, tests d'intrusion. À traiter en phase 6, si le projet y arrive.

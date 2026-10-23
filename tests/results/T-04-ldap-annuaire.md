# T-04 — Annuaire OpenLDAP opérationnel — **EN COURS**

**Date de démarrage :** 2026-10-23 (soir), sur la VM du responsable (Linux Mint, KVM)
**Objectif :** prouver qu'un annuaire centralise les identités sur FreeBSD — deuxième brique de l'axe réseau (EF-N-03).
**Protocole exécutable :** `scripts/60-banc-T04-ldap.sh` (4 blocs, chacun vérifiable).

---

## 1. Ce que le test doit démontrer

| Étape | Preuve attendue |
|---|---|
| A | la VM a un accès réseau (`INTERNET_OK`) et un compte utilisateur non-root |
| B | `openldap26-server` installé depuis les dépôts officiels |
| C | `slapd` **tourne** (`SLAPD_OK`) et écoute |
| D | `ldapadd` crée l'arborescence ; `ldapsearch` **retrouve** l'utilisateur |
| E *(étape suivante)* | Samba authentifie un utilisateur **via l'annuaire**, pas via sa base locale |

## 2. Identifiants de laboratoire (usage strictement local)

| Élément | Valeur | Remarque |
|---|---|---|
| Suffixe | `dc=nexbsd,dc=local` | arborescence d'essai |
| Admin annuaire | `cn=admin,dc=nexbsd,dc=local` | mot de passe `adminsecret` — **laboratoire uniquement** |
| Utilisateur test | `uid=omrane,ou=people,…` | `uidNumber=10000` |

**Ces secrets ne doivent jamais être réutilisés hors de cette VM jetable.** Le système final ne les contiendra pas.

## 3. Journal d'exécution

| Étape | Résultat | Observations |
|---|---|---|
| A — réseau | ⬜ à renseigner | |
| B — installation | ⬜ | durée réelle à noter (avec KVM, attendu bien plus rapide que les 4 min 30 de l'émulation) |
| C — slapd | ⬜ | |
| D — ldapsearch | ⬜ | sortie verbatim à coller |

## 4. Pièges connus (anticipés)

| Symptôme | Cause probable | Correction |
|---|---|---|
| `database mdb` → « backend not found » | backend compilé en module | ajouter `moduleload back_mdb` en tête de `slapd.conf` |
| `slapd` refuse de démarrer | `/var/db/openldap-data` absent ou mal propriétaire | `mkdir -p` + `chown ldap:ldap` |
| `ldapadd` : « Invalid credentials » | mot de passe `rootpw` différent | vérifier la ligne `rootpw` |
| `ldapsearch` : « No such object » | base pas encore importée | refaire le bloc D |

## 5. Verdict

**NON CONCLU** — le test est lancé, aucun résultat n'est encore consigné. Tant que ce tableau n'est pas rempli, T-04 reste `EN COURS` dans `tests/plan-tests.md`.

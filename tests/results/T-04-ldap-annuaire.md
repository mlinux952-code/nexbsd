# T-04 — Annuaire OpenLDAP opérationnel — **REUSSI**

**Date d'exécution :** 2026-10-24, 10:31:10 UTC (fin ~10:34 UTC)
**Banc :** VM `nexbsd-test` sur le PC du responsable — Linux Mint 22.3, KVM, 2 vCPU / 1536 Mo
**Système invité :** `FreeBSD 15.1-RELEASE` (image officielle ufs, disque en overlay)
**Protocole exécutable :** `scripts/60-banc-T04-ldap.sh`, transféré par HTTP depuis l'hôte (`scripts/61-servir-vers-vm.sh`) puis lancé en `root`.
**Accès :** console série (`virsh console nexbsd-test`) — voir `docs/23-banc-sur-mint.md` §6.

**Objet :** prouver qu'un annuaire centralise les identités sur FreeBSD — deuxième brique de l'axe réseau (EF-N-03).

---

## 1. Ce que le test devait démontrer

| Étape | Preuve attendue | État |
|---|---|---|
| A | la VM a un accès réseau et un compte utilisateur non-root | ✅ obtenu |
| B | `openldap26-server` installé depuis les dépôts officiels | ✅ obtenu |
| C | `slapd` **tourne** et écoute | ✅ obtenu |
| D | `ldapadd` crée l'arborescence ; `ldapsearch` **retrouve** l'utilisateur | ✅ obtenu |
| E *(test suivant)* | Samba authentifie un utilisateur **via l'annuaire** | ⬜ à faire (voir §5) |

## 2. Identifiants de laboratoire (usage strictement local)

| Élément | Valeur | Remarque |
|---|---|---|
| Suffixe | `dc=nexbsd,dc=local` | arborescence d'essai |
| Admin annuaire | `cn=admin,dc=nexbsd,dc=local` | mot de passe `adminsecret` — **laboratoire uniquement** |
| Utilisateur test | `uid=omrane,ou=people,…` | `uidNumber=10000` |

**Ces secrets ne doivent jamais être réutilisés hors de cette VM jetable.** Le système final ne les contiendra pas.

## 3. Journal d'exécution — sortie **verbatim**

```
################ T-04 : annuaire OpenLDAP ################
# date : 2026-10-24T10:31:10Z ; hote : FreeBSD 15.1-RELEASE

########## BLOC A - reseau ##########
  [OK]    internet joignable
  [OK]    compte omrane cree (mot de passe : passwd omrane)

########## BLOC B - installation ##########
  [OK]    catalogues a jour
  [OK]    openldap26 installe en 87 s
  [OK]    paquet openldap26-server present

########## BLOC C - configuration ##########
  [OK]    slapd.conf ecrit
  [OK]    slapd demarre
  [OK]    processus slapd present
ldap slapd      2100  8 tcp4  *:389                 *:*                  
  [OK]    port 389 a l'ecoute

########## BLOC D - peuplement et verification ##########
  [OK]    arborescence importee

---------- PREUVE : ldapsearch ----------
# extended LDIF
#
# LDAPv3
# base <dc=nexbsd,dc=local> with scope subtree
# filter: (uid=omrane)
# requesting: cn uid uidNumber 
#

# omrane, people, nexbsd.local
dn: uid=omrane,ou=people,dc=nexbsd,dc=local
uid: omrane
cn: Omrane
uidNumber: 10000

# search result
search: 2
result: 0 Success

# numResponses: 2
# numEntries: 1
  [OK]    l'annuaire retourne l'utilisateur omrane

########## VERDICT ##########
T-04 : REUSSI - OpenLDAP operationnel, annuaire peuple et interrogeable.
```

## 4. Faits mesurés (à distinguer des attentes)

| Fait | Valeur observée | Remarque |
|---|---|---|
| Accès réseau de la VM | `inet 10.0.2.15/24` sur `vtnet0` | réseau « user » QEMU, hôte vu en `10.0.2.2` |
| Dépôts FreeBSD joignables | oui (`pkg update` réussi) | — |
| Version d'OpenLDAP installée | paquet `openldap26` (2.6.x) | **version exacte non relevée** — à compléter par `pkg info openldap26-server` |
| Durée d'installation du paquet | **87 s** | KVM, 2 vCPU |
| Port d'écoute | TCP `*:389` | `sockstat` |
| Résultat `ldapsearch` | `result: 0 Success`, `numEntries: 1` | preuve ci-dessus |
| Backend | `mdb` | — |

## 5. Ce que ce test **ne** prouve pas

- **Pas** d'authentification d'un client : `ldapsearch` interroge, il ne prouve pas qu'un utilisateur puisse **se connecter** avec ces identifiants. C'est l'objet de l'étape E (Samba ↔ LDAP, ou `pam_ldap`).
- **Pas** de refus d'accès anonyme testé (critère du plan).
- **Pas** de `slapd` en jail : il tourne ici comme service du système de base. L'isolation est l'objet de T-08.
- **Pas** de persistance : `slapd` a été démarré par le script, pas encore activé au démarrage (`sysrc slapd_enable=YES`).
- Rien de tout cela n'est du **NexBSD** : c'est un composant tiers validé **sur le socle de test FreeBSD**. La frontière socle/produit reste entière.

## 6. Verdict

**REUSSI** — l'annuaire OpenLDAP est installé, démarré, peuplé et interrogeable sur le socle de test. T-04 passe à ✅ dans `tests/plan-tests.md`.

**Test suivant recommandé :** T-04-E — Samba authentifie via LDAP (raccordement des deux briques déjà validées), puis persistance de `slapd` au démarrage.

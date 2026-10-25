# Compte rendu de session — modèle et dernier état

**Rôle :** livrable exigé par la **Partie XVIII** (continuité et mémoire) et la **Partie XX §7** (continuité entre
intelligences artificielles) du méga-prompt maître. Ce document doit permettre à **une autre IA ou à un autre
développeur** de reprendre le projet **sans lire l'historique d'une conversation**.

**Règle :** on n'y écrit que ce qui a été **vérifié**. Un élément non exécuté est noté « non exécuté ».

---

## Session S-016 — 2026-10-24

### 1. État du projet à la fin de la session

| Élément | État |
|---|---|
| Phase | 4 (**preuve de faisabilité**) en cours — les phases 0 à 3 sont documentées |
| Banc d'essai | **VM FreeBSD 15.1-RELEASE opérationnelle** (KVM/virt-manager, console série `ttyu0`, réseau `10.0.2.15`, hôte `10.0.2.2`) |
| Tests réussis | **6 sur 19** : T-01, T-03, T-04, T-04-E, T-04-F, **T-04-G (11/11)** |
| Problème ouvert | **aucun bloquant** — C-14 **clos** le 2026-10-25 (cause : la machine ne résolvait pas les identités de l'annuaire ; correctif `nss-pam-ldapd`) |
| Image NexBSD | **aucune** — aucun fichier compilé, aucune image produite |
| Prototype minimal livrable (livrable 11) | **amorcé** : le banc fonctionne, mais s'obtient en enchaînant 4 scripts à la main |

### 2. Fichiers créés ou modifiés pendant la session

| Fichier | Nature |
|---|---|
| `scripts/62-banc-T04E-samba-ldap.sh` | **v3** — Samba + annuaire ; attente active de l'écoute (correctif C-11) |
| `scripts/63-banc-T04F-droits-groupes.sh` | **v2** — droits par groupes de l'annuaire ; **nouveau** |
| `scripts/64-banc-T04G-persistance.sh` | **v2** — persistance après redémarrage ; **nouveau** |
| `tests/results/T-04E-samba-ldap.md` | RÉUSSI, journal des 3 essais |
| `tests/results/T-04F-droits-groupes.md` | RÉUSSI, journal des 2 essais |
| `tests/results/T-04G-persistance.md` | EN COURS, essai 1 (7/11) |
| `tests/plan-tests.md` | 18 tests, 5 réussis |
| `docs/16-registre-problemes.md` | C-10, C-11, C-12, C-13 **clos** ; **C-14 ouvert** ; C-15 **clos** |
| `docs/15-conformite-mega-prompt.md` | **v1.1** — livrables 11 et 12 « amorcés » ; nouveau §3 (Partie XX) |
| `docs/ETAT.md` | **v14** |
| `CHANGELOG.md` | entrées S-015 et S-016 |

### 3. Décisions prises (par le responsable ou validées par les faits)

| Décision | Fondement |
|---|---|
| L'axe prioritaire reste le **réseau façon NetWare** | ADR-0017 ; le banc d'identités le sert directement |
| Le schéma Samba **n'entre jamais** dans le dépôt (GPL-3.0+) | frontière de licences, ADR-0012 ; téléchargé à l'exécution avec SHA256 épinglée |
| Sous `ldapsam:trusted`, **tout groupe référencé par un `gidNumber` doit porter son identité Samba** | constat C-13 |
| Un test de droits **sans refus** ne prouve rien | règle posée avant l'exécution de T-04-F |

### 4. Résultats vérifiés (pas des hypothèses)

- **T-04-E** : `sambaSID` de `omrane` **dans l'annuaire** ; `smbclient` s'authentifie et liste le partage.
- **T-04-F** : un compte créé **uniquement** dans l'annuaire (`sara`) est authentifié ; `omrane` (groupe `bureau`)
  écrit dans `[commun]`, `sara` (groupe `stagiaires`) y est **refusée** ; `sara` lit `[public]`.
- **T-04-G (partiel)** : après un **redémarrage réel**, `slapd` et `smbd` reviennent **seuls**, `smbd` écoute sur
  `:445`, l'annuaire est **intact** (10 entrées avant et après, `sara` garde son SID `…-1010`, appartenance
  `omrane → bureau` conservée), le fichier témoin est retrouvé.

### 5. Problème ouvert — C-14 (à reprendre en premier)

**Symptôme :** après redémarrage, `smbclient` renvoie `NT_STATUS_LOGON_FAILURE` pour **tous** les comptes, alors
que les mêmes accès fonctionnaient avant.

**Faits établis :** `slapd` et `smbd` tournent ; `:445` écoute ; l'annuaire est intact ; `pdbedit` lit le compte
et les bons SID ; `net getlocalsid` = `S-1-5-21-692378897-511874203-3061570918` ; `secrets.tdb` daté du **12:10**
(antérieur aux redémarrages de 13:20).

**Hypothèses éliminées :** secrets perdus / domaine régénéré.

**Hypothèses restantes, par ordre de probabilité :**
1. **État interne de `smbd` figé au démarrage** — il aurait initialisé `ldapsam` avant que `slapd` écoute.
   *Rectification importante* : le succès de `pdbedit` **n'élimine pas** cette hypothèse, car `pdbedit` est un
   processus neuf qui ouvre sa propre connexion ; il ne dit rien de l'état de `smbd`.
2. **Droits de lecture sur `sambaNTPassword`** — la lecture du compte réussirait, pas celle de l'empreinte.

**Deux commandes suffisent à trancher** (première action de la prochaine session) :

```
sh -c 'tail -30 /var/log/samba4/log.smbd; echo "==MDP-LDAP=="; ldapsearch -x -b "dc=nexbsd,dc=local" "(uid=omrane)" sambaNTPassword; echo "==ORDRE=="; grep -iE "smbd|slapd" /var/log/messages | tail -10'
```

```
service samba_server restart; sleep 12; smbclient //127.0.0.1/commun -U 'omrane%omranelab' -c 'ls'
```

### 6. Prochaines actions, dans l'ordre

| # | Action | Critère de réussite |
|---|---|---|
| 1 | Trancher C-14 avec les deux commandes ci-dessus | la cause est nommée par une preuve |
| 2 | Corriger la cause **dans la configuration**, pas à la main | le correctif survit lui-même à un redémarrage |
| 3 | Rejouer T-04-G en entier (phase `avant` puis `apres`) | **11 / 11** |
| 4 | Transformer les scripts 60→64 en **un seul composant installable** (`components/identites/`) | une machine nue devient serveur d'identités par **une** commande |
| 5 | Ranger le dossier Drive selon l'arborescence de la Partie XX | dossiers `00_Gouvernance` … `08_Versions_et_Archives` |

### 7. Ce qu'il ne faut pas oublier en reprenant

- **Ne jamais relancer 60/62/63 après un redémarrage** pour « faire marcher » : cela masquerait C-14.
- Le **serveur HTTP** du Mint sert `~/Projets/nexbsd/scripts` : après une fusion, la VM voit les nouveaux
  scripts **sans redémarrage** du serveur.
- Les **mots de passe du banc sont de laboratoire** (`adminsecret`, `omranelab`, `saralab`) — VM jetable,
  non exposée au réseau. Ils ne doivent jamais servir ailleurs.
- **L'IA n'a aucun accès à GitHub.** L'état du dépôt distant ne peut être affirmé que par le responsable.

---

## Session S-017 — 2026-10-25

### Ce qui a changé

- **C-14 trouvé, compris, corrigé, vérifié.** Cause réelle, lue dans le journal du démarrage à froid :
  `add_local_groups: SID …-1001 -> getpwuid(10000) failed, is nsswitch configured?` puis
  `check_sam_security: make_server_info_sam() failed with 'NT_STATUS_NO_SUCH_USER'`. **L'annuaire
  délivrait les identités, la machine ne les résolvait pas.** Correctif : `scripts/65` (`nss-pam-ldapd`).
- **T-04-G RÉUSSI, 11 contrôles sur 11** : le banc revient seul après redémarrage, annuaire et droits
  intacts, `omrane` écrit, `sara` reste refusée.
- **Identité du produit (rapport du responsable)** : `docs/26-identite-et-nommage.md` distingue le
  **socle** (FreeBSD 15.1 stock) du **produit** (NexBSD) ; `scripts/66` applique l'**étage 1** (nom
  d'hôte, accueil, invite) sans prétendre que le système *est* NexBSD.

### Prochaine action

| # | Action | Critère de réussite |
|---|---|---|
| 1 | Exécuter `scripts/66` (T-16, étage 1) | l'invite affiche `root@nexbsd`, les services répondent |
| 2 | Regrouper les scripts `60`→`66` en **un composant** `components/identites/` | une machine nue devient serveur d'identités NexBSD par **une** commande |
| 3 | Étages 2 et 3 de l'identité (chaîne de version, image propre) | bloqués par le profil **L3** (P-03) |

# T-18 — Harnais de tests automatisé

**Date :** 2026-10-26 · **Objet :** passer d'une suite de protocoles manuels à **une commande, un verdict,
un code de retour** (manque n° 2 de l'audit croisé, `docs/32`).

---

## Essai 1 — harnais v1.0 : **ÉCHEC (22/24)**, code de retour 1

Sortie verbatim (extraits significatifs) :

```
# hote : FreeBSD 15.1-NEXBSD-L1 ; noyau : NEXBSD_L1 ; mode : complet
  [OK]    empreinte du noyau demarre = 82dc5681397b06fa... (identique au noyau construit)
  [KO]    /var/samba/commun : drwxrws--- bureau (attendu drwxrws--- 2001)
  [KO]    omrane n'a pas pu ecrire dans [commun] : putting file /tmp/harnais.mQptXc as \harnais-221555.txt (0.5 kB/s) (average 0.5 kB/s)
controles : 24 au total | 22 reussis | 2 en echec | 0 non applicables
HARNAIS : ECHEC (22/24 obligatoires)
CODE DE RETOUR : 1
```

### Analyse : les deux défauts sont dans le **harnais**, pas dans le système

| Échec | Cause réelle | Correctif |
|---|---|---|
| `drwxrws--- bureau (attendu 2001)` | `ls -ld` affiche le **nom** du groupe ; le controle attendait le **numéro**. `scripts/64` utilisait deja `ls -ldn`. | `ls -ldn` (numerique) |
| `omrane n'a pas pu ecrire` | `smbclient` affiche **toujours** sa ligne de progression (`putting file ... (0.5 kB/s)`), meme quand l'ecriture **reussit**. Le controle jugeait sur le **texte** au lieu du **code de retour**. `scripts/64` testait deja le code de retour. | juger sur le code de retour ; le texte ne sert qu'a **qualifier** le refus (`NT_STATUS_ACCESS_DENIED`) |

**Preuve que le systeme, lui, allait bien :** dans le meme passage, `sara est refusee dans [commun]`,
`sara lit [public]`, annuaire (10 entrees, SID de `sara`, groupe `bureau`), NSS (`2001`, `2002`),
`ldapsam:trusted = yes`, `netbios name = NEXBSDFS`, et surtout **l'empreinte du noyau demarre
`82dc5681…` identique au noyau construit**.

**Leçon methodologique :** un harnais qui se trompe est **plus dangereux** qu'aucun harnais, parce qu'il
accuse le systeme a tort. Tout controle doit etre ecrit **d'apres une source de verite deja validee**
(ici `scripts/64`), pas reinvente.

---

## Essai 2 — harnais v1.1 : (a completer apres execution)

Empreinte du fichier v1.1 : **`ef46576c2fa67b485a587135e757553693dbb0f9c31b8336d8bec42618513c8d`** (267 lignes)

## Essai 2 — harnais v1.1 : **RÉUSSI (24/24)**, code de retour 0

Empreinte du fichier : `ef46576c2fa67b485a587135e757553693dbb0f9c31b8336d8bec42618513c8d` (267 lignes).
Sortie verbatim (intégrale) :

```
############## HARNAIS NEXBSD v1.1 ##############
# date : 2026-10-26T22:19:32Z
# hote : FreeBSD 15.1-NEXBSD-L1 ; noyau : NEXBSD_L1 ; mode : complet

----- 1. identite du systeme -----
  [OK]    uname -i = NEXBSD_L1 (le systeme annonce notre identite)
  [OK]    uname -r = 15.1-NEXBSD-L1
  [OK]    uname -s = FreeBSD (le socle, conformement a docs/26)
  [OK]    nom d'hote = nexbsd
  [OK]    empreinte du noyau demarre = 82dc5681397b06fa... (identique au noyau construit)

----- 2. services d'annuaire et de fichiers -----
  [OK]    slapd tourne
  [OK]    389 (LDAP) en ecoute
  [OK]    smbd tourne
  [OK]    445 (SMB) en ecoute

----- 3. contenu de l'annuaire -----
  [OK]    annuaire : 10 entrees (minimum 10)
  [OK]    sara a un SID : S-1-5-21-692378897-511874203-3061570918-1010
  [OK]    groupe bureau : SID S-1-5-21-692378897-511874203-3061570918-3001
  [OK]    bureau a pour membre : omrane

----- 4. identites Unix derivees de l'annuaire (NSS) -----
  [OK]    NSS : bureau -> gid 2001
  [OK]    NSS : stagiaires -> gid 2002
  [OK]    NSS : omrane resolu

----- 5. droits des partages sur le disque -----
  [OK]     /var/samba/commun : drwxrws--- 2001 (setgid + groupe 2001)
  [OK]     /var/samba/public : drwxr-xr-x 0 (lecture pour tous)

----- 6. configuration Samba (testparm) -----
  [OK]    ldapsam:trusted = yes
  [OK]    netbios name = NEXBSDFS
  [OK]    passdb backend = ldapsam

----- 7. service reellement utilisable (ecriture / refus / lecture) -----
  [OK]    omrane ecrit dans [commun] (code de retour 0)
  [OK]    sara est refusee dans [commun] avec ACCESS_DENIED (attendu)
  [OK]    sara lit [public] par le reseau

########## VERDICT ##########
controles : 24 au total | 24 reussis | 0 en echec | 0 non applicables
HARNAIS : REUSSI (24/24 obligatoires)
CODE DE RETOUR : 0
```

## Verdict final : **RÉUSSI**

| Élément | Valeur |
|---|---|
| Contrôles | **24 / 24** |
| Échecs | **0** |
| Non applicables | **0** |
| Code de retour | **0** |
| Durée | **~30 secondes** (contre plusieurs minutes de recopie manuelle) |

**Ce qui est désormais vrai :** l'état du banc NexBSD se vérifie par **une commande**, en **30 secondes**,
avec un **verdict calculé** et un **code de retour** exploitable par un script ou une intégration continue.
Aucun humain ne peut plus « se tromper de bonne foi » en recopiant un résultat.

**Ce que cela ne prouve pas :** la persistance après redémarrage (c'est T-04-G), ni le pare-feu (T-05), ni
l'accès depuis un poste client réel (non testé à ce jour). Le harnais mesure **l'état courant du banc**, rien
de plus — et c'est déjà beaucoup.

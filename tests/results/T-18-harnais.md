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

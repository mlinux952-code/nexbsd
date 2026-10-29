# 55 — Exécution #16 : **le système NexBSD a été assemblé** (3 h 14 de construction)

> **Ce document est une PREUVE.** Verbatim de la page GitHub Actions, exécution #16, tâche IMAGE,
> telle que le responsable l'a collée le 2026-10-29. On ne la réécrit jamais : si elle devient
> fausse, on la masque en le disant.

```
NexBSD #16
Annotations : 1 error and 1 warning
3/4 — construction + assemblage NexBSD (plusieurs heures)
Process completed with exit code 1.

IMAGE — buildworld + configuration + media
failed 3 hours ago in 3h 18m 27s
2s / 1s / 2m 19s / 47s / 1s / 16s / 1s / 3h 14m 52s
```

Une seule erreur, sur `3/4`. Les étapes `1/4`, `2/4` et `2bis` sont passées :
le pré-vol a **accepté** l'arbre, ce qui confirme C-41.

---

## 1. Ce qui a été fait, dans l'ordre, pendant ces 3 heures et quart

```
DEBUT 2026-10-28T22:47:55Z

install -T release -o root -g wheel -m 444   zfs.ko  /usr/obj/nexbsd-rootfs/boot/kernel/
install -T dbg     -o root -g wheel -m 444   zfs.ko.debug  /usr/obj/nexbsd-rootfs/usr/lib/debug/…
kldxref /usr/obj/nexbsd-rootfs/boot/kernel
>>> Installing kernel NEXBSD_L1 completed on Thu Oct 29 02:02:45 UTC 2026
>>> Install kernel(s) NEXBSD_L1 completed in 11 seconds, ncpu: 4
```

**Traduction, sans jargon :**

| Étape | Ce qu'elle a fait | Statut |
|---|---|---|
| `buildworld` | compilé le monde FreeBSD complet avec `src.conf` NexBSD | ✅ **fait** |
| `buildkernel NEXBSD_L1` | compilé **notre** noyau (profil PC faible) | ✅ **fait** |
| `installworld` + `distribution` | installé le monde dans `/usr/obj/nexbsd-rootfs` | ✅ **fait** |
| `installkernel NEXBSD_L1` | installé **notre** noyau dans cette racine | ✅ **fait** — 11 s |

C'est la **première fois du projet** qu'un système complet est assemblé dans une racine. Jusqu'ici
on n'avait qu'un noyau compilé et des configs testées au banc.

## 2. La configuration du produit est ENTRÉE dans le système

```
→ application de la configuration NexBSD (fork/overlay/)
########## NexBSD — application de la configuration du produit ##########
# racine    : /usr/obj/nexbsd-rootfs
# mode      : REEL

  [OK] tous les placeholders ont une valeur
  [OK ] /etc/motd
  [OK ] /etc/nexbsd-version
  [OK ] /etc/pam.d/su
  [OK ] /etc/pf.conf
  [OK ] /etc/ssh/sshd_config
  [OK ] /usr/local/etc/openldap/slapd.conf
  [OK ] /usr/local/etc/smb4.conf
  [OK ] /usr/local/etc/nslcd.conf
  [OK ] /root/install-annuaire-base.ldif

--- fusions (jamais de remplacement) ---
  [--  ] /etc/nsswitch.conf : déjà à jour
  [KO ] /etc/rc.conf absent de la racine : fusion impossible
  [KO]    la construction ou l'assemblage a échoué — voir les lignes ci-dessus
```

**Neuf pièces du produit sur neuf sont dans la racine.** L'identité (motd, nexbsd-version), la
sécurité (pam.d/su, pf.conf, sshd_config), l'annuaire (slapd.conf, nslcd.conf, le LDIF) et le
partage (smb4.conf). C'est exactement ce que C-39 avait rendu possible : avant, `make release`
aurait livré une image **sans** tout cela.

## 3. La cause de l'échec — un fichier vide qui manquait

```
[KO ] /etc/rc.conf absent de la racine : fusion impossible
```

`make distribution` **ne crée pas** `/etc/rc.conf` dans une racine `DESTDIR`. Notre
`70-appliquer-overlay.sh` refusait alors de fusionner dans un fichier absent, et **toute la chaîne
s'arrêtait** — à dix secondes de la fin, après 3 h 14 de calcul.

> Refuser de remplir un fichier absent n'est pas une précaution : c'est un blocage.
> Il n'y avait rien à écraser.

## 4. Correctifs (C-42)

1. **`fusionner()` crée désormais le fichier absent**, en l'annonçant :
   `[CREÉ] /etc/rc.conf (absent de la racine : cree par la configuration NexBSD)`.
   Vérifié sur une fausse racine sans `rc.conf` : les **10 réglages NexBSD** y entrent
   (hostname, sshd_enable="NO", samba_server_enable, pf_enable, pflog_enable, slapd_enable,
   nslcd_enable, syslogd_enable, dumpdev, ntpd_enable).
2. **La taille de l'image n'est plus une constante.** `installworld` installe aussi les fichiers
   de débogage (`usr/lib/debug`) : la racine pèse plusieurs Go, et une image de 4 Go fixes aurait
   été refusée par `makefs` (« filesystem too small »). On **mesure** puis on dimensionne
   (+20 % + 512 Mo).
3. **`mkimg` n'est plus fatal.** Le `.ufs` **est** le produit : un système de fichiers complet,
   montable et vérifiable. Le disque bootable n'est qu'une enveloppe. Si l'enveloppe échoue, le
   système n'est pas jeté — c'est la route que `docs/46` décrit comme « la sûre ».
4. **Compression pour le transport** : une image de plusieurs Go n'est pas téléchargeable
   utilement. `gzip -1` en fin de tâche, l'empreinte du fichier **brut** relevée avant, le brut
   supprimé seulement si la compression réussit.

## 5. Ce que cette exécution prouve

| Affirmation | Preuve |
|---|---|
| un monde FreeBSD complet **se compile** avec notre `src.conf` | `buildworld` terminé après ~3 h |
| **notre noyau `NEXBSD_L1` se compile ET s'installe** | `>>> Installing kernel NEXBSD_L1 completed` |
| une racine système complète se construit | `installworld` + `distribution` + `installkernel` |
| **la configuration du produit entre dans le système** | 9 × `[OK ]` sur les fichiers NexBSD |
| les placeholders de secrets sont substitués | `[OK] tous les placeholders ont une valeur` |

## 6. Ce que cette exécution NE prouve PAS

| Affirmation | Statut |
|---|---|
| une **image** existe | ❌ **pas encore** — `makefs` n'a pas été atteint |
| l'image **démarre** | ❌ jamais essayé |
| la session graphique s'affiche | ❌ jamais |
| PAM vérifie un mot de passe | ❌ jamais |
| l'installeur `fork/80` tourne | ❌ jamais |
| les services (Samba, OpenLDAP, nslcd) **démarrent** | ❌ la config est là, inerte |

**Phrase exacte :** *un système NexBSD complet a été assemblé dans une racine, avec le noyau
NexBSD et les neuf pièces de configuration du produit ; l'emballage de ce système en image a
échoué sur un fichier de configuration absent, et rien n'a encore démarré.*

## 7. Ce que coûte une tentative

**3 h 14 de construction + ~4 min de préparation = 3 h 18.** C'est le prix d'un essai, et il n'y a
pas de reprise possible : chaque exécution repart d'une VM vierge. D'où la règle appliquée cette
fois : **corriger tout ce qui peut encore casser APRÈS l'overlay avant de relancer**, parce qu'un
aller-retour coûte une demi-journée.

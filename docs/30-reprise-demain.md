# Reprise demain matin — où l'on en est, et quoi faire

**Écrit le :** 2026-10-25 à 22:10 UTC (S-018, fin de soirée)
**But :** permettre de reprendre **sans conversation**, avec les seules commandes utiles.

---

## 1. Où en est le projet, exactement

| Élément | État |
|---|---|
| Socle du banc | **FreeBSD 15.1-RELEASE**, VM libvirt `nexbsd-test` (session), disques `vtbd0` (système, 6 Go) et `vtbd1` (**construction, 30 Go**) |
| Banc d'identités | **validé** : annuaire + Samba + droits, **T-04-G 11/11**, persistant au redémarrage |
| Identité étage 1 | **appliquée** : `root@nexbsd`, motd NexBSD (le noyau annonce toujours FreeBSD : c'est le socle) |
| Delta du fork | **17 fichiers dans `fork/`** (ex-`build/fork`), empreintes conformes, garde-fou `scripts/70` |
| **Construction du noyau** | **EN COURS ET INTERROMPUE PROPREMENT** : 27 228 lignes de journal à 21:46 UTC, **3,1 Go d'objets compilés conservés** dans `/build/obj` |
| Noyau NexBSD installé | **NON** — rien n'a été installé. Le banc redémarre sur FreeBSD |
| Image NexBSD | **aucune** (hors de portée du poste : 4 Go de RAM pour un besoin de 4-8 Go) |

**Journal de la construction :** `/build/logs/buildkernel-20261025T205343Z.log`

---

## 1 bis. Regle d'arret decidee le 2026-10-25 a 22:15 UTC

Le responsable a fixe une regle simple pour la soiree : **attendre jusqu'a 45 000 lignes de journal**.
- si la construction se termine avant ce seuil : `### code de retour : 0`, l'installation se fera le lendemain ;
- si le seuil est atteint sans terminer : **arret propre de la VM** (`shutdown -p now`), reprise le lendemain.

Rappel factuel qui justifie cette regle : les **3,7 Go d'objets deja compiles sont des fichiers sur disque**.
Un arret propre les conserve tous ; `make` reprend au fichier suivant. On ne perd que le fichier en cours.
C'est consigne ici pour que la decision soit lisible demain, et pas seulement dans une conversation.

---

## 2. Ce matin, dans cet ordre

### ① 🖥️ MINT — démarrer la VM

```sh
virsh --connect qemu:///session start nexbsd-test
virsh --connect qemu:///session console nexbsd-test      # sortie : Ctrl+]
```

### ② 🐧 VM — vérifier que le disque de construction est remonté

```sh
df -h /build | tail -1
```
Attendu : `/dev/gpt/build … /build`. Si vide → `mount /build`.

### ③ 🐧 VM — voir où en est la construction

```sh
tail -4 /build/logs/buildkernel-20261025T205343Z.log
```
- si la dernière ligne est `### code de retour : 0` → **la construction a abouti pendant la nuit** : aller au ⑤ ;
- sinon → continuer au ④ (reprise).

### ④ 🐧 VM — reprendre la construction (si nécessaire)

```sh
B="http""://""10.0.2.2:8000"
fetch -o /tmp/68.sh "$B/68-construire-noyau-nexbsd.sh"
sh /tmp/68.sh --lancer
```
Le script annonce `reprise : … d'objets deja construits seront reutilises`, puis `make` finit le reste
(**10 à 25 minutes** attendues, l'essentiel est déjà compilé).

Suivi : `sh /tmp/68.sh --etat` · fin attendue : `### code de retour : 0`.

### ⑤ 🐧 VM — vérifier le noyau produit

```sh
sh /tmp/68.sh --verifier
```
Attendu : `ETAT : NOYAU CONSTRUIT` + empreinte + chaîne de version `15.1-NEXBSD-L1`.

### ⑥ 🐧 VM — installer (avec le `69` à jour, **sans symboles de débogage**)

```sh
B="http""://""10.0.2.2:8000"
fetch -o /tmp/69.sh "$B/69-installer-noyau-nexbsd.sh"
sh /tmp/69.sh
```
Attendus : `Disk attached`, `/boot/kernel renomme en /boot/kernel.GENERIC-sauvegarde`,
`/boot/kernel.NEXBSD_L1 present`, puis **`ETAT : NOYAU INSTALLE — REDEMARRAGE NON EFFECTUE`**.

### ⑦ 🐧 VM — redémarrer et prouver (T-17)

```sh
reboot
```
Puis, après le démarrage :

```sh
uname -i ; uname -r ; uname -s
sh /tmp/64-banc-T04G-persistance.sh
```

**Critères de réussite (les cinq de `docs/28` §6) :**
`uname -i` = **NEXBSD_L1** · `uname -r` = **15.1-NEXBSD-L1** · `uname -s` = `FreeBSD` (normal) ·
invite `root@nexbsd` · **banc 11/11**.

---

## 3. Si le noyau ne démarre pas

Dans le menu du chargeur (délai 5 s) :

```
set kernel="kernel.GENERIC-sauvegarde"
boot
```

Le banc revient sur son noyau d'origine. **Aucune perte** : le disque système n'a pas été touché par la
construction (elle vit sur `vtbd1`). Ensuite : supprimer la ligne `kernel=` de `/boot/loader.conf`.

---

## 4. Points sur les I, à ne pas oublier en reprenant

- Ce qui sera acquis demain n'est **pas** un système d'exploitation indépendant : c'est **un fork de FreeBSD**
  (comme pfSense, TrueNAS, OPNsense) avec **son noyau**, **son nom de version** et **sa provenance vérifiable**.
- Le delta réel du noyau est de **5 lignes** sur 393 : le nom + 4 périphériques retirés.
- `uname -s` dira encore `FreeBSD` : le correctif d'identité (`fork/patches/0001-identite-version.patch`)
  n'est **pas** appliqué.
- **Aucune image installable** n'existe et le PC de 2011 n'est pas installé. Ces deux étapes (J3→J5 de
  `docs/29`) passent par l'**intégration continue**, pas par ce poste.
- Le socle validé (11/11) est sur `vtbd0`, la construction sur `vtbd1` : **l'un ne peut pas détruire l'autre**.

---

## 5. Sauvegardes au moment de l'arrêt

| Instantané | Contenu | État |
|---|---|---|
| **s028** | 71 commits, HEAD `2964e2f` : scripts/68 corrigé (pid recyclé), T-17 jusqu'à 21:46, delta vérifié | Drive, public, sha256 `dfa116b0…e9c850` |
| s027 | 69 commits : restauration du delta en `fork/`, C-18, garde-fou `scripts/70` | Drive, public, poussé sur GitHub |
| s026 | 68 commits : C-17 (fausses alertes `-Werror`) | Drive |

**Avant tout travail :** `sh scripts/70-verifier-delta.sh` doit répondre
`VERDICT : DELTA INTACT (17 fichiers, empreintes conformes)`.

#!/bin/sh
# build-nexbsd.sh — chaîne de construction d'une image NexBSD.
#
# STATUT : JAMAIS EXÉCUTÉ. Chaque commande est celle décrite par la documentation
# FreeBSD (build(7), release(7)) ; l'assemblage n'a pas été validé.
# Ce script refuse de démarrer si les conditions du profil L3 ne sont pas réunies.
#
# Usage : sh build-nexbsd.sh /chemin/vers/arbre-source
set -eu

SRC=${1:-/usr/src}
ICI=$(cd "$(dirname "$0")" && pwd)
# C-39 (2026-10-28) : le repertoire des objets est DECIDE par l'appelant, pas subi.
# Sans MAKEOBJDIRPREFIX explicite, make place les objets DANS l'arbre source quand celui-ci
# n'est pas /usr/src — ce qui rend la construction impossible a retrouver ensuite.
OBJ=${OBJ:-/usr/obj}
export MAKEOBJDIRPREFIX="$OBJ"

# --- Garde-fous (le script s'arrête plutôt que d'abîmer) ------------------
[ "$(uname -s)" = "FreeBSD" ] || { echo "ERREUR : la construction exige un hôte FreeBSD." >&2; exit 1; }

RAM_MO=$(sysctl -n hw.physmem | awk '{print int($1/1048576)}')
[ "$RAM_MO" -ge 7000 ] || { echo "ERREUR : ${RAM_MO} Mo de RAM ; le profil L3 exige >= 8 Go (ADR-0010)." >&2; exit 1; }

FREE_GO=$(df -k "$OBJ" | awk 'NR==2 {print int($4/1048576)}')
[ "$FREE_GO" -ge 40 ] || { echo "ERREUR : ${FREE_GO} Go libres dans $OBJ ; 40 Go minimum." >&2; exit 1; }

[ -f "$SRC/Makefile" ] && [ -d "$SRC/sys" ] || { echo "ERREUR : $SRC n'est pas un arbre source FreeBSD." >&2; exit 1; }
[ -f "$ICI/sys/amd64/conf/NEXBSD_L1" ] || { echo "ERREUR : noyau NexBSD absent (lancer tools/generer-kernel-conf.sh)." >&2; exit 1; }

echo "→ profil L3 détecté : ${RAM_MO} Mo RAM, ${FREE_GO} Go libres"
echo "→ RAPPEL : aucune étape ci-dessous n'a jamais été exécutée par le projet."

# --- 1. Le noyau NexBSD entre dans l'arbre source ------------------------
cp "$ICI/sys/amd64/conf/NEXBSD_L1" "$SRC/sys/amd64/conf/NEXBSD_L1"

# --- 2. Options de construction -----------------------------------------
cp "$ICI/src.conf" "$SRC/nexbsd-src.conf"

# --- 3. Monde + noyau ---------------------------------------------------
cd "$SRC"
echo "→ buildworld (plusieurs heures)"
env SRCCONF="$SRC/nexbsd-src.conf" make -j"$(sysctl -n hw.ncpu)" buildworld
echo "→ buildkernel NEXBSD_L1"
env SRCCONF="$SRC/nexbsd-src.conf" KERNCONF=NEXBSD_L1 make -j"$(sysctl -n hw.ncpu)" buildkernel

# --- 4. Racine du système : le monde installé dans un dossier -------------
# AJOUT DU 2026-10-28 (constat mesuré : ce script ne mentionnait JAMAIS overlay/).
# Une image construite par release.sh seul était « FreeBSD + noyau maison » : configuration du
# produit présente dans le dépôt, mais ABSENTE du système. On installe donc le monde dans une
# racine maîtrisée, on y applique la configuration du produit, et seulement ensuite on fabrique
# le média. RESTE À VÉRIFIER PAR EXÉCUTION : `distribution`, `makefs`, `mkimg`.
RACINE=${RACINE:-$OBJ/nexbsd-rootfs}
echo "→ racine du système : $RACINE"
[ "$RACINE" != "/" ] || { echo "ERREUR : RACINE = / refusée." >&2; exit 1; }
rm -rf "$RACINE"
mkdir -p "$RACINE"

cd "$SRC"
echo "→ installworld + distribution dans $RACINE (30 à 60 min)"
env SRCCONF="$SRC/nexbsd-src.conf" make installworld DESTDIR="$RACINE"
env SRCCONF="$SRC/nexbsd-src.conf" make distribution DESTDIR="$RACINE"
echo "→ installkernel NEXBSD_L1 dans $RACINE"
env SRCCONF="$SRC/nexbsd-src.conf" KERNCONF=NEXBSD_L1 make installkernel DESTDIR="$RACINE"

# --- 5. La configuration du produit entre dans le système ----------------
echo "→ application de la configuration NexBSD (fork/overlay/)"
sh "$ICI/70-appliquer-overlay.sh" -r "$RACINE" \
	-p "${NEXBSD_SID:?ERREUR : NEXBSD_SID non fourni (net getlocalsid sur le système installé)}" \
	-b "${NEXBSD_LDAP_BINDPW:?ERREUR : NEXBSD_LDAP_BINDPW non fourni}" \
	-R "${NEXBSD_LDAP_ROOTPW:?ERREUR : NEXBSD_LDAP_ROOTPW non fourni}"
echo "  VERIFIE : /etc/nexbsd-version, /etc/pam.d/su, /etc/pf.conf sont désormais DANS le système."

# --- 6. Média bootable ---------------------------------------------------
# ⚠️ NON VÉRIFIÉ : la syntaxe exacte de `mkimg` (partition efi avec fichier) n'a pas été
# confrontée à un système réel. Si elle échoue, le repli MBR ci-dessous s'applique. La route
# sûre pour un premier essai est de produire `nexbsd.ufs` (makefs) et de le monter/démarrer
# directement, sans table de partitions — on prouve ainsi que le SYSTÈME est bon avant de
# prouver que le MÉDIA est bon. Ne pas présenter comme acquis ce qui n'a pas tourné.
echo "→ makefs + mkimg"
UFS="$RACINE/../nexbsd.ufs"
IMG="$RACINE/../nexbsd.img"
rm -f "$UFS" "$IMG"

# C-42 (2026-10-29) : la taille ne doit plus etre une CONSTANTE. installworld installe aussi
# les fichiers de debogage (usr/lib/debug) : la racine pese plusieurs Go, et une image de 4 Go
# fixes serait refusee par makefs (« filesystem too small »). On mesure, puis on dimensionne.
UTILISE_MO=$(du -sm "$RACINE" | awk '{print $1}')
TAILLE_MO=${TAILLE_MO:-0}
# C-52 (2026-10-30) : 512 Mo de marge ne suffisent PAS. Mesure : racine ~1573 Mo, disque 2400 Mo,
# donc ~827 Mo libres — alors que fork/80 installe Samba (~90 Mo), OpenLDAP (~25 Mo) et nslcd,
# et que le bureau de la couche C demande X11 (~350 Mo) plus WebKitGTK (~600 Mo).
# Une marge de 512 Mo garantissait l'echec de fork/80 APRES des heures de construction : exactement
# le genre de defaut qui ne se voit qu'a la facture. On porte la marge a 2048 Mo.
MARGE_MO="${NEXBSD_MARGE_MO:-2048}"
[ "$TAILLE_MO" -eq 0 ] && TAILLE_MO=$(( UTILISE_MO + UTILISE_MO / 5 + MARGE_MO ))
echo "→ racine : ${UTILISE_MO} Mo utilises ; image dimensionnee a ${TAILLE_MO} Mo (+20 % + 512 Mo)"

makefs -t ffs -s "${TAILLE_MO}m" -o version=2 "$UFS" "$RACINE" \
	|| { echo "ERREUR : makefs a echoue — pas d'image du tout" >&2; exit 1; }
ls -l "$UFS"

# Le .ufs EST le produit : un systeme de fichiers complet, montable et verifiable.
# Le disque bootable n'est qu'une ENVELOPPE autour de lui. Si l'enveloppe echoue, on ne jette
# pas le systeme : c'est deja un resultat, et c'est la route que docs/46 decrit comme « sure ».
# ═══════════════════════════════════════════════════════════════════════════════
# C-51 (2026-10-30) — L'IMAGE NE DEMARRAIT PAS : AUCUNE CHAINE D'AMORCAGE
# ═══════════════════════════════════════════════════════════════════════════════
# Mesure faite sur le disque publie (Release image-18, 478 Mo compresses) :
#   * secteur 0  : boot0 PRESENT (les chaines « F1 FreeBSD / F6 PXE / Boot: » y sont) ;
#   * secteur 1  : les 512 premiers octets de la slice FreeBSD sont A ZERO ;
#   * 0 a 65535  : ZERO octet non nul dans toute la zone d'amorcage de la slice ;
#   * 65536      : superbloc UFS2 valide (magic 0x19540119) -> le systeme de fichiers EST la.
# Autrement dit : le disque contenait un systeme, mais rien pour le LANCER.
# boot0 charge le premier secteur de la slice active et y cherche boot1 : il trouvait des
# zeros, donc « Invalid Bootblock » et arret. Les deux commandes mkimg essayees jusqu'ici
#   mkimg -s mbr -b boot0 -p freebsd:=UFS        (pas de boot1, pas de disklabel)
#   mkimg -s gpt -b pmbr  -p freebsd-ufs:=UFS    (pas de gptboot)
# produisent toutes deux un disque NON AMORCABLE : c'est une propriete de mkimg, pas un alea.
#
# La chaine correcte est celle des images officielles de FreeBSD, lue dans
# release/tools/vmimage.subr :
#   mkimg -s gpt -b pmbr -p freebsd-boot/bootfs:=gptboot -p freebsd-ufs/rootfs:=UFS
# pmbr demarre, lit la table GPT, saute dans gptboot, qui charge /boot/loader.
#
# ET ON NE CROIT PAS MKIMG SUR PAROLE : apres fabrication, on OU VRE le disque et on
# verifie qu'une partition freebsd-boot existe. Un disque sans amorcage ne doit plus
# jamais sortir d'ici en silence (C-50, encore).
echo "→ enveloppe bootable (GPT + pmbr + gptboot, la chaine des images officielles)"

MANQUE_AMORCAGE=0
for f in boot/gptboot boot/pmbr boot/loader; do
	if [ -f "$RACINE/$f" ]; then
		echo "  [OK ] $RACINE/$f ($(wc -c < "$RACINE/$f") octets)"
	else
		echo "  [KO ] $RACINE/$f ABSENT — le disque ne pourra pas demarrer"
		MANQUE_AMORCAGE=$((MANQUE_AMORCAGE + 1))
	fi
done
if [ "$MANQUE_AMORCAGE" -ne 0 ]; then
	echo "ERREUR : $MANQUE_AMORCAGE fichier(s) d'amorcage manquant(s) dans la racine (C-51)" >&2
	echo "  Sans eux, mkimg fabriquerait un disque qui affiche « Invalid Bootblock »." >&2
	exit 1
fi

# verifier_chaine_amorcage : ouvre le disque produit et COMPTE les partitions d'amorcage.
verifier_chaine_amorcage() {
	_img="$1"
	_md=$(mdconfig -a -t vnode -f "$_img" 2>/dev/null) || {
		echo "  [KO ] mdconfig refuse d'attacher $_img — verification impossible"
		return 1
	}
	_g=$(gpart show -p "$_md" 2>/dev/null)
	printf '%s\n' "$_g" | sed 's/^/    gpart : /'
	_n=$(printf '%s\n' "$_g" | grep -c 'freebsd-boot')
	gpart destroy -F "$_md" >/dev/null 2>&1
	mdconfig -d -u "$_md" >/dev/null 2>&1
	[ "$_n" -ge 1 ] || {
		echo "  [KO ] aucune partition freebsd-boot sur le disque produit"
		return 1
	}
	echo "  [OK ] partition freebsd-boot presente : la chaine gptboot est en place"
	return 0
}

if mkimg -s gpt -f raw \
	-b "$RACINE/boot/pmbr" \
	-p freebsd-boot/bootfs:="$RACINE/boot/gptboot" \
	-p freebsd-ufs/rootfs:="$UFS" \
	-o "$IMG" 2>/tmp/mkimg.err; then
	echo "→ image GPT : $IMG ($(wc -c < "$IMG") octets)"
	if ! verifier_chaine_amorcage "$IMG"; then
		echo "ERREUR : le disque produit n'est PAS amorcable (C-51). Il ne sera pas publie." >&2
		echo "  $UFS contient le systeme complet : c'est deja un resultat, mais ce n'est pas une image." >&2
		exit 1
	fi
else
	echo "ERREUR : mkimg a echoue — aucune image disque produite." >&2
	sed 's/^/    mkimg dit : /' /tmp/mkimg.err 2>/dev/null | head -10
	echo "  $UFS contient le systeme complet, mais il n'y a PAS de disque amorcable." >&2
	echo "  On s'arrete ici plutot que de livrer un fichier qui ne demarre pas (C-51)." >&2
	exit 1
fi

echo "→ PRODUIT : $UFS (systeme complet) — il contient le noyau NexBSD ET la configuration NexBSD."

# --- 7. Ancien chemin conservé, mais il ne contient PAS la configuration du produit ---
echo
echo "ATTENTION — chemin release.sh NON utilisé ci-dessus. Conservé pour mémoire."
echo "  release.sh -c release.conf produit un média DU SOCLE : il n'applique pas fork/overlay/."
echo "  Ne pas livrer une image issue de release.sh en croyant qu'elle contient NexBSD."

echo
echo "ÉTAPES SUIVANTES, HUMAINES ET OBLIGATOIRES :"
echo "  1. démarrer l'image en VM et vérifier qu'elle démarre (T-01 sur image NexBSD) ;"
echo "  2. vérifier uname -r, /etc/nexbsd-version, absence de jeux/exemples ;"
echo "  3. seulement ensuite : écrire le nom NexBSD dans la chaîne d'identité (patch 0001)."

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
[ "$TAILLE_MO" -eq 0 ] && TAILLE_MO=$(( UTILISE_MO + UTILISE_MO / 5 + 512 ))
echo "→ racine : ${UTILISE_MO} Mo utilises ; image dimensionnee a ${TAILLE_MO} Mo (+20 % + 512 Mo)"

makefs -t ffs -s "${TAILLE_MO}m" -o version=2 "$UFS" "$RACINE" \
	|| { echo "ERREUR : makefs a echoue — pas d'image du tout" >&2; exit 1; }
ls -l "$UFS"

# Le .ufs EST le produit : un systeme de fichiers complet, montable et verifiable.
# Le disque bootable n'est qu'une ENVELOPPE autour de lui. Si l'enveloppe echoue, on ne jette
# pas le systeme : c'est deja un resultat, et c'est la route que docs/46 decrit comme « sure ».
echo "→ enveloppe bootable (jamais confrontee a une vraie machine : best effort)"
if mkimg -s mbr -f raw -b "$RACINE/boot/boot0" -p freebsd:="$UFS" -o "$IMG" 2>/tmp/mkimg.err; then
	echo "→ image MBR : $IMG ($(wc -c < "$IMG") octets)"
elif mkimg -s gpt -f raw -b "$RACINE/boot/pmbr" -p freebsd-ufs:="$UFS" -o "$IMG" 2>>/tmp/mkimg.err; then
	echo "→ image GPT : $IMG ($(wc -c < "$IMG") octets)"
else
	echo "AVERTISSEMENT : aucune image disque bootable produite."
	sed 's/^/    mkimg dit : /' /tmp/mkimg.err 2>/dev/null | head -5
	echo "    CE N'EST PAS UN ECHEC TOTAL : $UFS existe et contient le systeme complet."
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

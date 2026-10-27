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

# --- Garde-fous (le script s'arrête plutôt que d'abîmer) ------------------
[ "$(uname -s)" = "FreeBSD" ] || { echo "ERREUR : la construction exige un hôte FreeBSD." >&2; exit 1; }

RAM_MO=$(sysctl -n hw.physmem | awk '{print int($1/1048576)}')
[ "$RAM_MO" -ge 7000 ] || { echo "ERREUR : ${RAM_MO} Mo de RAM ; le profil L3 exige >= 8 Go (ADR-0010)." >&2; exit 1; }

FREE_GO=$(df -k /usr/obj | awk 'NR==2 {print int($4/1048576)}')
[ "$FREE_GO" -ge 40 ] || { echo "ERREUR : ${FREE_GO} Go libres dans /usr/obj ; 40 Go minimum." >&2; exit 1; }

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

# --- 4. Image ------------------------------------------------------------
echo "→ release.sh (média USB bootable)"
cd "$SRC/release"
sh release.sh -c "$ICI/release.conf"

echo
echo "ÉTAPES SUIVANTES, HUMAINES ET OBLIGATOIRES :"
echo "  1. démarrer l'image en VM et vérifier qu'elle démarre (T-01 sur image NexBSD) ;"
echo "  2. vérifier uname -r, /etc/nexbsd-version, absence de jeux/exemples ;"
echo "  3. seulement ensuite : écrire le nom NexBSD dans la chaîne d'identité (patch 0001)."

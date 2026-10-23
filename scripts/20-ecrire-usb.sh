#!/usr/bin/env bash
# NexBSD — Écriture d'une image sur un support AMOVIBLE
#
# ⚠️  OPÉRATION DESTRUCTIVE : tout le contenu du périphérique cible est effacé.
#
# Usage : sudo bash scripts/20-ecrire-usb.sh <image> <périphérique>
# Exemple: sudo bash scripts/20-ecrire-usb.sh ~/nexbsd-images/FreeBSD-...-memstick.img /dev/sdb
#
# Garde-fous :
#   1. le périphérique doit être un disque bloc réel
#   2. refus si le périphérique porte le système de fichiers racine
#   3. refus si le périphérique n'est pas amovible/USB (sauf --force explicite)
#   4. refus si le périphérique est plus petit que l'image
#   5. confirmation par recopie EXACTE du nom du périphérique
set -uo pipefail

die() { echo "ERREUR : $*" >&2; exit 1; }
[ "$(id -u)" -eq 0 ] || die "ce script doit être lancé avec sudo"

FORCE=0
args=()
for a in "$@"; do
  case "$a" in
    --force) FORCE=1 ;;
    *) args+=("$a") ;;
  esac
done

[ "${#args[@]}" -eq 2 ] || die "usage : sudo $0 <image> <périphérique> [--force]"
img="${args[0]}"; dev="${args[1]}"

[ -f "$img" ] || die "image introuvable : $img"
[ -b "$dev" ] || die "$dev n'est pas un périphérique bloc"

# --- Garde-fou 2 : ne jamais écrire sur le disque qui porte le système ---
rootsrc="$(findmnt -no SOURCE / 2>/dev/null || true)"
if [ -n "$rootsrc" ]; then
  rootdisk="/dev/$(lsblk -no PKNAME "$(readlink -f "$rootsrc")" 2>/dev/null | head -1)"
  if [ "$(readlink -f "$dev")" = "$(readlink -f "$rootdisk")" ]; then
    die "$dev porte le système de fichiers racine ($rootsrc). Écriture refusée."
  fi
  echo "Disque système détecté : $rootdisk (protégé, non ciblé)"
fi

# --- Garde-fou 3 : support amovible ? ---
rm_flag="$(lsblk -dno RM "$dev" 2>/dev/null | tr -d ' ')"
tran="$(lsblk -dno TRAN "$dev" 2>/dev/null | tr -d ' ')"
if [ "$rm_flag" != "1" ] && [ "$tran" != "usb" ]; then
  if [ "$FORCE" -ne 1 ]; then
    die "$dev ne semble pas amovible (RM=$rm_flag, TRAN=${tran:-?}). Utiliser --force si c'est un disque externe volontaire."
  fi
  echo "ATTENTION : --force utilisé sur un périphérique non amovible."
fi

# --- Garde-fou 4 : capacité suffisante ---
img_bytes=$(stat -c %s "$img")
dev_bytes=$(blockdev --getsize64 "$dev")
if [ "$dev_bytes" -lt "$img_bytes" ]; then
  die "périphérique trop petit : $(numfmt --to=iec "$dev_bytes") < image $(numfmt --to=iec "$img_bytes")"
fi

echo "=============================================================="
echo " RÉCAPITULATIF — À LIRE AVANT DE CONFIRMER"
echo "=============================================================="
echo " image source : $img"
echo "                $(du -h "$img" | cut -f1)"
echo " cible        : $dev"
lsblk -o NAME,SIZE,TYPE,TRAN,MODEL,MOUNTPOINT "$dev"
echo "--------------------------------------------------------------"
echo " TOUT LE CONTENU DE $dev SERA DÉFINITIVEMENT EFFACÉ."
echo "=============================================================="

# démonter les partitions montées de ce périphérique
mapfile -t mounted < <(lsblk -lno NAME,MOUNTPOINT "$dev" | awk 'NF==2 && $2!="" {print "/dev/"$1}')
if [ "${#mounted[@]}" -gt 0 ]; then
  echo "Partitions montées à démonter : ${mounted[*]}"
  for m in "${mounted[@]}"; do umount "$m" || die "échec du démontage de $m"; done
  echo "Démontage effectué."
fi

# --- Garde-fou 5 : confirmation par recopie ---
echo
echo "Pour confirmer, tapez exactement : $dev"
read -r reponse
[ "$reponse" = "$dev" ] || die "confirmation incorrecte — aucune écriture effectuée."

echo "Écriture en cours..."
dd if="$img" of="$dev" bs=4M status=progress conv=fsync || die "échec de dd"
sync
echo
echo "Écriture terminée : $dev"
echo "Le support peut être retiré en sécurité."
echo
echo "Rappel : consigner l'opération dans reports/ (image, périphérique, date, empreinte vérifiée)."

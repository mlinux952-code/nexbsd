#!/usr/bin/env bash
# NexBSD — Vérification d'intégrité d'une image téléchargée (lecture seule)
#
# Usage : bash scripts/10-verifier-image.sh <image> <fichier-de-sommes>
# Exemple:
#   bash scripts/10-verifier-image.sh \
#        ~/nexbsd-images/FreeBSD-15.1-RELEASE-amd64-memstick.img \
#        ~/nexbsd-images/FreeBSD-15.1-RELEASE-amd64-CHECKSUM
#
# Gère les deux conventions de fichier de sommes :
#   FreeBSD  : SHA256 (nom_fichier) = <empreinte>
#   standard : <empreinte>  nom_fichier
set -uo pipefail

die() { echo "ERREUR : $*" >&2; exit 1; }

[ $# -eq 2 ] || die "usage : $0 <image> <fichier-de-sommes>"
img="$1"; sums="$2"
[ -f "$img" ]  || die "image introuvable : $img"
[ -f "$sums" ] || die "fichier de sommes introuvable : $sums"

base="$(basename "$img")"
echo "=============================================================="
echo " Vérification d'intégrité"
echo " image   : $base"
echo " taille  : $(du -h "$img" | cut -f1)"
echo " sommes  : $sums"
echo "=============================================================="

# Extrait l'empreinte attendue pour un algorithme donné (sha256 / sha512)
attendu() {
  local algo="$1" hexlen="$2"
  awk -v a="$algo" -v n="$base" -v L="$hexlen" '
    {
      low = tolower($0); ln = tolower(n); la = tolower(a);
      # format FreeBSD (insensible à la casse de l algorithme) : SHA256 (nom) = empreinte
      if (low ~ ("^" la "[ ]*\\(" ln "\\)[ ]*=")) { print tolower($NF); exit }
      # format standard : empreinte  nom
      if (tolower($NF) == ln && $1 ~ /^[0-9a-fA-F]+$/ && length($1) == L) { print tolower($1); exit }
    }' "$sums"
}

echec=0
verifie=0

for spec in "sha256 64" "sha512 128"; do
  set -- $spec
  algo="$1"; hexlen="$2"
  exp="$(attendu "$algo" "$hexlen")"
  if [ -z "$exp" ]; then
    echo "[$algo] aucune empreinte trouvée dans le fichier de sommes (ignoré)"
    continue
  fi
  echo -n "[$algo] calcul en cours... "
  got="$("${algo}sum" "$img" | awk '{print tolower($1)}')"
  if [ "$got" = "$exp" ]; then
    echo "OK"
    echo "        attendu : $exp"
    echo "        obtenu  : $got"
    verifie=$((verifie+1))
  else
    echo "ÉCHEC"
    echo "        attendu : $exp"
    echo "        obtenu  : $got"
    echec=1
  fi
done

echo "--------------------------------------------------------------"
if [ "$echec" -ne 0 ]; then
  die "au moins une empreinte ne correspond pas — image corrompue ou incomplète. NE PAS ÉCRIRE CETTE IMAGE. Retélécharger."
fi
if [ "$verifie" -eq 0 ]; then
  die "aucune empreinte exploitable trouvée : vérifier le contenu de $sums (cat $sums | head)"
fi

echo "RÉSULTAT : image intègre ($verifie empreinte(s) vérifiée(s))."
echo "Prochaine étape : scripts/20-ecrire-usb.sh"
exit 0

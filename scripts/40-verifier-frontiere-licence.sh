#!/usr/bin/env bash
# NexBSD — Contrôle de la frontière de licence (ADR-0012 / test T-13)
#
# Vérifie qu'aucun code sous licence copyleft (GPL/LGPL/AGPL) ne se trouve
# dans l'arbre de la BASE NexBSD. Le copyleft est autorisé dans la couche
# PLATEFORME (paquets séparés), pas dans la base.
#
# Usage :
#   bash scripts/40-verifier-frontiere-licence.sh <arborescence> [--allow <fichier>]
#
#   --allow <fichier>  liste de motifs (globs) explicitement exemptés,
#                      une ligne par motif, '#' pour les commentaires.
#                      Les motifs sont RELATIFS à l'arborescence scannée
#                      (ex. « third_party/* », pas « monarbre/third_party/* »).
#                      Chaque exemption doit être justifiée par écrit.
#
# Codes de retour : 0 = conforme · 1 = violations détectées · 2 = erreur d'usage
#
# Limites assumées : détection par signatures textuelles (SPDX, en-têtes connus).
# Ce script NE REMPLACE PAS une revue humaine : il attrape les oublis évidents.

set -uo pipefail

die() { echo "ERREUR : $*" >&2; exit 2; }

[ $# -ge 1 ] || die "usage : $0 <arborescence> [--allow <fichier>]"
ROOT="$1"; shift
ALLOW=""
while [ $# -gt 0 ]; do
  case "$1" in
    --allow) ALLOW="${2:-}"; shift 2 ;;
    *) die "option inconnue : $1" ;;
  esac
done
[ -d "$ROOT" ] || die "arborescence introuvable : $ROOT"
[ -z "$ALLOW" ] || [ -f "$ALLOW" ] || die "fichier d'exemptions introuvable : $ALLOW"

# --- motifs de copyleft recherchés ---
# SPDX : toute mention GPL/LGPL/AGPL (y compris variantes)
SPDX_RE='SPDX-License-Identifier:.*(GPL|AGPL)'
# en-têtes classiques des fichiers sources
HEADER_RE='(GNU (Lesser |Affero )?General Public License|under the terms of the GNU)'

is_allowed() {
  local f="$1" pat
  [ -n "$ALLOW" ] || return 1
  while IFS= read -r pat; do
    case "$pat" in ''|\#*) continue ;; esac
    # shellcheck disable=SC2053
    if [[ "$f" == $pat ]]; then return 0; fi
  done < "$ALLOW"
  return 1
}

echo "=============================================================="
echo " NexBSD — contrôle de la frontière de licence"
echo " arbre   : $ROOT"
echo " date    : $(date -Is)"
[ -n "$ALLOW" ] && echo " exemptions : $ALLOW"
echo "=============================================================="

violations=0
exempted=0
scanned=0

# Fichiers texte uniquement, en excluant les répertoires techniques.
while IFS= read -r -d '' f; do
  scanned=$((scanned+1))
  rel="${f#"$ROOT"/}"
  hits="$(grep -nE "$SPDX_RE|$HEADER_RE" "$f" 2>/dev/null | head -3)"
  [ -z "$hits" ] && continue
  if is_allowed "$rel"; then
    exempted=$((exempted+1))
    echo "[EXEMPTÉ] $rel"
    echo "$hits" | sed 's/^/            /'
  else
    violations=$((violations+1))
    echo "[VIOLATION] $rel"
    echo "$hits" | sed 's/^/            /'
  fi
done < <(find "$ROOT" \
          \( -name .git -o -name node_modules -o -name .venv -o -name __pycache__ \) -prune -o \
          -type f -print0 2>/dev/null)

echo "--------------------------------------------------------------"
echo "Fichiers analysés : $scanned"
echo "Exemptés          : $exempted"
echo "Violations        : $violations"

if [ "$violations" -gt 0 ]; then
  echo
  echo "RÉSULTAT : NON CONFORME à ADR-0012."
  echo "Action : déplacer ces fichiers vers la couche Plateforme, ou justifier"
  echo "         chaque exemption dans le fichier d'exemptions (avec un ADR)."
  exit 1
fi

echo "RÉSULTAT : conforme — aucun copyleft non exempté détecté dans l'arbre."
echo "Rappel : la couche Plateforme (Samba GPL-3, WebKitGTK) est contrôlée séparément."
exit 0

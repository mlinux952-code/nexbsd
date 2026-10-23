#!/bin/sh
# NexBSD — chaîne de construction garde-fou
# ---------------------------------------------------------------------------
# STATUT : NON EXÉCUTÉ. Ce script n'a jamais produit d'image.
# Il refuse de s'exécuter ailleurs que sur FreeBSD, ou sans ressources
# suffisantes : c'est volontaire (ADR-0010).
#
# Usage :
#   sh build-nexbsd.sh --check-licence
#   sh build-nexbsd.sh --world
#   sh build-nexbsd.sh --kernel
#   sh build-nexbsd.sh --release
# ---------------------------------------------------------------------------
set -eu

DELTA="$(cd "$(dirname "$0")" && pwd)"
SRC="$(cd "$DELTA/.." && pwd)"
LOGS="$DELTA/logs"
mkdir -p "$LOGS"

log() { echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] $*" | tee -a "$LOGS/build.log"; }
die() { log "ERREUR : $*"; exit 1; }

# --- garde-fou 1 : on ne construit que sous FreeBSD ---
os="$(uname -s)"
[ "$os" = "FreeBSD" ] || die "construction impossible sous $os : un buildworld FreeBSD doit s'exécuter sous FreeBSD (profil L3 requis)."

# --- garde-fou 2 : ressources ---
mem_go=$(( $(sysctl -n hw.physmem) / 1024 / 1024 / 1024 ))
[ "$mem_go" -ge 8 ] || die "RAM insuffisante : ${mem_go} Go détectés, 8 Go minimum pour construire la base."
free_go=$(df -g "$SRC" | awk 'NR==2 {print int($4)}')
[ "$free_go" -ge 40 ] || die "espace insuffisant : ${free_go} Go libres, 40 Go minimum."

# --- garde-fou 3 : arbre source présent ---
[ -f "$SRC/Makefile" ] || die "arbre source FreeBSD introuvable dans $SRC"
[ -f "$DELTA/src.conf" ] || die "src.conf absent"

log "environnement validé : $os, ${mem_go} Go de RAM, ${free_go} Go libres"

case "${1:-}" in
  --check-licence)
    log "contrôle de la frontière de licence (T-13)"
    sh "$DELTA/../../scripts/40-verifier-frontiere-licence.sh" "$SRC" \
        --allow "$DELTA/exceptions-licence.txt" | tee -a "$LOGS/licence.log"
    ;;

  --world)
    log "buildworld (SRCCONF=$DELTA/src.conf) — plusieurs heures attendues"
    ( cd "$SRC" && make -j"$(sysctl -n hw.ncpu)" buildworld SRCCONF="$DELTA/src.conf" ) 2>&1 | tee -a "$LOGS/buildworld.log"
    log "buildworld terminé"
    ;;

  --kernel)
    log "buildkernel (KERNCONF=NEXBSD_L1)"
    cp "$DELTA/NEXBSD_L1" "$SRC/sys/amd64/conf/NEXBSD_L1"
    ( cd "$SRC" && make -j"$(sysctl -n hw.ncpu)" buildkernel KERNCONF=NEXBSD_L1 SRCCONF="$DELTA/src.conf" ) 2>&1 | tee -a "$LOGS/buildkernel.log"
    log "buildkernel terminé"
    ;;

  --release)
    log "production de l'image (release.sh)"
    ( cd "$SRC" && sh release/release.sh -c "$DELTA/release.conf" ) 2>&1 | tee -a "$LOGS/release.log"
    log "image produite — consigner le chemin et l'empreinte dans reports/"
    ;;

  *)
    echo "usage : sh build-nexbsd.sh --check-licence | --world | --kernel | --release"
    exit 2
    ;;
esac

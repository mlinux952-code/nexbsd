#!/bin/sh
# 68-construire-noyau-nexbsd.sh — ETAGE 2, ETAPE 2 : construire le noyau NEXBSD_L1.
#
# C'est LA commande de l'etage 2 : apres elle, il existera un fichier noyau
# compile a partir de la configuration du projet. Sa duree est de 2 a 6 heures
# sur le poste du responsable (2 coeurs, 3,7 Go de RAM, VM a 2 Go).
#
# Usage :
#   sh 68-construire-noyau-nexbsd.sh            # = --lancer
#   sh 68-construire-noyau-nexbsd.sh --lancer   # verifie les garde-fous puis lance
#   sh 68-construire-noyau-nexbsd.sh --etat     # ou en est-on (sans bloquer)
#   sh 68-construire-noyau-nexbsd.sh --suivre   # suit le journal en direct (Ctrl+C pour sortir)
#   sh 68-construire-noyau-nexbsd.sh --verifier # le noyau est-il produit ?
#
# CHOIX TECHNIQUES EXPLIQUES :
#  * BRANCH_OVERRIDE=NEXBSD-L1 : levier PREVU PAR L'AMONT (sys/conf/newvers.sh 15.1).
#    Le noyau annoncera donc `15.1-NEXBSD-L1`. Aucune ligne de FreeBSD n'est modifiee.
#  * KERNCONF=NEXBSD_L1 : c'est notre configuration (5 lignes de delta, verifiee par 67).
#  * MAKEOBJDIRPREFIX=/build/obj : les objets vont sur le disque de construction,
#    jamais sur le disque systeme du banc valide.
#  * -j plafonne par la RAM : sur 2 Go, -j4 fait echanger la machine et peut la tuer.
#    On prefere 4 h a 45 minutes suivies d'une panne memoire.
#
# Reference : docs/28 ; ADR-0020 (derogation bornee) ; ADR-0010 (reste en vigueur
# pour buildworld et l'image : ce script ne construit PAS le monde).
# Version 1 (2026-10-25).

set -u

ok()   { echo "  [OK]    $*"; }
ko()   { echo "  [ECHEC] $*"; }
info() { echo "  ...     $*"; }
attn() { echo "  [ATTN]  $*"; }

BASE=/build
SRC=$BASE/src
OBJ=$BASE/obj
LOGS=$BASE/logs
KERNCONF=NEXBSD_L1
SURVERSION=NEXBSD-L1
MODE=${1:---lancer}

echo "########## ETAGE 2 / ETAPE 2 : construire le noyau $KERNCONF ##########"
echo "# date : $(date -u +%FT%TZ) ; hote : $(hostname) ; systeme : $(uname -sr)"

[ "$(id -u)" = "0" ] || { ko "ce script doit tourner en root"; exit 1; }

# ---------------------------------------------------------------- --etat / --suivre
if [ "$MODE" = "--suivre" ]; then
  J=$(ls -t "$LOGS"/buildkernel-*.log 2>/dev/null | head -1)
  [ -n "$J" ] || { ko "aucun journal dans $LOGS"; exit 1; }
  echo "  journal : $J  (Ctrl+C pour quitter l'affichage, la construction continue)"
  tail -f "$J"
  exit 0
fi

JOURNAL_EXISTANT=$(ls -t "$LOGS"/buildkernel-*.log 2>/dev/null | head -1)

if [ "$MODE" = "--etat" ]; then
  echo
  if [ -f "$LOGS/buildkernel.pid" ] && kill -0 "$(cat "$LOGS/buildkernel.pid")" 2>/dev/null; then
    ok "construction EN COURS (pid $(cat "$LOGS/buildkernel.pid"))"
    info "depuis : $(cat "$LOGS/buildkernel.debut" 2>/dev/null)"
  else
    attn "aucune construction en cours"
  fi
  if [ -n "$JOURNAL_EXISTANT" ]; then
    info "journal    : $JOURNAL_EXISTANT ($(wc -l < "$JOURNAL_EXISTANT" | tr -d ' ') lignes)"
    echo "  --- 12 dernieres lignes ---"
    tail -12 "$JOURNAL_EXISTANT" | sed 's/^/  | /'
    echo "  --- erreurs eventuelles ---"
    grep -iE "(^|[^a-z])(error|erreur|panic|No space|Cannot allocate|signal 11)" "$JOURNAL_EXISTANT" | tail -5 | sed 's/^/  | /' || info "aucune ligne d'erreur detectee"
  fi
  echo
  info "noyau produit ?"
  find "$OBJ" -name kernel -type f 2>/dev/null | sed 's/^/  ...     /' || true
  exit 0
fi

if [ "$MODE" = "--verifier" ]; then
  echo
  K=$(find "$OBJ" -path "*sys/$KERNCONF/kernel" -type f 2>/dev/null | head -1)
  if [ -n "$K" ]; then
    ok "noyau trouve : $K ($(du -h "$K" | awk '{print $1}'))"
    info "empreinte : $(sha256 -q "$K")"
    info "version annoncee par le fichier noyau :"
    strings "$K" | grep -m3 -E "15\.1-($SURVERSION|RELEASE)" | sed 's/^/  ...     /'
    echo
    echo "ETAT : NOYAU CONSTRUIT — l'installation se fait avec le script 69."
    exit 0
  fi
  ko "aucun noyau $KERNCONF dans $OBJ : la construction n'a pas abouti."
  echo "  -> voir : sh 68-construire-noyau-nexbsd.sh --etat"
  exit 1
fi

# ---------------------------------------------------------------- --lancer
echo
echo "########## BLOC A - garde-fous (mesures reelles) ##########"
[ -f "$SRC/Makefile" ] || { ko "$SRC/Makefile absent : lancer 67 d'abord"; exit 1; }
[ -f "$SRC/sys/amd64/conf/$KERNCONF" ] || { ko "configuration $KERNCONF absente : lancer 67 d'abord"; exit 1; }
ok "arbre source et configuration presents"

RAM_MO=$(sysctl -n hw.physmem | awk '{print int($1/1048576)}')
NCPU=$(sysctl -n hw.ncpu)
SWAP_MO=$( { swapinfo -k 2>/dev/null || pstat -s 2>/dev/null; } | awk 'NR>1 && $2 ~ /^[0-9]+$/ {t+=$2} END {print int(t/1024)}')
LIBRE_MO=$(df -k "$OBJ" | awk 'NR==2 {print int($4/1024)}')
info "RAM ${RAM_MO} Mo · echange ${SWAP_MO} Mo · ${NCPU} fils · ${LIBRE_MO} Mo libres dans $OBJ"

if [ "$RAM_MO" -lt 1800 ]; then ko "RAM < 1800 Mo : refus (ADR-0020)"; exit 1; fi
if [ "$LIBRE_MO" -lt 6000 ]; then ko "moins de 6000 Mo libres : refus"; exit 1; fi

J=2
if [ "$RAM_MO" -ge 6000 ]; then J=$NCPU; fi
if [ "$NCPU" -lt 2 ]; then J=1; fi
ok "parallelisme retenu : -j$J (plafonne par la RAM, pas par la bonne volonte)"

if [ -f "$LOGS/buildkernel.pid" ] && kill -0 "$(cat "$LOGS/buildkernel.pid")" 2>/dev/null; then
  ko "une construction tourne deja (pid $(cat "$LOGS/buildkernel.pid")) — voir --etat"
  exit 1
fi

echo
echo "########## BLOC B - ce qui va etre compile (et rien d'autre) ##########"
info "configuration : $SRC/sys/amd64/conf/$KERNCONF"
info "empreinte     : $(sha256 -q "$SRC/sys/amd64/conf/$KERNCONF")"
info "delta vs GENERIC : $(diff "$SRC/sys/amd64/conf/GENERIC" "$SRC/sys/amd64/conf/$KERNCONF" | grep -c '^[<>]') lignes"
info "ident         : $(grep -m1 '^ident' "$SRC/sys/amd64/conf/$KERNCONF")"
echo
info "RAPPEL HONNETE : ce noyau sera a ~99 % celui de FreeBSD 15.1."
info "Il prouve que le projet SAIT construire son noyau — pas qu'il l'a reinvente."
info "Le monde (buildworld) et l'image restent interdits sur ce poste (ADR-0010)."

echo
echo "########## BLOC C - lancement en arriere-plan, journalise ##########"
TS=$(date -u +%Y%m%dT%H%M%SZ)
JOURNAL="$LOGS/buildkernel-$TS.log"
echo "$(date -u +%FT%TZ)" > "$LOGS/buildkernel.debut"

# sh -c pour que le journal contienne la commande exacte : c'est une preuve.
CMD="cd $SRC && env MAKEOBJDIRPREFIX=$OBJ KERNCONF=$KERNCONF BRANCH_OVERRIDE=$SURVERSION make -j$J buildkernel"
info "commande exacte :"
echo "  | $CMD"
nohup sh -c "echo \"### commande : $CMD\" ; echo \"### debut : \$(date -u +%FT%TZ)\" ; $CMD ; echo \"### code de retour : \$?\" ; echo \"### fin : \$(date -u +%FT%TZ)\"" \
      > "$JOURNAL" 2>&1 &
PID=$!
echo "$PID" > "$LOGS/buildkernel.pid"
echo "$JOURNAL" > "$LOGS/buildkernel.journal"
ok "construction lancee (pid $PID)"
info "journal : $JOURNAL"
echo
echo "CE QU'IL FAUT FAIRE MAINTENANT :"
echo "  - laisser la VM allumee, ne rien compiler d'autre, ne pas lancer de copie massive ;"
echo "  - suivre     : sh 68-construire-noyau-nexbsd.sh --suivre"
echo "  - etat court : sh 68-construire-noyau-nexbsd.sh --etat"
echo "  - quand le journal affiche '### code de retour : 0' :"
echo "                 sh 68-construire-noyau-nexbsd.sh --verifier"
echo
echo "ETAT : CONSTRUCTION LANCEE (2 a 6 h). Rien ne se conclut avant la fin."

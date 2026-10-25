#!/bin/sh
# 67-preparer-construction-noyau.sh — ETAGE 2, ETAPE 1 : rendre le banc capable de
# construire le noyau NexBSD.
#
# CE QUE FAIT CE SCRIPT (dans la VM, en root, idempotent) :
#   A. verifie les ressources REELLES et refuse si elles sont insuffisantes ;
#   B. prepare le disque de construction (30 Go, ajoute par l'hyperviseur) :
#      GPT + partition UFS etiquetee `build`, montee sur /build, inscrite dans fstab ;
#   C. ajoute 2 Go d'echange sur ce disque (la RAM du poste est de 3,7 Go : c'est la marge) ;
#   D. telecharge les sources de FreeBSD 15.1-RELEASE (src.txz, 253 Mo) et VERIFIE
#      l'empreinte SHA256 epinglee (provenance unique, aucune improvisation) ;
#   E. extrait l'arbre dans /build/src et fait pointer /usr/src dessus ;
#   F. REGENERE la configuration NexBSD_L1 a partir du GENERIC de CET arbre, puis
#      VERIFIE que son empreinte est identique a celle du depot NexusBSD
#      -> la configuration compilee est prouvablement celle de build/fork/.
#
# CE QUE CE SCRIPT NE FAIT PAS : il ne compile rien (voir 68), il n'installe rien (voir 69).
#
# Reference : docs/28-campagne-construction-noyau.md ; ADR-0020 ; ADR-0010.
# Version 1 (2026-10-25).

set -u

ok()   { echo "  [OK]    $*"; }
ko()   { echo "  [ECHEC] $*"; }
info() { echo "  ...     $*"; }
attn() { echo "  [ATTN]  $*"; }

# ---- Valeurs epinglees (docs/28 §4) --------------------------------------
URL_SRC="https://download.freebsd.org/releases/amd64/amd64/15.1-RELEASE/src.txz"
SHA_SRC="cf5762da53fd52e1eaf0f9ceee9bf58cbe314c821031d0d9ffa76823185a89e1"
TAILLE_SRC=253039000
SHA_GENERIC_REF="02491b53b793cc5e1a3d622675d1aaf32d5da1973832cb13ff6d85d541d84878"
SHA_CONF_REF="14c86800fa6ae198d0625fdca885966fe9bd90c9f28853ae67991ab2129eb301"

DISQUE=${1:-}
BASE=/build

echo "########## ETAGE 2 / ETAPE 1 : preparer la construction du noyau NexBSD ##########"
echo "# date : $(date -u +%FT%TZ) ; hote : $(hostname) ; systeme : $(uname -sr)"
echo "# disque de construction demande : ${DISQUE:-<detection automatique>}"

[ "$(id -u)" = "0" ] || { ko "ce script doit tourner en root"; exit 1; }
[ "$(uname -s)" = "FreeBSD" ] || { ko "hote non FreeBSD : buildkernel est impossible"; exit 1; }

echo
echo "########## BLOC A - ressources reelles (mesurees, pas supposees) ##########"
RAM_MO=$(sysctl -n hw.physmem | awk '{print int($1/1048576)}')
NCPU=$(sysctl -n hw.ncpu)
info "RAM totale      : ${RAM_MO} Mo"
info "processeurs     : ${NCPU} fils (le poste a 2 coeurs physiques)"
info "echange actuel  : $(swapinfo -h | awk 'NR==2 {print $2" utilises / "$3" libres"}')"

if [ "$RAM_MO" -lt 1800 ]; then
  ko "RAM ${RAM_MO} Mo < 1800 Mo : refus (garde-fou ADR-0020)."
  ko "Relever la RAM de la VM dans l'hyperviseur (2048 Mo), puis relancer."
  exit 1
fi
ok "RAM suffisante pour un noyau (>= 1800 Mo) — derogation ADR-0020"
if [ "$RAM_MO" -lt 4000 ]; then
  attn "RAM < 4000 Mo : le monde complet (buildworld) reste INTERDIT sur ce poste (ADR-0010)."
fi

echo
echo "########## BLOC B - disque de construction ##########"
if [ -z "$DISQUE" ]; then
  RACINE=$(df -k / | awk 'NR==2 {print $1}' | sed -E 's|^/dev/([a-z]+[0-9]+).*|\1|')
  info "disque systeme : $RACINE (il ne sera PAS touche)"
  for D in $(geom disk list | sed -n 's/^Geom name: //p'); do
    if [ "$D" != "$RACINE" ]; then DISQUE=$D; break; fi
  done
  [ -n "$DISQUE" ] || {
    ko "aucun disque de construction trouve."
    ko "Ajouter un disque de 30 Go a la VM (etape 2 de docs/28), puis relancer ce script."
    exit 1
  }
  info "disque retenu  : $DISQUE (detecte)"
fi

[ -c "/dev/$DISQUE" ] || { ko "/dev/$DISQUE n'existe pas"; exit 1; }
TAILLE_GO=$(diskinfo -v "$DISQUE" 2>/dev/null | awk '/mediasize in sectors/ {print int($1*512/1073741824)}')
info "taille de $DISQUE : ${TAILLE_GO:-?} Go"
if [ -n "${TAILLE_GO:-}" ] && [ "$TAILLE_GO" -lt 14 ]; then
  ko "disque trop petit (${TAILLE_GO} Go < 14 Go) : un noyau demande ~6 Go."
  exit 1
fi

if gpart show "/dev/$DISQUE" >/dev/null 2>&1; then
  ok "table de partitions deja presente sur $DISQUE"
else
  gpart create -s GPT "/dev/$DISQUE" || { ko "gpart create a echoue"; exit 1; }
  ok "table GPT creee sur $DISQUE"
fi

if [ -c /dev/gpt/build ]; then
  ok "partition gpt/build deja presente"
else
  gpart add -t freebsd-ufs -l build "/dev/$DISQUE" || { ko "gpart add a echoue"; exit 1; }
  ok "partition UFS etiquetee 'build' ajoutee"
fi

if [ "$(fstyp /dev/gpt/build 2>/dev/null)" = "ufs" ]; then
  ok "systeme de fichiers UFS deja present sur /dev/gpt/build"
else
  newfs -U -L build /dev/gpt/build >/dev/null 2>&1 || { ko "newfs a echoue"; exit 1; }
  ok "systeme de fichiers UFS cree (avec soft-updates)"
fi

mkdir -p "$BASE"
if mount -p | awk '{print $1}' | grep -qx "/dev/gpt/build"; then
  ok "$BASE deja monte"
else
  mount /dev/gpt/build "$BASE" || { ko "montage de $BASE impossible"; exit 1; }
  ok "$BASE monte depuis /dev/gpt/build"
fi

if grep -q "^/dev/gpt/build[[:space:]]*$BASE" /etc/fstab 2>/dev/null; then
  ok "entree fstab deja presente"
else
  echo "/dev/gpt/build	/build	ufs	rw	2	2" >> /etc/fstab
  ok "entree fstab ajoutee (le montage survit au redemarrage)"
fi

LIBRE_MO=$(df -k "$BASE" | awk 'NR==2 {print int($4/1024)}')
info "espace libre sur $BASE : ${LIBRE_MO} Mo"
if [ "$LIBRE_MO" -lt 12000 ]; then
  ko "espace libre insuffisant (< 12000 Mo) : sources 1,5 Go + objets 4-8 Go."
  exit 1
fi
ok "espace suffisant pour un noyau (>= 12000 Mo)"

echo
echo "########## BLOC C - echange sur le disque de construction ##########"
mkdir -p "$BASE/logs" "$BASE/txz" "$BASE/obj"
if [ -f "$BASE/logs/md_swap" ] && swapinfo | grep -q "^/dev/$(cat "$BASE/logs/md_swap")"; then
  ok "echange deja actif sur /dev/$(cat "$BASE/logs/md_swap")"
else
  if [ ! -f "$BASE/swap0" ]; then
    truncate -s 2G "$BASE/swap0" || { ko "creation de swap0 impossible"; exit 1; }
    chmod 600 "$BASE/swap0"
  fi
  MD=$(mdconfig -a -t vnode -f "$BASE/swap0" 2>/dev/null)
  if [ -n "$MD" ] && swapon "/dev/$MD" 2>/dev/null; then
    echo "$MD" > "$BASE/logs/md_swap"
    ok "2 Go d'echange actifs sur /dev/$MD (a recreer apres redemarrage : relancer ce script)"
  else
    attn "echange non active : la construction reste possible mais plus risquee"
  fi
fi
info "echange total : $(swapinfo -h | awk 'NR>1 {t+=$2} END {print t" Mo"}')"

echo
echo "########## BLOC D - sources FreeBSD 15.1-RELEASE, empreinte verifiee ##########"
cd "$BASE/txz" || exit 1
if [ -f src.txz ] && [ "$(sha256 -q src.txz)" = "$SHA_SRC" ]; then
  ok "src.txz deja present et conforme a l'empreinte"
else
  info "telechargement de src.txz (253 Mo) depuis download.freebsd.org ..."
  rm -f src.txz
  if ! fetch -q -o src.txz "$URL_SRC"; then
    ko "telechargement impossible. Verifier la sortie reseau de la VM (NAT)."
    exit 1
  fi
  T=$(stat -f %z src.txz)
  info "taille telechargee : $T octets (attendu $TAILLE_SRC)"
  [ "$T" = "$TAILLE_SRC" ] || { ko "taille differente : fichier incomplet ou different"; exit 1; }
  H=$(sha256 -q src.txz)
  if [ "$H" != "$SHA_SRC" ]; then
    ko "EMPREINTE DIFFERENTE : $H"
    ko "attendu : $SHA_SRC"
    ko "on ne compile JAMAIS une archive non verifiee. Arret."
    exit 1
  fi
  ok "empreinte SHA256 conforme : $H"
fi

echo
echo "########## BLOC E - extraction de l'arbre source ##########"
if [ -f "$BASE/src/Makefile" ] && [ -d "$BASE/src/sys/amd64/conf" ]; then
  ok "arbre source deja extrait dans $BASE/src"
else
  mkdir -p "$BASE/src"
  info "extraction (quelques minutes) ..."
  if ! tar -xf src.txz -C "$BASE/src" --strip-components 2; then
    ko "extraction impossible"; exit 1
  fi
  ok "arbre extrait"
fi
[ -f "$BASE/src/Makefile" ] || { ko "$BASE/src/Makefile absent : arbre invalide"; exit 1; }
[ -d "$BASE/src/sys/amd64/conf" ] || { ko "sys/amd64/conf absent : arbre invalide"; exit 1; }
info "Makefile : premiere ligne = $(head -1 "$BASE/src/Makefile")"
info "REVISION : $(cat "$BASE/src/sys/conf/newvers.sh" | grep -m1 '^REVISION=' || true)"

# /usr/src -> arbre de construction (necessaire a make buildkernel/installkernel)
if [ -L /usr/src ]; then
  ok "/usr/src est deja un lien vers $(readlink /usr/src)"
elif [ -d /usr/src ] && [ -n "$(ls -A /usr/src 2>/dev/null)" ]; then
  ko "/usr/src existe et n'est pas vide : on ne le detruit pas. Deplacer son contenu puis relancer."
  exit 1
else
  rmdir /usr/src 2>/dev/null
  ln -s "$BASE/src" /usr/src
  ok "/usr/src -> $BASE/src"
fi
if [ ! -e /usr/obj ]; then ln -s "$BASE/obj" /usr/obj; ok "/usr/obj -> $BASE/obj"; else ok "/usr/obj existe deja"; fi

echo
echo "########## BLOC F - configuration NEXBSD_L1 : regeneree puis verifiee ##########"
GENERIC="$BASE/src/sys/amd64/conf/GENERIC"
[ -f "$GENERIC" ] || { ko "GENERIC absent de l'arbre"; exit 1; }
H_GEN=$(sha256 -q "$GENERIC")
info "GENERIC de l'arbre : $H_GEN"
if [ "$H_GEN" = "$SHA_GENERIC_REF" ]; then
  ok "GENERIC identique a la reference du depot (reference/GENERIC-15.1)"
else
  attn "GENERIC different de la reference du depot ($SHA_GENERIC_REF)"
  attn "on derive du GENERIC REELLEMENT present : c'est le seul honnete."
fi

CONF="$BASE/src/sys/amd64/conf/NEXBSD_L1"
awk '
  /^ident[ \t]+GENERIC[ \t]*$/ { print "ident\t\tNEXBSD_L1"; next }
  /^device[ \t]+(fdc|cbb|cardbus|hyperv)([ \t]|$)/ { sub(/^device/, "# [NEXBSD-L1] retiré : device"); print; next }
  { print }
' "$GENERIC" > "$CONF" || { ko "generation de NEXBSD_L1 impossible"; exit 1; }

H_CONF=$(sha256 -q "$CONF")
info "NEXBSD_L1 genere    : $H_CONF"
if [ "$H_CONF" = "$SHA_CONF_REF" ]; then
  ok "IDENTIQUE au fichier du depot (build/fork/sys/amd64/conf/NEXBSD_L1)"
  info "=> la configuration qui sera compilee est prouvablement celle du depot."
else
  attn "empreinte differente de celle du depot ($SHA_CONF_REF)."
  attn "Ce n'est pas forcement une faute (GENERIC local different), mais c'est a CONSTATER :"
  diff -u /dev/null "$CONF" | grep -c "^+" | sed 's/^/  ...     lignes dans la config generee : /'
  grep -nE "^(ident|# \[NEXBSD-L1\])" "$CONF" | sed 's/^/  ...     /'
fi
grep -q "^ident[[:space:]]*NEXBSD_L1" "$CONF" && ok "ident = NEXBSD_L1" || { ko "ident mal modifie"; exit 1; }

echo
echo "########## RESUME ##########"
info "arbre source   : $BASE/src ($(du -sh "$BASE/src" | awk '{print $1}'))"
info "objets         : $BASE/obj"
info "configuration  : $CONF"
info "journal        : $BASE/logs"
info "RAM / disque   : ${RAM_MO} Mo / ${LIBRE_MO} Mo libres"
echo
echo "ETAT : PRET A CONSTRUIRE"
echo "Commande suivante : sh 68-construire-noyau-nexbsd.sh --lancer"

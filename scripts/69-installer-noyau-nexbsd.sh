#!/bin/sh
# 69-installer-noyau-nexbsd.sh — ETAGE 2, ETAPE 3 : installer le noyau construit
# comme noyau de demarrage du banc, SANS perdre le noyau d'origine.
#
# PRINCIPE DE SURETE (le banc valide doit survivre) :
#   1. le noyau FreeBSD actuel /boot/kernel est RENOMME en /boot/kernel.GENERIC-sauvegarde
#      (renommage, pas copie : aucune place disque consommee, retour arriere instantane) ;
#   2. installkernel ecrit /boot/kernel.NEXBSD_L1 (notre noyau) ;
#   3. loader.conf est modifie pour demarrer NEXBSD_L1, avec un delai de 5 s ;
#   4. le script N'EXECUTE PAS le redemarrage : c'est l'operateur qui decide, en connaissance
#      de cause, apres avoir lu ce que le script a verifie.
#
# RETOUR ARRIERE (si le noyau ne demarre pas) — dans le menu du chargeur :
#   set kernel="kernel.GENERIC-sauvegarde"
#   boot
# puis, de retour dans le systeme : supprimer la ligne kernel= de /boot/loader.conf.
#
# Usage : sh 69-installer-noyau-nexbsd.sh
# Reference : docs/28 §7 ; ADR-0020.
# Version 1 (2026-10-25).

set -u

ok()   { echo "  [OK]    $*"; }
ko()   { echo "  [ECHEC] $*"; }
info() { echo "  ...     $*"; }
attn() { echo "  [ATTN]  $*"; }

BASE=/build
SRC=$BASE/src
OBJ=$BASE/obj
KERNCONF=NEXBSD_L1
SURVERSION=NEXBSD-L1
SAUVE=kernel.GENERIC-sauvegarde

echo "########## ETAGE 2 / ETAPE 3 : installer le noyau $KERNCONF ##########"
echo "# date : $(date -u +%FT%TZ) ; hote : $(hostname) ; systeme actuel : $(uname -sr)"
echo "# noyau en service : $(uname -i) / repertoire : /boot/$(sysctl -n kern.bootfile | sed 's|^/boot/||; s|/.*||')"

[ "$(id -u)" = "0" ] || { ko "ce script doit tourner en root"; exit 1; }

echo
echo "########## BLOC A - le noyau construit existe-t-il vraiment ? ##########"
K=$(find "$OBJ" -path "*sys/$KERNCONF/kernel" -type f 2>/dev/null | head -1)
if [ -z "$K" ]; then
  ko "aucun noyau $KERNCONF dans $OBJ."
  echo "  -> la construction n'a pas abouti : voir  sh 68-construire-noyau-nexbsd.sh --etat"
  exit 1
fi
ok "noyau trouve : $K ($(du -h "$K" | awk '{print $1}'))"
info "empreinte SHA256 : $(sha256 -q "$K")"
VERS=$(strings "$K" | grep -m1 -E "^FreeBSD 15\.1(-| )" || true)
[ -n "$VERS" ] && info "version inscrite dans le binaire : $VERS" || attn "chaine de version non trouvee dans le binaire (peu grave, verifiable au demarrage)"

echo
echo "########## BLOC B - place disque et sauvegarde du noyau d'origine ##########"
# MESURE REELLE DU BANC (2026-10-25) : la racine ne dispose que de ~1,1 Go.
# installkernel ecrit le noyau ET ses modules, et ce DEUX FOIS (/boot/kernel.NEXBSD_L1
# et /boot/kernel). Avec les symboles de debogage (makeoptions DEBUG=-g du GENERIC),
# cela depasserait 1,3 Go et echouerait APRES plusieurs heures de compilation.
# On installe donc SANS les symboles (MK_KERNEL_SYMBOLS=no) : ~350-400 Mo au total.
# Le noyau conserve dans /build/obj garde, lui, tous ses symboles pour le debogage.
LIBRE_MO=$(df -k /boot | awk 'NR==2 {print int($4/1024)}')
info "libre sur /boot : ${LIBRE_MO} Mo (mesure du banc : la racine est petite)"
if [ "$LIBRE_MO" -lt 700 ]; then
  ko "moins de 700 Mo libres sur /boot : l'installation du noyau + modules echouerait."
  ko "Liberer de l'espace, ou agrandir la racine (qemu-img resize + gpart resize + growfs)."
  exit 1
fi
ok "place suffisante pour installer noyau + modules SANS symboles de debogage"

if [ -d "/boot/$SAUVE" ]; then
  ok "sauvegarde /boot/$SAUVE deja presente (elle n'est pas ecrasee)"
else
  if [ -d /boot/kernel ]; then
    mv /boot/kernel "/boot/$SAUVE" || { ko "renommage de /boot/kernel impossible"; exit 1; }
    ok "/boot/kernel renomme en /boot/$SAUVE (retour arriere possible)"
  else
    attn "/boot/kernel absent : rien a sauvegarder (situation inhabituelle, a signaler)"
  fi
fi

echo
echo "########## BLOC C - compilation-installation du noyau ##########"
info "commande : env MAKEOBJDIRPREFIX=$OBJ KERNCONF=$KERNCONF make MK_KERNEL_SYMBOLS=no installkernel"
cd "$SRC" || exit 1
if env MAKEOBJDIRPREFIX="$OBJ" KERNCONF="$KERNCONF" make -j2 MK_KERNEL_SYMBOLS=no installkernel; then
  ok "installkernel termine sans erreur"
else
  ko "installkernel a echoue. Le noyau d'origine est toujours dans /boot/$SAUVE :"
  echo "     pour redemarrer dessus : set kernel=\"$SAUVE\" dans le menu du chargeur."
  exit 1
fi

[ -d "/boot/$KERNCONF" ] && ok "/boot/$KERNCONF present" || { ko "/boot/$KERNCONF absent apres installation"; exit 1; }
if [ -f "/boot/$KERNCONF/kernel" ]; then
  info "empreinte installee : $(sha256 -q "/boot/$KERNCONF/kernel")"
  [ "$(sha256 -q "/boot/$KERNCONF/kernel")" = "$(sha256 -q "$K")" ] && ok "le noyau installe est bien celui qui a ete construit" || attn "empreintes differentes : a examiner avant de redemarrer"
fi

echo
echo "########## BLOC D - demarrage sur le noyau NexBSD ##########"
LC=/boot/loader.conf
cp -p "$LC" "$LC.avant-noyau-nexbsd" 2>/dev/null || true
if grep -q '^kernel="kernel.NEXBSD_L1"' "$LC" 2>/dev/null; then
  ok "loader.conf designe deja kernel.NEXBSD_L1"
else
  {
    echo ""
    echo "# --- NexBSD : etage 2 (ajoute par scripts/69, $(date -u +%F)) ---"
    echo 'kernel="kernel.NEXBSD_L1"'
    echo 'autoboot_delay="5"'
  } >> "$LC"
  ok "loader.conf : demarrage sur kernel.NEXBSD_L1, delai 5 s"
fi
info "extrait de $LC :"
grep -nE "kernel|autoboot" "$LC" | sed 's/^/  ...     /'

echo
echo "########## RESUME ##########"
info "noyau en service actuellement : $(uname -i) ($(uname -r))"
info "noyau au prochain demarrage   : $KERNCONF (version annoncee : 15.1-$SURVERSION)"
info "sauvegarde du noyau d'origine : /boot/$SAUVE"
info "retour arriere, menu du chargeur : set kernel=\"$SAUVE\"  puis  boot"
echo
echo "ETAT : NOYAU INSTALLE — REDEMARRAGE NON EFFECTUE (decision a l'operateur)."
echo
echo "Commande suivante : reboot"
echo "Puis, apres le redemarrage, les verifications de T-17 :"
echo "  uname -a ; uname -i ; uname -r ; sysctl -n kern.ident ; sysctl -n kern.osrelease"
echo "  sh 64-banc-T04G-persistance.sh     (le banc doit rejouer 11/11 sur NOTRE noyau)"

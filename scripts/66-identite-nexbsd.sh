#!/bin/sh
# 66-identite-nexbsd.sh — ETAGE 1 de l'identite : le banc s'appelle NexBSD.
#
# ATTENTION A LA JUSTESSE (voir docs/26-identite-et-nommage.md) :
#   Ce script change l'IDENTITE VISIBLE du banc (nom d'hote, message d'accueil,
#   invite). Il ne transforme PAS le socle : `uname -r` continuera d'annoncer
#   FreeBSD 15.1-RELEASE, car la chaine de version NexBSD exige un arbre source
#   et une construction (profil L3, indisponible : P-03). On ne pretend donc
#   jamais, apres ce script, que « NexBSD existe » — on dit qu'il a un nom.
#
# A executer DANS la VM, en root. Idempotent. Reversible.
# Version 1 (2026-10-25).

ok()   { echo "  [OK]    $*"; }
ko()   { echo "  [ECHEC] $*"; }
info() { echo "  ...     $*"; }

NOM="nexbsd"
MOTD=/etc/motd
RC=/etc/rc.conf

echo "########## Etage 1 de l'identite : nommer le banc ##########"
echo "# date : $(date -u +%FT%TZ) ; hote actuel : $(hostname)"

echo
echo "########## BLOC A - etat avant ##########"
info "hostname      : $(hostname)"
info "uname -n      : $(uname -n)"
info "uname -sr     : $(uname -sr)      <- restera FreeBSD : c'est le SOCLE, pas le produit"

echo
echo "########## BLOC B - nom d'hote ##########"
cp "$RC" /tmp/rc.conf.avant-identite
sysrc hostname="$NOM" >/dev/null 2>&1
hostname "$NOM" >/dev/null 2>&1
if [ "$(hostname)" = "$NOM" ] && [ "$(sysrc -n hostname 2>/dev/null)" = "$NOM" ]; then
    ok "nom d'hote = $NOM (immediat et arme au demarrage)"
    ok "invite : root@$NOM:~ #"
else
    ko "nom d'hote non applique ; restauration"
    cp /tmp/rc.conf.avant-identite "$RC"
    exit 1
fi

echo
echo "########## BLOC C - message d'accueil ##########"
[ -f "$MOTD" ] && cp "$MOTD" /tmp/motd.avant-identite
cat > "$MOTD" <<EOF_MOTD

  ==============================================================
     NEXBSD  —  systeme experimental        (banc d'essai)
  ==============================================================

  Ce banc teste les briques du produit NexBSD.
  Socle actuel : FreeBSD $(freebsd-version 2>/dev/null)  — image d'origine, non modifiee.
  Le nom affiche est celui du PRODUIT ; le socle reste FreeBSD.

  Briques validees sur ce banc :
    - annuaire d'identites (OpenLDAP)                 T-04
    - authentification SMB via l'annuaire             T-04-E
    - droits decides par les groupes de l'annuaire    T-04-F
    - retour autonome apres redemarrage               T-04-G

  Documentation : depot du projet, docs/ETAT.md
  ==============================================================

EOF_MOTD
if grep -q NEXBSD "$MOTD"; then ok "message d'accueil NexBSD ecrit dans $MOTD"; else
    ko "message d'accueil non ecrit"; fi

echo
echo "########## BLOC D - le renommage n'a rien casse ##########"
if pgrep -q slapd; then ok "slapd tourne toujours"; else ko "slapd arrete"; fi
if pgrep -q nslcd; then ok "nslcd tourne toujours"; else ko "nslcd arrete"; fi
i=0
while [ "$i" -lt 30 ]; do
    sockstat -4l 2>/dev/null | grep -q ':445 ' && break
    i=$((i+1)); sleep 1
done
if sockstat -4l 2>/dev/null | grep -q ':445 '; then ok "smbd ecoute toujours sur :445"; else
    ko "smbd n'ecoute plus : le renommage a casse le service"; fi
if getent passwd 10000 >/dev/null 2>&1 && [ -n "$(getent passwd 10000 2>/dev/null)" ]; then
    ok "les identites de l'annuaire sont toujours resolues : $(getent passwd 10000)"
else
    ko "resolution des identites perdue"; fi

echo
echo "########## VERDICT ##########"
if [ "$(hostname)" = "$NOM" ] && grep -q NEXBSD "$MOTD" 2>/dev/null; then
    echo "IDENTITE : ETAGE 1 APPLIQUE - ce banc s'appelle desormais $NOM."
    echo
    echo "  Rappel de justesse : uname -sr dit encore « $(uname -sr) »."
    echo "  Le socle est FreeBSD ; le nom est celui du produit. L'etage 2"
    echo "  (chaine de version NexBSD) exige la construction du fork (profil L3)."
else
    echo "IDENTITE : ECHEC - voir les lignes [ECHEC] ci-dessus."
fi
echo
echo "Pour voir le resultat : se deconnecter (exit) puis se reconnecter,"
echo "ou simplement lire : hostname ; head -20 $MOTD"

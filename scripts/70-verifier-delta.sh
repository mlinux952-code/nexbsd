#!/bin/sh
# 70-verifier-delta.sh — GARDE-FOU : le delta du fork est-il toujours la ?
#
# POURQUOI CE SCRIPT EXISTE (incident C-16 puis C-18, 2026-10-25) :
#   Deux fois dans la meme journee, le delta du fork (17 fichiers a l epoque) a ete SUPPRIME
#   par un commit qui parlait d'autre chose. La premiere fois par accident humain,
#   la seconde parce que l'environnement de preparation efface tout repertoire
#   nomme « build ». A chaque fois, la documentation continuait d'affirmer que le
#   delta existait : c'est exactement la faute que ce projet interdit.
#
#   Ce script transforme une affirmation (« le delta existe ») en VERIFICATION.
#   Il doit etre lance AVANT chaque commit et AVANT chaque instantane.
#
# Usage : sh scripts/70-verifier-delta.sh
# Code retour : 0 si le delta est complet, 1 sinon.
# Version 1 (2026-10-25).

set -u

ok()   { echo "  [OK]    $*"; }
ko()   { echo "  [ECHEC] $*"; }
info() { echo "  ...     $*"; }

# Les fichiers du delta et leurs empreintes de reference (relevees le 2026-10-25).
# 2026-10-27 : 17 -> 20 fichiers. Le delta s enrichit des reglages PROUVES au banc (T-05/T-05a/T-21) :
#   overlay/etc/pf.conf, overlay/etc/ssh/sshd_config.nexbsd, overlay/etc/pam.d/su.
EXPECTED=20
SHA_CONF="14c86800fa6ae198d0625fdca885966fe9bd90c9f28853ae67991ab2129eb301"
SHA_GENERIC="02491b53b793cc5e1a3d622675d1aaf32d5da1973832cb13ff6d85d541d84878"

echo "########## Garde-fou : le delta du fork est-il intact ? ##########"
echo "# date : $(date -u +%FT%TZ)"

DEPOT=$(cd "$(dirname "$0")/.." && pwd)
cd "$DEPOT" || { ko "depot introuvable"; exit 1; }

echo
echo "########## BLOC A - presence sur le disque ##########"
if [ ! -d fork ]; then
  ko "le repertoire fork/ est ABSENT."
  ko "Pour le restaurer : git checkout 3d4eceb -- build/ ; git mv build/fork fork"
  exit 1
fi
ok "repertoire fork/ present"

# Un repertoire nomme « build » ne doit JAMAIS reapparaitre : c'est lui qui disparait.
if [ -d build ]; then
  ko "un repertoire nomme build/ existe a nouveau : il sera efface par l'environnement."
  ko "Deplacer son contenu vers fork/ et supprimer build/."
  exit 1
fi
ok "aucun repertoire nomme build/ (nom interdit dans ce depot)"

echo
echo "########## BLOC B - suivi par Git (pas seulement present sur le disque) ##########"
SUIVIS=$(git ls-files fork | wc -l | tr -d ' ')
info "fichiers suivis dans fork/ : $SUIVIS (attendu : $EXPECTED)"
if [ "$SUIVIS" -ne "$EXPECTED" ]; then
  ko "le nombre de fichiers suivis est FAUX."
  ko "Suppression accidentelle probable — verifier : git status --short ; git log --diff-filter=D -- fork"
  exit 1
fi
ok "$EXPECTED fichiers suivis par Git"

echo
echo "########## BLOC C - les fichiers critiques existent ##########"
MANQUANTS=0
for f in sys/amd64/conf/NEXBSD_L1 sys/amd64/conf/NEXBSD_L1.rapport src.conf release.conf \
         overlay/etc/motd overlay/etc/nexbsd-version overlay/etc/rc.conf.defaults \
         overlay/etc/pf.conf overlay/etc/ssh/sshd_config.nexbsd overlay/etc/pam.d/su \
         patches/0001-identite-version.patch tools/generer-kernel-conf.sh \
         reference/GENERIC-15.1 reference/newvers.sh-15.1 exceptions-licence.txt; do
  if git ls-files --error-unmatch "fork/$f" >/dev/null 2>&1; then
    info "present et suivi : fork/$f"
  else
    ko "MANQUANT ou non suivi : fork/$f"
    MANQUANTS=$((MANQUANTS + 1))
  fi
done
[ "$MANQUANTS" -eq 0 ] || { ko "$MANQUANTS fichier(s) critique(s) manquant(s)"; exit 1; }
ok "tous les fichiers critiques sont la"

echo
echo "########## BLOC D - empreintes : le contenu est-il le bon ? ##########"
H_CONF=$(sha256 -q fork/sys/amd64/conf/NEXBSD_L1 2>/dev/null || sha256sum fork/sys/amd64/conf/NEXBSD_L1 | cut -d' ' -f1)
H_GEN=$(sha256 -q fork/reference/GENERIC-15.1 2>/dev/null || sha256sum fork/reference/GENERIC-15.1 | cut -d' ' -f1)
info "NEXBSD_L1            : $H_CONF"
info "reference/GENERIC    : $H_GEN"
if [ "$H_CONF" = "$SHA_CONF" ]; then ok "NEXBSD_L1 identique a la reference (configuration compilee)"; else ko "NEXBSD_L1 DIFFERENT de la reference ($SHA_CONF) : verifier avant toute construction"; fi
if [ "$H_GEN" = "$SHA_GENERIC" ]; then ok "GENERIC-15.1 identique a la reference"; else ko "GENERIC-15.1 different ($SHA_GENERIC)"; fi

echo
echo "########## RESUME ##########"
info "les 5 lignes du delta vs GENERIC :"
grep -nE "^(ident|# \[NEXBSD-L1\] retiré)" fork/sys/amd64/conf/NEXBSD_L1 | sed 's/^/  ...     /'
echo
if [ "$H_CONF" = "$SHA_CONF" ] && [ "$H_GEN" = "$SHA_GENERIC" ]; then
  echo "VERDICT : DELTA INTACT ($EXPECTED fichiers, empreintes conformes)"
  exit 0
fi
echo "VERDICT : DELTA PRESENT MAIS EMPREINTES NON CONFORMES — a examiner"
exit 1

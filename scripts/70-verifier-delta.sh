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
#   overlay/etc/pf.conf, overlay/etc/ssh/sshd_config.nexbsd, overlay/etc/pam.d/su,
#   puis la configuration d identite extraite des scripts de banc (A-23..A-27) :
#   overlay/usr-local-etc-openldap-slapd.conf, overlay/usr-local-etc-smb4.conf,
#   overlay/usr-local-etc-nslcd.conf, overlay/etc-nsswitch.conf.fragment,
#   overlay/install-annuaire-base.ldif.
# 2026-10-28 : 25 -> 26 fichiers. Ajout de fork/70-appliquer-overlay.sh : le script qui APPLIQUE
#   la configuration du produit sur une racine de systeme. Justification : sans lui, les 11 fichiers
#   de overlay/ existaient dans le depot mais n'arrivaient JAMAIS dans le systeme (build-nexbsd.sh
#   ne les mentionnait pas). Ce n est pas un script de banc, c est un maillon de la chaine de
#   production : sa place est dans le delta produit.
# 2026-10-28 (soir) : 26 -> 27 fichiers. Ajout de fork/80-installer-nexbsd.sh : l'installeur qui
#   rend la configuration VIVANTE (paquets, SID lu et non fige, services, annuaire, verifications).
#   Sans lui, A-02 a A-06 restaient « config ecrite, personne ne l'applique ». C est un maillon de
#   la chaine de production, pas un outil de banc : sa place est dans le delta produit.
# 2026-10-28 (soir) : 27 -> 30 fichiers. Premiere pierre du BUREAU (couche C, A-21) :
#   fork/bureau/nexbsd-bureau.html      (le bureau lui-meme, autonome, JS valide par node --check)
#   fork/bureau/nexbsd-session.sh       (la session X : openbox + WebKitGTK en mode application)
#   fork/overlay/usr-local-share-xsessions/nexbsd.desktop  (entree de session)
#   Le bureau est le produit le plus VISIBLE : sans lui, NexBSD reste un serveur sans ecran.
# 2026-10-28 (nuit) : 30 -> 33 fichiers. AUTHENTIFICATION du bureau (exigence du responsable :
#   « un serveur doit demander quelque chose pour entrer ») :
#   fork/bureau/nexbsd-authentifier.sh      (verifie le mot de passe par PAM via su ; refuse root)
#   fork/bureau/tester-session.js           (17 cas, execute par node)
#   fork/bureau/tester-authentification.sh  (14 cas, execute avec un faux su)
#   Les deux fichiers de test sont dans le delta produit : un test qui ne voyage pas avec le produit
#   ne prouve rien sur le produit. Ils ne sont pas installes dans l image, seulement verifiables.
EXPECTED=33
SHA_CONF="14c86800fa6ae198d0625fdca885966fe9bd90c9f28853ae67991ab2129eb301"
SHA_GENERIC="02491b53b793cc5e1a3d622675d1aaf32d5da1973832cb13ff6d85d541d84878"

echo "########## Garde-fou : le delta du fork est-il intact ? ##########"
echo "# date : $(date -u +%FT%TZ)"

DEPOT=$(cd "$(dirname "$0")/.." && pwd)
cd "$DEPOT" || { ko "depot introuvable"; exit 1; }

# --- C-34 (2026-10-28) : QUI SUIT LES FICHIERS ? -----------------------------
# Constat MESURE, pas suppose : le systeme de base FreeBSD ne contient PAS git.
# Lance dans la VM de la CI, ce script comptait donc « 0 fichier suivi » et criait
# « suppression accidentelle probable » alors que rien n'avait disparu.
# On ne supprime pas le controle : on prend la source de verite disponible, et on DIT laquelle.
if command -v git >/dev/null 2>&1 && [ -d .git ]; then
  MODE_SUIVI="git — fichiers suivis par le depot (le plus strict)"
  suivis()   { git ls-files -- "$@" ; }
  suit_un()  { git ls-files --error-unmatch "$1" >/dev/null 2>&1 ; }
else
  MODE_SUIVI="disque — git absent, on compte les fichiers reellement presents"
  suivis()   { find "$@" -type f | sort ; }
  suit_un()  { [ -f "$1" ] ; }
fi

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
SUIVIS=$(suivis fork | wc -l | tr -d ' ')
info "mode de comptage : $MODE_SUIVI"
info "fichiers comptes dans fork/ : $SUIVIS (attendu : $EXPECTED)"
if [ "$SUIVIS" -ne "$EXPECTED" ]; then
  ko "le nombre de fichiers suivis est FAUX."
  ko "Suppression accidentelle probable — verifier : git status --short ; git log --diff-filter=D -- fork"
  exit 1
fi
ok "$EXPECTED fichiers dans fork/ (mode : $MODE_SUIVI)"

echo
echo "########## BLOC C - les fichiers critiques existent ##########"
MANQUANTS=0
for f in sys/amd64/conf/NEXBSD_L1 sys/amd64/conf/NEXBSD_L1.rapport src.conf release.conf \
         overlay/etc/motd overlay/etc/nexbsd-version overlay/etc/rc.conf.defaults \
         overlay/etc/pf.conf overlay/etc/ssh/sshd_config.nexbsd overlay/etc/pam.d/su \
         overlay/usr-local-etc-openldap-slapd.conf overlay/usr-local-etc-smb4.conf \
         overlay/usr-local-etc-nslcd.conf overlay/etc-nsswitch.conf.fragment \
         overlay/install-annuaire-base.ldif \
         patches/0001-identite-version.patch tools/generer-kernel-conf.sh \
         reference/GENERIC-15.1 reference/newvers.sh-15.1 exceptions-licence.txt; do
  if suit_un "fork/$f"; then
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
echo "########## BLOC E - garde-fou C-30 : les scripts sont-ils executables ? ##########"
NON_EXEC=0
for f in scripts/*.sh fork/*.sh fork/tools/*.sh; do
  [ -f "$f" ] || continue
  if [ -x "$f" ]; then
    :
  else
    NON_EXEC=$((NON_EXEC+1))
    echo "  [KO] $f n'est pas executable (chmod +x manquant)"
  fi
done
if [ "$NON_EXEC" -eq 0 ]; then
  ok "tous les scripts portent le bit executable (garde-fou C-30)"
else
  ko "$NON_EXEC script(s) sans bit executable — sur une machine reelle, ./script echoue (C-30)"
fi
# C-30 : l'atelier perd le bit executable a chaque reecriture d'un fichier. Sans ce controle,
# le defaut revient a chaque fois — exactement comme le dossier build/ efface (C-16 puis C-18).
NON_EXEC_OK=$([ "$NON_EXEC" -eq 0 ] && echo oui || echo non)

echo
if [ "$H_CONF" = "$SHA_CONF" ] && [ "$H_GEN" = "$SHA_GENERIC" ] && [ "$NON_EXEC_OK" = oui ]; then
  echo "VERDICT : DELTA INTACT ($EXPECTED fichiers, empreintes conformes)"
  exit 0
fi
# Verdicts separes : nommer la VRAIE cause. Un garde-fou qui dit "empreintes non conformes"
# alors que le probleme est un chmod fait perdre du temps et finit par etre ignore.
if [ "$NON_EXEC" -ne 0 ]; then
  echo "VERDICT : ECHEC — $NON_EXEC script(s) sans bit executable (C-30). Rien a voir avec les empreintes."
  exit 1
fi
echo "VERDICT : DELTA PRESENT MAIS EMPREINTES NON CONFORMES — a examiner"
exit 1

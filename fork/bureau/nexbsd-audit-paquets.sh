#!/bin/sh
# NexBSD — audit de sécurité des paquets, AVANT d'ouvrir le bureau (couche C).
#
# Origine : docs/51 §4 point 1 — « pkg audit doit tourner au démarrage de session et REFUSER de
# lancer le bureau si le paquet est vulnérable — à écrire, pas encore fait » (28/10).
# Écrit le 2026-10-29 (acquis A-67).
#
# POURQUOI CE SCRIPT EXISTE
# Le bureau NexBSD est rendu par WebKitGTK (fork/bureau/nexbsd-bureau.html). Ce moteur a un
# historique de vulnérabilités : 20 CVE corrigées en mai 2026. Un bureau qui affiche du contenu
# avec un moteur vulnérable est une porte ouverte, même si le fichier affiché est local.
#
# RÈGLE DE CONCEPTION (leçon M-10, docs/54) : un garde-fou ne doit pas crier à tort.
# Le script distingue TROIS états, et n'interdit le démarrage que sur le premier :
#
#   1. VULNÉRABLE      — un paquet de la chaîne d'affichage est prouvé vulnérable.  -> REFUS
#   2. INCONNU         — impossible de vérifier (pas de réseau, base absente).      -> on continue,
#                        mais on l'ANNONCE très haut : l'utilisateur doit savoir.
#   3. SANS OBJET      — pkg n'est pas installé (le produit en est encore au socle FreeBSD,
#                        aucun paquet tiers).                                        -> on continue.
#
# Usage :
#   sh fork/bureau/nexbsd-audit-paquets.sh                  # mode réel (FreeBSD avec pkg)
#   sh fork/bureau/nexbsd-audit-paquets.sh --simulation F   # lit la sortie de `pkg audit` dans F
#   sh fork/bureau/nexbsd-audit-paquets.sh --forcer          # dérogation (roue uniquement)
#
# Codes de sortie :
#   0  le bureau peut s'ouvrir (aucune vulnérabilité critique, ou état annoncé)
#   3  REFUS : vulnérabilité critique prouvée
#   4  dérogation refusée (demandeur non membre de wheel, ou pas sur FreeBSD)

set -u

CRITIQUES="webkit2-gtk epiphany wpewebkit gtk3 gtk4 glib libsoup libsoup3 webkitgtk"
# Justification de cette liste : ce sont les paquets qui, une fois vulnérables, permettent
# l'exécution de code pendant que le bureau affiche quelque chose. Un défaut dans, disons,
# `zip` n'ouvre pas la même porte.

ok()    { echo "  [OK]    $*"; }
ko()    { echo "  [ECHEC] $*"; }
info()  { echo "  ...     $*"; }
alarme(){ echo "  !!      $*"; }

SIMULATION=""
FORCER=0
while [ $# -gt 0 ]; do
	case "$1" in
		--simulation) SIMULATION="${2:-}"; shift 2 ;;
		--forcer)     FORCER=1; shift ;;
		*) echo "option inconnue : $1" >&2; exit 4 ;;
	esac
done

echo "########## NexBSD — audit de sécurité des paquets ##########"
echo "# date : $(date -u +%Y-%m-%dT%H:%M:%SZ)"

# --- 1. dérogation : réservée à la roue -------------------------------------
if [ "$FORCER" -eq 1 ]; then
	if [ "$(uname -s)" = "FreeBSD" ] && id -nG 2>/dev/null | tr ' ' '\n' | grep -qx wheel; then
		alarme "DÉROGATION demandée par $(id -un), membre de wheel : l'audit est ignoré."
		alarme "Ce choix est assumé par l'administrateur et trace ci-dessous."
		exit 0
	fi
	ko "dérogation refusée : elle est réservée aux membres de wheel sur FreeBSD."
	exit 4
fi

# --- 2. obtenir la sortie de l'audit ----------------------------------------
SORTIE_AUDIT=""
ETAT=""
if [ -n "$SIMULATION" ]; then
	[ -r "$SIMULATION" ] || { ko "fichier de simulation illisible : $SIMULATION"; exit 2; }
	SORTIE_AUDIT=$(cat "$SIMULATION")
	info "mode simulation : lecture de $SIMULATION"
	ETAT="verifie"
elif ! command -v pkg >/dev/null 2>&1; then
	# État 3 : pkg absent. Ce n'est PAS une faille : c'est le produit à l'étape « socle FreeBSD ».
	info "pkg n'est pas installé sur cette machine."
	info "aucun logiciel tiers n'est donc présent : il n'y a rien à auditer."
	info "le bureau peut s'ouvrir ; cet état cessera dès que fork/80 installera Samba et OpenLDAP."
	exit 0
else
	# `pkg audit -F` met la base à jour. Sans réseau, il échoue : ce n'est pas une faille,
	# c'est un état INCONNU, et on le dit.
	if pkg audit -F >/dev/null 2>&1; then
		SORTIE_AUDIT=$(pkg audit 2>&1)
		ETAT="verifie"
		grep -q '0 problem' <<EOF
$SORTIE_AUDIT
EOF
		ok "base de vulnérabilités à jour, audit effectué"
	else
		SORTIE_AUDIT=$(pkg audit 2>&1 || true)
		ETAT="inconnu"
		alarme "IMPOSSIBLE DE METTRE LA BASE À JOUR (réseau ?). L'état de sécurité est INCONNU."
		alarme "L'audit ci-dessous porte sur une base peut-être périmée : il ne prouve rien."
	fi
fi

# --- 3. lire l'audit : quels paquets sont vulnérables ? ----------------------
# Format de `pkg audit` :
#     webkit2-gtk-2.48.3 is vulnerable:
#       webkit2-gtk -- multiple vulnerabilities
#       ...
#     1 problem(s) in 1 installed package(s) found.
VULN_CRITIQUE=""
VULN_AUTRE=""
LISTE=$(echo "$SORTIE_AUDIT" | awk '
	/is vulnerable:/ {
		p = $1
		sub(/-[0-9][^-]*$/, "", p)   # retire -2.48.3 (version = dernier segment commençant par un chiffre)
		print p
	}' | sort -u)

if grep -qi 'no packages installed\|0 problem' <<EOF
$SORTIE_AUDIT
EOF
then
	ok "aucune vulnérabilité connue dans les paquets installés"
fi

if [ -n "$LISTE" ]; then
	for p in $LISTE; do
		trouve=0
		for c in $CRITIQUES; do
			[ "$p" = "$c" ] && trouve=1
		done
		if [ "$trouve" -eq 1 ]; then
			VULN_CRITIQUE="$VULN_CRITIQUE $p"
			ko "PAQUET CRITIQUE VULNÉRABLE : $p"
		else
			VULN_AUTRE="$VULN_AUTRE $p"
			alarme "paquet vulnérable, hors chaîne d'affichage : $p"
		fi
	done
fi

# --- 4. décision -------------------------------------------------------------
if [ -n "$VULN_CRITIQUE" ]; then
	echo
	echo "  ============================================================"
	echo "   BUREAU REFUSÉ — un paquet qui affiche l'écran est vulnérable"
	echo "  ============================================================"
	echo "   paquets :$VULN_CRITIQUE"
	echo
	echo "   Corriger (en root) :"
	echo "       pkg upgrade -y$(for p in $VULN_CRITIQUE; do printf ' %s' "$p"; done)"
	echo "       pkg audit -F"
	echo
	echo "   Pour ouvrir le bureau malgré tout, en connaissance de cause :"
	echo "       sh $0 --forcer     (réservé aux membres de wheel)"
	echo
	info "on n'ouvre pas une session graphique sur un moteur de rendu troué."
	exit 3
fi

if [ -n "$VULN_AUTRE" ]; then
	alarme "des paquets vulnérables existent, mais aucun sur le chemin de l'affichage."
	alarme "à corriger : pkg upgrade -y$VULN_AUTRE"
fi

if [ "$ETAT" = "inconnu" ]; then
	echo "  !!  L'état de sécurité est INCONNU — le bureau s'ouvre, mais sans garantie.  !!"
	exit 0
fi

ok "le bureau peut s'ouvrir (état vérifié, aucune vulnérabilité critique)"
exit 0

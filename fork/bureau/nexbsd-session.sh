#!/bin/sh
# NexBSD — session graphique du bureau (couche C).
#
# POURQUOI CE SCRIPT EXISTE (2026-10-28)
#   Le bureau NexBSD est écrit en HTML/CSS/JS (fork/bureau/nexbsd-bureau.html), affiché par WebKitGTK.
#   Ce script est ce qui transforme un FreeBSD en console en un FreeBSD en bureau : il démarre X,
#   un gestionnaire de fenêtres léger, puis affiche le bureau en plein écran.
#
# ÉTAT HONNÊTE : JAMAIS EXÉCUTÉ. Aucun système NexBSD n'existe, et le bureau n'a jamais été affiché
#   dans un vrai serveur X. Les trois commandes ci-dessous viennent de la documentation FreeBSD
#   (xinit(1), epiphany) ; elles n'ont pas été confrontées à une machine réelle.
#
# CHOIX ASSUMÉS (voir docs/51) :
#   - X11 et non Wayland : les pilotes et la documentation FreeBSD 15 sont mûrs sur X11,
#     Wayland existe mais demande seatd + un compositeur, pour un gain nul sur un PC de 2011 ;
#   - openbox comme gestionnaire de fenêtres : il ne fournit QUE le déplacement/redimensionnement,
#     tout le reste (barre, icônes, fenêtres) est notre code, dans la page HTML ;
#   - le bureau est une page locale : AUCUNE ressource distante (vérifié par grep), donc il
#     fonctionne sur une machine sans réseau — exigence du produit.
#
# USAGE
#   démarrage automatique : voir fork/overlay/usr/local/share/xsessions/nexbsd.desktop
#   à la main, depuis la console : startx /usr/local/bin/nexbsd-session
set -eu

BUREAU="/usr/local/share/nexbsd/bureau/nexbsd-bureau.html"
JOURNAL="/var/log/nexbsd-bureau.log"

ok()   { echo "  [OK]    $*"; }
ko()   { echo "  [ECHEC] $*"; }
info() { echo "  ...     $*"; }

echo "########## NexBSD — session bureau ##########"
echo "# date : $(date -u +%Y-%m-%dT%H:%M:%SZ)"

# --- 1. préconditions ------------------------------------------------------
[ "$(uname -s)" = "FreeBSD" ] || { echo "ERREUR : cette session ne tourne que sur FreeBSD." >&2; exit 1; }

if [ ! -r "$BUREAU" ]; then
	ko "le bureau est absent : $BUREAU"
	info "il doit être posé là par l'installeur (fork/80-installer-nexbsd.sh)"
	exit 1
fi
ok "le bureau est présent ($(wc -c <"$BUREAU") octets)"

# WebKitGTK via epiphany (www/epiphany, paqueté pour FreeBSD 15 amd64).
NAVIGATEUR=""
for c in epiphany epiphany-browser; do
	if command -v "$c" >/dev/null 2>&1; then NAVIGATEUR="$c"; break; fi
done
if [ -z "$NAVIGATEUR" ]; then
	ko "aucun navigateur WebKit trouvé (paquet attendu : epiphany / www/epiphany)"
	info "installer : pkg install -y epiphany"
	exit 1
fi
ok "navigateur WebKit : $NAVIGATEUR"

# --- 2. dossier de session ------------------------------------------------
export LANG="${LANG:-fr_FR.UTF-8}"
export LC_ALL="${LC_ALL:-fr_FR.UTF-8}"
export XDG_SESSION_TYPE=x11
export XDG_CURRENT_DESKTOP=NexBSD
export XDG_SESSION_DESKTOP=nexbsd
export DESKTOP_SESSION=nexbsd

# --- 3. gestionnaire de fenêtres ------------------------------------------
if command -v openbox >/dev/null 2>&1; then
	openbox >>"$JOURNAL" 2>&1 &
	WM_PID=$!
	ok "openbox démarré (pid $WM_PID)"
	sleep 1
else
	info "openbox absent : le bureau s'affichera quand même, mais sans déplacement de fenêtres"
	info "installer : pkg install -y openbox"
	WM_PID=""
fi

# --- 4. le bureau ---------------------------------------------------------
# --application-mode : pas d'onglets, pas de barre d'adresse — on veut une application, pas un site.
info "lancement du bureau : $BUREAU"
info "journal : $JOURNAL"

BOUCLE=0
while [ "$BOUCLE" -lt 3 ]; do
	BOUCLE=$((BOUCLE+1))
	"$NAVIGATEUR" --application-mode "file://$BUREAU" >>"$JOURNAL" 2>&1 || true
	# Si le bureau se ferme, on le relance. Après 3 fermetures, on rend la main :
	# un utilisateur qui veut sortir doit pouvoir sortir (ne pas emprisonner).
	info "le bureau s'est fermé (tentative $BOUCLE sur 3)"
done

[ -n "$WM_PID" ] && kill "$WM_PID" 2>/dev/null || true
echo "session terminée."

#!/bin/sh
# NexBSD — authentification de la session (écran d'ouverture). 2026-10-28.
#
# COMMENT ELLE VÉRIFIE VRAIMENT UN MOT DE PASSE
#   Par `su -l <utilisateur> -c /usr/bin/true`. `su` interroge PAM, donc :
#     - les mots de passe locaux fonctionnent ;
#     - quand l'annuaire LDAP sera branché (nslcd + pam_ldap), les identités de l'annuaire
#       fonctionneront SANS MODIFIER CE FICHIER : c'est PAM qui décide, pas nous.
#   C'est aussi ce qui rend la règle A-14 (su doit demander un mot de passe) vitale : si `su`
#   laissait passer sans mot de passe, ce script aussi.
#
# ⚠️ POURQUOI CE SCRIPT REFUSE DE TOURNER EN ROOT
#   `su` ne demande AUCUN mot de passe quand on est déjà root. Si la session tournait en root,
#   l'écran d'ouverture serait décoratif. Ce script refuse donc l'utilisateur root : c'est une
#   conséquence directe du défaut constaté au banc (Cmd 25bis : « su - » passait sans mot de passe).
#
# SORTIE : écrit uniquement le nom d'utilisateur authentifié sur stdout, et rien d'autre.
#          Tout le dialogue passe par stderr, pour que l'appelant ne récupère que le nom.
#
# USAGE : sh nexbsd-authentifier.sh [nombre d'essais, défaut 3]
#         (variables) NEXBSD_SU : commande de vérification, par défaut "su"
#                     NEXBSD_FINSESSION : "1" pour ne pas boucler (utile aux tests)
set -eu

ESSAIS=${1:-3}
SU_CMD=${NEXBSD_SU:-su}
FINSESSION=${NEXBSD_FINSESSION:-0}

if [ "$(id -u)" -eq 0 ]; then
	echo "ERREUR : l'authentification de session refuse de tourner en root." >&2
	echo "         En root, 'su' ne demande aucun mot de passe : l'écran serait décoratif." >&2
	echo "         La session doit tourner sous un compte ordinaire (non membre de wheel)." >&2
	exit 2
fi

valide() {
	case "$1" in
		'') return 1 ;;
	esac
	printf '%s' "$1" | grep -qE '^[a-z_][a-z0-9_-]{0,31}$'
}

n=0
while [ "$n" -lt "$ESSAIS" ]; do
	n=$((n+1))
	printf 'Utilisateur : ' >&2
	lu=""
	read -r lu || true
	if ! valide "$lu"; then
		echo "  nom d'utilisateur invalide (lettres minuscules, chiffres, - et _)" >&2
		continue
	fi
	# -l : session de connexion complète (profil, variables) ; -c : on ne veut rien exécuter d'autre
	# que la vérification du mot de passe. su interroge PAM, et donc les éventuelles identités LDAP.
	if "$SU_CMD" -l "$lu" -c /usr/bin/true 2>/dev/null; then
		printf '%s\n' "$lu"
		exit 0
	fi
	echo "  mot de passe refusé (essai $n sur $ESSAIS)" >&2
	[ "$FINSESSION" = "1" ] && break
done

echo "ÉCHEC de l'authentification après $n tentative(s)." >&2
exit 1

#!/bin/sh
# NexBSD — interpréteur de script de connexion et mappage des lecteurs réseau.
#
# EXIGENCE DU PRODUIT : EF-N-06 de docs/02 — « les lecteurs réseau se connectent automatiquement
# selon l'utilisateur (esprit script de connexion) ; un poste client voit ses lecteurs après
# connexion, sans action manuelle ». C'est la fonction n° 1 de NetWare, et jusqu'au 2026-10-29,
# RIEN n'existait dans NexBSD (docs/57 §2, priorité 3). Acquis A-68, problème C-45.
#
# CE QUE FAIT CE SCRIPT, EN LANGAGE COURANT
# Quand un utilisateur ouvre sa session, NexBSD lit un petit fichier de commandes (le « script de
# connexion »), exactement comme NetWare depuis 1983. Ce fichier dit : « pour cet utilisateur,
# branche le lecteur H sur son dossier personnel, P sur le partage commun, et écris-lui bonjour ».
# L'utilisateur ne fait rien : ses lecteurs sont là.
#
# COMMANDES RECONNUES (sous-ensemble volontairement borné) :
#   MAP H: \\serveur\partage          branche une lettre de lecteur
#   MAP ROOT P: \\serveur\commun      idem, mais la lettre est la RACINE du partage
#   WRITE "texte"                     affiche un message (variables %...% développées)
#   IF MEMBER OF "groupe" / ENDIF     exécute un bloc seulement pour les membres d'un groupe
#   INCLUDE fichier                   exécute un autre script de connexion
#   ; ceci est un commentaire         (point-virgule, comme dans NetWare)
#   # commande-shell                  exécute une commande (comme dans NetWare)
#   EXIT                              arrête le script
#
# VARIABLES : %UTILISATEUR% %NOM_COMPLET% %JOUR% %MOIS% %HEURE% %SERVEUR% %GROUPE%
#
# POURQUOI LES LECTEURS SONT DES MONTAGES SMB
# NexBSD n'implémente pas le protocole NCP (client NetWare historique) : c'est N-11, non commencé.
# Les lecteurs sont donc des montages SMB (mount_smbfs, noyau FreeBSD) vers notre propre Samba.
# L'utilisateur voit la même chose qu'avec NetWare — des lettres de lecteur — par un autre chemin.
#
# LE MOT DE PASSE (question honnête)
# Monter un partage SMB exige le mot de passe de l'utilisateur. Ce script l'obtient d'un fichier
# 0600 que l'écran d'ouverture de session dépose, et il en tire ~/.nsmbrc (mécanisme officiel
# FreeBSD : mount_smbfs -N lit ~/.nsmbrc). Ce fichier est supprimé à la fermeture de session.
# C'est la première brique de N-05 (mot de passe unique) : un seul mot de passe saisi, plusieurs
# services servis. Limite à dire tout haut : pendant la session, le mot de passe existe en clair
# dans un fichier lisible par son seul propriétaire. C'est moins bon qu'un ticket Kerberos, c'est
# mieux que six mots de passe différents.
#
# Usage :
#   sh fork/netware/nexbsd-script-connexion.sh --script F --utilisateur U
#   sh ... --simulation          (n'effectue aucun montage : montre ce qui serait fait)
#   sh ... --mdp-fichier F       (fichier 0600 contenant le mot de passe, pour monter vraiment)

set -u

BASE="${NEXBSD_LECTEURS:-$HOME/Lecteurs}"
SERVEUR="${NEXBSD_SERVEUR:-nexbsd}"
SCRIPT=""
UTILISATEUR="${USER:-$(id -un 2>/dev/null || echo inconnu)}"
GROUPES=""
SIMULATION=0
MDP_FICHIER=""
JOURNAL="${NEXBSD_JOURNAL_CONNEXION:-}"

ok()   { echo "  [OK]    $*"; }
ko()   { echo "  [ECHEC] $*"; }
info() { echo "  ...     $*"; }

while [ $# -gt 0 ]; do
	case "$1" in
		--script)       SCRIPT="${2:-}"; shift 2 ;;
		--utilisateur)  UTILISATEUR="${2:-}"; shift 2 ;;
		--groupes)      GROUPES="${2:-}"; shift 2 ;;
		--mdp-fichier)  MDP_FICHIER="${2:-}"; shift 2 ;;
		--simulation)   SIMULATION=1; shift ;;
		--journal)      JOURNAL="${2:-}"; shift 2 ;;
		*) echo "option inconnue : $1" >&2; exit 2 ;;
	esac
done

[ -n "$GROUPES" ] || GROUPES=$(id -Gn 2>/dev/null | tr ' ' '\n' | grep -v '^$' | tr '\n' ' ')

echo "########## NexBSD — script de connexion ##########"
echo "# utilisateur : $UTILISATEUR"
echo "# serveur     : $SERVEUR"
echo "# date        : $(date -u +%Y-%m-%dT%H:%M:%SZ)"
[ "$SIMULATION" -eq 1 ] && info "MODE SIMULATION : aucun montage réel ne sera fait"

# --- 1. développement des variables ----------------------------------------
NOM_COMPLET=$(getent passwd "$UTILISATEUR" 2>/dev/null | cut -d: -f5)
[ -n "${NOM_COMPLET:-}" ] || NOM_COMPLET="$UTILISATEUR"

developper() {
	printf '%s' "$1" | sed \
		-e "s|%UTILISATEUR%|$UTILISATEUR|g" \
		-e "s|%NOM_COMPLET%|$NOM_COMPLET|g" \
		-e "s|%SERVEUR%|$SERVEUR|g" \
		-e "s|%JOUR%|$(date +%A)|g" \
		-e "s|%MOIS%|$(date +%B)|g" \
		-e "s|%HEURE%|$(date +%H:%M)|g" \
		-e "s|%GROUPE%|$(printf '%s' "$GROUPES" | sed 's/ $//')|g"
}

# --- 2. préparation du fichier ~/.nsmbrc (si un mot de passe est fourni) ----
NSMBRC="$HOME/.nsmbrc"
POSER_NSMBRC=0
if [ -n "$MDP_FICHIER" ]; then
	if [ ! -r "$MDP_FICHIER" ]; then
		ko "fichier de mot de passe illisible : $MDP_FICHIER"
		exit 1
	fi
	permissions=$(ls -l "$MDP_FICHIER" 2>/dev/null | cut -c1-10)
	case "$permissions" in
		-rw-------|-r--------) : ;;
		*) ko "le fichier de mot de passe n'est pas privé ($permissions) : refus."
		   info "il doit être en 0600 — un mot de passe lisible par d'autres n'est pas un secret"
		   exit 1 ;;
	esac
	MDP=$(cat "$MDP_FICHIER")
	if [ -z "$MDP" ]; then
		ko "le fichier de mot de passe est vide"; exit 1
	fi
	if [ "$SIMULATION" -eq 0 ]; then
		umask 077
		{
			printf '[%s:%s]\n' "$SERVEUR" "$UTILISATEUR"
			printf 'password=%s\n' "$MDP"
		} >"$NSMBRC"
		POSER_NSMBRC=1
		ok "~/.nsmbrc posé (0600) pour $UTILISATEUR@$SERVEUR"
	fi
	unset MDP
else
	info "aucun mot de passe fourni : les montages seront refusés s'ils en exigent un"
fi

# --- 3. moteur d'exécution --------------------------------------------------
NBLIGNES=0
NMONTES=0
NECHECS=0
PROFONDEUR_IF=0
SAUTER_A=0   # 0 = exécuter ; 1 = sauter jusqu'à ENDIF
LIGNE_COURANTE=0
INCLUSIONS=0

monter() {
	# $1 = lettre (H) ; $2 = chemin UNC (\\serveur\partage) ; $3 = ROOT ou ""
	_lettre=$1
	_unc=$2
	_cible="$BASE/$_lettre"

	# Les variables du script (%UTILISATEUR%, %SERVEUR%...) doivent etre developpees ICI aussi :
	# sans cela, le lecteur H pointerait vers un dossier litteralement nomme « %UTILISATEUR% ».
	# Defaut trouve par le test T-22 (cas 6) le 2026-10-29 — corrige, pas contourne.
	_unc=$(developper "$_unc")

	# \\serveur\partage[\sous\chemin]  ->  //serveur/partage[/sous/chemin]
	_fixe=$(printf '%s' "$_unc" | sed -e 's|^\\\\||' -e 's|\\|/|g')
	_hote=${_fixe%%/*}
	_partage=${_fixe#*/}
	if [ -z "$_hote" ] || [ -z "$_partage" ] || [ "$_hote" = "$_fixe" ]; then
		ko "chemin réseau invalide : $_unc (attendu : \\\\serveur\\partage)"
		NECHECS=$((NECHECS + 1))
		return 1
	fi

	if mount 2>/dev/null | grep -q " on $_cible "; then
		info "lettre $_lettre : déjà branchée sur $_cible"
		return 0
	fi

	if [ "$SIMULATION" -eq 1 ]; then
		ok "lettre $_lettre : brancherait //$_hote/$_partage sur $_cible"
		NMONTES=$((NMONTES + 1))
		return 0
	fi

	if [ -z "$MDP_FICHIER" ] && [ ! -r "$NSMBRC" ]; then
		ko "lettre $_lettre : aucun identifiant SMB (ni --mdp-fichier, ni ~/.nsmbrc)"
		info "un lecteur réseau sans authentification ne s'ouvre pas — c'est normal"
		NECHECS=$((NECHECS + 1))
		return 1
	fi

	if ! command -v mount_smbfs >/dev/null 2>&1; then
		ko "lettre $_lettre : mount_smbfs absent (noyau sans SMBFS ?)"
		NECHECS=$((NECHECS + 1))
		return 1
	fi

	mkdir -p "$_cible" 2>/dev/null || true
	if mount_smbfs -N -f 0600 "//$UTILISATEUR@$_hote/$_partage" "$_cible" 2>&1; then
		ok "lettre $_lettre : //$_hote/$_partage branchée sur $_cible"
		NMONTES=$((NMONTES + 1))
		return 0
	fi
	ko "lettre $_lettre : montage de //$_hote/$_partage impossible"
	NECHECS=$((NECHECS + 1))
	return 1
}

executer_script() {
	_fichier=$1
	INCLUSIONS=$((INCLUSIONS + 1))
	if [ "$INCLUSIONS" -gt 8 ]; then
		ko "trop d'INCLUDE imbriqués (8) : boucle probable, on arrête"
		exit 1
	fi
	if [ ! -r "$_fichier" ]; then
		ko "script de connexion introuvable : $_fichier"
		return 1
	fi
	while IFS= read -r ligne || [ -n "$ligne" ]; do
		LIGNE_COURANTE=$((LIGNE_COURANTE + 1))
		# retirer les espaces de tête et de fin
		ligne=$(printf '%s' "$ligne" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
		[ -z "$ligne" ] && continue
		case "$ligne" in
			';'*) continue ;;                     # commentaire NetWare
			EXIT*|exit*) 
				[ "$SAUTER_A" -eq 1 ] && continue
				info "EXIT rencontré ligne $LIGNE_COURANTE : fin du script"
				return 0 ;;
		esac

		# gestion des blocs IF
		case "$ligne" in
			IF\ MEMBER\ OF*|IF\ NOT\ MEMBER\ OF*)
				if [ "$SAUTER_A" -eq 1 ]; then
					PROFONDEUR_IF=$((PROFONDEUR_IF + 1))
					continue
				fi
				_neg=0
				case "$ligne" in IF\ NOT\ MEMBER\ OF*) _neg=1 ;; esac
				_grp=$(printf '%s' "$ligne" | sed -e 's/.*OF[[:space:]]*//' -e 's/^"//' -e 's/"[[:space:]]*$//')
				_membre=0
				for g in $GROUPES; do
					[ "$g" = "$_grp" ] && _membre=1
				done
				[ "$_neg" -eq 1 ] && _membre=$((1 - _membre))
				if [ "$_membre" -eq 1 ]; then
					PROFONDEUR_IF=$((PROFONDEUR_IF + 1))
					info "ligne $LIGNE_COURANTE : IF MEMBER OF \"$_grp\" -> vrai"
				else
					info "ligne $LIGNE_COURANTE : IF MEMBER OF \"$_grp\" -> faux, bloc sauté"
					SAUTER_A=1
					PROFONDEUR_IF=$((PROFONDEUR_IF + 1))
				fi
				continue ;;
			ENDIF*|endif*)
				PROFONDEUR_IF=$((PROFONDEUR_IF - 1))
				[ "$PROFONDEUR_IF" -le 0 ] && { PROFONDEUR_IF=0; SAUTER_A=0; }
				continue ;;
		esac
		[ "$SAUTER_A" -eq 1 ] && continue

		case "$ligne" in
			MAP\ *)
				_reste=$(printf '%s' "$ligne" | sed 's/^MAP[[:space:]]*//')
				root=""
				case "$_reste" in
					ROOT\ *) root="ROOT"; _reste=$(printf '%s' "$_reste" | sed 's/^ROOT[[:space:]]*//') ;;
				esac
				_lettre=$(printf '%s' "$_reste" | sed -e 's/:.*//')
				_unc=$(printf '%s' "$_reste" | sed -e 's/^[^:]*:[[:space:]]*//')
				if [ -z "$_lettre" ] || [ -z "$_unc" ]; then
					ko "ligne $LIGNE_COURANTE : MAP incomplet -> $ligne"
					NECHECS=$((NECHECS + 1))
					continue
				fi
				case "$_lettre" in
					[A-Za-z]) : ;;
					*) ko "ligne $LIGNE_COURANTE : lettre de lecteur invalide '$_lettre'"
					   NECHECS=$((NECHECS + 1)); continue ;;
				esac
				monter "$(printf '%s' "$_lettre" | tr 'a-z' 'A-Z')" "$_unc" "$root" ;;
			WRITE\ *|write\ *)
				_msg=$(printf '%s' "$ligne" | sed -e 's/^[Ww][Rr][Ii][Tt][Ee][[:space:]]*//' -e 's/^"//' -e 's/"$//')
				printf '  | %s\n' "$(developper "$_msg")" ;;
			INCLUDE\ *)
				_inc=$(printf '%s' "$ligne" | sed -e 's/^INCLUDE[[:space:]]*//' -e 's/"//g')
				[ -f "$_inc" ] || _inc="$(dirname "$_fichier")/$_inc"
				executer_script "$_inc" || NECHECS=$((NECHECS + 1)) ;;
			'#'*)
				_cmd=$(printf '%s' "$ligne" | sed 's/^#[[:space:]]*//')
				if [ "$SIMULATION" -eq 1 ]; then
					info "ligne $LIGNE_COURANTE : exécuterait : $_cmd"
				else
					sh -c "$_cmd" || { ko "ligne $LIGNE_COURANTE : commande en échec : $_cmd"; NECHECS=$((NECHECS + 1)); }
				fi ;;
			*)
				ko "ligne $LIGNE_COURANTE : commande inconnue -> $ligne"
				info "commandes reconnues : MAP, WRITE, IF MEMBER OF, ENDIF, INCLUDE, EXIT, #, ;"
				NECHECS=$((NECHECS + 1)) ;;
		esac
		NBLIGNES=$((NBLIGNES + 1))
	done <"$_fichier"
	return 0
}

# --- 4. choisir le script ---------------------------------------------------
if [ -z "$SCRIPT" ]; then
	for c in "$HOME/.nexbsd/script-connexion" /usr/local/etc/nexbsd/script-connexion; do
		if [ -r "$c" ]; then SCRIPT="$c"; break; fi
	done
fi
if [ -z "$SCRIPT" ] || [ ! -r "$SCRIPT" ]; then
	ko "aucun script de connexion trouvé"
	info "cherché : ~/.nexbsd/script-connexion puis /usr/local/etc/nexbsd/script-connexion"
	info "sans script, la session est normale mais AUCUN lecteur réseau n'est branché"
	exit 1
fi
ok "script de connexion : $SCRIPT"

mkdir -p "$BASE" 2>/dev/null || true

# --- 5. exécution -----------------------------------------------------------
executer_script "$SCRIPT"
EXEC_CODE=$?

if [ "$PROFONDEUR_IF" -ne 0 ]; then
	ko "bloc IF non refermé (ENDIF manquant) : le script est mal formé"
	NECHECS=$((NECHECS + 1))
fi

echo "-----------------------------------------------------------"
echo "  lignes exécutées : $NBLIGNES"
echo "  lecteurs branchés : $NMONTES"
echo "  échecs : $NECHECS"

if [ -n "$JOURNAL" ]; then
	{
		printf '%s connexion utilisateur=%s lecteurs=%s echecs=%s script=%s\n' \
			"$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$UTILISATEUR" "$NMONTES" "$NECHECS" "$SCRIPT"
	} >>"$JOURNAL" 2>/dev/null || true
fi

if [ "$NECHECS" -gt 0 ] || [ "$EXEC_CODE" -ne 0 ]; then
	ko "la connexion s'est terminée avec des erreurs"
	info "l'utilisateur garde sa session : un lecteur manquant ne doit pas fermer le bureau"
	exit 1
fi
ok "connexion terminée : $NMONTES lecteur(s) disponible(s)"
exit 0

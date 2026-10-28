#!/bin/sh
# NexBSD — appliquer la configuration du produit (fork/overlay/) sur une racine de système.
#
# POURQUOI CE SCRIPT EXISTE (2026-10-28)
#   Constat mesuré : `fork/build-nexbsd.sh` ne mentionne JAMAIS `overlay/`. Les 11 fichiers de
#   configuration du produit existaient donc sans que RIEN ne les applique : une image construite
#   aurait été « FreeBSD + noyau maison », sans annuaire, sans Samba, sans pare-feu, sans identité.
#   Ce script est le maillon manquant entre « des fichiers dans le dépôt » et « un système qui les a ».
#
# USAGE
#   sh fork/70-appliquer-overlay.sh -r <racine>            applique pour de vrai
#   sh fork/70-appliquer-overlay.sh -n -r <racine>         simulation (n'écrit rien)
#   options de substitution : -p <SID> -b <mot de passe liaison LDAP> -R <mot de passe root LDAP>
#
# RÈGLES APPLIQUÉES
#   - ne REMPLACE JAMAIS /etc/nsswitch.conf ni /etc/rc.conf : il FUSIONNE (files reste en premier,
#     la machine reste administrable si l'annuaire tombe) ;
#   - refuse de s'exécuter si un placeholder @NEXBSD_...@ n'a pas de valeur : jamais de mot de passe
#     laissé en clair dans une image ;
#   - idempotent : relancer ne duplique rien ;
#   - sans -r, refuse : on n'écrit pas dans / par accident.
#
# CE QUE CE SCRIPT NE FAIT PAS (limites écrites, pas cachées)
#   - il n'installe pas les paquets (slapd, samba, nss-pam-ldapd) : cela exige un dépôt de paquets ;
#   - il ne démarre pas les services : c'est rc.conf qui les active au démarrage ;
#   - il n'est pas encore branché dans la chaîne de release (voir docs/48 §5).
set -eu

RACINE=""
SIMULATION="non"
SID=""
BINDPW=""
ROOTPW=""

while getopts "nr:p:b:R:" opt; do
	case "$opt" in
		n) SIMULATION="oui" ;;
		r) RACINE="$OPTARG" ;;
		p) SID="$OPTARG" ;;
		b) BINDPW="$OPTARG" ;;
		R) ROOTPW="$OPTARG" ;;
		*) echo "usage : $0 -r <racine> [-n] [-p SID] [-b mdp_liaison] [-R mdp_racine_ldap]" >&2; exit 2 ;;
	esac
done

ICI=$(cd "$(dirname "$0")" && pwd)
O="$ICI/overlay"
[ -d "$O" ] || { echo "ERREUR : $O introuvable." >&2; exit 1; }

if [ -z "$RACINE" ]; then
	echo "ERREUR : -r <racine> obligatoire (refus d'écrire dans / par accident)." >&2
	exit 1
fi
RACINE=$(cd "$RACINE" 2>/dev/null && pwd) || { echo "ERREUR : racine '$RACINE' inexistante." >&2; exit 1; }
[ "$RACINE" != "/" ] || { echo "ERREUR : racine = / refusée par sécurité." >&2; exit 1; }

echo "########## NexBSD — application de la configuration du produit ##########"
echo "# racine    : $RACINE"
echo "# mode      : $([ "$SIMULATION" = oui ] && echo SIMULATION || echo REEL)"
echo ""

# --- 1. vérification des placeholders AVANT toute écriture ---------------------
MANQUANT=0
if grep -q '@NEXBSD_LDAP_ROOTPW@' "$O/usr-local-etc-openldap-slapd.conf" 2>/dev/null; then
	[ -n "$ROOTPW" ] || { echo "  [KO] @NEXBSD_LDAP_ROOTPW@ sans valeur (-R)"; MANQUANT=1; }
fi
if grep -q '@NEXBSD_LDAP_BINDPW@' "$O/usr-local-etc-nslcd.conf" 2>/dev/null; then
	[ -n "$BINDPW" ] || { echo "  [KO] @NEXBSD_LDAP_BINDPW@ sans valeur (-b)"; MANQUANT=1; }
fi
if grep -q '@NEXBSD_SID@' "$O/install-annuaire-base.ldif" 2>/dev/null; then
	[ -n "$SID" ] || { echo "  [KO] @NEXBSD_SID@ sans valeur (-p) — lire 'net getlocalsid' APRES la première installation, jamais le figer avant (C-13)"; MANQUANT=1; }
fi
[ "$MANQUANT" -eq 0 ] || { echo ""; echo "ARRET : aucun fichier écrit. Rien de partiel n'a été laissé."; exit 1; }
echo "  [OK] tous les placeholders ont une valeur"

# --- 2. substitutions ---------------------------------------------------------
TRAVAIL=$(mktemp -d "${TMPDIR:-/tmp}/nexbsd-overlay.XXXXXX")
trap 'rm -rf "$TRAVAIL"' EXIT INT TERM

subst() {
	# $1 = fichier source, $2 = destination
	sed -e "s|@NEXBSD_LDAP_ROOTPW@|$ROOTPW|g" \
	    -e "s|@NEXBSD_LDAP_BINDPW@|$BINDPW|g" \
	    -e "s|@NEXBSD_SID@|$SID|g" "$1" > "$2"
}

# --- 3. copies simples (remplacement assumé : ce sont NOS fichiers) -----------
poser() {
	# $1 = source relative à overlay, $2 = destination relative à la racine, $3 = mode
	src="$O/$1"; dst="$RACINE$2"
	if grep -q '@NEXBSD_' "$src" 2>/dev/null; then subst "$src" "$TRAVAIL/x"; src="$TRAVAIL/x"; fi
	if [ "$SIMULATION" = oui ]; then
		echo "  [SIM] $2"
	else
		mkdir -p "$(dirname "$dst")"
		cp "$src" "$dst"
		chmod "$3" "$dst"
		echo "  [OK ] $2"
	fi
}

poser "etc/motd"                     "/etc/motd"                          644
poser "etc/nexbsd-version"           "/etc/nexbsd-version"                644
poser "etc/pam.d/su"                 "/etc/pam.d/su"                      644
poser "etc/pf.conf"                  "/etc/pf.conf"                       644
poser "etc/ssh/sshd_config.nexbsd"   "/etc/ssh/sshd_config"               600
poser "usr-local-etc-openldap-slapd.conf" "/usr/local/etc/openldap/slapd.conf" 600
poser "usr-local-etc-smb4.conf"      "/usr/local/etc/smb4.conf"           600
poser "usr-local-etc-nslcd.conf"     "/usr/local/etc/nslcd.conf"          600
poser "install-annuaire-base.ldif"   "/root/install-annuaire-base.ldif"   600

# --- 4. fusions (on n'écrase pas un fichier du système) -----------------------
fusionner() {
	# $1 = source, $2 = destination ; ajoute seulement les lignes absentes
	src="$1"; dst="$RACINE$2"
	[ -f "$dst" ] || { echo "  [KO ] $2 absent de la racine : fusion impossible"; return 1; }
	ajoute=0
	while IFS= read -r ligne; do
		case "$ligne" in ''|'#'*) continue ;; esac
		# La clé est ce qui précède le PREMIER séparateur, ':' (nsswitch.conf) ou '=' (rc.conf).
		# Bug corrigé le 2026-10-28 : ne traiter que ':' dupliquait toutes les lignes de rc.conf
		# (sshd_enable="YES" puis sshd_enable="NO" — la dernière gagne par chance, pas par maîtrise).
		cle=$(printf '%s' "$ligne" | sed 's/[[:space:]]*#.*$//' | sed 's/[:=].*//' | cut -d: -f1 | tr -d '[:space:]')
		if [ -n "$cle" ] && grep -qE "^[[:space:]]*${cle}[[:space:]]*[:=]" "$dst" 2>/dev/null; then
			continue
		fi
		if [ "$SIMULATION" = oui ]; then
			echo "  [SIM] + $2 : $ligne"
		else
			printf '%s\n' "$ligne" >> "$dst"
			echo "  [OK ] + $2 : $ligne"
		fi
		ajoute=$((ajoute+1))
	done < "$src"
	[ "$ajoute" -gt 0 ] || echo "  [--  ] $2 : déjà à jour"
}

echo ""
echo "--- fusions (jamais de remplacement) ---"
fusionner "$O/etc-nsswitch.conf.fragment" "/etc/nsswitch.conf"
fusionner "$O/etc/rc.conf.defaults"       "/etc/rc.conf"

# --- 5. vérifications finales -------------------------------------------------
echo ""
echo "--- contrôle ---"
if [ "$SIMULATION" = oui ]; then
	echo "  [SIM] aucune écriture — contrôle d'écriture sauté"
	echo ""
	echo "SIMULATION : la configuration du produit EST applicable. Rien n'a été écrit."
	exit 0
fi

KO=0
verifie() { if [ -s "$RACINE$1" ]; then echo "  [OK ] $1 présent ($(wc -c <"$RACINE$1") o)"; else echo "  [KO ] $1 absent ou vide"; KO=1; fi; }
verifie "/etc/nexbsd-version"
verifie "/etc/pam.d/su"
verifie "/etc/pf.conf"
verifie "/usr/local/etc/openldap/slapd.conf"
verifie "/usr/local/etc/smb4.conf"
verifie "/usr/local/etc/nslcd.conf"

if grep -q '@NEXBSD_' "$RACINE/etc/nexbsd-version" "$RACINE/etc/pam.d/su" "$RACINE/etc/pf.conf" \
	"$RACINE/usr/local/etc/openldap/slapd.conf" "$RACINE/usr/local/etc/smb4.conf" \
	"$RACINE/usr/local/etc/nslcd.conf" 2>/dev/null; then
	echo "  [KO ] un placeholder subsiste dans la racine"
	KO=1
else
	echo "  [OK ] aucun placeholder ne subsiste"
fi

echo ""
if [ "$KO" -eq 0 ]; then
	echo "VERDICT : configuration du produit APPLIQUÉE sur $RACINE (11 fichiers, 2 fusions)."
	echo "RESTE À FAIRE, hors de ce script : installer les paquets (slapd, samba, nss-pam-ldapd)"
	echo "et démarrer les services — sinon la configuration est présente mais inerte."
else
	echo "VERDICT : ÉCHEC — voir les [KO] ci-dessus."
	exit 1
fi

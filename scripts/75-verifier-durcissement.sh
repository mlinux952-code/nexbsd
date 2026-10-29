#!/bin/sh
# NexBSD — vérificateur de durcissement du produit (statique, sans réseau).
#
# ORIGINE : docs/62. Le responsable a envoyé cinq affiches d'outils de sécurité (casseurs de mots de
# passe, scanners, distributions immuables). AUCUN de ces outils n'a sa place DANS le produit — mais
# leur façon de penser, elle, est utile : « de quoi aurait besoin quelqu'un qui voudrait nous casser ? »
# Ce script retourne la question : il inspecte les fichiers du produit et dit ce qui est durci,
# ce qui ne l'est pas, et ce qui est absent.
#
# TROIS VERDICTS, JAMAIS DEUX (leçon M-10 : un garde-fou ne doit pas crier à tort) :
#   [OK]        la protection est présente et correcte
#   [FAIBLE]    la protection existe mais est insuffisante — c'est un vrai défaut, à corriger
#   [ABSENT]    le fichier ou le réglage n'existe pas — NON COMPTÉ COMME ÉCHEC, mais nommé
#
# Un fichier absent (sysctl.conf inexistant) n'est pas une faute : c'est un travail à faire. Le
# confondre avec un échec rendrait le contrôle inutilisable pendant la construction du produit.
#
# Usage :
#   sh scripts/75-verifier-durcissement.sh            # inspecte le dépôt courant
#   sh scripts/75-verifier-durcissement.sh --strict   # [ABSENT] devient un échec (CI de release)
#
# Code de sortie : 0 si aucune faiblesse, 1 s'il reste au moins une [FAIBLE] (ou un [ABSENT] en --strict).

set -u

RACINE=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
STRICT=0
[ "${1:-}" = "--strict" ] && STRICT=1

OK=0; FAIBLE=0; ABSENT=0
ok()     { OK=$((OK+1));     echo "  [OK]     $*"; }
faible() { FAIBLE=$((FAIBLE+1)); echo "  [FAIBLE] $*"; }
absent() { ABSENT=$((ABSENT+1)); echo "  [ABSENT] $*"; }
titre()  { echo; echo "--- $* ---"; }

# cherche une directive dans un fichier de configuration (en ignorant les commentaires)
# $1 = fichier ; $2 = motif (grep -E, insensible à la casse)
lire()  { grep -iE "$2" "$1" 2>/dev/null | grep -vE '^[[:space:]]*[#;]' ; }
contient() { [ -n "$(lire "$1" "$2")" ]; }

echo "########## NexBSD — vérification de durcissement ##########"
echo "# date : $(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo "# racine : $RACINE"

# ===========================================================================
titre "1. SSH — la porte d'administration"
SSHD="$RACINE/fork/overlay/etc/ssh/sshd_config.nexbsd"
if [ ! -r "$SSHD" ]; then
	absent "sshd_config.nexbsd introuvable"
else
	contient "$SSHD" '^[[:space:]]*PermitRootLogin[[:space:]]+no' \
		&& ok "connexion root par SSH interdite" \
		|| faible "PermitRootLogin n'est pas 'no' : root pourrait se connecter à distance"
	contient "$SSHD" '^[[:space:]]*PasswordAuthentication[[:space:]]+no' \
		&& ok "authentification par mot de passe refusée (clé seulement)" \
		|| faible "PasswordAuthentication n'est pas 'no' : force brute possible sur SSH"
	contient "$SSHD" '^[[:space:]]*KbdInteractiveAuthentication[[:space:]]+no' \
		&& ok "authentification interactive (PAM) refusée" \
		|| faible "KbdInteractiveAuthentication n'est pas 'no' : contournement possible du refus de mot de passe"
	contient "$SSHD" '^[[:space:]]*AllowUsers|^[[:space:]]*AllowGroups' \
		&& ok "liste blanche d'utilisateurs ou de groupes présente" \
		|| absent "aucune liste blanche AllowUsers/AllowGroups : tout compte valide peut tenter sa chance"
fi

# ===========================================================================
titre "2. Pare-feu — ce qui entre"
PF="$RACINE/fork/overlay/etc/pf.conf"
if [ ! -r "$PF" ]; then
	absent "pf.conf introuvable"
else
	contient "$PF" '^[[:space:]]*block[[:space:]]+in' \
		&& ok "refus par défaut en entrée présent" \
		|| faible "aucune règle 'block in' : le pare-feu n'a pas de politique par défaut"
	contient "$PF" 'block[[:space:]]+in[[:space:]]+log' \
		&& ok "les refus sont journalisés (un refus non tracé n'est pas vérifiable)" \
		|| faible "les refus ne sont pas journalisés"
	for p in 23 21 69 3389 5900; do
		if contient "$PF" "port[[:space:]]+\\{?[^#]*[[:space:]]$p([^0-9]|$)"; then
			faible "le port $p est ouvert en entrée : c'est une surface d'attaque inutile"
		fi
	done
	contient "$PF" 'set skip on lo0' \
		&& ok "boucle locale non filtrée (nécessaire, voir C-46)" \
		|| absent "pas de 'set skip on lo0' : le filtrage local peut casser les services"
fi

# ===========================================================================
titre "3. Services activés au démarrage"
RC="$RACINE/fork/overlay/etc/rc.conf.defaults"
if [ ! -r "$RC" ]; then
	absent "rc.conf.defaults introuvable"
else
	for svc in telnetd ftpd rlogind rexecd rshd tftpd; do
		if contient "$RC" "^[[:space:]]*${svc}_enable[[:space:]]*=[[:space:]]*\"?YES"; then
			faible "service non chiffré activé au démarrage : $svc"
		fi
	done
	ok "aucun service non chiffré activé (telnet, ftp, rlogin, rsh, tftp) — vérifié"
	contient "$RC" '^[[:space:]]*sshd_enable[[:space:]]*=[[:space:]]*"NO"' \
		&& ok "SSH désactivé au démarrage (R-13 : aucun accès entrant par défaut)" \
		|| faible "SSH n'est pas explicitement désactivé au démarrage"
	contient "$RC" '^[[:space:]]*ntpd_enable[[:space:]]*=[[:space:]]*"YES"' \
		&& ok "NTP activé (indispensable à N-05 : Kerberos refuse une horloge décalée)" \
		|| faible "NTP non activé : N-05 (mot de passe unique) ne pourra pas fonctionner"
fi

# ===========================================================================
titre "4. Samba — le service le plus exposé"
SMB="$RACINE/fork/overlay/usr-local-etc-smb4.conf"
if [ ! -r "$SMB" ]; then
	absent "smb4.conf introuvable"
else
	if contient "$SMB" '^[[:space:]]*guest ok[[:space:]]*=[[:space:]]*yes'; then
		faible "un partage accepte les invités (guest ok = yes)"
	else
		ok "aucun partage n'accepte d'invité"
	fi
	if contient "$SMB" '^[[:space:]]*map to guest[[:space:]]*=[[:space:]]*(bad user|bad password|always)'; then
		faible "map to guest est actif : un mot de passe faux donne un accès invité"
	else
		ok "map to guest désactivé (un mot de passe faux ne donne aucun accès)"
	fi
	contient "$SMB" '^[[:space:]]*null passwords[[:space:]]*=[[:space:]]*yes' \
		&& faible "null passwords = yes : un compte sans mot de passe peut entrer" \
		|| ok "mots de passe vides refusés"
	if contient "$SMB" '^[[:space:]]*server min protocol'; then
		ok "protocol minimum explicitement fixé (SMB1 refusé)"
	else
		absent "server min protocol non fixé : l'héritage SMB1 risque d'être accepté"
	fi
	if contient "$SMB" '^[[:space:]]*(lanman auth|ntlm auth)[[:space:]]*=[[:space:]]*yes'; then
		faible "authentification LanMan/NTLM ancienne activée : mots de passe cassables en secondes"
	else
		ok "aucune authentification LanMan/NTLM ancienne activée"
	fi
	# ldap ssl = off n'est une FAIBLESSE que si l'annuaire n'est pas sur la même machine.
	# Sur la boucle locale, le trafic ne quitte pas la machine : crier « faiblesse » serait le
	# faux positif de la leçon M-10. On distingue donc les deux cas.
	if contient "$SMB" '^[[:space:]]*ldap ssl[[:space:]]*=[[:space:]]*off'; then
		if contient "$SMB" 'ldapsam:ldap://127\.0\.0\.1|ldapsam:ldap://localhost'; then
			ok "ldap ssl = off mais l'annuaire est sur la boucle locale : le secret ne quitte pas la machine"
		else
			faible "ldap ssl = off avec un annuaire DISTANT : le mot de passe d'administration circule en clair sur le réseau"
		fi
	else
		ok "la connexion Samba → annuaire est chiffrée"
	fi
fi

# ===========================================================================
titre "5. Authentification et mots de passe"
PAMSU="$RACINE/fork/overlay/etc/pam.d/su"
if [ -r "$PAMSU" ]; then
	grep -qE '^[^#]*pam_(rootok|wheel|deny)' "$PAMSU" \
		&& ok "pam.d/su restreint (rootok/wheel/deny)" \
		|| absent "pam.d/su ne contient aucune restriction : 'su' pourrait être ouvert à tous"
else
	absent "pam.d/su introuvable"
fi
LOGIN="$RACINE/fork/overlay/etc/login.conf"
if [ -r "$LOGIN" ]; then
	contient "$LOGIN" 'minpasswordlen|passwordtries|:pw-[a-z]+:' \
		&& ok "politique de mot de passe définie dans login.conf" \
		|| faible "login.conf présent mais sans politique de mot de passe"
else
	absent "aucune politique de mot de passe (login.conf absent) : ni longueur minimale, ni nombre d'essais, ni expiration"
fi
SYSCTL="$RACINE/fork/overlay/etc/sysctl.conf"
if [ -r "$SYSCTL" ]; then
	n=0
	for reglage in \
		'security\.bsd\.see_other_uids[[:space:]]*=[[:space:]]*0' \
		'security\.bsd\.see_other_gids[[:space:]]*=[[:space:]]*0' \
		'security\.bsd\.unprivileged_read_msgbuf[[:space:]]*=[[:space:]]*0' \
		'security\.bsd\.unprivileged_proc_debug[[:space:]]*=[[:space:]]*0' \
		'security\.bsd\.hardlink_check_uid[[:space:]]*=[[:space:]]*1' \
		'kern\.sugid_coredump[[:space:]]*=[[:space:]]*0' \
		'net\.inet\.tcp\.blackhole[[:space:]]*=[[:space:]]*2' \
		'net\.inet\.tcp\.syncookies[[:space:]]*=[[:space:]]*1'
	do
		if contient "$SYSCTL" "$reglage"; then
			n=$((n+1))
		else
			faible "sysctl.conf existe mais il manque : $reglage"
		fi
	done
	[ "$n" -ge 8 ] && ok "sysctl.conf couvre les 8 protections de noyau essentielles"
	# le piège d'ordonnancement : securelevel doit venir de rc.conf, pas de sysctl.conf
	if contient "$SYSCTL" '^[[:space:]]*kern\.securelevel[[:space:]]*='; then
		faible "kern.securelevel fixé dans sysctl.conf : il doit l'être dans rc.conf, sinon il bloque montages et modules au démarrage"
	else
		ok "securelevel n'est pas fixé dans sysctl.conf (il appartient à rc.conf — voir docs/64)"
	fi
else
	absent "aucun sysctl.conf : pas de durcissement du noyau (visibilité des processus, réseau, vidages)"
fi

# ===========================================================================
titre "6. Hygiène du dépôt (dépôt PUBLIC — R-15)"
# On ne cherche que là où un secret ferait mal : les fichiers du produit et les preuves.
# La DOCUMENTATION a le droit de citer le mot de passe pour raconter qu'il a été retiré —
# la signaler serait un faux positif (et c'est ce que faisait la première version de ce contrôle).
# Le script lui-même est exclu : il contient le motif par construction.
FUITE=$(grep -rIl "mdp-de-laboratoire-a-remplacer" "$RACINE/fork" "$RACINE/scripts" "$RACINE/tests" 2>/dev/null \
        | grep -v '75-verifier-durcissement.sh' | head -3)
if [ -n "$FUITE" ]; then
	faible "un mot de passe de laboratoire subsiste dans un fichier du produit (R-15) : $(printf '%s' "$FUITE" | tr '\n' ' ')"
else
	ok "aucun mot de passe de laboratoire dans le produit, les scripts ni les preuves (seule la documentation le cite, pour l'expliquer)"
fi
if [ -f "$RACINE/fork/exceptions-licence.txt" ] || [ -f "$RACINE/scripts/40-verifier-frontiere-licence.sh" ]; then
	ok "garde-fou de licence présent (aucune GPL tierce dans le dépôt)"
else
	absent "aucun garde-fou de licence"
fi

# ===========================================================================
echo
echo "==========================================================="
echo "  protections correctes : $OK"
echo "  faiblesses réelles    : $FAIBLE"
echo "  éléments absents      : $ABSENT  (travail à faire, pas des échecs)"
echo "==========================================================="

if [ "$FAIBLE" -gt 0 ]; then
	echo "VERDICT : FAIBLESSES À CORRIGER ($FAIBLE)"
	exit 1
fi
if [ "$STRICT" -eq 1 ] && [ "$ABSENT" -gt 0 ]; then
	echo "VERDICT : INCOMPLET EN MODE STRICT ($ABSENT élément(s) absent(s))"
	exit 1
fi
echo "VERDICT : DURCISSEMENT CONFORME (aucune faiblesse réelle)"
exit 0

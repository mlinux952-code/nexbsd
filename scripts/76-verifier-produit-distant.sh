#!/bin/sh
# NexBSD — vérification du produit VU DE L'EXTÉRIEUR (depuis MINT, jamais depuis NexBSD).
#
# ORIGINE : docs/67. Répond à la question du responsable du 2026-10-29 : « peut-on vérifier tout
# NexBSD avec les outils des images ? » — OUI, mais avec une règle stricte :
#
#   >>> Les outils offensifs tournent SUR LA MACHINE QUI MESURE, JAMAIS sur la machine MESURÉE. <<<
#
# Ce script s'exécute donc sur MINT (ou n'importe quel poste du réseau), et observe une machine
# NexBSD allumée. Il ne modifie rien, n'exploite rien : il CONSTATE.
#
# Ce qu'il prouve, quand il passe :
#   - NexBSD répond (la machine est vivante) ;
#   - elle n'expose QUE les ports prévus par le produit ;
#   - les ports INTERDITS sont bien fermés (telnet, ftp, tftp, RDP, VNC, messagerie) ;
#   - un port fermé est MUET (pas de refus TCP) : c'est net.inet.tcp.blackhole=2 (A-74) ;
#   - SSH, s'il est ouvert, ne propose pas l'authentification par mot de passe.
#
# Ce qu'il ne prouve PAS : que les services fonctionnent (il faut Samba, LDAP, le bureau pour ça),
# ni que les données sont protégées, ni qu'aucune faille logicielle n'existe.
#
# Usage :
#   sh scripts/76-verifier-produit-distant.sh 192.168.122.50
#   sh scripts/76-verifier-produit-distant.sh 192.168.122.50 --attendu-ssh
#
#   Par défaut, SSH (22) est considéré FERMÉ, conformément à rc.conf.defaults (R-13).
#   --attendu-ssh déclare que l'administrateur l'a activé : le port devient attendu.

set -u

CIBLE="${1:-}"
ATTENDU_SSH=0
[ "${2:-}" = "--attendu-ssh" ] && ATTENDU_SSH=1

if [ -z "$CIBLE" ]; then
	echo "usage : sh $0 <adresse-ip-de-nexbsd> [--attendu-ssh]" >&2
	exit 2
fi

OK=0; ECHEC=0
ok()    { OK=$((OK+1));     echo "  [OK]    $*"; }
ko()    { ECHEC=$((ECHEC+1)); echo "  [ECHEC] $*"; }
info()  { echo "  ...     $*"; }

# --- ports attendus et interdits ---------------------------------------------
# attendus : le produit les ouvre (pf.conf prouvé T-05/T-05a)
ATTENDUS="445 139"
# 137/138 sont en UDP : traités à part
INTERDITS="21 23 25 69 80 110 111 135 143 161 389 512 513 514 636 993 995 2049 3306 3389 5432 5900"
[ "$ATTENDU_SSH" -eq 0 ] && INTERDITS="$INTERDITS 22"

echo "########## NexBSD — vérification vue de l'extérieur ##########"
echo "# cible     : $CIBLE"
echo "# depuis    : $(hostname 2>/dev/null || echo 'poste de mesure')"
echo "# date      : $(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo "# règle     : aucun outil offensif sur la machine mesurée. On constate, on n'attaque pas."

# --- 1. la machine est-elle vivante ? ----------------------------------------
echo
echo "--- 1. la machine répond-elle ? ---"
if ping -c 3 -W 2 "$CIBLE" >/dev/null 2>&1; then
	ok "NexBSD répond au ping (ICMP echo autorisé par pf.conf)"
else
	ko "aucune réponse au ping — machine éteinte, mauvaise adresse, ou pare-feu"
	info "sans machine vivante, le reste du contrôle n'a aucun sens : on s'arrête"
	exit 1
fi

# --- 2. y a-t-il un outil de scan ? ------------------------------------------
OUTIL=""
command -v nmap >/dev/null 2>&1 && OUTIL="nmap"
[ -z "$OUTIL" ] && command -v nc >/dev/null 2>&1 && OUTIL="nc"

scan_tcp() {
	# $1 = port ; renvoie 0 si ouvert
	case "$OUTIL" in
		nmap) nmap -Pn -p "$1" --host-timeout 12s "$CIBLE" 2>/dev/null | grep -qE "^$1/tcp +open" ;;
		nc)   nc -z -w 3 "$CIBLE" "$1" >/dev/null 2>&1 ;;
		*)    (exec 3<>"/dev/tcp/$CIBLE/$1") >/dev/null 2>&1 && { exec 3>&- 3<&-; return 0; } || return 1 ;;
	esac
}

if [ -n "$OUTIL" ]; then
	info "outil de mesure : $OUTIL"
else
	info "ni nmap ni nc : bascule sur /dev/tcp (moins fiable, mais utilisable)"
	OUTIL="devtcp"
fi

# --- 3. les ports ATTENDUS sont-ils ouverts ? --------------------------------
echo
echo "--- 2. les ports du produit sont-ils ouverts ? ---"
for p in $ATTENDUS; do
	if scan_tcp "$p"; then
		ok "port $p ouvert (attendu : le service de fichiers)"
	else
		ko "port $p FERMÉ (attendu ouvert) — soit Samba ne tourne pas, soit pf bloque"
	fi
done
if [ "$ATTENDU_SSH" -eq 1 ]; then
	if scan_tcp 22; then ok "port 22 ouvert (déclaré par --attendu-ssh)"; else ko "port 22 fermé alors qu'il était déclaré attendu"; fi
fi

# --- 4. les ports INTERDITS sont-ils fermés ? -------------------------------
echo
echo "--- 3. les ports interdits sont-ils bien fermés ? ---"
FUITE=0
for p in $INTERDITS; do
	if scan_tcp "$p"; then
		ko "port $p OUVERT — il devrait être fermé (surface d'attaque inutile)"
		FUITE=$((FUITE+1))
	fi
done
[ "$FUITE" -eq 0 ] && ok "aucun des 22 ports interdits n'est ouvert (telnet, ftp, tftp, RDP, VNC, messagerie, bases de données, NFS)"

# --- 5. un port fermé est-il MUET ? (preuve de net.inet.tcp.blackhole=2) -----
echo
echo "--- 4. un port fermé est-il muet ? (preuve du réglage noyau A-74) ---"
if command -v nc >/dev/null 2>&1; then
	# 9 est presque toujours fermé. S'il REFUSE (connexion refusée), blackhole ne s'applique pas.
	if nc -z -w 3 "$CIBLE" 9 >/dev/null 2>&1; then
		ko "le port 9 répond — inattendu, à examiner"
	else
		# on distingue « refusé » (RST immédiat) de « muet » (silence puis délai)
		DEBUT=$(date +%s)
		nc -z -w 3 "$CIBLE" 9 >/dev/null 2>&1
		DUREE=$(( $(date +%s) - DEBUT ))
		if [ "$DUREE" -ge 2 ]; then
			ok "port fermé MUET (silence de ${DUREE}s) : net.inet.tcp.blackhole=2 est actif"
		else
			ko "port fermé mais REFUSANT (réponse en ${DUREE}s) : blackhole ne s'applique pas — un scan devient facile"
		fi
	fi
else
	info "nc absent : contrôle du silence impossible, à faire depuis une machine qui l'a"
fi

# --- 6. SSH propose-t-il le mot de passe ? (si ouvert) ----------------------
echo
echo "--- 5. SSH, s'il est ouvert, refuse-t-il les mots de passe ? ---"
if scan_tcp 22; then
	if command -v ssh >/dev/null 2>&1; then
		BANNIERE=$(ssh -o BatchMode=yes -o StrictHostKeyChecking=no \
			-o ConnectTimeout=5 -o PreferredAuthentications=none \
			"nexbsd@$CIBLE" true 2>&1 | head -3)
		case "$BANNIERE" in
			*"Permission denied (publickey)"*) ok "SSH n'accepte QUE la clé publique (pas de mot de passe)" ;;
			*"password"*)  ko "SSH propose l'authentification par mot de passe — contraire à sshd_config.nexbsd" ;;
			*) info "réponse SSH non concluante : $(printf '%s' "$BANNIERE" | head -1)" ;;
		esac
	else
		info "client ssh absent du poste de mesure"
	fi
else
	info "port 22 fermé : R-13 respecté (aucun accès entrant par défaut). Rien à vérifier."
fi

# --- 7. SMB : quelle version parle-t-on ? -----------------------------------
echo
echo "--- 6. SMB refuse-t-il les protocoles anciens ? ---"
if command -v nmap >/dev/null 2>&1 && scan_tcp 445; then
	V=$(nmap -Pn -p 445 --script smb-protocols --host-timeout 40s "$CIBLE" 2>/dev/null | grep -iE "SMB [0-9]|NT LM" | head -6)
	if [ -n "$V" ]; then
		echo "$V" | sed 's/^/          /'
		case "$V" in
			*"SMBv1"*|*"NT LM 0.12"*) ko "SMB1 est proposé — contraire à server min protocol (C-48)" ;;
			*) ok "SMB1 non proposé" ;;
		esac
	else
		info "smb-protocols n'a rien renvoyé (script nmap indisponible ?)"
	fi
else
	info "nmap ou le port 445 absent : contrôle SMB sauté"
fi

# --- bilan -------------------------------------------------------------------
echo
echo "==========================================================="
echo "  constats conformes : $OK"
echo "  constats en défaut : $ECHEC"
echo "==========================================================="
echo
echo "  CE QUE CE CONTROLE NE DIT PAS :"
echo "   - il ne prouve aucun service (pour cela : se connecter à un partage, ouvrir le bureau) ;"
echo "   - il ne voit pas les failles logicielles (c'est pkg audit -F, À L'INTÉRIEUR) ;"
echo "   - il ne vérifie pas les fichiers du système (c'est freebsd-update IDS, À L'INTÉRIEUR) ;"
echo "   - il regarde la machine de dehors ; il ne juge pas ce qu'elle contient."

if [ "$ECHEC" -gt 0 ]; then
	echo "VERDICT : ECARTS DETECTES ($ECHEC)"
	exit 1
fi
echo "VERDICT : CONFORME VU DE L'EXTERIEUR"
exit 0

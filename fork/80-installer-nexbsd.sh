#!/bin/sh
# NexBSD — installeur : rendre la configuration VIVANTE (paquets, services, annuaire).
#
# POURQUOI CE SCRIPT EXISTE (2026-10-28)
#   `70-appliquer-overlay.sh` pose les fichiers de configuration, mais la configuration seule est
#   INERTE : sans slapd, samba et nslcd installés puis démarrés, il ne se passe rien. Les acquis
#   A-02 à A-06 sont dans cet état : « config écrite, aucun installeur ne l'applique ».
#   Ce script est cet installeur. Il tourne SUR le système NexBSD, une fois, en root.
#
# ÉTAT HONNÊTE : JAMAIS EXÉCUTÉ. Aucun système NexBSD n'existe encore (aucune image produite).
#   Les noms de paquets et certaines options sont marqués NON VÉRIFIÉ : ils viennent de la doc
#   FreeBSD, pas d'une exécution. Le script refuse de continuer dès qu'une vérification échoue,
#   plutôt que de laisser un système à moitié configuré.
#
# USAGE (sur le système NexBSD, en root)
#   NEXBSD_LDAP_ROOTPW='…' NEXBSD_LDAP_BINDPW='…' sh 80-installer-nexbsd.sh
#   option : --simulation   n'installe rien, vérifie seulement les préconditions
#
# CE QUE CE SCRIPT NE FAIT PAS
#   - il ne crée pas les comptes utilisateurs (ils viennent de l'annuaire, `install-annuaire-base.ldif`) ;
#   - il ne configure pas TLS sur LDAP (à décider, ADR à écrire) ;
#   - il ne choisit pas les mots de passe : ils sont FOURNIS, jamais inventés ni par défaut.
set -eu

SIMULATION="non"
for a in "$@"; do
	[ "$a" = "--simulation" ] && SIMULATION="oui"
done

ICI=$(cd "$(dirname "$0")" && pwd)

ok()   { echo "  [OK]    $*"; }
ko()   { echo "  [ECHEC] $*"; }
info() { echo "  ...     $*"; }
etape() { echo; echo "----- $* -----"; }

echo "########## NexBSD — installeur ##########"
echo "# date : $(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo "# mode : $([ "$SIMULATION" = oui ] && echo SIMULATION || echo REEL)"

# ---------------------------------------------------------------------------
etape "0. préconditions"
[ "$(uname -s)" = "FreeBSD" ] || { echo "ERREUR : cet installeur ne tourne que sur FreeBSD (système NexBSD)." >&2; exit 1; }
ok "système = FreeBSD"
[ "$(id -u)" -eq 0 ] || { echo "ERREUR : l'installation exige root." >&2; exit 1; }
ok "utilisateur = root"
command -v pkg >/dev/null 2>&1 || { echo "ERREUR : pkg introuvable (système NexBSD incomplet)." >&2; exit 1; }
ok "pkg présent"
[ -f "$ICI/70-appliquer-overlay.sh" ] || { echo "ERREUR : 70-appliquer-overlay.sh introuvable à côté de cet installeur." >&2; exit 1; }
ok "l'applicateur de configuration est présent"

# Refus de réinstaller par-dessus une installation existante (idempotence par le refus).
if [ -f /var/db/nexbsd-installe ] && [ "$SIMULATION" = non ]; then
	echo "ERREUR : NexBSD est déjà installé (marqueur /var/db/nexbsd-installe)." >&2
	echo "        Pour réinstaller volontairement : supprimer ce marqueur, en connaissance de cause." >&2
	exit 1
fi

# Mots de passe : fournis, jamais inventés, jamais par défaut.
: "${NEXBSD_LDAP_ROOTPW:?ERREUR : definir NEXBSD_LDAP_ROOTPW (mot de passe de l'admin de l'annuaire)}"
: "${NEXBSD_LDAP_BINDPW:?ERREUR : definir NEXBSD_LDAP_BINDPW (mot de passe de liaison Samba<->LDAP)}"
ok "mots de passe fournis par l'appelant"
case "$NEXBSD_LDAP_ROOTPW" in
	*'[mot de passe du banc'*) echo "ERREUR : valeur de laboratoire refusée (R-15 : ces valeurs sont brûlées)." >&2; exit 1 ;;
esac

LIBRE=$(df -k /usr/local 2>/dev/null | awk 'NR==2 {print int($4/1048576)}' || echo 0)
info "espace libre dans /usr/local : ${LIBRE} Go"
[ "${LIBRE:-0}" -ge 1 ] || { echo "ERREUR : moins de 1 Go libre." >&2; exit 1; }

if [ "$SIMULATION" = oui ]; then
	echo
	echo "SIMULATION : préconditions réunies. Rien n'a été installé."
	exit 0
fi

# ---------------------------------------------------------------------------
etape "1. paquets de la plateforme (NON VÉRIFIÉ : noms à confirmer sur 15.1)"
# openldap-server  : l'annuaire (A-03)
# samba419         : le partage authentifié (A-02, A-04) — le numéro de version peut changer
# nss-pam-ldapd    : les identités de l'annuaire côté système (A-06, C-14)
pkg install -y openldap-server samba419 nss-pam-ldapd || {
	ko "installation des paquets échouée"
	echo "          -> vérifier les noms disponibles : pkg search openldap / pkg search samba"
	exit 1
}
ok "paquets installés"

# ---------------------------------------------------------------------------
etape "2. SID du domaine (jamais figé à l'avance — leçon C-13)"
# On ne peut pas inventer le SID : il est créé par Samba à la première initialisation.
# Tenter de le fixer a déjà provoqué NT_STATUS_INTERNAL_DB_CORRUPTION au banc.
SID=$(net getlocalsid 2>/dev/null | sed -n 's/.*is: //p' | tr -d ' ')
case "$SID" in
	S-1-5-21-*) ok "SID obtenu : $SID" ;;
	*) ko "SID introuvable (net getlocalsid)"; echo "          -> Samba n'est pas initialisé ; ne PAS inventer de SID (C-13)."; exit 1 ;;
esac

# ---------------------------------------------------------------------------
etape "3. configuration du produit (fichiers + fusions)"
sh "$ICI/70-appliquer-overlay.sh" --systeme \
	-R "$NEXBSD_LDAP_ROOTPW" -b "$NEXBSD_LDAP_BINDPW" -p "$SID"
ok "configuration appliquée (11 fichiers, 2 fusions)"

# ---------------------------------------------------------------------------
etape "4. annuaire : initialisation de la base"
mkdir -p /var/db/openldap-data /var/run/openldap
chown -R ldap:ldap /var/db/openldap-data /var/run/openldap 2>/dev/null || true
sysrc slapd_enable=YES >/dev/null
service slapd start || { ko "slapd ne démarre pas"; exit 1; }
sleep 2
if ldapadd -x -D "cn=admin,dc=nexbsd,dc=local" -w "$NEXBSD_LDAP_ROOTPW" \
	-f /root/install-annuaire-base.ldif >/tmp/nexbsd-ldapadd.log 2>&1; then
	ok "annuaire initialisé (base, groupes, utilisateurs du LDIF)"
else
	ko "ldapadd a échoué — voir /tmp/nexbsd-ldapadd.log"
	tail -5 /tmp/nexbsd-ldapadd.log | sed 's/^/          /'
	exit 1
fi

# ---------------------------------------------------------------------------
etape "5. Samba : liaison avec l'annuaire, puis démarrage"
# smbpasswd -w enregistre le mot de passe de liaison que Samba utilise pour écrire dans LDAP.
printf '%s\n%s\n' "$NEXBSD_LDAP_BINDPW" "$NEXBSD_LDAP_BINDPW" | smbpasswd -w >/dev/null 2>&1 || {
	ko "smbpasswd -w a échoué"; exit 1; }
ok "mot de passe de liaison enregistré"
sysrc samba_server_enable=YES >/dev/null
service samba_server start || { ko "samba ne démarre pas"; exit 1; }
sleep 3

# ---------------------------------------------------------------------------
etape "6. identités système : nslcd (NSS + PAM)"
sysrc nslcd_enable=YES >/dev/null
service nslcd start || { ko "nslcd ne démarre pas"; exit 1; }
sleep 2

# ---------------------------------------------------------------------------
etape "7. vérifications — la configuration est-elle VIVANTE ?"
KO=0

# a) l'annuaire répond
if ldapsearch -x -H ldap://127.0.0.1 -b "dc=nexbsd,dc=local" -s base >/dev/null 2>&1; then
	ok "l'annuaire répond sur ldap://127.0.0.1"
else
	ko "l'annuaire ne répond pas"; KO=$((KO+1))
fi

# b) une identité de l'annuaire est visible par le système (le cœur de A-06)
if getent passwd omrane >/dev/null 2>&1; then
	ok "getent passwd omrane répond (identité issue de l'annuaire)"
else
	ko "getent passwd omrane ne répond pas — NSS ne consulte pas l'annuaire"; KO=$((KO+1))
fi

# c) Samba connaît le domaine
if net getdomainsid >/dev/null 2>&1; then
	ok "Samba connaît le domaine ($(net getdomainsid 2>/dev/null | tr -d '\n'))"
else
	ko "Samba ne connaît pas le domaine"; KO=$((KO+1))
fi

# d) le pare-feu est actif
if service pf status >/dev/null 2>&1; then
	ok "pf actif"
else
	info "pf non démarré (à faire : service pf start ; vérifier règle par règle avant d'activer)"
fi

# ---------------------------------------------------------------------------
echo
if [ "$KO" -eq 0 ]; then
	touch /var/db/nexbsd-installe
	echo "VERDICT : NexBSD est INSTALLÉ et la configuration est VIVANTE."
	echo "RESTE À FAIRE, humain et non automatisable ici :"
	echo "  1. changer les mots de passe des comptes du LDIF (ils viennent d'un exemple) ;"
	echo "  2. décider de TLS sur LDAP (aucun ADR n'existe) ;"
	echo "  3. vérifier le partage depuis UNE AUTRE machine (preuve A-02) ;"
	echo "  4. vérifier que 'su' demande un mot de passe (preuve A-14, toujours manquante)."
else
	echo "VERDICT : ÉCHEC — $KO vérification(s) en échec. Le système n'est PAS marqué installé."
	echo "         Aucun marqueur écrit : on peut relancer après correction."
	exit 1
fi

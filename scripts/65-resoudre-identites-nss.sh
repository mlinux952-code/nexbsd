#!/bin/sh
# 65-resoudre-identites-nss.sh — CORRECTIF DE C-14.
#
# Probleme constate (2026-10-25) :
#   add_local_groups: SID ...-1001 -> getpwuid(10000) failed, is nsswitch configured?
#   check_sam_security: make_server_info_sam() failed with 'NT_STATUS_NO_SUCH_USER'
#
# L'annuaire DELIVRE les identites (uid 10000 = omrane, gid 2001 = bureau) mais la
# MACHINE ne sait pas les resoudre : /etc/passwd ne contient pas d'uid 10000. Samba
# refuse donc la session, car il ne peut pas construire le jeton d'authentification.
#
# Correctif : nss-pam-ldapd (demon nslcd). Les recherches d'utilisateurs et de
# groupes interrogent l'annuaire APRES les fichiers locaux. Une seule source
# d'identites pour le systeme ET pour Samba — c'est le modele vise par NexBSD.
#
# A executer DANS la VM FreeBSD, en root. Idempotent. Reversible (restauration de
# /etc/nsswitch.conf en cas d'echec).
#
# Version 1 (2026-10-25).

ok()   { echo "  [OK]    $*"; }
ko()   { echo "  [ECHEC] $*"; }
info() { echo "  ...     $*"; }

SUFFIXE="dc=nexbsd,dc=local"
ADMIN_DN="cn=admin,$SUFFIXE"
ADMIN_PW="adminsecret"
NSSWITCH=/etc/nsswitch.conf
NSLCD_CONF=/usr/local/etc/nslcd.conf

echo "########## Correctif C-14 : le systeme resout les identites de l'annuaire ##########"
echo "# date : $(date -u +%FT%TZ) ; hote : $(uname -sr)"

# ---------------------------------------------------------------------------
echo
echo "########## BLOC A - etat des lieux ##########"
if ! pgrep -q slapd; then
    info "slapd arrete : demarrage"
    sysrc slapd_enable=YES >/dev/null 2>&1
    service slapd onestart >/dev/null 2>&1
fi
if pgrep -q slapd; then ok "slapd tourne"; else
    ko "slapd ne tourne pas : relancer scripts/60 d'abord"
    echo; echo "CORRECTIF : ECHEC - annuaire indisponible."; exit 1
fi

echo "--- avant correctif : la machine connait-elle uid 10000 ? ---"
if getent passwd 10000 >/dev/null 2>&1 && [ -n "$(getent passwd 10000 2>/dev/null)" ]; then
    ok "deja resolu : $(getent passwd 10000)"
    DEJA=1
else
    info "non resolu (c'est le defaut a corriger)"
    DEJA=0
fi

# ---------------------------------------------------------------------------
echo
echo "########## BLOC B - nss-pam-ldapd ##########"
if pkg info -e nss-pam-ldapd >/dev/null 2>&1; then
    ok "nss-pam-ldapd deja installe"
else
    info "installation de nss-pam-ldapd (paquet officiel FreeBSD)"
    env ASSUME_ALWAYS_YES=yes pkg install -y nss-pam-ldapd >/tmp/pkg-nslcd.log 2>&1
    if pkg info -e nss-pam-ldapd >/dev/null 2>&1; then
        ok "nss-pam-ldapd installe"
    else
        ko "installation impossible ; fin du journal :"
        tail -12 /tmp/pkg-nslcd.log
        echo; echo "CORRECTIF : ECHEC - paquet indisponible."
        exit 1
    fi
fi

# le compte de service nslcd
if pw usershow nslcd >/dev/null 2>&1; then
    ok "compte de service nslcd present"
else
    info "creation du compte de service nslcd"
    pw useradd -n nslcd -u 389 -c "nslcd" -d /nonexistent -s /usr/sbin/nologin >/dev/null 2>&1 \
        && ok "compte nslcd cree" || ko "compte nslcd non cree (nslcd pourrait refuser de demarrer)"
fi

# ---------------------------------------------------------------------------
echo
echo "########## BLOC C - configuration nslcd ##########"
[ -f "$NSLCD_CONF" ] && cp "$NSLCD_CONF" /tmp/nslcd.conf.avant 2>/dev/null
cat > "$NSLCD_CONF" <<CONF_NSLCD
# nslcd — NexBSD banc d'identites (laboratoire)
# Le systeme interroge l'annuaire pour les utilisateurs et les groupes POSIX.
uid nslcd
gid nslcd
uri ldap://127.0.0.1/
base $SUFFIXE
binddn $ADMIN_DN
bindpw $ADMIN_PW
scope sub
ldap_version 3
timelimit 10
bind_timelimit 5

# --- utilisateurs ---
filter passwd (&(objectClass=posixAccount)(uid=*))
map    passwd uid           uid
map    passwd uidNumber     uidNumber
map    passwd gidNumber     gidNumber
map    passwd gecos         cn
map    passwd homeDirectory homeDirectory
map    passwd loginShell    loginShell

# --- groupes ---
filter group (&(objectClass=posixGroup)(cn=*))
map    group gidNumber gidNumber
map    group memberUid memberUid
CONF_NSLCD
chmod 600 "$NSLCD_CONF"
ok "nslcd.conf ecrit (droits 600 : il contient un secret de laboratoire)"

# ---------------------------------------------------------------------------
echo
echo "########## BLOC D - nsswitch ##########"
cp "$NSSWITCH" /tmp/nsswitch.conf.avant
info "sauvegarde dans /tmp/nsswitch.conf.avant"

# on remplace les lignes passwd/group, en gardant 'files' en premier (securite :
# le root local et les comptes systeme restent resolus meme si l'annuaire tombe)
awk '
  /^passwd:/ { print "passwd: files ldap"; next }
  /^group:/  { print "group:  files ldap"; next }
  { print }
' /tmp/nsswitch.conf.avant > "$NSSWITCH"

if grep -q '^passwd:.*ldap' "$NSSWITCH" && grep -q '^group:.*ldap' "$NSSWITCH"; then
    ok "nsswitch.conf : passwd et group interrogent l'annuaire apres les fichiers"
else
    ko "nsswitch.conf non modifie : restauration"
    cp /tmp/nsswitch.conf.avant "$NSSWITCH"
    echo; echo "CORRECTIF : ECHEC - nsswitch inchange."; exit 1
fi
echo "--- lignes resultantes ---"
grep -E '^(passwd|group):' "$NSSWITCH"

sysrc nslcd_enable=YES >/dev/null 2>&1
service nslcd restart >/dev/null 2>&1 || service nslcd onestart >/dev/null 2>&1
sleep 2

# ---------------------------------------------------------------------------
echo
echo "########## BLOC E - VERIFICATION ##########"
if pgrep -q nslcd; then ok "nslcd tourne"; else
    ko "nslcd ne tourne pas : restauration de nsswitch"
    cp /tmp/nsswitch.conf.avant "$NSSWITCH"
    service nslcd stop >/dev/null 2>&1
    info "journal :"; tail -10 /var/log/messages 2>/dev/null | grep -i nslcd
    echo; echo "CORRECTIF : ECHEC - nslcd ne demarre pas (systeme laisse en etat)."; exit 1
fi

echo "--- uid 10000 (omrane, annuaire) ---"
P_UID=$(getent passwd 10000 2>/dev/null)
if [ -n "$P_UID" ]; then ok "resolu : $P_UID"; R1=1; else
    ko "uid 10000 toujours non resolu"
    info "test direct : nslcd debug"
    R1=0
fi

echo "--- uid 10002 (sara, annuaire uniquement) ---"
P_SARA=$(getent passwd 10002 2>/dev/null)
if [ -n "$P_SARA" ]; then ok "resolu : $P_SARA"; R2=1; else
    ko "uid 10002 non resolu"; R2=0
fi

echo "--- gid 2001 (groupe bureau) ---"
G_BUREAU=$(getent group 2001 2>/dev/null)
if [ -n "$G_BUREAU" ]; then ok "resolu : $G_BUREAU"; R3=1; else
    ko "gid 2001 non resolu"; R3=0
fi

if [ "$R1" = "0" ] || [ "$R2" = "0" ] || [ "$R3" = "0" ]; then
    ko "la resolution par l'annuaire ne fonctionne pas : restauration de nsswitch"
    cp /tmp/nsswitch.conf.avant "$NSSWITCH"
    service nslcd stop >/dev/null 2>&1
    echo; echo "CORRECTIF : ECHEC - la machine ne resout pas les identites de l'annuaire."
    echo "Pistes : mauvais binddn/mot de passe dans $NSLCD_CONF ;"
    echo "         annuaire non joignable en 127.0.0.1 ; journal nslcd."
    exit 1
fi

# ---------------------------------------------------------------------------
echo
echo "########## BLOC F - le service Samba repart avec ces identites ##########"
service samba_server restart >/dev/null 2>&1
i=0
while [ "$i" -lt 90 ]; do
    sockstat -4l 2>/dev/null | grep -q ':445 ' && break
    i=$((i+1)); sleep 1
done
if sockstat -4l 2>/dev/null | grep -q ':445 '; then
    ok "smbd ecoute (${i} s)"
else
    ko "smbd n'ecoute pas"; tail -8 /var/log/samba4/log.smbd 2>/dev/null
fi

echo "--- authentification reelle : omrane ---"
if smbclient //127.0.0.1/commun -U 'omrane%omranelab' -c 'ls' >/tmp/fix-omrane.out 2>&1; then
    ok "omrane s'authentifie et lit [commun]"
    R4=1
else
    ko "omrane toujours refuse :"; tail -6 /tmp/fix-omrane.out
    if grep -q 'NO_SUCH_USER' /tmp/fix-omrane.out; then
        info "NO_SUCH_USER persiste : verifier add_local_groups dans le journal"
    fi
    tail -6 /var/log/samba4/log.smbd 2>/dev/null
    R4=0
fi

echo "--- authentification reelle : sara ---"
if smbclient //127.0.0.1/public -U 'sara%saralab' -c 'ls' >/tmp/fix-sara.out 2>&1; then
    ok "sara s'authentifie et lit [public]"
    R5=1
else
    ko "sara refusee :"; tail -6 /tmp/fix-sara.out
    R5=0
fi

echo "--- les droits tiennent toujours (sara ne doit PAS ecrire dans commun) ---"
printf 'tentative de sara\n' > /tmp/x-sara.txt
if smbclient //127.0.0.1/commun -U 'sara%saralab' -c 'put /tmp/x-sara.txt x-sara.txt' >/tmp/fix-sara-commun.out 2>&1; then
    ko "sara a ecrit dans [commun] : les droits ne sont plus appliques"
    R6=0
else
    if grep -qiE 'ACCESS_DENIED|PERMISSION_DENIED|NT_STATUS_ACCESS' /tmp/fix-sara-commun.out; then
        ok "sara est bien refusee dans [commun] (refus explicite)"
        R6=1
    else
        ko "sara refusee, mais pas pour la bonne raison :"
        tail -4 /tmp/fix-sara-commun.out
        R6=0
    fi
fi

# ---------------------------------------------------------------------------
echo
echo "########## VERDICT ##########"
echo "Resolution NSS : uid10000=$R1 uid10002=$R2 gid2001=$R3 | SMB : omrane=$R4 sara=$R5 refus=$R6"
if [ "$R1$R2$R3$R4$R5$R6" = "111111" ]; then
    echo "C-14 : CORRIGE - la machine resout les identites de l'annuaire, Samba les accepte."
    echo
    echo "ETAPE SUIVANTE : rejouer T-04-G en entier pour un verdict propre :"
    echo "  cp /root/t04g.sh /root/t04g.sh 2>/dev/null; sh /tmp/t04g.sh avant"
    echo "  reboot"
    echo "  sh /root/t04g.sh apres"
else
    echo "C-14 : NON CORRIGE - voir les lignes [ECHEC] ci-dessus."
fi

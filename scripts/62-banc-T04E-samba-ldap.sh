#!/bin/sh
# 62-banc-T04E-samba-ldap.sh — T-04-E : Samba authentifie via l'annuaire OpenLDAP.
# À exécuter DANS la VM FreeBSD, en root. Idempotent.
# Prérequis : T-04 (scripts/60) déjà passé — slapd tourne, l'annuaire est peuplé.
# Secrets de LABORATOIRE uniquement (VM jetable, non exposée au réseau).

ok()   { echo "  [OK]    $*"; }
ko()   { echo "  [ECHEC] $*"; }
info() { echo "  ...     $*"; }

SUFFIXE="dc=nexbsd,dc=local"
ADMIN_DN="cn=admin,$SUFFIXE"
ADMIN_PW="adminsecret"
MDP_USER="omranelab"
CONF="/usr/local/etc/smb4.conf"

echo "################ T-04-E : Samba + annuaire ################"
echo "# date : $(date -u +%FT%TZ) ; hote : $(uname -sr)"

echo
echo "########## BLOC A - prerequis ##########"
if ! pgrep -q slapd; then
    info "slapd arrete : on le demarre"
    sysrc slapd_enable=YES >/dev/null 2>&1
    service slapd onestart >/dev/null 2>&1
fi
if pgrep -q slapd; then ok "slapd tourne"; else
    ko "slapd ne tourne pas : arret (relancer d'abord scripts/60)"
    echo; echo "T-04-E : ECHEC - annuaire indisponible."
    exit 1
fi
if ! pkg info 2>/dev/null | grep -q '^samba'; then
    info "samba absent : installation"
    env ASSUME_ALWAYS_YES=yes pkg install -y samba423 >/tmp/pkg-samba.log 2>&1
fi
if pkg info 2>/dev/null | grep -q '^samba'; then
    ok "samba present : $(pkg info | grep '^samba' | head -1 | awk '{print $1"-"$2}')"
else
    ko "samba ne s'installe pas ; fin du journal pkg :"
    tail -15 /tmp/pkg-samba.log
    echo; echo "T-04-E : ECHEC - client/serveur SMB indisponible."
    exit 1
fi

echo
echo "########## BLOC B - Samba a-t-il le support LDAP ? ##########"
if smbd -b 2>/dev/null | grep -qi 'WITH_LDAP'; then
    ok "support LDAP compile dans Samba"
    SUPPORT_LDAP=1
else
    info "smbd -b ne montre pas WITH_LDAP : la suite dira si ldapsam fonctionne"
    SUPPORT_LDAP=0
fi

echo
echo "########## BLOC C - schema samba dans l'annuaire ##########"
SCHEMA=""
for c in /usr/local/etc/openldap/schema/samba.schema \
         /usr/local/share/examples/samba/samba.schema \
         /usr/local/share/examples/samba4/samba.schema; do
    [ -f "$c" ] && SCHEMA="$c" && break
done
if [ -z "$SCHEMA" ]; then
    SCHEMA=$(find /usr/local -name samba.schema 2>/dev/null | head -1)
fi
if [ -n "$SCHEMA" ]; then
    ok "schema trouve : $SCHEMA"
    if [ "$SCHEMA" != "/usr/local/etc/openldap/schema/samba.schema" ]; then
        cp "$SCHEMA" /usr/local/etc/openldap/schema/samba.schema
        SCHEMA=/usr/local/etc/openldap/schema/samba.schema
        info "copie vers /usr/local/etc/openldap/schema/"
    fi
else
    ko "samba.schema introuvable : le compte ne pourra pas etre stocke dans l'annuaire"
fi

SLAPDCONF=/usr/local/etc/openldap/slapd.conf
if ! grep -q 'samba.schema' "$SLAPDCONF" 2>/dev/null; then
    cp "$SLAPDCONF" "/tmp/slapd.conf.avant-T04E" 2>/dev/null
    awk 'BEGIN{fait=0}
         /^database/ && !fait { print "include\t\t/usr/local/etc/openldap/schema/samba.schema"; fait=1 }
         { print }' "/tmp/slapd.conf.avant-T04E" > "$SLAPDCONF"
    ok "include du schema ajoute a slapd.conf"
else
    ok "schema deja inclus (relance)"
fi
service slapd restart >/dev/null 2>&1
sleep 2
if pgrep -q slapd; then ok "slapd redemarre avec le schema"; else
    ko "slapd ne redemarre pas avec le schema : restauration"
    cp /tmp/slapd.conf.avant-T04E "$SLAPDCONF" 2>/dev/null
    service slapd restart >/dev/null 2>&1
fi

echo
echo "########## BLOC D - conteneurs et domaine dans l'annuaire ##########"
cat > /tmp/samba-containers.ldif <<'LDIF'
dn: ou=groups,dc=nexbsd,dc=local
objectClass: organizationalUnit
ou: groups

dn: ou=computers,dc=nexbsd,dc=local
objectClass: organizationalUnit
ou: computers

dn: ou=idmap,dc=nexbsd,dc=local
objectClass: organizationalUnit
ou: idmap
LDIF
if ldapadd -x -D "$ADMIN_DN" -w "$ADMIN_PW" -f /tmp/samba-containers.ldif >/tmp/ldapadd2.log 2>&1; then
    ok "conteneurs samba crees"
elif grep -qi "already exists" /tmp/ldapadd2.log; then
    ok "conteneurs deja presents (relance)"
else
    ko "creation des conteneurs : voir /tmp/ldapadd2.log"
    tail -5 /tmp/ldapadd2.log
fi

echo
echo "########## BLOC E - configuration de Samba en ldapsam ##########"
[ -f "$CONF" ] && cp "$CONF" /tmp/smb4.conf.avant-T04E && info "smb4.conf sauvegarde dans /tmp"
mkdir -p /var/samba/partage
chmod 0777 /var/samba/partage
cat > "$CONF" <<CONF_SAMBA
[global]
   workgroup = NEXBSD
   netbios name = NEXBSDFS
   server string = NexBSD banc T-04-E
   security = user
   passdb backend = ldapsam:ldap://127.0.0.1
   ldap admin dn = $ADMIN_DN
   ldap suffix = $SUFFIXE
   ldap user suffix = ou=people
   ldap group suffix = ou=groups
   ldap machine suffix = ou=computers
   ldap idmap suffix = ou=idmap
   ldap ssl = off
   ldap passwd sync = no
   log level = 1

[partage]
   path = /var/samba/partage
   read only = no
   guest ok = no
CONF_SAMBA
ok "smb4.conf ecrit (passdb = ldapsam)"

if smbpasswd -w "$ADMIN_PW" >/tmp/smbpasswd-w.log 2>&1; then
    ok "mot de passe d'administration LDAP enregistre dans secrets.tdb"
else
    ko "smbpasswd -w a echoue :"
    tail -5 /tmp/smbpasswd-w.log
fi

if pdbedit -L 2>/dev/null | grep -q '^omrane:'; then
    info "compte omrane deja dans la passdb"
    printf '%s\n%s\n' "$MDP_USER" "$MDP_USER" | smbpasswd -s omrane >/tmp/smbpasswd-a.log 2>&1 \
        && ok "mot de passe SMB mis a jour" || { ko "smbpasswd (mise a jour) :"; tail -5 /tmp/smbpasswd-a.log; }
else
    printf '%s\n%s\n' "$MDP_USER" "$MDP_USER" | smbpasswd -s -a omrane >/tmp/smbpasswd-a.log 2>&1
    if [ $? -eq 0 ]; then
        ok "compte omrane ajoute a la passdb (stockee dans l'annuaire)"
    else
        ko "smbpasswd -a a echoue :"
        tail -10 /tmp/smbpasswd-a.log
    fi
fi

sysrc samba_server_enable=YES >/dev/null 2>&1
service samba_server restart >/dev/null 2>&1 || service samba_server onestart >/dev/null 2>&1
sleep 3
if pgrep -q smbd; then ok "smbd tourne"; else ko "smbd ne tourne pas"; fi

echo
echo "########## BLOC F - PREUVES ##########"
echo
echo "----- preuve 1 : le compte vu par Samba (pdbedit) -----"
pdbedit -L -v omrane 2>&1 | tee /tmp/pdbedit.out | head -12
if grep -qi 'User SID' /tmp/pdbedit.out; then
    ok "Samba connait omrane avec un SID"
    P1=1
else
    ko "Samba ne remonte pas le compte"
    P1=0
fi

echo
echo "----- preuve 2 : les attributs Samba sont DANS l'annuaire -----"
ldapsearch -x -b "$SUFFIXE" '(uid=omrane)' sambaSID sambaPrimaryGroupSID 2>&1 | tee /tmp/ldap-samba.out | head -14
if grep -qi 'sambaSID:' /tmp/ldap-samba.out; then
    ok "l'annuaire contient le SID du compte (le mot de passe vit dans l'annuaire)"
    P2=1
else
    ko "aucun attribut samba dans l'annuaire"
    P2=0
fi

echo
echo "----- preuve 3 : authentification reelle en SMB -----"
smbclient //127.0.0.1/partage -U "omrane%$MDP_USER" -c 'ls' >/tmp/smbclient.out 2>&1
if [ $? -eq 0 ]; then
    ok "authentification SMB reussie via l'annuaire"
    head -6 /tmp/smbclient.out
    P3=1
else
    ko "authentification SMB refusee :"
    tail -6 /tmp/smbclient.out
    P3=0
fi

echo
echo "########## VERDICT ##########"
if [ "$P1" = "1" ] && [ "$P2" = "1" ] && [ "$P3" = "1" ]; then
    echo "T-04-E : REUSSI - Samba authentifie omrane via OpenLDAP."
elif [ "$P1" = "1" ] && [ "$P2" = "1" ]; then
    echo "T-04-E : PARTIEL - compte et SID dans l'annuaire, mais authentification SMB non prouvee."
else
    echo "T-04-E : ECHEC - voir les lignes [ECHEC] ci-dessus."
fi
echo
echo "Pour transmettre le resultat :  cat /tmp/pdbedit.out /tmp/ldap-samba.out /tmp/smbclient.out"

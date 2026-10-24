#!/bin/sh
# 62-banc-T04E-samba-ldap.sh — T-04-E : Samba authentifie via l'annuaire OpenLDAP.
# Version 2 (2026-10-24) — corrige trois defauts constates lors du 1er essai :
#   1. le paquet FreeBSD samba423 ne livre PAS samba.schema -> telechargement
#      depuis le depot officiel Samba, avec empreinte SHA256 verifiee ;
#   2. le script v1 ajoutait la ligne include meme sans schema -> slapd cassait ;
#      desormais on valide slapd.conf avec slaptest AVANT tout redemarrage ;
#   3. detection du support LDAP de Samba par ldd + liste du paquet, pas par 'smbd -b'.
# Le schema reste GPL (Samba) : il n'entre jamais dans le depot NexBSD, il est
# telecharge a l'execution dans la VM de laboratoire.
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
SCHEMA_URL="https://git.samba.org/?p=samba.git;a=blob_plain;f=examples/LDAP/samba.schema;hb=HEAD"
SCHEMA_SHA="b9081b7234762c3fc02861fbb88ed8b52a523dced38e15051dc980f0b34b23dd"
SCHEMA_DST="/usr/local/etc/openldap/schema/samba.schema"

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
SUPPORT_LDAP=0
if pkg info -l 2>/dev/null | grep -q 'libsmbldap.so'; then
    ok "modules LDAP livres par le paquet (libsmbldap.so)"
    SUPPORT_LDAP=1
fi
if ldd "$(command -v smbd)" 2>/dev/null | grep -qi 'libldap'; then
    ok "smbd est lie a libldap"
    SUPPORT_LDAP=1
fi
if [ "$SUPPORT_LDAP" = "0" ]; then
    ko "ce Samba ne semble pas compile avec LDAP : passdb ldapsam impossible"
    echo
    echo "T-04-E : ECHEC - Samba sans support LDAP (paquet a reconstruire avec l'option LDAP)."
    exit 1
fi

echo
echo "########## BLOC C - schema samba dans l'annuaire ##########"
if [ -f "$SCHEMA_DST" ] && grep -q 'sambaDomainName' "$SCHEMA_DST" 2>/dev/null; then
    ok "schema deja present : $SCHEMA_DST"
else
    info "telechargement du schema depuis le depot officiel Samba"
    fetch -q -o /tmp/samba.schema "$SCHEMA_URL" 2>/tmp/fetch-schema.log \
        || curl -sL -o /tmp/samba.schema "$SCHEMA_URL" 2>>/tmp/fetch-schema.log
    if [ -s /tmp/samba.schema ] && grep -q 'sambaDomainName' /tmp/samba.schema; then
        GOT=$(sha256 -q /tmp/samba.schema 2>/dev/null)
        if [ "$GOT" = "$SCHEMA_SHA" ]; then
            ok "schema telecharge, empreinte SHA256 verifiee"
            cp /tmp/samba.schema "$SCHEMA_DST"
        else
            ko "empreinte differente : attendu $SCHEMA_SHA"
            info "obtenu : $GOT"
            info "le schema n'est PAS installe (provenance non verifiee)"
            SCHEMA_OK=0
        fi
    else
        ko "telechargement du schema impossible (voir /tmp/fetch-schema.log)"
        SCHEMA_OK=0
    fi
fi
[ -f "$SCHEMA_DST" ] && grep -q 'sambaDomainName' "$SCHEMA_DST" 2>/dev/null && SCHEMA_OK=1

SLAPDCONF=/usr/local/etc/openldap/slapd.conf
if [ "${SCHEMA_OK:-0}" != "1" ]; then
    ko "sans schema, Samba ne peut pas stocker le compte : arret propre"
    echo
    echo "T-04-E : ECHEC - schema samba indisponible (annuaire laisse intact)."
    exit 1
fi

if ! grep -q 'samba.schema' "$SLAPDCONF" 2>/dev/null; then
    cp "$SLAPDCONF" /tmp/slapd.conf.avant-T04E
    awk 'BEGIN{fait=0}
         /^database/ && !fait { print "include\t\t/usr/local/etc/openldap/schema/samba.schema"; fait=1 }
         { print }' /tmp/slapd.conf.avant-T04E > "$SLAPDCONF"
    ok "include du schema ajoute a slapd.conf"
else
    ok "schema deja inclus (relance)"
fi

SLAPTEST=$(command -v slaptest || echo /usr/local/sbin/slaptest)
if [ -x "$SLAPTEST" ]; then
    if "$SLAPTEST" -f "$SLAPDCONF" -u >/tmp/slaptest.log 2>&1; then
        ok "slaptest valide la configuration"
    else
        ko "slaptest refuse la configuration : restauration"
        tail -5 /tmp/slaptest.log
        cp /tmp/slapd.conf.avant-T04E "$SLAPDCONF" 2>/dev/null
        echo
        echo "T-04-E : ECHEC - configuration OpenLDAP invalide (restauree)."
        exit 1
    fi
else
    info "slaptest introuvable : on redemarre a l'aveugle"
fi

service slapd restart >/dev/null 2>&1
sleep 2
if pgrep -q slapd; then
    ok "slapd redemarre avec le schema"
else
    ko "slapd ne redemarre pas : restauration"
    cp /tmp/slapd.conf.avant-T04E "$SLAPDCONF" 2>/dev/null
    service slapd restart >/dev/null 2>&1
    echo
    echo "T-04-E : ECHEC - slapd refuse de demarrer (configuration restauree)."
    exit 1
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

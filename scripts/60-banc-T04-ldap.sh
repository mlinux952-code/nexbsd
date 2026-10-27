#!/bin/sh
# 60-banc-T04-ldap.sh — T-04 : annuaire OpenLDAP sur FreeBSD (banc de test).
# À exécuter DANS la VM FreeBSD, en root.
# Idempotent : peut être relancé sans casser l'existant.
# Ne s'arrête pas au premier échec : il rapporte tout, puis donne un VERDICT.
# Secrets de LABORATOIRE uniquement (VM jetable, non exposée au réseau).

ok()   { echo "  [OK]    $*"; }
ko()   { echo "  [ECHEC] $*"; }
info() { echo "  ...     $*"; }

echo "################ T-04 : annuaire OpenLDAP ################"
echo "# date : $(date -u +%FT%TZ) ; hote : $(uname -sr)"

echo
echo "########## BLOC A - reseau ##########"
if fetch -q -o /dev/null http://pkg.freebsd.org/ 2>/dev/null; then
    ok "internet joignable"
else
    ko "pas d'internet : arret"
    exit 1
fi
if pw usershow omrane >/dev/null 2>&1; then
    info "compte omrane deja present"
else
    pw useradd -n omrane -m -s /bin/sh -G wheel && ok "compte omrane cree (mot de passe : passwd omrane)"
fi

echo
echo "########## BLOC B - installation ##########"
DEBUT=$(date +%s)
env ASSUME_ALWAYS_YES=yes pkg update -q -f >/dev/null 2>&1 && ok "catalogues a jour"
if env ASSUME_ALWAYS_YES=yes pkg install -y openldap26-server openldap26-client >/tmp/pkg.log 2>&1; then
    ok "openldap26 installe en $(( $(date +%s) - DEBUT )) s"
else
    ko "installation echouee ; fin du journal pkg :"
    tail -15 /tmp/pkg.log
fi
pkg info openldap26-server >/dev/null 2>&1 && ok "paquet openldap26-server present"

echo
echo "########## BLOC C - configuration ##########"
mkdir -p /var/db/openldap-data /var/run/openldap
cat > /usr/local/etc/openldap/slapd.conf <<'CONF'
include		/usr/local/etc/openldap/schema/core.schema
include		/usr/local/etc/openldap/schema/cosine.schema
include		/usr/local/etc/openldap/schema/inetorgperson.schema
include		/usr/local/etc/openldap/schema/nis.schema
pidfile		/var/run/openldap/slapd.pid
argsfile	/var/run/openldap/slapd.args
database	mdb
maxsize		1073741824
suffix		"dc=nexbsd,dc=local"
rootdn		"cn=admin,dc=nexbsd,dc=local"
rootpw		adminsecret
directory	/var/db/openldap-data
index		objectClass eq
CONF
chown -R ldap:ldap /var/db/openldap-data /var/run/openldap
ok "slapd.conf ecrit"

sysrc slapd_enable=YES >/dev/null 2>&1
service slapd onestop >/dev/null 2>&1
if service slapd onestart >/dev/null 2>&1; then
    ok "slapd demarre"
else
    info "echec au demarrage : on ajoute le module mdb explicitement"
    cp /usr/local/etc/openldap/slapd.conf /tmp/slapd.conf.bak
    { echo "moduleload	back_mdb"; cat /tmp/slapd.conf.bak; } > /usr/local/etc/openldap/slapd.conf
    if service slapd onestart >/dev/null 2>&1; then
        ok "slapd demarre (module mdb charge)"
    else
        ko "slapd ne demarre pas ; essai manuel :"
        /usr/local/libexec/slapd -d 1 2>&1 | head -20
    fi
fi
sleep 2
if pgrep -q slapd; then ok "processus slapd present"; else ko "aucun processus slapd"; fi
sockstat -4 -l 2>/dev/null | grep ':389' && ok "port 389 a l'ecoute" || info "port 389 non vu en IPv4"

echo
echo "########## BLOC D - peuplement et verification ##########"
cat > /tmp/base.ldif <<'LDIF'
dn: dc=nexbsd,dc=local
objectClass: dcObject
objectClass: organization
o: NexBSD
dc: nexbsd

dn: ou=people,dc=nexbsd,dc=local
objectClass: organizationalUnit
ou: people

dn: uid=omrane,ou=people,dc=nexbsd,dc=local
objectClass: inetOrgPerson
objectClass: posixAccount
uid: omrane
cn: Omrane
sn: Omrane
uidNumber: 10000
gidNumber: 10000
homeDirectory: /home/omrane
loginShell: /bin/sh
LDIF

if ldapadd -x -D "cn=admin,dc=nexbsd,dc=local" -w adminsecret -f /tmp/base.ldif >/tmp/ldapadd.log 2>&1; then
    ok "arborescence importee"
else
    if grep -qi "already exists" /tmp/ldapadd.log; then
        ok "arborescence deja presente (relance)"
    else
        ko "ldapadd a echoue :"
        cat /tmp/ldapadd.log
    fi
fi

echo
echo "---------- PREUVE : ldapsearch ----------"
ldapsearch -x -b "dc=nexbsd,dc=local" '(uid=omrane)' cn uid uidNumber 2>&1 | tee /tmp/ldapsearch.out
if grep -q "uidNumber: 10000" /tmp/ldapsearch.out; then
    ok "l'annuaire retourne l'utilisateur omrane"
else
    ko "l'annuaire ne retourne pas l'utilisateur"
fi

echo
echo "########## VERDICT ##########"
RES=0
pkg info openldap26-server >/dev/null 2>&1 || RES=1
pgrep -q slapd || RES=1
grep -q "uidNumber: 10000" /tmp/ldapsearch.out || RES=1
if [ "$RES" -eq 0 ]; then
    echo "T-04 : REUSSI - OpenLDAP operationnel, annuaire peuple et interrogeable."
else
    echo "T-04 : ECHEC PARTIEL - voir les lignes [ECHEC] ci-dessus."
fi
echo
echo "Pour transmettre le resultat :  cat /tmp/ldapsearch.out"

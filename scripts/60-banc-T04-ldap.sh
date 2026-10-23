#!/bin/sh
# 60-banc-T04-ldap.sh — protocole T-04 : annuaire OpenLDAP dans la VM de test.
# À exécuter DANS la VM FreeBSD, en root. Découpé en blocs pour que chaque étape
# soit vérifiable avant de passer à la suivante.
#
# ATTENTION : mots de passe de LABORATOIRE uniquement. Cette VM n'est pas exposée
# et ne doit contenir aucune donnée réelle.
set -eu

echo "=== BLOC A — identités et réseau ==="
pw useradd -n omrane -m -s /bin/sh -G wheel 2>/dev/null || echo "utilisateur déjà présent"
echo "→ définir le mot de passe de omrane :"; passwd omrane || true
ifconfig vtnet0 inet
fetch -q -o /dev/null http://pkg.freebsd.org/ && echo "INTERNET_OK" || echo "PAS D'INTERNET"

echo "=== BLOC B — installation (plusieurs minutes) ==="
env ASSUME_ALWAYS_YES=yes pkg update -f
env ASSUME_ALWAYS_YES=yes pkg install -y openldap26-server openldap26-client

echo "=== BLOC C — configuration de l'annuaire ==="
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
mkdir -p /var/db/openldap-data
chown -R ldap:ldap /var/db/openldap-data
sysrc slapd_enable=YES
service slapd restart
sleep 2
service slapd status && echo "SLAPD_OK"

echo "=== BLOC D — peuplement et vérification ==="
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
ldapadd -x -D "cn=admin,dc=nexbsd,dc=local" -w adminsecret -f /tmp/base.ldif
echo "--- vérification :"
ldapsearch -x -b "dc=nexbsd,dc=local" '(uid=omrane)' cn uidNumber

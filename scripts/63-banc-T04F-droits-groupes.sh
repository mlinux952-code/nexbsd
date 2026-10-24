#!/bin/sh
# 63-banc-T04F-droits-groupes.sh — T-04-F : les DROITS sont decides par des
# groupes qui vivent dans l'annuaire, pas par des comptes locaux.
#
# Objectif (axe reseau facon NetWare, docs/14) : apres T-04-E (Samba authentifie
# via l'annuaire), prouver la brique suivante — un utilisateur qui n'existe QUE
# dans l'annuaire est authentifie, et son ACCES aux partages est decide par son
# GROUPE, egalement defini dans l'annuaire.
#
# Principe technique : ldapsam:trusted = yes fait que Samba prend l'uid, le gid et
# les appartenances DIRECTEMENT dans l'annuaire (posixAccount / posixGroup), sans
# passer par le systeme local (NSS). Les droits fichiers restent des droits POSIX
# classiques (proprietaire / groupe / autres) : ce sont les identifiants de
# l'annuaire qui les alimentent. Les ACL NT viendront dans un test ulterieur.
#
# A executer DANS la VM FreeBSD, en root. Idempotent.
# Prerequis : scripts/60 (T-04) et scripts/62 (T-04-E) deja passes.
# Secrets de LABORATOIRE uniquement (VM jetable, non exposee au reseau).
#
# Version 1 (2026-10-24).

ok()   { echo "  [OK]    $*"; }
ko()   { echo "  [ECHEC] $*"; }
info() { echo "  ...     $*"; }

SUFFIXE="dc=nexbsd,dc=local"
ADMIN_DN="cn=admin,$SUFFIXE"
ADMIN_PW="adminsecret"
MDP_OMRANE="omranelab"
MDP_SARA="saralab"
GID_BUREAU=2001
GID_STAGIAIRES=2002
UID_OMRANE=10000
UID_SARA=10002
CONF="/usr/local/etc/smb4.conf"

echo "############## T-04-F : droits par groupes de l'annuaire ##############"
echo "# date : $(date -u +%FT%TZ) ; hote : $(uname -sr)"

# ---------------------------------------------------------------------------
# BLOC A — prerequis : l'annuaire et T-04-E doivent etre en place
# ---------------------------------------------------------------------------
echo
echo "########## BLOC A - prerequis ##########"
if ! pgrep -q slapd; then
    info "slapd arrete : demarrage"
    sysrc slapd_enable=YES >/dev/null 2>&1
    service slapd onestart >/dev/null 2>&1
fi
if pgrep -q slapd; then ok "slapd tourne"; else
    ko "slapd ne tourne pas : relancer d'abord scripts/60"
    echo; echo "T-04-F : ECHEC - annuaire indisponible."
    exit 1
fi

if ! pkg info 2>/dev/null | grep -q '^samba'; then
    ko "samba absent : relancer d'abord scripts/62"
    echo; echo "T-04-F : ECHEC - Samba indisponible."
    exit 1
fi
if ! ldapsearch -x -b "$SUFFIXE" '(uid=omrane)' sambaSID 2>/dev/null | grep -q 'sambaSID:'; then
    ko "le compte omrane n'a pas de sambaSID dans l'annuaire"
    info "c'est le resultat de T-04-E : relancer scripts/62 avant ce test"
    echo; echo "T-04-F : ECHEC - T-04-E non acquis sur ce banc."
    exit 1
fi
ok "T-04-E acquis : omrane a un sambaSID dans l'annuaire"

SID_DOMAINE=$(net getlocalsid 2>/dev/null | awk '{print $NF}')
if [ -n "$SID_DOMAINE" ]; then ok "SID du domaine : $SID_DOMAINE"; else
    info "SID du domaine non lu par net getlocalsid (non bloquant)"
fi

# ---------------------------------------------------------------------------
# BLOC B — les groupes dans l'annuaire
# ---------------------------------------------------------------------------
echo
echo "########## BLOC B - groupes dans l'annuaire ##########"
cat > /tmp/t04f-groupes.ldif <<'LDIF'
dn: cn=bureau,ou=groups,dc=nexbsd,dc=local
objectClass: top
objectClass: posixGroup
cn: bureau
gidNumber: 2001
description: Groupe bureau - ecriture autorisee sur le partage commun

dn: cn=stagiaires,ou=groups,dc=nexbsd,dc=local
objectClass: top
objectClass: posixGroup
cn: stagiaires
gidNumber: 2002
description: Groupe stagiaires - aucun droit sur le partage commun
LDIF
if ldapadd -x -D "$ADMIN_DN" -w "$ADMIN_PW" -f /tmp/t04f-groupes.ldif >/tmp/t04f-ldapadd.log 2>&1; then
    ok "groupes bureau ($GID_BUREAU) et stagiaires ($GID_STAGIAIRES) crees"
elif grep -qi 'already exists' /tmp/t04f-ldapadd.log; then
    ok "groupes deja presents (relance)"
else
    ko "creation des groupes : voir /tmp/t04f-ldapadd.log"
    tail -6 /tmp/t04f-ldapadd.log
fi

# appartenances (replace = idempotent)
cat > /tmp/t04f-membres.ldif <<'LDIF'
dn: cn=bureau,ou=groups,dc=nexbsd,dc=local
changetype: modify
replace: memberUid
memberUid: omrane
-
dn: cn=stagiaires,ou=groups,dc=nexbsd,dc=local
changetype: modify
replace: memberUid
memberUid: sara
-
LDIF
if ldapmodify -x -D "$ADMIN_DN" -w "$ADMIN_PW" -f /tmp/t04f-membres.ldif >/tmp/t04f-ldapmod.log 2>&1; then
    ok "appartenances fixees : bureau <- omrane ; stagiaires <- sara"
else
    ko "appartenances non ecrites : voir /tmp/t04f-ldapmod.log"
    tail -6 /tmp/t04f-ldapmod.log
fi

# ---------------------------------------------------------------------------
# BLOC C — un utilisateur qui n'existe QUE dans l'annuaire
# ---------------------------------------------------------------------------
echo
echo "########## BLOC C - sara, dans l'annuaire seulement ##########"
if ldapsearch -x -b "$SUFFIXE" '(uid=sara)' uid >/dev/null 2>&1 && \
   ldapsearch -x -b "$SUFFIXE" '(uid=sara)' uid 2>/dev/null | grep -q 'uid: sara'; then
    ok "entree uid=sara deja presente (relance)"
else
    cat > /tmp/t04f-sara.ldif <<LDIF
dn: uid=sara,ou=people,$SUFFIXE
objectClass: top
objectClass: person
objectClass: organizationalPerson
objectClass: inetOrgPerson
objectClass: posixAccount
cn: Sara Test
sn: Test
uid: sara
uidNumber: $UID_SARA
gidNumber: $GID_STAGIAIRES
homeDirectory: /home/sara
loginShell: /bin/sh
userPassword: $MDP_SARA
LDIF
    if ldapadd -x -D "$ADMIN_DN" -w "$ADMIN_PW" -f /tmp/t04f-sara.ldif >/tmp/t04f-sara.log 2>&1; then
        ok "entree uid=sara creee dans l'annuaire (uidNumber $UID_SARA, gidNumber $GID_STAGIAIRES)"
    else
        ko "creation de sara : voir /tmp/t04f-sara.log"
        tail -6 /tmp/t04f-sara.log
    fi
fi

# preuve negative indispensable : sara ne doit PAS exister dans le systeme local
if pw usershow sara >/dev/null 2>&1; then
    ko "sara existe DEJA comme compte local : le test perdrait son sens"
    info "supprimer le compte local (pw userdel sara) puis relancer"
    SARA_LOCALE=1
else
    ok "sara n'existe PAS dans le systeme local (identite d'annuaire uniquement)"
    SARA_LOCALE=0
fi

# mot de passe Samba -> ecrit les attributs samba* dans l'annuaire
if pdbedit -L 2>/dev/null | grep -q '^sara:'; then
    printf '%s\n%s\n' "$MDP_SARA" "$MDP_SARA" | smbpasswd -s sara >/tmp/t04f-smbpasswd.log 2>&1 \
        && ok "mot de passe SMB de sara mis a jour" \
        || { ko "smbpasswd (mise a jour de sara) :"; tail -5 /tmp/t04f-smbpasswd.log; }
else
    printf '%s\n%s\n' "$MDP_SARA" "$MDP_SARA" | smbpasswd -s -a sara >/tmp/t04f-smbpasswd.log 2>&1
    if [ $? -eq 0 ]; then
        ok "sara ajoutee a la passdb (attributs samba* ecrits dans l'annuaire)"
    else
        ko "smbpasswd -a sara a echoue :"
        tail -8 /tmp/t04f-smbpasswd.log
    fi
fi

if ldapsearch -x -b "$SUFFIXE" '(uid=sara)' sambaSID 2>/dev/null | grep -q 'sambaSID:'; then
    ok "sara possede un sambaSID dans l'annuaire"
    SARA_SID=1
else
    ko "sara n'a pas de sambaSID : l'annuaire ne la connait pas comme compte Samba"
    SARA_SID=0
fi

# ---------------------------------------------------------------------------
# BLOC D — groupes POSIX des comptes et espaces partages
# ---------------------------------------------------------------------------
echo
echo "########## BLOC D - identifiants et espaces partages ##########"
cat > /tmp/t04f-gid.ldif <<LDIF
dn: uid=omrane,ou=people,$SUFFIXE
changetype: modify
replace: gidNumber
gidNumber: $GID_BUREAU
-
LDIF
if ldapmodify -x -D "$ADMIN_DN" -w "$ADMIN_PW" -f /tmp/t04f-gid.ldif >/tmp/t04f-gid.log 2>&1; then
    ok "omrane rattache au groupe bureau (gidNumber $GID_BUREAU) dans l'annuaire"
else
    ko "gidNumber d'omrane non modifie : voir /tmp/t04f-gid.log"
    tail -5 /tmp/t04f-gid.log
fi

mkdir -p /var/samba/commun /var/samba/public
chown root:"$GID_BUREAU" /var/samba/commun
chmod 2770 /var/samba/commun
chown root:wheel /var/samba/public
chmod 0755 /var/samba/public
printf 'Fichier lisible par tout compte authentifie.\n' > /var/samba/public/lisez-moi.txt
chown root:wheel /var/samba/public/lisez-moi.txt
chmod 0644 /var/samba/public/lisez-moi.txt
ok "espaces prets : /var/samba/commun (root:$GID_BUREAU 2770), /var/samba/public (0755)"

# ---------------------------------------------------------------------------
# BLOC E — configuration Samba : les identifiants viennent de l'annuaire
# ---------------------------------------------------------------------------
echo
echo "########## BLOC E - smb4.conf : ldapsam:trusted ##########"
[ -f "$CONF" ] && cp "$CONF" /tmp/smb4.conf.avant-T04F && info "smb4.conf sauvegarde dans /tmp"
cat > "$CONF" <<CONF_SAMBA
[global]
   workgroup = NEXBSD
   netbios name = NEXBSDFS
   server string = NexBSD banc T-04-F
   security = user
   passdb backend = ldapsam:ldap://127.0.0.1
   ldapsam:trusted = yes
   ldap admin dn = $ADMIN_DN
   ldap suffix = $SUFFIXE
   ldap user suffix = ou=people
   ldap group suffix = ou=groups
   ldap machine suffix = ou=computers
   ldap idmap suffix = ou=idmap
   ldap ssl = off
   ldap passwd sync = no
   log level = 1

; le partage historique de T-03 / T-04-E : conserve
[partage]
   path = /var/samba/partage
   read only = no
   guest ok = no

; ecriture reservee au groupe bureau (gid $GID_BUREAU, defini dans l'annuaire)
[commun]
   path = /var/samba/commun
   read only = no
   guest ok = no
   create mask = 0660
   directory mask = 2770

; lecture seule pour tous les comptes authentifies
[public]
   path = /var/samba/public
   read only = yes
   guest ok = no
CONF_SAMBA
ok "smb4.conf ecrit (passdb ldapsam + ldapsam:trusted = yes)"

sysrc samba_server_enable=YES >/dev/null 2>&1
service samba_server restart >/dev/null 2>&1 || service samba_server onestart >/dev/null 2>&1

# attente ACTIVE de l'ecoute (lecon du correctif C-11 : jamais de delai fixe)
if pgrep -q smbd; then ok "smbd tourne"; else ko "smbd ne tourne pas"; fi
info "attente de l'ecoute effective sur le port 445 (90 s max)"
i=0
while [ "$i" -lt 90 ]; do
    if sockstat -4l 2>/dev/null | grep -q ':445 '; then break; fi
    i=$((i+1)); sleep 1
done
if sockstat -4l 2>/dev/null | grep -q ':445 '; then
    ok "smbd ecoute (${i} s d'attente)"
    EN_ECOUTE=1
else
    ko "smbd n'ecoute pas apres 90 s : dernieres lignes du journal"
    tail -10 /var/log/samba4/log.smbd 2>/dev/null
    EN_ECOUTE=0
fi

# --- fabrique : smbclient avec reprises, contre le refus transitoire ---
# usage : smb_tente <partage> <user> <mdp> <commandes> <fichier_sortie>
smb_tente() {
    _p="$1"; _u="$2"; _m="$3"; _c="$4"; _o="$5"
    _e=0
    while [ "$_e" -lt 5 ]; do
        _e=$((_e+1))
        smbclient "//127.0.0.1/$_p" -U "$_u%$_m" -c "$_c" >"$_o" 2>&1 && return 0
        grep -q 'CONNECTION_REFUSED' "$_o" || return 1
        sleep 3
    done
    return 1
}

# ---------------------------------------------------------------------------
# BLOC F — PREUVES
# ---------------------------------------------------------------------------
echo
echo "########## BLOC F - PREUVES ##########"

echo
echo "----- preuve 1 : omrane (groupe bureau) ECRIT dans [commun] -----"
printf 'ecrit par omrane, membre du groupe bureau\n' > /tmp/essai-omrane.txt
if smb_tente commun omrane "$MDP_OMRANE" 'put /tmp/essai-omrane.txt essai-omrane.txt' /tmp/t04f-omrane.out; then
    ok "ecriture SMB acceptee pour omrane"
    if [ -f /var/samba/commun/essai-omrane.txt ]; then
        info "fichier sur le disque : $(ls -ln /var/samba/commun/essai-omrane.txt | awk '{print $3"  "$4"  "$1}')"
    fi
    P1=1
else
    ko "ecriture SMB refusee pour omrane :"
    tail -5 /tmp/t04f-omrane.out
    P1=0
fi

echo
echo "----- preuve 1b : le proprietaire du fichier vient de l'annuaire -----"
if [ -f /var/samba/commun/essai-omrane.txt ]; then
    UID_FICHIER=$(ls -ln /var/samba/commun/essai-omrane.txt | awk '{print $3}')
    GID_FICHIER=$(ls -ln /var/samba/commun/essai-omrane.txt | awk '{print $4}')
    info "uid du fichier = $UID_FICHIER (attendu $UID_OMRANE)"
    info "gid du fichier = $GID_FICHIER (attendu $GID_BUREAU)"
    if [ "$UID_FICHIER" = "$UID_OMRANE" ] && [ "$GID_FICHIER" = "$GID_BUREAU" ]; then
        ok "uid et gid du fichier sont ceux declares DANS L'ANNUAIRE"
        P1B=1
    else
        ko "uid/gid du fichier differents de l'annuaire (mapping local != annuaire)"
        P1B=0
    fi
else
    ko "fichier absent du disque : preuve non etablie"
    P1B=0
fi

echo
echo "----- preuve 2 : sara (groupe stagiaires) est REFUSEE dans [commun] -----"
printf 'ecrit par sara, hors du groupe bureau\n' > /tmp/essai-sara.txt
if smb_tente commun sara "$MDP_SARA" 'put /tmp/essai-sara.txt essai-sara.txt' /tmp/t04f-sara.out; then
    ko "sara a ECRIT dans [commun] : les droits ne sont PAS appliques"
    info "c'est un echec du test, pas un succes : a diagnostiquer"
    P2=0
else
    if grep -qiE 'ACCESS_DENIED|PERMISSION_DENIED|NT_STATUS_ACCESS' /tmp/t04f-sara.out; then
        ok "acces refuse a sara comme attendu (refus explicite du service)"
        P2=1
    else
        ko "sara n'a pas ecrit, mais pas pour la bonne raison :"
        tail -5 /tmp/t04f-sara.out
        P2=0
    fi
fi
if [ -f /var/samba/commun/essai-sara.txt ]; then
    ko "le fichier de sara existe malgre tout sur le disque : incoherence"
    P2=0
fi

echo
echo "----- preuve 3 : sara LIT [public] mais ne peut pas y ecrire -----"
if smb_tente public sara "$MDP_SARA" 'ls; get lisez-moi.txt /tmp/lu-par-sara.txt' /tmp/t04f-public.out; then
    ok "lecture de [public] acceptee pour sara"
    if [ -s /tmp/lu-par-sara.txt ]; then
        ok "contenu du fichier rapatrie : $(cat /tmp/lu-par-sara.txt)"
        P3=1
    else
        ko "fichier non rapatrie"
        P3=0
    fi
else
    ko "lecture de [public] refusee a sara :"
    tail -5 /tmp/t04f-public.out
    P3=0
fi
if smb_tente public sara "$MDP_SARA" 'put /tmp/essai-sara.txt ecrit-par-sara.txt' /tmp/t04f-public-ecrit.out; then
    ko "sara a ecrit dans [public] alors qu'il est en lecture seule"
    P3B=0
else
    ok "ecriture dans [public] refusee (partage en lecture seule)"
    P3B=1
fi

echo
echo "----- preuve 4 : ce que l'annuaire contient vraiment -----"
echo "--- groupe bureau ---"
ldapsearch -x -b "cn=bureau,ou=groups,$SUFFIXE" -s base '(objectClass=*)' cn gidNumber memberUid 2>&1 | grep -E '^(cn|gidNumber|memberUid):' | tee /tmp/t04f-groupe-bureau.out
if grep -q 'memberUid: omrane' /tmp/t04f-groupe-bureau.out && grep -q "gidNumber: $GID_BUREAU" /tmp/t04f-groupe-bureau.out; then
    ok "l'annuaire dit : omrane appartient a bureau (gid $GID_BUREAU)"
    P4=1
else
    ko "l'annuaire ne confirme pas l'appartenance"
    P4=0
fi
echo "--- compte sara ---"
ldapsearch -x -b "$SUFFIXE" '(uid=sara)' uid uidNumber gidNumber sambaSID 2>&1 | grep -E '^(uid|uidNumber|gidNumber|sambaSID):' | tee /tmp/t04f-sara-ldap.out
if grep -q "uidNumber: $UID_SARA" /tmp/t04f-sara-ldap.out; then
    ok "l'annuaire porte l'identite complete de sara (uid, gid, SID)"
    P4B=1
else
    ko "identite de sara incomplete dans l'annuaire"
    P4B=0
fi

# ---------------------------------------------------------------------------
echo
echo "########## VERDICT ##########"
if [ "$P1" = "1" ] && [ "$P1B" = "1" ] && [ "$P2" = "1" ] && [ "$P3" = "1" ] && [ "$P3B" = "1" ]; then
    echo "T-04-F : REUSSI - les droits sont decides par les groupes de l'annuaire."
elif [ "$P1" = "1" ] && [ "$P2" = "1" ]; then
    echo "T-04-F : PARTIEL - le controle d'acces par groupe fonctionne, mais toutes les preuves ne sont pas reunies."
elif [ "$P1" = "0" ] && [ "$SARA_LOCALE" = "1" ]; then
    echo "T-04-F : NON CONCLU - sara existe en local : l'identite n'est pas d'annuaire uniquement."
else
    echo "T-04-F : ECHEC - voir les lignes [ECHEC] ci-dessus."
    echo
    echo "Piste si sara ne s'authentifie pas du tout avec ldapsam:trusted :"
    echo "  - verifier que sara porte bien posixAccount ET sambaSamAccount sur la MEME entree ;"
    echo "  - verifier que gidNumber de sara correspond a un posixGroup existant ;"
    echo "  - journal : tail -20 /var/log/samba4/log.smbd"
fi
echo
echo "Pour transmettre le resultat :  cat /tmp/t04f-omrane.out /tmp/t04f-sara.out /tmp/t04f-public.out /tmp/t04f-public-ecrit.out"

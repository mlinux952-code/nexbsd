#!/bin/sh
# 63-banc-T04F-droits-groupes.sh — T-04-F : les DROITS sont decides par des
# groupes qui vivent dans l'annuaire, pas par des comptes locaux.
#
# Objectif (axe reseau facon NetWare, docs/14) : apres T-04-E (Samba authentifie
# via l'annuaire), prouver la brique suivante — un utilisateur qui n'existe QUE
# dans l'annuaire est authentifie, et son ACCES aux partages est decide par son
# GROUPE, egalement defini dans l'annuaire.
#
# A executer DANS la VM FreeBSD, en root. Idempotent.
# Prerequis : scripts/60 (T-04) et scripts/62 (T-04-E) deja passes.
# Secrets de LABORATOIRE uniquement (VM jetable, non exposee au reseau).
#
# Version 2 (2026-10-24) — corrige les trois defauts constates a l'essai 1 :
#   1. LDIF d'appartenance invalide : il manquait la LIGNE VIDE apres le "-"
#      separateur -> ldapmodify refusait tout le bloc ("modify operation type
#      is missing at line 6"). Aucun memberUid n'etait ecrit.
#   2. Les groupes n'avaient que posixGroup : OR avec ldapsam:trusted = yes,
#      Samba resout gid -> SID via l'entree de groupe. Sans sambaGroupMapping
#      ni sambaSID, la resolution echoue -> NT_STATUS_INTERNAL_DB_CORRUPTION
#      des l'ouverture de session (constate sur omrane, preuve 1).
#      -> les groupes portent desormais sambaSID / sambaGroupType.
#   3. smbpasswd -a sara echouait ("Failed to add entry for user sara") : le
#      chemin d'AJOUT de compte Samba sur une entree existante est fragile.
#      -> l'entree est creee avec sambaSamAccount et son SID, et smbpasswd ne
#         fait plus que POSER LE MOT DE PASSE (smbpasswd -s).
#
# Version 1 (2026-10-24).

ok()   { echo "  [OK]    $*"; }
ko()   { echo "  [ECHEC] $*"; }
info() { echo "  ...     $*"; }

SUFFIXE="dc=nexbsd,dc=local"
ADMIN_DN="cn=admin,$SUFFIXE"
ADMIN_PW="${NEXBSD_ADMIN_PW:?definir NEXBSD_ADMIN_PW (mot de passe de l admin de l annuaire)}"
MDP_OMRANE="${NEXBSD_MDP_OMRANE:?definir NEXBSD_MDP_OMRANE}"
MDP_SARA="${NEXBSD_MDP_SARA:?definir NEXBSD_MDP_SARA}"
GID_BUREAU=2001
GID_STAGIAIRES=2002
RID_BUREAU=3001
RID_STAGIAIRES=3002
RID_SARA=1010
RID_DOMAIN_USERS=513
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

# SID du domaine : d'abord par net, sinon lu dans l'annuaire (entree sambaDomain)
SID_DOMAINE=$(net getlocalsid 2>/dev/null | awk '{print $NF}')
if [ -z "$SID_DOMAINE" ]; then
    SID_DOMAINE=$(ldapsearch -x -b "$SUFFIXE" '(objectClass=sambaDomain)' sambaSID 2>/dev/null \
                  | awk '/^sambaSID:/{print $2}' | head -1)
    info "SID lu dans l'annuaire (entree sambaDomain)"
fi
if [ -n "$SID_DOMAINE" ]; then
    ok "SID du domaine : $SID_DOMAINE"
else
    ko "SID du domaine introuvable : les groupes ne peuvent pas recevoir de SID"
    info "verifier : ldapsearch -x -b '$SUFFIXE' '(objectClass=sambaDomain)' sambaSID"
    echo; echo "T-04-F : ECHEC - domaine Samba incomplet."
    exit 1
fi
SID_BUREAU="$SID_DOMAINE-$RID_BUREAU"
SID_STAGIAIRES="$SID_DOMAINE-$RID_STAGIAIRES"
SID_SARA="$SID_DOMAINE-$RID_SARA"
SID_DOMAIN_USERS="$SID_DOMAINE-$RID_DOMAIN_USERS"

# ---------------------------------------------------------------------------
# BLOC B — les groupes dans l'annuaire, avec leur identite Samba
# ---------------------------------------------------------------------------
echo
echo "########## BLOC B - groupes dans l'annuaire (posixGroup + sambaGroupMapping) ##########"
creer_groupe() {
    _cn="$1"; _gid="$2"; _rid="$3"
    # deja complet ?
    if ldapsearch -x -b "cn=$_cn,ou=groups,$SUFFIXE" -s base '(objectClass=*)' sambaSID 2>/dev/null \
       | grep -q 'sambaSID:'; then
        ok "groupe $_cn deja complet (gid $_gid, SID present)"
        return 0
    fi
    # existe sans Samba ?
    if ldapsearch -x -b "cn=$_cn,ou=groups,$SUFFIXE" -s base '(objectClass=*)' cn 2>/dev/null \
       | grep -q "^cn: $_cn"; then
        info "groupe $_cn present mais sans identite Samba : mise a niveau"
        cat > /tmp/t04f-up.ldif <<LDIF
dn: cn=$_cn,ou=groups,$SUFFIXE
changetype: modify
add: objectClass
objectClass: sambaGroupMapping
-
add: sambaSID
sambaSID: $SID_DOMAINE-$_rid
-
add: sambaGroupType
sambaGroupType: 2
-
add: displayName
displayName: $_cn
-
LDIF
        if ldapmodify -x -D "$ADMIN_DN" -w "$ADMIN_PW" -f /tmp/t04f-up.ldif >/tmp/t04f-up.log 2>&1; then
            ok "groupe $_cn : sambaSID $SID_DOMAINE-$_rid ajoute"
        else
            ko "mise a niveau de $_cn impossible :"
            tail -6 /tmp/t04f-up.log
            return 1
        fi
        return 0
    fi
    # creation complete
    cat > /tmp/t04f-grp.ldif <<LDIF
dn: cn=$_cn,ou=groups,$SUFFIXE
objectClass: top
objectClass: posixGroup
objectClass: sambaGroupMapping
cn: $_cn
gidNumber: $_gid
displayName: $_cn
sambaGroupType: 2
sambaSID: $SID_DOMAINE-$_rid
description: Groupe $_cn (laboratoire NexBSD)
LDIF
    if ldapadd -x -D "$ADMIN_DN" -w "$ADMIN_PW" -f /tmp/t04f-grp.ldif >/tmp/t04f-grp.log 2>&1; then
        ok "groupe $_cn cree (gid $_gid, SID $SID_DOMAINE-$_rid)"
    else
        ko "creation de $_cn impossible :"
        tail -6 /tmp/t04f-grp.log
        return 1
    fi
}
creer_groupe bureau "$GID_BUREAU" "$RID_BUREAU"
creer_groupe stagiaires "$GID_STAGIAIRES" "$RID_STAGIAIRES"

# appartenances — LDIF valide : la ligne "-" est suivie d'une LIGNE VIDE
cat > /tmp/t04f-membres.ldif <<LDIF
dn: cn=bureau,ou=groups,$SUFFIXE
changetype: modify
replace: memberUid
memberUid: omrane
-

dn: cn=stagiaires,ou=groups,$SUFFIXE
changetype: modify
replace: memberUid
memberUid: sara
-
LDIF
if ldapmodify -x -D "$ADMIN_DN" -w "$ADMIN_PW" -f /tmp/t04f-membres.ldif >/tmp/t04f-ldapmod.log 2>&1; then
    ok "appartenances fixees : bureau <- omrane ; stagiaires <- sara"
    APPART=1
else
    ko "appartenances non ecrites : voir /tmp/t04f-ldapmod.log"
    tail -6 /tmp/t04f-ldapmod.log
    APPART=0
fi

# ---------------------------------------------------------------------------
# BLOC C — un utilisateur qui n'existe QUE dans l'annuaire, complet des le depart
# ---------------------------------------------------------------------------
echo
echo "########## BLOC C - sara, dans l'annuaire seulement ##########"
if ldapsearch -x -b "$SUFFIXE" '(uid=sara)' sambaSID 2>/dev/null | grep -q 'sambaSID:'; then
    ok "entree uid=sara deja complete (posix + samba)"
else
    if ldapsearch -x -b "$SUFFIXE" '(uid=sara)' uid 2>/dev/null | grep -q 'uid: sara'; then
        info "uid=sara existe sans attributs Samba : mise a niveau"
        cat > /tmp/t04f-sara-up.ldif <<LDIF
dn: uid=sara,ou=people,$SUFFIXE
changetype: modify
add: objectClass
objectClass: sambaSamAccount
-
add: sambaSID
sambaSID: $SID_SARA
-
add: sambaPrimaryGroupSID
sambaPrimaryGroupSID: $SID_DOMAIN_USERS
-
add: sambaAcctFlags
sambaAcctFlags: [U          ]
-
LDIF
        if ldapmodify -x -D "$ADMIN_DN" -w "$ADMIN_PW" -f /tmp/t04f-sara-up.ldif >/tmp/t04f-sara-up.log 2>&1; then
            ok "sara : sambaSamAccount et SID ajoutes"
        else
            ko "mise a niveau de sara impossible :"
            tail -8 /tmp/t04f-sara-up.log
        fi
    else
        cat > /tmp/t04f-sara.ldif <<LDIF
dn: uid=sara,ou=people,$SUFFIXE
objectClass: top
objectClass: person
objectClass: organizationalPerson
objectClass: inetOrgPerson
objectClass: posixAccount
objectClass: sambaSamAccount
cn: Sara Test
sn: Test
uid: sara
uidNumber: $UID_SARA
gidNumber: $GID_STAGIAIRES
homeDirectory: /home/sara
loginShell: /bin/sh
userPassword: $MDP_SARA
sambaSID: $SID_SARA
sambaPrimaryGroupSID: $SID_DOMAIN_USERS
sambaAcctFlags: [U          ]
LDIF
        if ldapadd -x -D "$ADMIN_DN" -w "$ADMIN_PW" -f /tmp/t04f-sara.ldif >/tmp/t04f-sara.log 2>&1; then
            ok "entree uid=sara creee (uidNumber $UID_SARA, gid $GID_STAGIAIRES, SID $SID_SARA)"
        else
            ko "creation de sara : voir /tmp/t04f-sara.log"
            tail -8 /tmp/t04f-sara.log
        fi
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

# le mot de passe SMB : simple modification d'une entree qui porte deja son SID
printf '%s\n%s\n' "$MDP_SARA" "$MDP_SARA" | smbpasswd -s sara >/tmp/t04f-smbpasswd.log 2>&1
if [ $? -eq 0 ]; then
    ok "mot de passe SMB de sara enregistre dans l'annuaire"
else
    ko "smbpasswd -s sara a echoue :"
    tail -8 /tmp/t04f-smbpasswd.log
    info "journal smbd :"; tail -6 /var/log/samba4/log.smbd 2>/dev/null
fi

if ldapsearch -x -b "$SUFFIXE" '(uid=sara)' sambaNTPassword 2>/dev/null | grep -q 'sambaNTPassword:'; then
    ok "l'annuaire contient le mot de passe SMB de sara (hors /etc/master.passwd)"
    MDPSARA=1
else
    ko "aucun sambaNTPassword dans l'annuaire pour sara"
    MDPSARA=0
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
   log level = 2

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
else
    ko "smbd n'ecoute pas apres 90 s : dernieres lignes du journal"
    tail -10 /var/log/samba4/log.smbd 2>/dev/null
fi

# fabrique : smbclient avec reprises, contre le refus transitoire
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
echo "----- preuve 0 : les groupes vus par Samba (gid -> SID) -----"
net groupmap list 2>&1 | tee /tmp/t04f-groupmap.out | head -12
if grep -q "$SID_BUREAU" /tmp/t04f-groupmap.out 2>/dev/null || \
   ldapsearch -x -b "cn=bureau,ou=groups,$SUFFIXE" -s base '(objectClass=*)' sambaSID 2>/dev/null | grep -q "sambaSID: $SID_BUREAU"; then
    ok "le groupe bureau porte son SID Samba ($SID_BUREAU)"
    P0=1
else
    ko "le groupe bureau n'a pas de SID Samba : la resolution gid -> SID echouera"
    P0=0
fi

echo
echo "----- preuve 1 : omrane (groupe bureau) ECRIT dans [commun] -----"
printf 'ecrit par omrane, membre du groupe bureau\n' > /tmp/essai-omrane.txt
if smb_tente commun omrane "$MDP_OMRANE" 'put /tmp/essai-omrane.txt essai-omrane.txt' /tmp/t04f-omrane.out; then
    ok "ecriture SMB acceptee pour omrane"
    P1=1
else
    ko "ecriture SMB refusee pour omrane :"
    tail -6 /tmp/t04f-omrane.out
    if grep -q 'INTERNAL_DB_CORRUPTION' /tmp/t04f-omrane.out; then
        info "INTERNAL_DB_CORRUPTION = identifiants non resolvables cote annuaire"
        info "journal smbd :"; tail -8 /var/log/samba4/log.smbd 2>/dev/null
    fi
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
        tail -6 /tmp/t04f-sara.out
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
    tail -6 /tmp/t04f-public.out
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
ldapsearch -x -b "cn=bureau,ou=groups,$SUFFIXE" -s base '(objectClass=*)' cn gidNumber memberUid sambaSID 2>&1 \
    | grep -E '^(cn|gidNumber|memberUid|sambaSID):' | tee /tmp/t04f-groupe-bureau.out
if grep -q 'memberUid: omrane' /tmp/t04f-groupe-bureau.out && grep -q "gidNumber: $GID_BUREAU" /tmp/t04f-groupe-bureau.out; then
    ok "l'annuaire dit : omrane appartient a bureau (gid $GID_BUREAU)"
    P4=1
else
    ko "l'annuaire ne confirme pas l'appartenance"
    P4=0
fi
echo "--- compte sara ---"
ldapsearch -x -b "$SUFFIXE" '(uid=sara)' uid uidNumber gidNumber sambaSID sambaNTPassword 2>&1 \
    | grep -E '^(uid|uidNumber|gidNumber|sambaSID|sambaNTPassword):' | tee /tmp/t04f-sara-ldap.out
if grep -q "uidNumber: $UID_SARA" /tmp/t04f-sara-ldap.out; then
    ok "l'annuaire porte l'identite complete de sara (uid, gid, SID, mot de passe)"
    P4B=1
else
    ko "identite de sara incomplete dans l'annuaire"
    P4B=0
fi

# ---------------------------------------------------------------------------
echo
echo "########## VERDICT ##########"
if [ "$P0" = "1" ] && [ "$P1" = "1" ] && [ "$P1B" = "1" ] && [ "$P2" = "1" ] && [ "$P3" = "1" ] && [ "$P3B" = "1" ]; then
    echo "T-04-F : REUSSI - les droits sont decides par les groupes de l'annuaire."
elif [ "$SARA_LOCALE" = "1" ]; then
    echo "T-04-F : NON CONCLU - sara existe en local : l'identite n'est pas d'annuaire uniquement."
elif [ "$P1" = "1" ] && [ "$P2" = "1" ]; then
    echo "T-04-F : PARTIEL - controle d'acces par groupe acquis, toutes les preuves ne sont pas reunies."
else
    echo "T-04-F : ECHEC - voir les lignes [ECHEC] ci-dessus."
fi
echo
echo "Etat des preuves : P0(groupemap)=$P0 P1(ecrit)=$P1 P1b(uid/gid)=$P1B P2(refus)=$P2 P3(lecture)=$P3 P3b(ro)=$P3B"
echo "                   appartenances=$APPART mdp_sara=$MDPSARA sara_locale=$SARA_LOCALE"
echo
echo "Pour transmettre le resultat :"
echo "  cat /tmp/t04f-groupmap.out /tmp/t04f-omrane.out /tmp/t04f-sara.out /tmp/t04f-public.out"
echo "  tail -20 /var/log/samba4/log.smbd"

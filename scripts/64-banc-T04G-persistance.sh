#!/bin/sh
# 64-banc-T04G-persistance.sh — T-04-G : le banc survit a un REDEMARRAGE.
#
# Objectif : tout ce qui a ete construit depuis T-04 (annuaire, comptes, groupes,
# partages, droits) doit revenir TOUT SEUL apres une coupure, sans une seule
# commande a la main. C'est la difference entre un banc d'essai et un serveur.
#
# A executer DANS la VM FreeBSD, en root. En DEUX temps :
#   1) sh /tmp/t04g.sh avant     -> releve l'etat, arme les services, puis REBOOTER
#   2) sh /tmp/t04g.sh apres     -> verifie que tout est revenu, rend le verdict
#
# Le script n'installe rien et ne cree rien : il CONTROLE. Si une phase de
# controle devait reparer quelque chose, ce serait une defaillance a consigner.
#
# Version 2 (2026-10-24) — corrige deux defauts constates a l'essai 1 :
#   1. le fichier d'etat etait relu par '. fichier' (sourcing). Une valeur
#      contenant des espaces ("drwxrws--- 0 2001") cassait le shell :
#      "/root/nexbsd-t04g-etat.txt: 0: not found". DROITS_COMMUN restait vide,
#      d'ou un faux echec "les droits ont change".
#      -> l'etat est desormais LU par cle (sed), jamais execute.
#   2. aucun diagnostic n'etait produit quand les ouvertures de session
#      echouaient apres redemarrage. -> bloc de diagnostic ajoute.
#
# Version 1 (2026-10-24).

ok()   { echo "  [OK]    $*"; }
ko()   { echo "  [ECHEC] $*"; }
info() { echo "  ...     $*"; }

SUFFIXE="dc=nexbsd,dc=local"
ETAT="/root/nexbsd-t04g-etat.txt"
PHASE="${1:-avant}"
MDP_OMRANE="omranelab"
MDP_SARA="saralab"

echo "############## T-04-G : persistance apres redemarrage ##############"
echo "# date : $(date -u +%FT%TZ) ; hote : $(uname -sr) ; phase : $PHASE"

# ---------------------------------------------------------------------------
# attente ACTIVE de l'ecoute (lecon C-11 : jamais de delai fixe)
# ---------------------------------------------------------------------------
attendre_445() {
    _i=0
    while [ "$_i" -lt 90 ]; do
        sockstat -4l 2>/dev/null | grep -q ':445 ' && return 0
        _i=$((_i+1)); sleep 1
    done
    return 1
}

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

compte_entrees() {
    ldapsearch -x -b "$SUFFIXE" -s sub '(objectClass=*)' dn 2>/dev/null | grep -c '^dn: '
}

# ---------------------------------------------------------------------------
# PHASE 1 — AVANT
# ---------------------------------------------------------------------------
if [ "$PHASE" != "apres" ]; then

    echo
    echo "########## PHASE 1 - releve de l'etat AVANT redemarrage ##########"

    if ! pgrep -q slapd; then
        ko "slapd ne tourne pas : lancer d'abord scripts/60 (T-04)"
        echo; echo "T-04-G : ECHEC - annuaire indisponible."
        exit 1
    fi
    if ! pgrep -q smbd; then
        ko "smbd ne tourne pas : lancer d'abord scripts/63 (T-04-F)"
        echo; echo "T-04-G : ECHEC - Samba indisponible."
        exit 1
    fi
    ok "les deux services tournent"

    # 1. les services sont-ils ARMES au demarrage ? (le coeur du test)
    echo
    echo "----- armement au demarrage (rc.conf) -----"
    SLAPD_ENABLE=$(sysrc -n slapd_enable 2>/dev/null)
    SAMBA_ENABLE=$(sysrc -n samba_server_enable 2>/dev/null)
    info "slapd_enable = ${SLAPD_ENABLE:-<vide>}"
    info "samba_server_enable = ${SAMBA_ENABLE:-<vide>}"
    if [ "$SLAPD_ENABLE" != "YES" ]; then
        info "armement absent : on l'arme (c'est un prerequis du test, pas un resultat)"
        sysrc slapd_enable=YES >/dev/null 2>&1
    fi
    if [ "$SAMBA_ENABLE" != "YES" ]; then
        info "armement absent : on l'arme (prerequis du test)"
        sysrc samba_server_enable=YES >/dev/null 2>&1
    fi
    if [ "$(sysrc -n slapd_enable 2>/dev/null)" = "YES" ] && \
       [ "$(sysrc -n samba_server_enable 2>/dev/null)" = "YES" ]; then
        ok "slapd et samba_server sont armes au demarrage"
    else
        ko "armement impossible : le redemarrage ne prouverait rien"
        echo; echo "T-04-G : ECHEC - services non armes."
        exit 1
    fi

    # 2. etat a comparer plus tard
    echo
    echo "----- releve -----"
    N_ENTREES=$(compte_entrees)
    ok "annuaire : $N_ENTREES entrees"
    SID_SARA=$(ldapsearch -x -b "$SUFFIXE" '(uid=sara)' sambaSID 2>/dev/null | awk '/^sambaSID:/{print $2}')
    if [ -n "$SID_SARA" ]; then ok "sara a un SID : $SID_SARA"; else ko "sara sans SID dans l'annuaire"; fi
    SID_BUREAU=$(ldapsearch -x -b "cn=bureau,ou=groups,$SUFFIXE" -s base '(objectClass=*)' sambaSID 2>/dev/null | awk '/^sambaSID:/{print $2}')
    if [ -n "$SID_BUREAU" ]; then ok "groupe bureau : SID $SID_BUREAU"; else ko "groupe bureau sans SID"; fi
    MBR=$(ldapsearch -x -b "cn=bureau,ou=groups,$SUFFIXE" -s base '(objectClass=*)' memberUid 2>/dev/null | awk '/^memberUid:/{print $2}')
    if [ "$MBR" = "omrane" ]; then ok "bureau a pour membre : omrane"; else ko "appartenance omrane absente"; fi

    DROITS_COMMUN=$(ls -ldn /var/samba/commun 2>/dev/null | awk '{print $1" "$3" "$4}')
    info "droits de /var/samba/commun : $DROITS_COMMUN"
    DROITS_PUBLIC=$(ls -ldn /var/samba/public 2>/dev/null | awk '{print $1" "$3" "$4}')
    info "droits de /var/samba/public : $DROITS_PUBLIC"

    FICHIER_TEMOIN=/var/samba/public/temoin-t04g.txt
    printf 'temoin ecrit avant redemarrage : %s\n' "$(date -u +%FT%TZ)" > "$FICHIER_TEMOIN"
    if [ -f "$FICHIER_TEMOIN" ]; then ok "fichier temoin ecrit sur le disque"; fi

    UPTIME_AVANT=$(sysctl -n kern.boottime 2>/dev/null)
    {
        echo "# etat T-04-G releve le $(date -u +%FT%TZ)"
        echo "N_ENTREES=$N_ENTREES"
        echo "SID_SARA=$SID_SARA"
        echo "SID_BUREAU=$SID_BUREAU"
        echo "MEMBERUID_BUREAU=$MBR"
        echo "DROITS_COMMUN=$DROITS_COMMUN"
        echo "DROITS_PUBLIC=$DROITS_PUBLIC"
        echo "BOOTTIME=$UPTIME_AVANT"
    } > "$ETAT"
    ok "etat enregistre dans $ETAT"

    echo
    echo "################ A FAIRE MAINTENANT ################"
    echo "1. copier ce script pour le retrouver apres redemarrage :"
    echo "     cp /tmp/t04g.sh /root/t04g.sh"
    echo "2. redemarrer la machine :"
    echo "     reboot"
    echo "3. apres le retour de l'invite root, lancer :"
    echo "     sh /root/t04g.sh apres"
    echo "   (si le fichier a disparu : refaire le fetch depuis le Mint,"
    echo "    puis 'sh /tmp/t04g.sh apres')"
    echo "####################################################"
    exit 0
fi

# ---------------------------------------------------------------------------
# PHASE 2 — APRES
# ---------------------------------------------------------------------------
echo
echo "########## PHASE 2 - controle APRES redemarrage ##########"

if [ ! -f "$ETAT" ]; then
    ko "aucun releve trouve dans $ETAT"
    info "la phase 'avant' n'a pas ete executee, ou le disque a ete perdu"
    echo; echo "T-04-G : NON CONCLU - pas de point de comparaison."
    exit 1
fi
# v2 : on LIT les valeurs, on ne les execute pas (une valeur avec espaces
# casserait le shell : c'etait le defaut de la v1).
lire_etat() { sed -n "s/^$1=//p" "$ETAT" 2>/dev/null | head -1; }
N_ENTREES=$(lire_etat N_ENTREES)
SID_SARA=$(lire_etat SID_SARA)
SID_BUREAU=$(lire_etat SID_BUREAU)
MEMBERUID_BUREAU=$(lire_etat MEMBERUID_BUREAU)
DROITS_COMMUN=$(lire_etat DROITS_COMMUN)
DROITS_PUBLIC=$(lire_etat DROITS_PUBLIC)
BOOTTIME=$(lire_etat BOOTTIME)
info "releve : $N_ENTREES entrees / SID sara=$SID_SARA / droits commun=[$DROITS_COMMUN]"

# 1. un redemarrage a-t-il vraiment eu lieu ?
echo
echo "----- 1. redemarrage effectif -----"
UPTIME_COURT=$(sysctl -n kern.boottime 2>/dev/null)
if [ "$UPTIME_COURT" != "$BOOTTIME" ]; then
    ok "la machine a bien redemarre (instant de demarrage different)"
    R0=1
else
    ko "instant de demarrage identique : la machine n'a PAS redemarre"
    info "sans redemarrage, ce test ne prouve rien"
    R0=0
fi
info "demarree depuis : $(uptime | sed 's/^ *//')"

# 2. les services sont-ils revenus TOUT SEULS ?
echo
echo "----- 2. services revenus sans intervention -----"
if pgrep -q slapd; then ok "slapd tourne, sans commande manuelle"; R1=1; else
    ko "slapd est arrete apres redemarrage"
    info "verifier : sysrc -n slapd_enable ; tail -20 /var/log/messages"
    R1=0
fi
if grep -q 'Serving' /dev/null 2>&1; then :; fi
if pgrep -q smbd; then ok "smbd (demon) present"; else ko "smbd absent apres redemarrage"; fi
if attendre_445; then
    ok "smbd ecoute sur :445 sans commande manuelle"
    R2=1
else
    ko "smbd n'ecoute pas sur :445"
    info "journal :"; tail -10 /var/log/samba4/log.smbd 2>/dev/null
    R2=0
fi

# 3. les donnees sont-elles intactes ?
echo
echo "----- 3. donnees de l'annuaire intactes -----"
N_APRES=$(compte_entrees)
info "entrees : $N_APRES (releve : $N_ENTREES)"
if [ "$N_APRES" -ge "$N_ENTREES" ] 2>/dev/null; then
    ok "aucune entree perdue"
    R3=1
else
    ko "des entrees ont disparu : l'annuaire n'est pas persistant"
    R3=0
fi
SID_SARA_APRES=$(ldapsearch -x -b "$SUFFIXE" '(uid=sara)' sambaSID 2>/dev/null | awk '/^sambaSID:/{print $2}')
if [ -n "$SID_SARA_APRES" ] && [ "$SID_SARA_APRES" = "$SID_SARA" ]; then
    ok "sara garde son SID ($SID_SARA_APRES)"
    R4=1
else
    ko "SID de sara absent ou different apres redemarrage"
    R4=0
fi
MBR_APRES=$(ldapsearch -x -b "cn=bureau,ou=groups,$SUFFIXE" -s base '(objectClass=*)' memberUid 2>/dev/null | awk '/^memberUid:/{print $2}')
if [ "$MBR_APRES" = "omrane" ]; then
    ok "l'appartenance omrane -> bureau est conservee"
    R5=1
else
    ko "appartenance perdue apres redemarrage"
    R5=0
fi

# 4. le fichier temoin a-t-il survecu ?
echo
echo "----- 4. donnees des partages conservees -----"
if [ -f /var/samba/public/temoin-t04g.txt ]; then
    ok "fichier temoin retrouve : $(cat /var/samba/public/temoin-t04g.txt)"
    R6=1
else
    ko "fichier temoin perdu"
    R6=0
fi
DROITS_COMMUN_APRES=$(ls -ldn /var/samba/commun 2>/dev/null | awk '{print $1" "$3" "$4}')
info "droits de /var/samba/commun : $DROITS_COMMUN_APRES (avant : $DROITS_COMMUN)"
if [ "$DROITS_COMMUN_APRES" = "$DROITS_COMMUN" ]; then
    ok "les droits des partages sont inchanges"
    R7=1
else
    ko "les droits ont change : les partages ne sont pas reproductibles"
    R7=0
fi

# 5. le service fonctionne-t-il vraiment, comme avant ?
echo
echo "----- 5. service reellement utilisable -----"
printf 'ecrit apres redemarrage par omrane\n' > /tmp/apres-omrane.txt
if smb_tente commun omrane "$MDP_OMRANE" 'put /tmp/apres-omrane.txt apres-omrane.txt' /tmp/t04g-omrane.out; then
    ok "omrane ecrit dans [commun] apres redemarrage"
    R8=1
else
    ko "omrane ne peut plus ecrire dans [commun] :"
    tail -6 /tmp/t04g-omrane.out
    R8=0
fi
if smb_tente commun sara "$MDP_SARA" 'put /tmp/apres-omrane.txt refus-attendu.txt' /tmp/t04g-sara.out; then
    ko "sara a ecrit dans [commun] : les droits ne sont plus appliques"
    R9=0
else
    if grep -qiE 'ACCESS_DENIED|PERMISSION_DENIED|NT_STATUS_ACCESS' /tmp/t04g-sara.out; then
        ok "sara est toujours refusee dans [commun] : les droits survivent au redemarrage"
        R9=1
    else
        ko "sara est refusee, mais pas pour la bonne raison :"
        tail -6 /tmp/t04g-sara.out
        R9=0
    fi
fi
if smb_tente public sara "$MDP_SARA" 'get temoin-t04g.txt /tmp/temoin-lu.txt' /tmp/t04g-public.out; then
    ok "sara lit le fichier temoin par le reseau : le partage fonctionne"
    R10=1
else
    ko "lecture du temoin impossible :"
    tail -6 /tmp/t04g-public.out
    R10=0
fi

# ---------------------------------------------------------------------------
# ---------------------------------------------------------------------------
# v2 : diagnostic automatique si une ouverture de session a echoue
if [ "$R8" = "0" ] || [ "$R9" = "0" ] || [ "$R10" = "0" ]; then
    echo
    echo "########## DIAGNOSTIC (automatique) ##########"
    if grep -q 'LOGON_FAILURE' /tmp/t04g-omrane.out 2>/dev/null; then
        info "les comptes sont REFUSES : le service repond, mais ne valide plus le mot de passe."
        echo
        echo "--- 1. Samba sait-il encore lire la passdb de l'annuaire ? ---"
        pdbedit -L -v omrane 2>&1 | head -6
        echo
        echo "--- 2. SID du domaine : celui du systeme doit egaler celui de l'annuaire ---"
        SID_LOCAL=$(net getlocalsid 2>/dev/null | awk '{print $NF}')
        SID_LDAP=$(ldapsearch -x -b "$SUFFIXE" '(objectClass=sambaDomain)' sambaSID 2>/dev/null | awk '/^sambaSID:/{print $2}' | head -1)
        info "SID du systeme      : ${SID_LOCAL:-<vide>}"
        info "SID dans l'annuaire : ${SID_LDAP:-<vide>}"
        if [ -n "$SID_LOCAL" ] && [ -n "$SID_LDAP" ] && [ "$SID_LOCAL" != "$SID_LDAP" ]; then
            info ">>> LES DEUX SID DIFFERENT : la base des secrets de Samba a ete perdue/regenernee."
        fi
        echo
        echo "--- 3. Ordre de demarrage : slapd doit etre pret AVANT smbd ---"
        info "slapd : $(grep -m1 slapd /var/log/messages 2>/dev/null | cut -c1-15)"
        info "smbd  : $(grep -m1 'smbd version' /var/log/samba4/log.smbd 2>/dev/null | cut -c1-15)"
        echo
        echo "--- 4. Journal smbd (fin) ---"
        tail -15 /var/log/samba4/log.smbd 2>/dev/null
        echo
        echo "--- 5. Discriminant : redemarrer SEULEMENT Samba, maintenant que slapd tourne ---"
        info "si les acces reviennent, la cause est l'ORDRE DE DEMARRAGE (smbd avant slapd)."
    fi
fi

echo
echo "########## VERDICT ##########"
TOTAL=$((R0+R1+R2+R3+R4+R5+R6+R7+R8+R9+R10))
echo "Controles reussis : $TOTAL / 11"
if [ "$TOTAL" -eq 11 ]; then
    echo "T-04-G : REUSSI - le banc revient seul apres redemarrage, donnees et droits compris."
elif [ "$R1" = "1" ] && [ "$R2" = "1" ] && [ "$R8" = "1" ] && [ "$R9" = "1" ]; then
    echo "T-04-G : PARTIEL - les services et les droits reviennent, mais un controle de donnees a echoue."
else
    echo "T-04-G : ECHEC - voir les lignes [ECHEC] ci-dessus."
    echo
    echo "Pistes selon le controle en echec :"
    echo "  - services absents : 'sysrc -n slapd_enable' et 'sysrc -n samba_server_enable' doivent valoir YES"
    echo "  - donnees perdues   : l'annuaire n'ecrit pas sur le disque (verifier la base mdb et ses droits)"
    echo "  - droits changes    : les 'chown/chmod' ne sont pas rejoues au demarrage -> ils doivent etre"
    echo "                        inscrits dans un mecanisme de demarrage, pas tapes a la main"
fi
echo
echo "Pour transmettre le resultat : cat /tmp/t04g-omrane.out /tmp/t04g-sara.out /tmp/t04g-public.out"

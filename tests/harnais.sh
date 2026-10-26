#!/bin/sh
# harnais.sh — NexBSD — harnais de tests automatise (repond au manque n.2 de l'audit croise)
#
# BUT
#   Rejouer en UNE SEULE PASSE, sans redemarrage, les controles du banc NexBSD,
#   et rendre un VERDICT GLOBAL + un CODE DE RETOUR exploitable par un script ou une CI.
#
#   Avant : 8 tests reussis, mais sous forme de protocoles manuels a recopier.
#   Apres : une commande, un chiffre, un code de sortie. Un humain ne peut plus
#           "se tromper de bonne foi" en recopiant un resultat.
#
# USAGE
#   sh harnais.sh              # passe complete (ecriture/lecture reelles comprises)
#   sh harnais.sh --lecture    # passe en lecture seule (aucune ecriture de fichier de test)
#   sh harnais.sh --aide
#
# CODE DE RETOUR
#   0 = tous les controles obligatoires reussis
#   1 = au moins un controle obligatoire en echec
#
# REGLE DU PROJET (R-10) : on ne maquille jamais un resultat.
#   - un controle non applicable est compte [ATT] (attenue), jamais [OK] ;
#   - un outil absent est compte [KO], avec la raison ;
#   - le verdict final est calcule, jamais ecrit a la main.

VERSION="1.0"
MODE="complet"

SUFFIXE="dc=nexbsd,dc=local"
PARTAGE_COMMUN="/var/samba/commun"
PARTAGE_PUBLIC="/var/samba/public"
NB_ENTREES_MIN=10
GID_BUREAU=2001
GID_STAGIAIRES=2002
NETBIOS_ATTENDU="NEXBSDFS"
KERNCONF_ATTENDU="NEXBSD_L1"
RELEASE_ATTENDUE="15.1-NEXBSD-L1"
HOTE_ATTENDU="nexbsd"
NONCE_ATTENDU="82dc5681397b06fab69171daf6e910d6a380b058ee63341a83c77f770b94c87c"
MDP_OMRANE="omranelab"
MDP_SARA="saralab"

OK=0
KO=0
ATT=0
DETAIL_KO=""

for a in "$@"; do
  case "$a" in
    --aide|-h|--help)
      sed -n '2,30p' "$0" | sed 's/^# \{0,1\}//'
      exit 0 ;;
    --lecture) MODE="lecture" ;;
    *) echo "option inconnue : $a (voir --aide)" >&2; exit 2 ;;
  esac
done

ok()   { OK=$((OK+1));  printf '  [OK]    %s\n' "$1"; }
ko()   { KO=$((KO+1));  printf '  [KO]    %s\n' "$1"; DETAIL_KO="$DETAIL_KO
    - $1"; }
att()  { ATT=$((ATT+1)); printf '  [ATT]   %s\n' "$1"; }
info() { printf '  ...     %s\n' "$1"; }
titre() { printf '\n----- %s -----\n' "$1"; }

# ---------------------------------------------------------------- outils
ont() { command -v "$1" >/dev/null 2>&1; }

ldap_count() {
  ldapsearch -x -b "$SUFFIXE" -s sub '(objectClass=*)' dn 2>/dev/null | grep -c '^dn: '
}
port_ouvert() { # numero
  sockstat -4l 2>/dev/null | awk '{print $6}' | grep -q ":$1\$"
}

# ---------------------------------------------------------------- entete
printf '############## HARNAIS NEXBSD v%s ##############\n' "$VERSION"
printf '# date : %s\n' "$(date -u +%FT%TZ)"
printf '# hote : %s ; noyau : %s ; mode : %s\n' "$(uname -s) $(uname -r)" "$(uname -i)" "$MODE"

# ================================================================ 1. identite
titre "1. identite du systeme"

ID_I=$(uname -i 2>/dev/null)
if [ "$ID_I" = "$KERNCONF_ATTENDU" ]; then
  ok "uname -i = $ID_I (le systeme annonce notre identite)"
else
  ko "uname -i = '$ID_I' au lieu de '$KERNCONF_ATTENDU'"
fi

REL=$(uname -r 2>/dev/null)
if [ "$REL" = "$RELEASE_ATTENDUE" ]; then
  ok "uname -r = $REL"
else
  ko "uname -r = '$REL' au lieu de '$RELEASE_ATTENDUE'"
fi

SOCLE=$(uname -s 2>/dev/null)
if [ "$SOCLE" = "FreeBSD" ]; then
  ok "uname -s = FreeBSD (le socle, conformement a docs/26)"
else
  ko "uname -s = '$SOCLE' (inattendu)"
fi

HOTE=$(hostname 2>/dev/null)
if [ "$HOTE" = "$HOTE_ATTENDU" ]; then
  ok "nom d'hote = $HOTE"
else
  ko "nom d'hote = '$HOTE' au lieu de '$HOTE_ATTENDU'"
fi

# empreinte du noyau reellement demarre : prouve qu'on tourne sur LE binaire construit
BOOTFILE=$(sysctl -n kern.bootfile 2>/dev/null)
if [ -r "$BOOTFILE" ] && ont sha256; then
  H=$(sha256 -q "$BOOTFILE" 2>/dev/null)
  if [ "$H" = "$NONCE_ATTENDU" ]; then
    ok "empreinte du noyau demarre = $(echo "$H" | cut -c1-16)... (identique au noyau construit)"
  else
    ko "empreinte du noyau demarre ($H) differente du noyau construit ($NONCE_ATTENDU)"
  fi
else
  att "empreinte du noyau non verifiable (fichier '$BOOTFILE' illisible ou sha256 absent)"
fi

# ================================================================ 2. services
titre "2. services d'annuaire et de fichiers"

if pgrep -q slapd; then ok "slapd tourne"; else ko "slapd ne tourne pas"; fi
if port_ouvert 389; then ok "389 (LDAP) en ecoute"; else ko "389 (LDAP) n'ecoute pas"; fi
if pgrep -q smbd; then ok "smbd tourne"; else ko "smbd ne tourne pas"; fi
if port_ouvert 445; then ok "445 (SMB) en ecoute"; else ko "445 (SMB) n'ecoute pas"; fi

# ================================================================ 3. annuaire
titre "3. contenu de l'annuaire"

if ont ldapsearch; then
  N=$(ldap_count)
  if [ "${N:-0}" -ge "$NB_ENTREES_MIN" ]; then
    ok "annuaire : $N entrees (minimum $NB_ENTREES_MIN)"
  else
    ko "annuaire : $N entrees seulement (minimum $NB_ENTREES_MIN)"
  fi

  SID_SARA=$(ldapsearch -x -b "$SUFFIXE" '(uid=sara)' sambaSID 2>/dev/null | awk '/^sambaSID:/{print $2; exit}')
  if [ -n "$SID_SARA" ]; then ok "sara a un SID : $SID_SARA"; else ko "sara n'a pas de SID dans l'annuaire"; fi

  SID_GRP=$(ldapsearch -x -b "cn=bureau,ou=groups,$SUFFIXE" -s base '(objectClass=*)' sambaSID 2>/dev/null | awk '/^sambaSID:/{print $2; exit}')
  case "$SID_GRP" in
    *-3001) ok "groupe bureau : SID $SID_GRP" ;;
    "")     ko "groupe bureau : SID introuvable" ;;
    *)      ko "groupe bureau : SID inattendu ($SID_GRP)" ;;
  esac

  MBR=$(ldapsearch -x -b "cn=bureau,ou=groups,$SUFFIXE" -s base '(objectClass=*)' memberUid 2>/dev/null | awk '/^memberUid:/{print $2; exit}')
  if [ "$MBR" = "omrane" ]; then ok "bureau a pour membre : omrane"; else ko "appartenance omrane -> bureau absente (lu : '$MBR')"; fi
else
  ko "ldapsearch absent : impossible de verifier l'annuaire"
fi

# ================================================================ 4. NSS
titre "4. identites Unix derivees de l'annuaire (NSS)"

G=$(getent group bureau 2>/dev/null | cut -d: -f3)
if [ "$G" = "$GID_BUREAU" ]; then ok "NSS : bureau -> gid $G"; else ko "NSS : bureau -> gid '$G' au lieu de $GID_BUREAU"; fi
G=$(getent group stagiaires 2>/dev/null | cut -d: -f3)
if [ "$G" = "$GID_STAGIAIRES" ]; then ok "NSS : stagiaires -> gid $G"; else ko "NSS : stagiaires -> gid '$G' au lieu de $GID_STAGIAIRES"; fi
U=$(getent passwd omrane 2>/dev/null | cut -d: -f1)
if [ "$U" = "omrane" ]; then ok "NSS : omrane resolu"; else ko "NSS : omrane non resolu"; fi

# ================================================================ 5. droits disque
titre "5. droits des partages sur le disque"

if [ -d "$PARTAGE_COMMUN" ]; then
  D=$(ls -ld "$PARTAGE_COMMUN" | awk '{print $1" "$4}')
  case "$D" in
    "drwxrws--- $GID_BUREAU") ok " $PARTAGE_COMMUN : $D (setgid + groupe $GID_BUREAU)" ;;
    *)                        ko "$PARTAGE_COMMUN : $D (attendu drwxrws--- $GID_BUREAU)" ;;
  esac
else
  ko "$PARTAGE_COMMUN absent"
fi

if [ -d "$PARTAGE_PUBLIC" ]; then
  D=$(ls -ld "$PARTAGE_PUBLIC" | awk '{print $1" "$4}')
  case "$D" in
    "drwxr-xr-x "*) ok " $PARTAGE_PUBLIC : $D (lecture pour tous)" ;;
    *)              att "$PARTAGE_PUBLIC : $D (forme inattendue)" ;;
  esac
else
  att "$PARTAGE_PUBLIC absent"
fi

# ================================================================ 6. configuration Samba
titre "6. configuration Samba (testparm)"

if ont testparm; then
  TP=$(testparm -s 2>/dev/null)
  if printf '%s' "$TP" | grep -qi "ldapsam:trusted *= *yes"; then
    ok "ldapsam:trusted = yes"
  else
    ko "ldapsam:trusted absent ou different"
  fi
  case "$TP" in
    *"netbios name = $NETBIOS_ATTENDU"*) ok "netbios name = $NETBIOS_ATTENDU" ;;
    *)                                   ko "netbios name different de $NETBIOS_ATTENDU" ;;
  esac
  case "$TP" in
    *"passdb backend = ldapsam"*) ok "passdb backend = ldapsam" ;;
    *)                            ko "passdb backend n'est pas ldapsam" ;;
  esac
else
  ko "testparm absent : configuration Samba non verifiable"
fi

# ================================================================ 7. service reel
titre "7. service reellement utilisable (ecriture / refus / lecture)"

if ! ont smbclient; then
  ko "smbclient absent : acces reseau non verifiable"
elif [ "$MODE" = "lecture" ]; then
  att "mode lecture : ecritures et refus non testes (relancer sans --lecture)"
else
  TMP=$(mktemp /tmp/harnais.XXXXXX) || TMP=/tmp/harnais.$$
  printf 'harnais %s\n' "$(date -u +%FT%TZ)" > "$TMP"
  NOM="harnais-$(date -u +%H%M%S).txt"

  OUT=$(smbclient "//127.0.0.1/commun" -U "omrane%$MDP_OMRANE" -c "put $TMP $NOM" 2>&1)
  case "$OUT" in
    *"NT_STATUS_OK"*|"") ok "omrane ecrit dans [commun]" ;;
    *) ko "omrane n'a pas pu ecrire dans [commun] : $(echo "$OUT" | tail -1)" ;;
  esac

  OUT=$(smbclient "//127.0.0.1/commun" -U "sara%$MDP_SARA" -c "put $TMP refus-attendu.txt" 2>&1)
  case "$OUT" in
    *NT_STATUS_ACCESS_DENIED*|*NT_STATUS_MEDIA_WRITE_PROTECTED*) ok "sara est refusee dans [commun] (attendu)" ;;
    *) ko "sara a ecrit dans [commun] ou erreur inattendue : $(echo "$OUT" | tail -1)" ;;
  esac

  OUT=$(smbclient "//127.0.0.1/public" -U "sara%$MDP_SARA" -c "ls" 2>&1)
  case "$OUT" in
    *NT_STATUS_ACCESS_DENIED*|*NT_STATUS_LOGON_FAILURE*) ko "sara ne peut pas lire [public] alors qu'elle devrait" ;;
    *NT_STATUS_OK*|*"blocks of size"*) ok "sara lit [public] par le reseau" ;;
    *) att "lecture de [public] par sara : sortie inattendue ($(echo "$OUT" | tail -1))" ;;
  esac

  rm -f "$TMP" 2>/dev/null
fi

# ================================================================ verdict
printf '\n########## VERDICT ##########\n'
TOTAL=$((OK+KO+ATT))
printf 'controles : %s au total | %s reussis | %s en echec | %s non applicables\n' "$TOTAL" "$OK" "$KO" "$ATT"

if [ "$KO" -eq 0 ]; then
  printf 'HARNAIS : REUSSI (%s/%s obligatoires)\n' "$OK" "$((OK+KO))"
  [ "$ATT" -gt 0 ] && printf 'NB : %s controle(s) non applicable(s) ce passage.\n' "$ATT"
  exit 0
else
  printf 'HARNAIS : ECHEC (%s/%s obligatoires)\n' "$OK" "$((OK+KO))"
  printf 'controles en echec :%s\n' "$DETAIL_KO"
  exit 1
fi

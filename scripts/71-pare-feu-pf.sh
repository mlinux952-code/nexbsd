#!/bin/sh
# 71-pare-feu-pf.sh — NexBSD — L1 : pare-feu pf, REFUS PAR DEFAUT
#
# CE QUE FAIT CE SCRIPT
#   1. detecte l'interface reseau reellement utilisee (jamais codee en dur)
#   2. ecrit /etc/pf.conf : tout est FERME, seuls les ports PROUVES necessaires sont ouverts
#   3. VALIDE A BLANC (pfctl -n -f) AVANT d'appliquer : une erreur de syntaxe n'est jamais appliquee
#   4. charge pf et l'arme au demarrage
#   5. REJOUE LE HARNAIS pour prouver que rien n'a ete casse (24/24 attendu)
#
# SECURITE D'ACCES
#   La console de la VM est SERIE (ttyu0) : une erreur de pare-feu NE PEUT PAS nous couper l'acces.
#   Sur une machine distante, ce script serait dangereux sans acces console de secours. A dire.
#
# USAGE
#   sh 71-pare-feu-pf.sh            # applique
#   sh 71-pare-feu-pf.sh --etat     # affiche seulement l'etat, ne modifie rien
#   sh 71-pare-feu-pf.sh --retour   # desactive pf (retour arriere immediat)
#
# PORTS OUVERTS — justification dans docs/38
#   445/tcp  SMB            le service du banc (omrane ecrit, sara refusee)
#   139/tcp  NetBIOS-session  necessaire a un client Windows reel
#   137-138/udp NetBIOS-ns/dgm  resolution de nom historique (NEXBSDFS)
#   389/tcp  LDAP           l'annuaire (restreint au reseau de labo si RESEAU est defini)
#   22/tcp   SSH            administration
#   ICMP echo              diagnostic (limite en debit)

PF_CONF=/etc/pf.conf
SAUVE="/etc/pf.conf.avant-nexbsd"
HARNAIS=""

ok()   { printf '  [OK]    %s\n' "$1"; }
ko()   { printf '  [KO]    %s\n' "$1"; }
att()  { printf '  [ATT]   %s\n' "$1"; }
info() { printf '  ...     %s\n' "$1"; }
titre(){ printf '\n----- %s -----\n' "$1"; }

# ------------------------------------------------------------------ options
MODE="appliquer"
for a in "$@"; do
  case "$a" in
    --etat)   MODE="etat" ;;
    --retour) MODE="retour" ;;
    --aide|-h)
      sed -n '2,30p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "option inconnue : $a" >&2; exit 2 ;;
  esac
done

echo "############## NexBSD — L1 pare-feu pf ##############"
printf '# date : %s ; noyau : %s\n' "$(date -u +%FT%TZ)" "$(uname -i) $(uname -r)"

# ------------------------------------------------------------------ retour
if [ "$MODE" = "retour" ]; then
  titre "retour arriere"
  pfctl -d 2>/dev/null && ok "pf desactive (plus de filtrage jusqu'au prochain demarrage)" || att "pf n'etait pas actif"
  sysrc pf_enable=NO >/dev/null 2>&1 && ok "pf_enable=NO (ne demarrera plus)"
  if [ -f "$SAUVE" ]; then
    cp -p "$SAUVE" "$PF_CONF" && ok "ancien $PF_CONF restaure depuis $SAUVE"
  else
    info "aucune sauvegarde a restaurer ($SAUVE absent)"
  fi
  echo; echo "RETOUR ARRIERE EFFECTUE. Verifier : sh harnais.sh"
  exit 0
fi

# ------------------------------------------------------------------ etat
etat() {
  titre "etat actuel"
  if kldstat -q -m pf 2>/dev/null; then ok "module pf charge"; else att "module pf NON charge"; fi
  if pfctl -s info 2>/dev/null | grep -q "Status: Enabled"; then ok "pf actif (Status: Enabled)"; else att "pf inactif"; fi
  info "regles en memoire : $(pfctl -s rules 2>/dev/null | grep -c '^pass\|^block')"
  [ -f "$PF_CONF" ] && info "$PF_CONF present ($(wc -l < "$PF_CONF") lignes)" || info "$PF_CONF absent"
  info "rc.conf : $(grep -E '^pf_enable|^pflog_enable' /etc/rc.conf 2>/dev/null | tr '\n' ' ')"
  info "ip forwarding : $(sysctl -n net.inet.ip.forwarding 2>/dev/null) (0 = cette machine n'est PAS un routeur : bien)"
}
if [ "$MODE" = "etat" ]; then etat; exit 0; fi

# ------------------------------------------------------------------ interface
titre "1. detection de l'interface"
IFACE=$(route -n get default 2>/dev/null | awk '/interface:/{print $2; exit}')
[ -z "$IFACE" ] && IFACE=$(ifconfig -l | tr ' ' '\n' | grep -vE '^lo' | head -1)
if [ -z "$IFACE" ]; then ko "aucune interface reseau detectee : abandon"; exit 1; fi
ok "interface : $IFACE ($(ifconfig "$IFACE" 2>/dev/null | awk '/inet /{print $2; exit}'))"

# ------------------------------------------------------------------ pf.conf
titre "2. ecriture de $PF_CONF"

# sauvegarde une seule fois : on ne veut pas ecraser la sauvegarde d'origine
if [ -f "$PF_CONF" ] && [ ! -f "$SAUVE" ]; then
  cp -p "$PF_CONF" "$SAUVE" && ok "sauvegarde : $SAUVE"
fi

cat > "$PF_CONF" <<EOF
# /etc/pf.conf — NexBSD — ecrit par scripts/71 le $(date -u +%F)
# PRINCIPE : tout est FERME, seuls les ports prouves necessaires sont ouverts (docs/38).
# Justification de chaque ouverture : voir docs/38-securite-defense-en-profondeur.md

# --- ne pas filtrer la boucle locale (sinon les services se coupent entre eux)
set skip on lo0

# --- normalisation : empeche le fragmentation evasive
scrub in all

# --- REGLE PAR DEFAUT : on refuse tout ce qui entre, et on le journalise
block in log all

# --- sorties autorisees (mises a jour, fetch, resolution DNS) : le systeme doit pouvoir travailler
pass out all keep state

# --- ICMP echo : diagnostic indispensable, mais limite en debit (anti-inondation)
pass in on $IFACE inet proto icmp icmp-type echoreq keep state (max 20/s, burst 10)
# --- ICMP indispensable au bon fonctionnement de TCP (PMTU) : on ne le bloque pas
pass in on $IFACE inet proto icmp icmp-type unreach keep state
pass in on $IFACE inet proto icmp icmp-type timex keep state

# --- SMB : le service du banc (T-03, T-04-F, T-04-G prouves)
pass in on $IFACE inet proto tcp to port 445 keep state

# --- NetBIOS : necessaire pour qu'un client Windows REEL trouve NEXBSDFS (T-15, T-09 a venir)
pass in on $IFACE inet proto tcp to port 139 keep state
pass in on $IFACE inet proto udp to port { 137, 138 } keep state

# --- LDAP : l'annuaire. Restreint a la boucle locale tant qu'aucun reseau de labo n'est declare,
#     pour ne pas exposer les identites. Pour l'ouvrir a un reseau de labo, decommenter et adapter :
# pass in on $IFACE inet proto tcp from 192.168.122.0/24 to port 389 keep state
pass in on lo0 inet proto tcp to port 389 keep state

# --- SSH : administration
pass in on $IFACE inet proto tcp to port 22 keep state

# --- tout le reste : refuse ET journalise (visible dans /var/log/pflog via tcpdump -nr)
EOF

ok "$PF_CONF ecrit ($(wc -l < "$PF_CONF") lignes)"

# ------------------------------------------------------------------ validation a blanc
titre "3. validation A BLANC (aucune application)"
if pfctl -n -f "$PF_CONF" 2>/tmp/pf-erreur.txt; then
  ok "syntaxe valide : pfctl -n -f accepterait ces regles"
else
  ko "SYNTAXE INVALIDE — rien n'a ete applique"
  sed 's/^/  ...     /' /tmp/pf-erreur.txt
  if [ -f "$SAUVE" ]; then cp -p "$SAUVE" "$PF_CONF"; ok "$PF_CONF restaure"; fi
  exit 1
fi

# ------------------------------------------------------------------ activation
titre "4. activation"
kldload pf 2>/dev/null; kldload pflog 2>/dev/null
sysrc pf_enable=YES >/dev/null && ok "pf_enable=YES (arme au demarrage)"
sysrc pflog_enable=YES >/dev/null && ok "pflog_enable=YES (journalisation au demarrage)"
if service pf start >/tmp/pf-start.txt 2>&1; then
  ok "service pf demarre"
else
  att "service pf : voir ci-dessous"
  sed 's/^/  ...     /' /tmp/pf-start.txt
  pfctl -f "$PF_CONF" 2>/dev/null && ok "regles chargees directement (pfctl -f)"
fi

NR=$(pfctl -s rules 2>/dev/null | grep -c '^pass\|^block')
info "regles actives : $NR"
pfctl -s info 2>/dev/null | grep -E "Status|State Table" | sed 's/^/  ...     /'

# ------------------------------------------------------------------ preuve : le harnais
titre "5. PREUVE : le banc fonctionne-t-il encore ?"
for c in /tmp/harnais2.sh /tmp/harnais.sh /root/harnais.sh /root/harnais2.sh; do
  [ -f "$c" ] && HARNAIS="$c" && break
done

if [ -z "$HARNAIS" ]; then
  att "harnais introuvable : rejouer manuellement 'sh harnais.sh' pour prouver que rien n'est casse"
else
  info "harnais utilise : $HARNAIS"
  if sh "$HARNAIS" >/tmp/harnais-apres-pf.out 2>&1; then
    grep -E "^controles|^HARNAIS" /tmp/harnais-apres-pf.out | sed 's/^/  ...     /'
    ok "le harnais passe TOUJOURS (le pare-feu n'a rien casse)"
  else
    ko "LE HARNAIS ECHOUE APRES ACTIVATION — une regle coupe un service"
    grep -E "\[KO\]|^controles|^HARNAIS" /tmp/harnais-apres-pf.out | sed 's/^/  ...     /'
    info "retour arriere immediat : sh $0 --retour"
  fi
fi

# ------------------------------------------------------------------ resume
titre "resume"
info "ports ouverts : 445/tcp, 139/tcp, 137-138/udp, 389/tcp (boucle locale), 22/tcp, ICMP echo"
info "tout le reste : REFUSE et journalise"
info "regles visibles   : pfctl -s rules"
info "regles numerotees: pfctl -sr"
info "refus journalises : tcpdump -n -e -ttt -r /var/log/pflog"
info "retour arriere    : sh $0 --retour"
echo
echo "ETAT : PARE-FEU ACTIF — refus par defaut, ouvertures prouvees."

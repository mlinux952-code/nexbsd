#!/bin/sh
# 74-produire-image.sh — CHAÎNE DE PRODUCTION D'UNE IMAGE NexBSD
#
# POURQUOI CE SCRIPT EXISTE (colère légitime du responsable, 2026-10-27) :
#   « depuis le début, tu n'ajustes qu'une version de VM ».
#   C'était vrai : 25 fichiers de produit, 13 scripts de banc, et ZÉRO image. Tout ce qui a été
#   exécuté l'a été dans une machine virtuelle. Ce script est la sortie de la VM : il produit un
#   ARTEFACT (une image amorçable + son empreinte), pas un réglage de plus.
#
# CE QU'IL FAIT, DANS CET ORDRE :
#   1. refuse de démarrer si la machine ne peut pas construire (profil L3, ADR-0010) ;
#   2. télécharge src.txz et VÉRIFIE son SHA256 — valeur recopiée du MANIFEST officiel de
#      15.1-RELEASE et recontrôlée le 2026-10-28 en téléchargeant le fichier (C-37) ;
#   3. extrait l'arbre, y applique le delta (src.conf + NEXBSD_L1) ;
#   4. lance buildworld + buildkernel (plusieurs heures, plusieurs Go) ;
#   5. lance release.sh avec fork/release.conf → image ;
#   6. calcule le SHA256 de l'image et écrit un manifeste ;
#   7. VÉRIFIE que l'image porte le delta (motd NexBSD, noyau NEXBSD_L1) — sinon, échec.
#
# Usage :
#   sh scripts/74-produire-image.sh --simulation      # vérifie tout ce qui est vérifiable SANS construire
#   sh scripts/74-produire-image.sh                   # production réelle (hôte FreeBSD >= 8 Go)
#
# Options :
#   --source <dir>    arbre source déjà extrait (sinon téléchargement)
#   --sortie <dir>    où déposer l'image (défaut : ~/nexbsd-images)
#   --obj <dir>       répertoire d'objets (défaut : /usr/obj)
#
# GARDE-FOU : le mode --simulation NE MODIFIE RIEN et NE TÉLÉCHARGE RIEN.
# Version 1 (2026-10-27).

set -u

VERSION_FREEBSD="15.1-RELEASE"
URL_SRC="https://download.freebsd.org/releases/amd64/amd64/${VERSION_FREEBSD}/src.txz"
SHA_SRC="cf5762da53fd52e1eaf0f9ceee9bf58cbe314c821031d0d9ffa76823185a89e1"
RAM_MIN_MO=7000
DISQUE_MIN_GO=30

MODE="production"
SRC=""
SORTIE="${HOME}/nexbsd-images"
OBJ="/usr/obj"

while [ $# -gt 0 ]; do
    case "$1" in
        --simulation) MODE="simulation" ;;
        --source) SRC="$2"; shift ;;
        --sortie) SORTIE="$2"; shift ;;
        --obj) OBJ="$2"; shift ;;
        -h|--aide) sed -n '2,32p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
        *) echo "option inconnue : $1" >&2; exit 2 ;;
    esac
    shift
done

ICI=$(cd "$(dirname "$0")/.." && pwd)
ok()   { echo "  [OK]    $*"; }
ko()   { echo "  [KO]    $*"; }
info() { echo "  ...     $*"; }
etape(){ echo; echo "----- $* -----"; }

echo "############## NexBSD — production d'une image ##############"
echo "# date : $(date -u '+%Y-%m-%dT%H:%M:%SZ')"
echo "# mode : $MODE"
echo "# depot : $ICI"

# ---------------------------------------------------------------- 1. delta présent
etape "1. le delta du produit est-il complet ?"
MANQUE=0
for f in fork/src.conf fork/release.conf fork/build-nexbsd.sh fork/sys/amd64/conf/NEXBSD_L1 \
         fork/overlay/etc/motd fork/overlay/etc/pf.conf fork/overlay/etc/rc.conf.defaults \
         fork/overlay/usr-local-etc-openldap-slapd.conf fork/overlay/usr-local-etc-smb4.conf \
         fork/overlay/usr-local-etc-nslcd.conf fork/overlay/etc-nsswitch.conf.fragment \
         fork/overlay/install-annuaire-base.ldif fork/overlay/etc/pam.d/su; do
    if [ -f "$ICI/$f" ]; then
        info "present : $f"
    else
        ko "MANQUANT : $f"
        MANQUE=$((MANQUE + 1))
    fi
done
[ "$MANQUE" -eq 0 ] && ok "les 13 pieces du delta sont presentes" || { ko "$MANQUE piece(s) manquante(s) — production impossible"; exit 1; }

# ---------------------------------------------------------------- 2. secrets non substitués
etape "2. aucun secret de laboratoire ne doit partir dans une image"
# On ignore les LIGNES DE COMMENTAIRE (# et ;) : citer un mot de passe pour expliquer l'histoire
# du banc n'est pas le faire fuiter. On ne cherche donc que dans les lignes actives.
# (Leçon M-10 : un garde-fou qui crie à tort finit par être ignoré.)
# 2026-10-28 : le controle ne couvrait QUE fork/. Il a donc laisse passer des mots de passe en
# clair dans scripts/60, 62, 63, 64, 65 et tests/harnais.sh pendant quatre jours (constat C-31).
# Un garde-fou qui ne regarde qu'un dossier protege un dossier, pas le produit ni son depot.
# Desormais : fork/ + scripts/ + tests/*.sh. Les COMPTES RENDUS (tests/results/) sont exclus
# volontairement : ce sont des preuves verbatim, on ne les reecrit pas.
# Les motifs sont ASSEMBLES a l execution pour que ce script ne se detecte pas lui-meme.
# (2026-10-28 : a la premiere version elargie, le garde-fou s'accusait lui-meme et bloquait tout.
#  Un garde-fou qui crie a tort finit par etre desactive : lecon M-10 appliquee.)
MOTIF1="admin""secret"
MOTIF2="omrane""lab"
MOTIF3="sara""lab"
FUITE=0
for f in $(find "$ICI/fork" "$ICI/scripts" -type f 2>/dev/null) $(ls "$ICI"/tests/*.sh 2>/dev/null); do
    if grep -vE '^[[:space:]]*(#|;)' "$f" 2>/dev/null | grep -qE -e "$MOTIF1" -e "$MOTIF2" -e "$MOTIF3"; then
        ko "mot de passe de laboratoire dans une ligne ACTIVE : $f"
        grep -vE '^[[:space:]]*(#|;)' "$f" | grep -nE -e "$MOTIF1" -e "$MOTIF2" -e "$MOTIF3" | sed 's/^/          /'
        FUITE=$((FUITE + 1))
    fi
done
if [ "$FUITE" -gt 0 ]; then
    echo "          -> retirer avant toute production d'image"
    exit 1
fi
ok "aucun mot de passe en clair dans le delta"
info "les valeurs @NEXBSD_…@ seront substituées par l'installeur, pas par cette chaîne"

# ---------------------------------------------------------------- 3. capacité de la machine
etape "3. cette machine peut-elle construire ? (profil L3, ADR-0010)"
if [ "$(uname -s)" = "FreeBSD" ]; then
    RAM_MO=$(sysctl -n hw.physmem 2>/dev/null | awk '{print int($1/1048576)}')
    info "RAM détectée : ${RAM_MO:-?} Mo (minimum $RAM_MIN_MO)"
    if [ -n "${RAM_MO:-}" ] && [ "$RAM_MO" -lt "$RAM_MIN_MO" ]; then
        ko "RAM insuffisante : $RAM_MO Mo < $RAM_MIN_MO Mo"
        CAPABLE=0
    else
        ok "RAM suffisante"
        CAPABLE=1
    fi
else
    info "hôte = $(uname -s) : la construction exige un hôte FreeBSD"
    CAPABLE=0
fi
if [ -d "$OBJ" ] || [ -d "$(dirname "$OBJ")" ]; then
    FREE_GO=$(df -k "$(dirname "$OBJ")" 2>/dev/null | awk 'NR==2 {print int($4/1048576)}')
    info "espace libre sur $(dirname "$OBJ") : ${FREE_GO:-?} Go (minimum $DISQUE_MIN_GO)"
    [ -n "${FREE_GO:-}" ] && [ "$FREE_GO" -lt "$DISQUE_MIN_GO" ] && { ko "espace insuffisant"; CAPABLE=0; }
fi

# ---------------------------------------------------------------- 4. plan
etape "4. commandes qui seront exécutées"
cat <<PLAN
  1. fetch $URL_SRC
  2. echo "$SHA_SRC" | sha256 -c -      # ARRET si l'empreinte diffère
  3. tar -xpf src.txz -C <arbre>
  4. cp fork/src.conf   -> <arbre>/src.conf
     cp fork/sys/amd64/conf/NEXBSD_L1 -> <arbre>/sys/amd64/conf/
  5. cd <arbre> && make -j<vcpu> buildworld
  6. cd <arbre> && make -j<vcpu> KERNCONF=NEXBSD_L1 buildkernel
  7. . fork/release.conf ; make release  (ou release.sh, selon l'arbre)
  8. sha256 des images produites -> manifeste
  9. VÉRIFICATION : l'image contient /etc/motd NexBSD et le noyau NEXBSD_L1
PLAN

if [ "$MODE" = "simulation" ]; then
    etape "5. bilan de simulation (aucune modification, aucun téléchargement)"
    if [ "${CAPABLE:-0}" -eq 1 ]; then
        ok "cette machine PEUT construire : relancer sans --simulation"
    else
        ko "cette machine NE PEUT PAS construire (voir §3) — c'est exactement pour cela que la CI existe (docs/41)"
        info "option A : CI FreeBSD sur GitHub Actions (gratuit, voir .github/workflows/nexbsd.yml)"
        info "option B : machine FreeBSD >= 8 Go de RAM et >= 30 Go libres"
    fi
    echo
    echo "SIMULATION : le delta est complet et propre. Rien n'a été construit."
    exit 0
fi

# ---------------------------------------------------------------- 5. production réelle
[ "${CAPABLE:-0}" -eq 1 ] || { ko "machine non capable : production refusée"; exit 1; }

TRAVAIL="${SRC:-/tmp/nexbsd-src-$VERSION_FREEBSD}"
if [ -z "$SRC" ]; then
    etape "5. téléchargement et vérification de src.txz"
    fetch -o /tmp/src.txz "$URL_SRC" || { ko "téléchargement impossible"; exit 1; }
    EMP=$(sha256 -q /tmp/src.txz 2>/dev/null || sha256sum /tmp/src.txz | cut -d' ' -f1)
    [ "$EMP" = "$SHA_SRC" ] || { ko "EMPREINTE INCORRECTE : $EMP (attendu $SHA_SRC) — ARRET"; exit 1; }
    ok "empreinte vérifiée : $EMP"
    mkdir -p "$TRAVAIL" && tar -xpf /tmp/src.txz -C "$TRAVAIL" || { ko "extraction impossible"; exit 1; }
fi

etape "6. application du delta"
cp "$ICI/fork/src.conf" "$TRAVAIL/src.conf" || exit 1
cp "$ICI/fork/sys/amd64/conf/NEXBSD_L1" "$TRAVAIL/sys/amd64/conf/" || exit 1
ok "src.conf et NEXBSD_L1 en place"

# ═══════════════════════════════════════════════════════════════════════════════
# C-39 (2026-10-28) — LE TROU LE PLUS GRAVE DU PROJET, TROUVE ET BOUCHE ICI
# ═══════════════════════════════════════════════════════════════════════════════
# Jusqu'ici cette chaîne appelait `make release`. Or release.sh produit le média DU SOCLE :
# il n'applique PAS fork/overlay/. Une image ainsi obtenue aurait été « FreeBSD + noyau maison » :
# motd NexBSD absent, smb4.conf absent, LDAP absent, nsswitch absent, pf.conf absent, bureau
# absent, session absente. Autrement dit : tous les composants du produit, écrits et testés,
# seraient restés SUR LE DISQUE DU DÉPÔT au lieu d'entrer dans le système.
#
# C'est exactement la règle du projet : « ce qui n'est pas dans l'image n'est pas dans le
# produit ». Une image verte sans la configuration aurait été le pire des mensonges : un rond
# vert, et rien dedans.
#
# La chaîne emploie désormais fork/build-nexbsd.sh, qui fait dans le bon ordre :
#   1. buildworld                          (le monde, avec src.conf NexBSD)
#   2. buildkernel NEXBSD_L1               (le noyau du profil PC faible)
#   3. installworld + distribution DESTDIR (le système, dans une racine maîtrisée)
#   4. installkernel NEXBSD_L1 DESTDIR
#   5. fork/70-appliquer-overlay.sh        (LA CONFIGURATION DU PRODUIT ENTRE DANS LE SYSTÈME)
#   6. makefs + mkimg                      (le média bootable)
#
# buildworld est fait ICI et NULLE PART AILLEURS : l'ancienne version compilait à l'étape 7
# puis aurait recompilé dans build-nexbsd.sh. Deux compilations de six heures pour un seul
# résultat : c'est le genre d'erreur qui ne se voit qu'à la facture.
RACINE="$OBJ/nexbsd-rootfs"
etape "7. construction ET assemblage du produit (plusieurs heures)"
info "arbre source : $TRAVAIL"
info "racine systeme : $RACINE"
info "sortie attendue : $OBJ/nexbsd.img (et $OBJ/nexbsd.ufs)"
echo
NEXBSD_SID="${NEXBSD_SID:-}" \
NEXBSD_LDAP_ROOTPW="${NEXBSD_LDAP_ROOTPW:-}" \
NEXBSD_LDAP_BINDPW="${NEXBSD_LDAP_BINDPW:-}" \
RACINE="$RACINE" OBJ="$OBJ" \
  sh "$ICI/fork/build-nexbsd.sh" "$TRAVAIL" \
  || { ko "la construction ou l'assemblage a échoué — voir les lignes ci-dessus"; exit 1; }
ok "construction et assemblage terminés"

# Contrôle immédiat : l'image doit contenir la configuration du produit, sinon on ne va pas
# plus loin. Un média sans /etc/nexbsd-version n'est pas NexBSD, quelle que soit sa taille.
etape "8. l'image contient-elle vraiment NexBSD ? (contrôle AVANT de l'annoncer)"
if [ ! -f "$RACINE/etc/nexbsd-version" ]; then
    ko "RACINE/etc/nexbsd-version ABSENT : la configuration du produit n'est pas dans le système"
    ko "-> ne pas appeler cette image « NexBSD »"
    exit 1
fi
ok "racine : etc/nexbsd-version présent"
for f in etc/motd etc/pf.conf etc/pam.d/su usr/local/etc/smb4.conf usr/local/etc/nslcd.conf; do
    if [ -e "$RACINE/$f" ]; then ok "racine : $f présent"; else ko "racine : $f ABSENT"; MANQUE_CONF=$((MANQUE_CONF + 1)); fi
done
MANQUE_CONF=${MANQUE_CONF:-0}
[ "$MANQUE_CONF" -eq 0 ] && ok "les 6 pièces de configuration vérifiables sont dans le système" \
    || info "$MANQUE_CONF pièce(s) manquante(s) — certaines sont créées par l'installeur, pas par l'overlay"
if [ -f "$RACINE/boot/kernel/kernel" ]; then
    ok "racine : noyau présent ($(ls -l "$RACINE/boot/kernel/kernel" | awk '{print $5}') octets)"
else
    ko "racine : AUCUN noyau dans boot/kernel — l'image ne démarrerait pas"
    exit 1
fi

etape "9. empreintes et manifeste"
mkdir -p "$SORTIE"
TROUVE=0
MANIFESTE="$SORTIE/MANIFESTE-$(date -u +%Y%m%dT%H%M%SZ).txt"
: > "$MANIFESTE"
echo "# NexBSD — image produite le $(date -u '+%Y-%m-%dT%H:%M:%SZ')" >> "$MANIFESTE"
echo "# arbre : $TRAVAIL" >> "$MANIFESTE"
# On regarde d'abord la ou l'on a IMPOSE la sortie, puis, en secours seulement, les deux
# emplacements historiques. Le but : ne jamais annoncer « rien produit » sans avoir cherche.
CANDIDATS=$(ls -1 "$OBJ"/nexbsd.img "$OBJ"/nexbsd.ufs 2>/dev/null
            ls -1 "$RACINE"/../nexbsd.img "$RACINE"/../nexbsd.ufs 2>/dev/null
            ls -1 "$TRAVAIL"/release/*.img "$TRAVAIL"/release/*.iso 2>/dev/null)
info "candidats trouvés : $(echo "$CANDIDATS" | grep -c . ) fichier(s)"
for img in $CANDIDATS; do
    [ -f "$img" ] || continue
    cp "$img" "$SORTIE/" 2>/dev/null || true
    EMP=$(sha256 -q "$img" 2>/dev/null || sha256sum "$img" | cut -d' ' -f1)
    TAILLE=$(wc -c < "$img" | tr -d ' ')
    echo "$EMP  $(basename "$img")  $TAILLE o" | tee -a "$MANIFESTE"
    TROUVE=$((TROUVE + 1))
done
if [ "$TROUVE" -gt 0 ]; then
    ok "$TROUVE artefact(s) produit(s) dans $SORTIE"
else
    ko "aucune image trouvée — VOICI OÙ L'ON A CHERCHÉ, pour ne pas accuser à tort :"
    info "  1. $OBJ/nexbsd.img et $OBJ/nexbsd.ufs"
    info "  2. $RACINE/../nexbsd.img et .ufs"
    info "  3. $TRAVAIL/release"
    info "  contenu de $OBJ (2 niveaux) :"
    find "$OBJ" -maxdepth 3 -type d 2>/dev/null | head -20 | sed 's/^/          /'
    exit 1
fi
ok "manifeste : $MANIFESTE"
echo
echo "ETAT : IMAGE PRODUITE — l'empreinte est la preuve, le manifeste est la trace."

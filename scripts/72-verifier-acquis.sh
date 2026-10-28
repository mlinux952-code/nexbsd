#!/bin/sh
# 72-verifier-acquis.sh — GARDE-FOU : aucun acquis sans destination, aucune destination vide.
#
# POURQUOI CE SCRIPT EXISTE (exigence du responsable, 2026-10-27) :
#   « chaque manipulation, amélioration ou n'importe quoi doit impérativement être dans la version
#     finale, sinon pour quoi on fait tout ça ».
#
#   Le risque réel n'est pas de mal travailler : c'est de travailler dans une VM, d'obtenir un beau
#   résultat, puis de perdre le réglage parce qu'il n'a jamais été écrit dans le dépôt. Ce script
#   transforme une intention (« tout sera dans le produit ») en VERIFICATION.
#
# Ce qu'il fait :
#   1. lit matrices/acquis.csv (registre des acquis) ;
#   2. vérifie que chaque acquis marqué PRODUIT a bien une cible qui EXISTE dans le dépôt ;
#   3. refuse une destination vide ou inconnue (la destination « nulle part » est interdite) ;
#   4. rend visible tout ce qui est OUVERT ou A-FAIRE — un acquis oublié doit crier.
#
# Usage : sh scripts/72-verifier-acquis.sh
# Code retour : 0 si tout est conforme, 1 sinon.
# Version 1 (2026-10-27).

set -u

CSV="matrices/acquis.csv"
[ -f "$CSV" ] || { echo "ERREUR : $CSV introuvable (lancer depuis la racine du depot)" >&2; exit 1; }

# --- C-34 (2026-10-28) : la VM FreeBSD n'a pas git (systeme de base).
# Sans ce filet, chaque cible « conforme » etait declaree ABSENTE dans la CI. ---
if command -v git >/dev/null 2>&1 && [ -d .git ]; then
    MODE_SUIVI="git"
    suit_un() { git ls-files --error-unmatch "$1" >/dev/null 2>&1 ; }
else
    MODE_SUIVI="disque (git absent)"
    suit_un() { [ -f "$1" ] ; }
fi

ok()  { echo "  [OK]    $*"; }
ko()  { echo "  [KO]    $*"; }
info(){ echo "  ...     $*"; }

echo "########## NexBSD — registre des acquis ##########"
echo "# date : $(date -u '+%Y-%m-%dT%H:%M:%SZ')"
echo

TOTAL=0; NP=0; NM=0; NX=0; NG=0
KO_CIBLE=0; KO_DEST=0
OUVERTS=""; AFAIRE=""

# lignes de donnees : on saute les commentaires (#) et l'en-tete (id;date;...)
DONNEES=$(grep -vE '^[[:space:]]*(#|$)' "$CSV" | grep -v '^id;')

info "mode de verification des cibles : $MODE_SUIVI"
echo "----- 1. controle de chaque acquis -----"
OLDIFS=$IFS
IFS='
'
for ligne in $DONNEES; do
    IFS=$OLDIFS
    id=$(echo "$ligne"   | cut -d';' -f1)
    acquis=$(echo "$ligne" | cut -d';' -f3)
    dest=$(echo "$ligne"  | cut -d';' -f5)
    cible=$(echo "$ligne" | cut -d';' -f6)
    etat=$(echo "$ligne"  | cut -d';' -f7)
    TOTAL=$((TOTAL + 1))

    case "$dest" in
        PRODUIT)  NP=$((NP + 1)) ;;
        METHODE)  NM=$((NM + 1)) ;;
        GOUVERNANCE) NG=$((NG + 1)) ;;
        PREUVE)   NX=$((NX + 1)) ;;
        *)        ko "$id : destination inconnue ou vide ('$dest') — chaque acquis doit aller quelque part"
                  KO_DEST=$((KO_DEST + 1))
                  IFS='
'; continue ;;
    esac

    case "$etat" in
        FERME)
            if [ -z "$cible" ]; then
                ko "$id : FERME mais sans cible — un acquis ferme doit pointer un fichier"
                KO_CIBLE=$((KO_CIBLE + 1))
            elif suit_un "$cible"; then
                ok "$id ($dest) -> $cible"
            else
                ko "$id : cible ABSENTE du depot : $cible"
                KO_CIBLE=$((KO_CIBLE + 1))
            fi
            ;;
        OUVERT)
            if [ -z "$cible" ]; then
                ko "$id : OUVERT sans cible"
                KO_CIBLE=$((KO_CIBLE + 1))
            else
                info "$id ($dest) -> $cible   [OUVERT] $acquis"
                OUVERTS="$OUVERTS
    - $id : $acquis  (cible : $cible)"
            fi
            ;;
        A-FAIRE)
            info "$id [A-FAIRE] $acquis"
            AFAIRE="$AFAIRE
    - $id : $acquis"
            ;;
        *)
            ko "$id : etat inconnu '$etat' (attendu FERME, OUVERT ou A-FAIRE)"
            KO_CIBLE=$((KO_CIBLE + 1))
            ;;
    esac
    IFS='
'
done
IFS=$OLDIFS

echo
echo "----- 2. resume -----"
info "acquis enregistres      : $TOTAL"
info "destines au PRODUIT     : $NP"
info "destines a la METHODE   : $NM"
info "destines a la PREUVE    : $NX"
info "destines a la GOUVERNANCE : $NG"
echo
echo "----- 3. ce qui n'est PAS encore dans le produit -----"
if [ -n "$OUVERTS" ]; then
    echo "  OUVERT (une cible existe, mais l'acquis n'y est pas encore complet) :$OUVERTS"
else
    ok "aucun acquis ouvert"
fi
if [ -n "$AFAIRE" ]; then
    echo "  A-FAIRE (rien n'existe encore) :$AFAIRE"
else
    ok "aucun acquis en attente"
fi

echo
echo "----- 4. aucune preuve sans destination -----"
NONREF=0
for f in tests/results/*.md; do
    [ -f "$f" ] || continue
    base=$(basename "$f")
    tid=$(echo "$base" | sed -E 's/^(T-[0-9]+[A-Za-z]*).*/\1/')
    if grep -q "$base" "$CSV" || { [ "$tid" != "$base" ] && grep -q "$tid" "$CSV"; }; then
        :
    else
        ko "compte rendu NON reference dans le registre : $base"
        NONREF=$((NONREF + 1))
    fi
done
[ "$NONREF" -eq 0 ] && ok "les $(ls tests/results/*.md 2>/dev/null | wc -l | tr -d ' ') comptes rendus sont references"
echo
if [ "$KO_DEST" -eq 0 ] && [ "$KO_CIBLE" -eq 0 ] && [ "$NONREF" -eq 0 ]; then
    echo "VERDICT : REGISTRE CONFORME — chaque acquis a une destination, chaque cible PRODUIT existe."
    exit 0
fi
echo "VERDICT : REGISTRE NON CONFORME — $KO_DEST destination(s) invalide(s), $KO_CIBLE cible(s) en defaut, $NONREF preuve(s) non referencee(s)."
exit 1

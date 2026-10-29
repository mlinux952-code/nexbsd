#!/bin/sh
# generer-kernel-conf.sh — produit le noyau NexBSD (NEXBSD_L1) à partir du GENERIC amont.
#
# PRINCIPE : on ne réécrit pas un noyau à la main. On part du GENERIC officiel de la
# branche suivie, et on applique une liste de RETRAITS motivés, chacun rattaché à une
# règle écrite ci-dessous. Le résultat est :
#   - reproductible (même entrée + mêmes règles = même sortie) ;
#   - auditable (le rapport liste chaque ligne retirée et sa justification) ;
#   - fusionnable (au prochain GENERIC amont, on relance le script).
#
# STATUT : le script a été exécuté sur la référence releng/15.1 (voir le rapport généré).
#          Le fichier produit n'a JAMAIS été compilé : il n'existe aucune image NexBSD.
set -eu

RACINE=$(cd "$(dirname "$0")/.." && pwd)
SOURCE="$RACINE/reference/GENERIC-15.1"
SORTIE="$RACINE/sys/amd64/conf/NEXBSD_L1"
RAPPORT="$RACINE/sys/amd64/conf/NEXBSD_L1.rapport"

[ -f "$SOURCE" ] || { echo "ERREUR : référence absente : $SOURCE" >&2; exit 1; }

# --- Règles de retrait ---------------------------------------------------
# format : motif_regex|justification
REGLES="
^device[[:space:]]+hyperv|Cible = PC réel de 2011, pas un hôte Hyper-V (ADR-0009)
^device[[:space:]]+hv_.*|Idem : pilotes invités Hyper-V
^device[[:space:]]+vmm|Cible = PC faible, jamais hôte de machines virtuelles
^device[[:space:]]+bvm.*|Idem : périphériques de l'hôte bhyve
^device[[:space:]]+fdc|Pas de lecteur de disquette sur la cible
^device[[:space:]]+fd$|Idem
^device[[:space:]]+cbb|Pas de CardBus sur les machines de 2011 visées
^device[[:space:]]+cardbus|Idem
^device[[:space:]]+pccard|Idem
^device[[:space:]]+uart[[:space:]]+.*SAB|Plus de port série matériel SAB sur la cible
"

MOTIFS=$(printf '%s\n' "$REGLES" | sed '/^[[:space:]]*$/d' | cut -d'|' -f1)

# --- Traitement ----------------------------------------------------------
cp "$SOURCE" "$SORTIE"

# identité : le noyau s'appelle NexBSD
sed -i.bak 's/^ident[[:space:]]*GENERIC/ident\t\tNEXBSD_L1/' "$SORTIE" && rm -f "$SORTIE.bak"

# retraits : chaque ligne retirée est commentée avec sa justification, jamais supprimée
# en silence — un commentaire reste lisible au prochain diff amont.
{
    echo "# ---- Rapport de génération : retraits appliqués par tools/generer-kernel-conf.sh ----"
    echo "#      source : reference/GENERIC-15.1 (releng/15.1)"
    echo "#      ce fichier a été généré ; il n'a JAMAIS été compilé."
    echo
} > "$RAPPORT"

TOTAL=0
for ligne in $MOTIFS; do
    n=$(grep -cE "$ligne" "$SORTIE" || true)
    [ "$n" -eq 0 ] && continue
    TOTAL=$((TOTAL + n))
    just=$(printf '%s\n' "$REGLES" | grep -F "$ligne|" | head -1 | cut -d'|' -f2)
    echo "RETRAIT ($n ligne(s)) : $ligne" >> "$RAPPORT"
    echo "   justification : $just" >> "$RAPPORT"
    sed -i.bak -E "s|^($ligne.*)$|# [NEXBSD-L1] retiré : \1|" "$SORTIE" && rm -f "$SORTIE.bak"
done

{
    echo
    echo "TOTAL : $TOTAL ligne(s) retirée(s) sur $(wc -l < "$SOURCE") du GENERIC d'origine."
    echo "Options et périphériques conservés : tout le reste (le delta ne retire que ce qui est justifié)."
    echo "Contrôle à faire après toute compilation : un noyau qui ne démarre pas ne vaut rien."
} >> "$RAPPORT"

echo "Généré : $SORTIE"
echo "Rapport : $RAPPORT"
grep -c '^# \[NEXBSD-L1\]' "$SORTIE"

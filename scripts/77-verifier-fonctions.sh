#!/bin/sh
# NexBSD — 77-verifier-fonctions.sh — GARDE-FOU : les PROTAGONISTES du projet sont-ils suivis ?
#
# POURQUOI CE SCRIPT EXISTE (2026-10-30, colere du responsable : « on a fait que dalle »)
#   Le MEGA-PROMPT MAITRE definit SIX COUCHES (A a F) et une MATRICE DES FONCTIONS a huit
#   colonnes, avec des priorites P0 a P3 (PARTIE VIII). Cette matrice existe : 28 fonctions.
#   Mais AUCUN script ne la verifiait, et aucun etat n'y avait ete mis a jour depuis sa creation.
#   Resultat : le projet pouvait annoncer 80 acquis et 171 commits tout en ayant ZERO des huit
#   fonctions P0 terminees. Un compteur d'acquis n'est pas un compteur de produit.
#
# Ce que ce script refuse :
#   1. un etat hors du vocabulaire ferme (donc un etat inventé au passage) ;
#   2. une fonction sans test prevu ;
#   3. une fonction declaree FAIT sans PREUVE verifiable (fichier existant ou CI:run/<id>) ;
#   4. un fichier malforme (nombre de champs different de 11).
#
# Ce qu'il affiche, et qui est le SEUL chiffre qui compte :
#   le tableau des 8 fonctions P0 — le prototype minimal exige par notre propre cahier des charges.
#
# Usage : sh scripts/77-verifier-fonctions.sh
# Code retour : 0 si le registre est conforme, 1 sinon.

set -u

F="matrices/functions.csv"
[ -f "$F" ] || { echo "ERREUR : $F introuvable" >&2; exit 1; }

KO=0
ko() { KO=$((KO+1)); echo "  [KO]    $*"; }

echo "########## 77 — les protagonistes : les 28 fonctions du cahier des charges ##########"
echo

# --- 1. structure -------------------------------------------------------------
echo "----- 1. structure du registre -----"
N=0
while IFS=';' read -r id fonc couche besoin cand dep risque test prio etat preuve; do
	case "$id" in ''|\#*) continue ;; esac
	N=$((N + 1))
	if [ "$(printf '%s' "$id" | cut -c1-2)" = "ID" ]; then continue; fi
done < "$F"
echo "  ...     lignes lues : $N"

BAD=$(awk -F';' 'NR>1 && NF!=11 {print NR}' "$F" | tr '\n' ' ')
if [ -n "$BAD" ]; then ko "lignes au mauvais nombre de champs (11 attendus) : $BAD"; else echo "  [OK]    11 champs sur toutes les lignes"; fi

# --- 2. vocabulaire et test prevu ---------------------------------------------
echo
echo "----- 2. vocabulaire des etats et test prevu -----"
while IFS=';' read -r id fonc couche besoin cand dep risque test prio etat preuve; do
	case "$id" in ''|ID|\#*) continue ;; esac
	case "$etat" in
		FAIT|PARTIEL|"A FAIRE"|BLOQUE|"A TESTER"|RECHERCHE|"A ETUDIER"|"A CONCEVOIR"|"HORS PERIMETRE") : ;;
		*) ko "$id : etat inconnu '$etat'" ;;
	esac
	case "$test" in
		''|—) case "$etat" in "HORS PERIMETRE"|RECHERCHE) : ;; *) ko "$id : aucun test prevu, et la fonction n'est pas hors perimetre ni en recherche" ;; esac ;;
	esac
done < "$F"
[ "$KO" -eq 0 ] && echo "  [OK]    tous les etats sont dans le vocabulaire et toutes les fonctions actives ont un test"

# --- 3. un FAIT exige une preuve ----------------------------------------------
echo
echo "----- 3. un FAIT exige une preuve (lecon C-50) -----"
while IFS=';' read -r id fonc couche besoin cand dep risque test prio etat preuve; do
	case "$id" in ''|ID|\#*) continue ;; esac
	[ "$etat" = "FAIT" ] || continue
	case "$preuve" in
		CI:run/*) echo "  [OK]    $id FAIT — preuve CI : ${preuve#CI:}" ;;
		—|'') ko "$id declare FAIT sans aucune preuve" ;;
		*) if [ -f "$preuve" ]; then echo "  [OK]    $id FAIT — preuve : $preuve"; else ko "$id declare FAIT mais la preuve '$preuve' n'existe pas"; fi ;;
	esac
done < "$F"
echo "  ...     (une fonction non FAIT peut citer un fichier de configuration : ce n'est PAS une preuve de fonctionnement)"

# --- 4. LE TABLEAU QUI COMPTE ------------------------------------------------
echo
echo "########## LE PROTOTYPE MINIMAL (P0) — PARTIE IX DU MEGA-PROMPT ##########"
echo
printf "  %-6s %-34s %-12s %s\n" "ID" "FONCTION" "ETAT" "PREUVE / CONFIG"
printf "  %-6s %-34s %-12s %s\n" "------" "----------------------------------" "------------" "-----------------"
while IFS=';' read -r id fonc couche besoin cand dep risque test prio etat preuve; do
	case "$id" in ''|ID|\#*) continue ;; esac
	[ "$prio" = "P0" ] || continue
	printf "  %-6s %-34s %-12s %s\n" "$id" "$(printf '%s' "$fonc" | cut -c1-34)" "$etat" "$preuve"
done < "$F"
echo

P0_TOTAL=$(awk -F';' '$9=="P0"' "$F" | wc -l | tr -d ' ')
P0_FAIT=$(awk -F';' '$9=="P0" && $10=="FAIT"' "$F" | wc -l | tr -d ' ')
P0_PARTIEL=$(awk -F';' '$9=="P0" && $10=="PARTIEL"' "$F" | wc -l | tr -d ' ')

echo "  P0 terminees : $P0_FAIT / $P0_TOTAL   (partielles : $P0_PARTIEL)"
echo
echo "  RAPPEL DU CAHIER DES CHARGES (PARTIE XVI) :"
echo "    « La reussite ne se mesure pas au nombre de systemes ou de composants ajoutes."
echo "      Elle se mesure a la qualite, a la coherence et a la validation des fonctions obtenues. »"
echo "  => le nombre d'acquis, de commits et de documents ne mesure PAS l'avancement du produit."
echo

# --- 5. rappel par couche ----------------------------------------------------
echo "----- 5. repartition par couche (les 6 protagonistes de la PARTIE IV) -----"
for c in A B C D-1 D-2 D-3 D-4 D-5 E F "A+F"; do
	n=$(awk -F';' -v c="$c" '$3==c' "$F" | wc -l | tr -d ' ')
	[ "$n" -eq 0 ] && continue
	f=$(awk -F';' -v c="$c" '$3==c && $10=="FAIT"' "$F" | wc -l | tr -d ' ')
	printf "  couche %-4s : %2s fonctions, %s terminee(s)\n" "$c" "$n" "$f"
done

echo
if [ "$KO" -gt 0 ]; then
	echo "VERDICT : REGISTRE DES FONCTIONS NON CONFORME ($KO defaut(s))"
	exit 1
fi
echo "VERDICT : REGISTRE DES FONCTIONS CONFORME — $P0_FAIT/$P0_TOTAL P0 terminees"
exit 0

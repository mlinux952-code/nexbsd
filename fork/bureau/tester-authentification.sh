#!/bin/sh
# NexBSD — test de l'authentification de session. 2026-10-28.
#
# CE QUI EST TESTÉ ICI : la logique de l'écran d'ouverture (validation du nom, nombre d'essais,
# valeur écrite sur stdout, refus de root) — en remplaçant `su` par un faux `su` contrôlé.
#
# CE QUI N'EST PAS TESTÉ ICI, ET QUI RESTE INCONNU : la vérification réelle du mot de passe par PAM.
# Elle n'a jamais tourné : aucun système NexBSD n'existe. Ce test ne remplace pas cette preuve,
# il garantit seulement que le script ne se trompe pas de logique autour.
set -u

ICI=$(cd "$(dirname "$0")" && pwd)
AUTH="$ICI/nexbsd-authentifier.sh"
BAC=$(mktemp -d)
trap 'rm -rf "$BAC"' EXIT INT TERM

echecs=0
total=0

cas() {
	total=$((total+1))
	if [ "$2" = "$3" ]; then
		echo "  [OK]    $1"
	else
		echecs=$((echecs+1))
		echo "  [ECHEC] $1"
		echo "          attendu : $3"
		echo "          obtenu  : $2"
	fi
}

echo "########## NexBSD — authentification de session ##########"
echo ""

# --- faux 'su' : accepte seulement si le mot de passe attendu a ete fourni par l'environnement ---
mkdir -p "$BAC/bin"
cat > "$BAC/bin/faux-su" <<'FSU'
#!/bin/sh
# ignore les arguments ; reussit si le mot de passe "bon" a ete pose par le test
[ "${FAUX_MDP:-}" = "bon" ]
FSU
chmod +x "$BAC/bin/faux-su"

run() {
	# $1 = saisies (lignes), $2 = mot de passe simule
	printf '%b' "$1" | FAUX_MDP="${2:-}" NEXBSD_SU="$BAC/bin/faux-su" NEXBSD_FINSESSION=1 \
		sh "$AUTH" 3 >"$BAC/out" 2>"$BAC/err"
}

echo "----- 1. nom valide + mot de passe correct : le nom doit sortir SEUL sur stdout -----"
run 'omrane\n' bon
cas "code de sortie" "$?" "0"
cas "stdout contient seulement le nom" "$(cat "$BAC/out")" "omrane"
cas "stdout n'a qu'une ligne" "$(wc -l <"$BAC/out" | tr -d ' ')" "1"

echo ""
echo "----- 2. mot de passe refusé : aucun nom sur stdout, code d'échec -----"
run 'omrane\n' faux
cas "code de sortie" "$?" "1"
cas "stdout vide" "$(cat "$BAC/out")" ""

echo ""
echo "----- 3. nom invalide : refusé AVANT tout appel à su -----"
run 'OMRANE\n' bon
cas "code de sortie (majuscules refusées)" "$?" "1"
run 'om rane\n' bon
cas "code de sortie (espace refusé)" "$?" "1"
run 'omrane;rm -rf /\n' bon
cas "code de sortie (point-virgule refusé)" "$?" "1"

echo ""
echo "----- 4. deux essais : le premier mauvais nom, le second bon -----"
printf 'XX\nomrane\n' | FAUX_MDP=bon NEXBSD_SU="$BAC/bin/faux-su" NEXBSD_FINSESSION=0 \
	sh "$AUTH" 3 >"$BAC/out" 2>"$BAC/err"
cas "réussit au 2e essai" "$?" "0"
cas "nom correct sur stdout" "$(cat "$BAC/out")" "omrane"

echo ""
echo "----- 5. nombre d'essais respecté (2 essais, tous mauvais) -----"
printf 'omrane\nomrane\nomrane\n' | FAUX_MDP=faux NEXBSD_SU="$BAC/bin/faux-su" NEXBSD_FINSESSION=0 \
	sh "$AUTH" 2 >"$BAC/out" 2>"$BAC/err"
cas "code de sortie" "$?" "1"
cas "exactement 2 refus enregistrés" "$(grep -c 'mot de passe refusé' "$BAC/err")" "2"

echo ""
echo "----- 6. sécurité : le script refuse de tourner en root -----"
# On ne peut pas devenir root ici ; on vérifie la règle dans le texte, et son message.
if grep -q 'refuse de tourner en root' "$AUTH"; then
	cas "la règle anti-root est écrite" "oui" "oui"
else
	cas "la règle anti-root est écrite" "non" "oui"
fi

echo ""
echo "----- 7. le mot de passe ne transite jamais par la ligne de commande -----"
if grep -nE '\-c +"?\$?(MDP|PASS|motdepasse)' "$AUTH" >/dev/null 2>&1; then
	cas "aucun mot de passe en argument" "trouve" "absent"
else
	cas "aucun mot de passe en argument" "absent" "absent"
fi

echo ""
if [ "$echecs" -eq 0 ]; then
	echo "VERDICT : $total cas, 0 échec."
	echo "LIMITE : PAM n'a pas été sollicité — 'su' était un faux. La vérification réelle du mot de"
	echo "         passe reste NON PROUVÉE, et le restera jusqu'à une exécution sur NexBSD."
	exit 0
else
	echo "VERDICT : ÉCHEC — $echecs cas en échec sur $total."
	exit 1
fi

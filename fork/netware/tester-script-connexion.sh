#!/bin/sh
# NexBSD — tests du script de connexion (A-68). Exécuté au banc, hors FreeBSD.
#
# Principe : un FAUX `mount_smbfs` est placé en tête de PATH. Il enregistre les appels au lieu de
# monter quoi que ce soit. On vérifie ainsi la LOGIQUE du script de connexion — pas le noyau.
# Un faux `mount` sert à simuler un lecteur déjà branché (idempotence).

set -u
ICI=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
SCRIPT_CONNEXION="$ICI/nexbsd-script-connexion.sh"
TRAVAIL=$(mktemp -d /tmp/nexbsd-test-connexion.XXXXXX)
export PATH="$TRAVAIL/bin:$PATH"
mkdir -p "$TRAVAIL/bin" "$TRAVAIL/home" "$TRAVAIL/logs"

TOTAL=0; REUSSIS=0; ECHOUES=0
T() { :; }   # le comptage se fait dans verdict()
verdict() {
	TOTAL=$((TOTAL+1))
	if [ "$2" = "$3" ]; then
		REUSSIS=$((REUSSIS+1)); echo "  [OK]    $1"
	else
		ECHOUES=$((ECHOUES+1)); echo "  [ECHEC] $1 (attendu '$3', obtenu '$2')"
	fi
}

# --- le faux mount_smbfs : enregistre et réussit ----------------------------
cat >"$TRAVAIL/bin/mount_smbfs" <<'EOF'
#!/bin/sh
echo "MOUNT $*" >>"$NEXBSD_TEST_LOG"
exit 0
EOF

# --- le faux mount : ne liste rien par défaut (option -m pour simuler) ------
cat >"$TRAVAIL/bin/mount" <<'EOF'
#!/bin/sh
if [ -n "${NEXBSD_TEST_MONTES:-}" ] && [ -r "$NEXBSD_TEST_MONTES" ]; then
	cat "$NEXBSD_TEST_MONTES"
fi
exit 0
EOF
chmod +x "$TRAVAIL/bin/mount_smbfs" "$TRAVAIL/bin/mount"

lancer() {
	: >"$TRAVAIL/logs/appels.log"
	NEXBSD_TEST_LOG="$TRAVAIL/logs/appels.log" \
	HOME="$TRAVAIL/home" \
	NEXBSD_LECTEURS="$TRAVAIL/home/Lecteurs" \
	sh "$SCRIPT_CONNEXION" "$@" 2>&1
}

echo "########## T-22 — tests du script de connexion NexBSD ##########"

# ===========================================================================
echo
echo "--- 1. le script système réel du produit, en simulation ---"
T; sortie=$(lancer --script "$ICI/script-connexion.systeme" --utilisateur omrane --groupes "omrane wheel" --simulation)
verdict "le script système s'exécute sans commande inconnue" "$(printf '%s' "$sortie" | grep -c 'commande inconnue')" "0"
T; verdict "deux lecteurs branchés (H et P)" "$(printf '%s' "$sortie" | grep -c 'brancherait')" "2"
T; verdict "H pointe vers le dossier personnel de l'utilisateur" "$(printf '%s' "$sortie" | grep -c 'utilisateurs/omrane')" "1"
T; verdict "le message WRITE développe %NOM_COMPLET%" "$(printf '%s' "$sortie" | grep -c 'Bienvenue sur NexBSD')" "1"
T; verdict "aucun montage réel en simulation" "$(cat "$TRAVAIL/logs/appels.log" | wc -l | tr -d ' ')" "0"

# ===========================================================================
echo
echo "--- 2. le bloc IF MEMBER OF respecte les groupes ---"
T; sortie=$(lancer --script "$ICI/script-connexion.systeme" --utilisateur omrane --groupes "omrane comptabilite" --simulation)
verdict "membre de comptabilite -> lecteur C branché" "$(printf '%s' "$sortie" | grep -c 'brancherait')" "3"
verdict "lecteur D absent (non membre de direction)" "$(printf '%s' "$sortie" | grep -c 'lettre D')" "0"

T; sortie=$(lancer --script "$ICI/script-connexion.systeme" --utilisateur omrane --groupes "omrane" --simulation)
verdict "non membre -> seulement H et P" "$(printf '%s' "$sortie" | grep -c 'brancherait')" "2"

# ===========================================================================
echo
echo "--- 3. un commentaire n'est pas une commande, EXIT arrête tout ---"
cat >"$TRAVAIL/s1.txt" <<'EOF'
; un commentaire ignoré
MAP H: \\nexbsd\utilisateurs\%UTILISATEUR%
EXIT
MAP P: \\nexbsd\commun%
EOF
T; sortie=$(lancer --script "$TRAVAIL/s1.txt" --utilisateur omrane --simulation)
verdict "EXIT arrête avant le second MAP" "$(printf '%s' "$sortie" | grep -c 'brancherait')" "1"
T; verdict "le commentaire n'est pas compté comme commande inconnue" "$(printf '%s' "$sortie" | grep -c 'commande inconnue')" "0"

# ===========================================================================
echo
echo "--- 4. erreurs de syntaxe : le script le dit, il ne se tait pas ---"
printf 'MAP 1: \\\\nexbsd\\commun%%\n' >"$TRAVAIL/s2.txt"
T; sortie=$(lancer --script "$TRAVAIL/s2.txt" --utilisateur omrane --simulation)
verdict "lettre de lecteur invalide refusée" "$(printf '%s' "$sortie" | grep -c 'lettre de lecteur invalide')" "1"

printf 'MAP H: pas-un-unc\n' >"$TRAVAIL/s3.txt"
T; sortie=$(lancer --script "$TRAVAIL/s3.txt" --utilisateur omrane --simulation)
verdict "chemin réseau invalide refusé" "$(printf '%s' "$sortie" | grep -c 'chemin réseau invalide')" "1"

printf 'BOGUS commande\n' >"$TRAVAIL/s4.txt"
T; sortie=$(lancer --script "$TRAVAIL/s4.txt" --utilisateur omrane --simulation)
verdict "commande inconnue signalée" "$(printf '%s' "$sortie" | grep -c 'commande inconnue')" "1"

printf 'IF MEMBER OF "compta"\nMAP H: \\\\nexbsd\\commun%%\n' >"$TRAVAIL/s5.txt"
T; sortie=$(lancer --script "$TRAVAIL/s5.txt" --utilisateur omrane --groupes "omrane" --simulation)
verdict "IF non refermé signalé" "$(printf '%s' "$sortie" | grep -c 'ENDIF manquant')" "1"

# ===========================================================================
echo
echo "--- 5. sans mot de passe, on ne fait pas semblant de monter ---"
T; sortie=$(lancer --script "$TRAVAIL/s1.txt" --utilisateur omrane)
verdict "montage refusé faute d'identifiants SMB" "$(printf '%s' "$sortie" | grep -c 'aucun identifiant SMB')" "1"
T; verdict "aucun appel réel à mount_smbfs" "$(cat "$TRAVAIL/logs/appels.log" | wc -l | tr -d ' ')" "0"

# ===========================================================================
echo
echo "--- 6. avec un fichier de mot de passe en 0600, le montage est tenté ---"
printf 'secret-de-test\n' >"$TRAVAIL/mdp.txt"; chmod 600 "$TRAVAIL/mdp.txt"
T; sortie=$(lancer --script "$TRAVAIL/s1.txt" --utilisateur omrane --mdp-fichier "$TRAVAIL/mdp.txt")
verdict "montage tenté une fois" "$(cat "$TRAVAIL/logs/appels.log" | wc -l | tr -d ' ')" "1"
T; verdict "l'appel porte le bon UNC" "$(grep -c 'utilsmbfs\|//omrane@nexbsd/utilisateurs/omrane' "$TRAVAIL/logs/appels.log")" "1"
T; verdict "~/.nsmbrc posé en 0600" "$(ls -l "$TRAVAIL/home/.nsmbrc" 2>/dev/null | cut -c1-10)" "-rw-------"

# ===========================================================================
echo
echo "--- 7. un fichier de mot de passe lisible par tous est REFUSÉ ---"
printf 'secret\n' >"$TRAVAIL/mdp-public.txt"; chmod 644 "$TRAVAIL/mdp-public.txt"
T; sortie=$(lancer --script "$TRAVAIL/s1.txt" --utilisateur omrane --mdp-fichier "$TRAVAIL/mdp-public.txt")
verdict "mot de passe non privé refusé" "$(printf '%s' "$sortie" | grep -c "n'est pas privé")" "1"

# ===========================================================================
echo
echo "--- 8. idempotence : un lecteur déjà branché n'est pas remonté ---"
cat >"$TRAVAIL/montes.txt" <<EOF
//omrane@nexbsd/utilisateurs/omrane on $TRAVAIL/home/Lecteurs/H (smbfs, local)
EOF
T; sortie=$(NEXBSD_TEST_MONTES="$TRAVAIL/montes.txt" lancer --script "$TRAVAIL/s1.txt" --utilisateur omrane --mdp-fichier "$TRAVAIL/mdp.txt")
verdict "lecteur déjà branché -> aucun nouvel appel" "$(cat "$TRAVAIL/logs/appels.log" | wc -l | tr -d ' ')" "0"
T; verdict "le script le dit ('déjà branchée')" "$(printf '%s' "$sortie" | grep -c 'déjà branchée')" "1"

# ===========================================================================
echo
echo "--- 9. INCLUDE exécute un autre script ---"
cat >"$TRAVAIL/inc.txt" <<'EOF'
MAP Q: \\nexbsd\outils%
EOF
cat >"$TRAVAIL/s6.txt" <<'EOF'
MAP H: \\nexbsd\utilisateurs\%UTILISATEUR%
INCLUDE inc.txt
EOF
T; sortie=$(lancer --script "$TRAVAIL/s6.txt" --utilisateur omrane --simulation)
verdict "le script inclus ajoute son lecteur" "$(printf '%s' "$sortie" | grep -c 'brancherait')" "2"

# ===========================================================================
echo
echo "--- 10. aucun script trouvé : la session continue, mais on le dit ---"
T; sortie=$(NEXBSD_TEST_LOG="$TRAVAIL/logs/appels.log" HOME="$TRAVAIL/vide" NEXBSD_LECTEURS="$TRAVAIL/vide/L" sh "$SCRIPT_CONNEXION" --utilisateur omrane 2>&1)
verdict "absence de script signalée" "$(printf '%s' "$sortie" | grep -c 'aucun script de connexion trouvé')" "1"
T; verdict "on dit que la session reste utilisable" "$(printf '%s' "$sortie" | grep -c 'AUCUN lecteur réseau')" "1"

# ===========================================================================
echo
echo "--- 11. le script personnel d'exemple est valide ---"
T; sortie=$(lancer --script "$ICI/script-connexion.utilisateur.exemple" --utilisateur omrane --simulation)
verdict "l'exemple ne contient aucune commande inconnue" "$(printf '%s' "$sortie" | grep -c 'commande inconnue')" "0"
T; verdict "l'exemple branche un lecteur" "$(printf '%s' "$sortie" | grep -c 'brancherait')" "1"

# ===========================================================================
echo
echo "-----------------------------------------------------------"
echo "  TOTAL : $TOTAL   REUSSIS : $REUSSIS   ECHOUES : $ECHOUES"
if [ "$ECHOUES" -gt 0 ]; then
	echo "VERDICT : ECHEC ($ECHOUES cas en défaut)"
	rm -rf "$TRAVAIL"
	exit 1
fi
echo "VERDICT : CONFORME — $REUSSIS cas sur $REUSSIS"
rm -rf "$TRAVAIL"
exit 0

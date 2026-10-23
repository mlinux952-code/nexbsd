#!/bin/sh
# 51-installer-depot-github.sh — installe le dépôt NexBSD depuis le .bundle de sauvegarde
# et le prépare pour GitHub, SANS pousser (le push reste une action consciente).
#
# Usage :
#   sh 51-installer-depot-github.sh <chemin/du/bundle> <url-github> [dossier] [branche]
# Exemple :
#   sh scripts/51-installer-depot-github.sh ~/Téléchargements/nexbsd-depot-2026-10-23-s007.bundle \
#      git@github.com:mlinux952-code/nexbsd.git ~/Projets/nexbsd main
#
# Le script REFUSE de travailler dans un dossier existant : il ne touche jamais
# à un dépôt déjà présent (c'est la cause n°1 des erreurs de manipulation).

set -eu

BUNDLE=${1:-}
URL=${2:-}
DEST=${3:-nexbsd}
BRANCHE=${4:-main}

if [ -z "$BUNDLE" ] || [ -z "$URL" ]; then
    echo "Usage : sh $0 <chemin/du/bundle> <url-github> [dossier] [branche]" >&2
    exit 2
fi

# 1. Le bundle existe-t-il vraiment ?
if [ ! -f "$BUNDLE" ]; then
    echo "ERREUR : bundle introuvable : $BUNDLE" >&2
    echo "  → l'avez-vous téléchargé depuis le dossier Drive « NexBSD » ?" >&2
    echo "  → sous Linux, le dossier de téléchargement est souvent ~/Téléchargements" >&2
    exit 1
fi

# 2. Le dossier de destination doit être libre
if [ -e "$DEST" ]; then
    echo "ERREUR : '$DEST' existe déjà. Ce script ne touche pas à un dossier existant." >&2
    echo "  → choisissez un autre nom : sh $0 \"$BUNDLE\" \"$URL\" nexbsd-2" >&2
    exit 1
fi

# 3. Clonage depuis le bundle
echo "→ Clonage depuis $BUNDLE"
git clone "$BUNDLE" "$DEST" >/dev/null 2>&1 || { echo "ERREUR : clonage impossible" >&2; exit 1; }
cd "$DEST"

# 4. Le remote créé par le clonage pointe vers le FICHIER bundle : on le retire
git remote remove origin 2>/dev/null || true

# 5. Nom de branche
ACTUELLE=$(git symbolic-ref --short HEAD)
if [ "$ACTUELLE" != "$BRANCHE" ]; then
    git branch -m "$ACTUELLE" "$BRANCHE"
    echo "→ Branche renommée : $ACTUELLE → $BRANCHE"
fi

# 6. Remote GitHub
git remote add origin "$URL"
echo "→ Remote ajouté : origin = $URL"

# 7. Vérification de l'authentification SSH (si URL SSH)
case "$URL" in
    git@*)
        echo "→ Test de la clé SSH…"
        if ssh -T -o BatchMode=yes -o StrictHostKeyChecking=accept-new git@github.com 2>&1 | grep -q "successfully authenticated"; then
            echo "  ✅ authentification SSH réussie"
        else
            echo "  ⚠️  authentification SSH NON confirmée." >&2
            echo "     Vérifiez que la clé publique est ajoutée à votre compte GitHub" >&2
            echo "     (Settings → SSH and GPG keys), puis testez : ssh -T git@github.com" >&2
        fi
        ;;
    https://*)
        echo "  ℹ️  URL HTTPS : un mot de passe ne fonctionne pas, il faut un jeton (token)."
        ;;
esac

echo
echo "Dépôt prêt dans : $(pwd)"
echo "Historique :"
git log --oneline | sed 's/^/  /'
echo
echo "Étape suivante — à exécuter à la main, après avoir créé le dépôt VIDE sur GitHub :"
echo "  git push -u origin $BRANCHE"

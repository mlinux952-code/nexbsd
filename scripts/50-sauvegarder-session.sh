#!/bin/sh
# 50-sauvegarder-session.sh — produit un instantané daté du projet NexBSD.
# Lecture seule sur le projet : n'écrit QUE dans archives/.
# N'exécute aucun envoi réseau (le téléversement reste manuel et explicite).
set -eu

RACINE=${1:-$(pwd)}
cd "$RACINE"

if [ ! -f docs/ETAT.md ]; then
    echo "ERREUR : docs/ETAT.md absent — mauvais répertoire ?" >&2
    exit 1
fi

DATE=$(date +%Y-%m-%d)
mkdir -p archives
ARCHIVE="archives/NexBSD-etat-conception-$DATE.tar.gz"
BUNDLE="archives/nexbsd-depot-$DATE.bundle"

if [ -d .git ]; then
    git bundle create "$BUNDLE" --all >/dev/null 2>&1 || { echo "ERREUR : git bundle a échoué" >&2; exit 1; }
else
    echo "AVERTISSEMENT : pas de dépôt Git ici — bundle ignoré" >&2
    BUNDLE=""
fi

tar --exclude=.git --exclude=archives -czf "$ARCHIVE" .

cd archives
if [ -n "$BUNDLE" ]; then
    sha256sum "$(basename "$ARCHIVE")" "$(basename "$BUNDLE")" > SHA256SUMS.txt
else
    sha256sum "$(basename "$ARCHIVE")" > SHA256SUMS.txt
fi

echo "Instantané créé :"
ls -lh "$(basename "$ARCHIVE")" ${BUNDLE:+$(basename "$BUNDLE")}
echo
echo "Empreintes :"
cat SHA256SUMS.txt
echo
echo "Étape suivante (manuelle) : téléverser ces fichiers dans le dossier Google Drive « NexBSD »."

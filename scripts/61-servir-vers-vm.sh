#!/bin/sh
# 61-servir-vers-vm.sh — sert le dossier scripts/ du dépôt à la VM, pour éviter
# tout copier-coller dans la fenêtre graphique de virt-manager.
#
# À exécuter SUR LE MINT (hôte). Laissez-le tourner, puis, DANS la VM, tapez
# la commande courte qu'il affiche.
#
# Pourquoi ça marche : la VM en réseau « user » (celle créée par virt-manager)
# voit l'hôte à l'adresse 10.0.2.2. Vérifié le 2026-10-23 : ping 10.0.2.2 OK.
#
# Sécurité : le serveur n'écoute que sur l'interface locale du réseau QEMU ;
# il sert uniquement des fichiers .sh/.md de ce dossier, sans secret.
set -eu

RACINE=$(cd "$(dirname "$0")/.." && pwd)
DOSSIER="$RACINE/scripts"
PORT=${PORT:-8000}

[ -d "$DOSSIER" ] || { echo "ERREUR : dossier scripts/ introuvable" >&2; exit 1; }
command -v python3 >/dev/null 2>&1 || { echo "ERREUR : python3 requis" >&2; exit 1; }

echo "Serveur de fichiers NexBSD"
echo "  dossier : $DOSSIER"
echo "  port    : $PORT"
echo
echo "Dans la VM FreeBSD, taper (une ligne à la fois) :"
echo
echo "    ifconfig vtnet0 inet"
echo "    fetch -o /tmp/t04.sh http://10.0.2.2:$PORT/60-banc-T04-ldap.sh"
echo "    sh /tmp/t04.sh"
echo
echo "Si 'fetch' échoue : dans la VM, lancer  dhclient vtnet0  puis réessayer."
echo "Arrêter ce serveur : Ctrl-C"
echo

cd "$DOSSIER"
exec python3 -m http.server "$PORT" --bind 0.0.0.0

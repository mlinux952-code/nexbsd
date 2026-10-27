#!/bin/sh
# 31-lancer-vm-freebsd.sh — lance la VM du banc NexBSD.
#
# HISTORIQUE (C-21, constate le 2026-10-27)
#   v1 : supposait une image QEMU directe (FreeBSD-15.1-ufs.qcow2 dans ~/.cache/nexbsd-vm).
#        Or le banc reel tourne sous **libvirt** : domaine `nexbsd-test`, lance par virt-manager,
#        console serie ttyu0. Le script echouait donc avec "image absente" alors que la VM existait.
#   v2 (ce fichier) : DETECTE le mode reel avant d'agir.
#        1. si un domaine libvirt existe (nexbsd-test, ou tout domaine contenant "nexbsd") -> libvirt
#        2. sinon, si l'image QEMU directe existe -> ancien chemin (conserve, il reste valable)
#        3. sinon, message clair avec les deux solutions, sans rien inventer.
#
# Usage :
#   sh 31-lancer-vm-freebsd.sh            # demarre la VM et ouvre la console
#   sh 31-lancer-vm-freebsd.sh --etat     # dit seulement quel mode serait utilise
#   sh 31-lancer-vm-freebsd.sh --stop     # arrete proprement la VM libvirt
#
set -u

MODE="lancer"
for a in "$@"; do
    case "$a" in
        --etat) MODE="etat" ;;
        --stop) MODE="stop" ;;
        --aide|-h) sed -n '2,25p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
        *) echo "option inconnue : $a" >&2; exit 2 ;;
    esac
done

URI="qemu:///session"

# --- 1. recherche d'un domaine libvirt -----------------------------------
DOMAINE=""
if command -v virsh >/dev/null 2>&1; then
    DOMAINE=$(virsh -c "$URI" list --all --name 2>/dev/null | grep -i nexbsd | head -1)
fi

if [ -n "$DOMAINE" ]; then
    ETAT=$(virsh -c "$URI" domstate "$DOMAINE" 2>/dev/null)
    echo "-> mode LIBVIRT detecte : domaine '$DOMAINE' (etat : ${ETAT:-inconnu})"

    case "$MODE" in
        etat)
            virsh -c "$URI" list --all
            echo "-> demarrage possible avec : virsh -c $URI start $DOMAINE"
            echo "-> console                : virsh -c $URI console $DOMAINE   (sortie : Ctrl+])"
            exit 0 ;;
        stop)
            virsh -c "$URI" shutdown "$DOMAINE" >/dev/null 2>&1 && echo "-> arret demande ($DOMAINE)" || echo "-> arret impossible (deja arretee ?)"
            exit 0 ;;
        lancer)
            if [ "$ETAT" != "running" ]; then
                virsh -c "$URI" start "$DOMAINE" || { echo "ERREUR : demarrage impossible" >&2; exit 1; }
                sleep 2
            else
                echo "-> deja en cours d'execution"
            fi
            echo "-> ouverture de la console (login root, puis Ctrl+] pour detacher)"
            exec virsh -c "$URI" console "$DOMAINE"
            ;;
    esac
fi


DIR=${1:-$HOME/.cache/nexbsd-vm}
IMAGE="$DIR/FreeBSD-15.1-ufs.qcow2"
OVERLAY="$DIR/disque-test.qcow2"
SER="$DIR/console.sock"
MON="$DIR/moniteur.sock"
PORT=${PORT:-4450}

# --- Ressources : surchargeables par l'environnement ---------------------
# Sur une machine de 3,7 Go de RAM avec 4 threads (i3-3110M), 1536 Mo / 2 vCPU
# laissent assez au systeme hote pour rester utilisable.
RAM_MO=${RAM_MO:-1536}
VCPU=${VCPU:-2}

# --- Acceleration materielle --------------------------------------------
# La recette du 2026-10-23 tournait en emulation pure (81 s de demarrage).
# Avec KVM, le meme demarrage prend quelques secondes.
if [ -r /dev/kvm ]; then
    ACCEL="-enable-kvm -cpu host"
    echo "-> acceleration KVM detectee : la VM tournera a pleine vitesse"
else
    ACCEL=""
    echo "-> pas de KVM : emulation logicielle (lent, mais fonctionnel)"
fi

# --- Garde-fous ---------------------------------------------------------
if [ ! -f "$IMAGE" ]; then
    echo "ERREUR : image absente : $IMAGE" >&2
    echo "  Télécharger (664 Mo) et vérifier le SHA256 :" >&2
    echo "  https://download.freebsd.org/releases/VM-IMAGES/15.1-RELEASE/amd64/Latest/" >&2
    exit 1
fi
for b in qemu-system-x86_64 qemu-img; do
    command -v "$b" >/dev/null 2>&1 || { echo "ERREUR : $b introuvable (sudo apt install qemu-system-x86 qemu-utils)" >&2; exit 1; }
done

# --- Disque de travail : COPIE SUR ÉCRITURE, jamais l'image d'origine --
if [ ! -f "$OVERLAY" ]; then
    echo "→ création du disque de travail (l'image d'origine reste intacte)"
    qemu-img create -f qcow2 -b "$IMAGE" -F qcow2 "$OVERLAY" >/dev/null
fi

rm -f "$SER" "$MON"

# --- Lancement ----------------------------------------------------------
# Pas de KVM sur cet hôte : émulation TCG, 1 vCPU, 768 Mo.
# Le disque est en virtio (vtblk0) et le réseau en virtio avec redirection
# de port, pour tester depuis la station Linux : 127.0.0.1:4450 → VM:445.
echo "→ démarrage : ${RAM_MO} Mo de RAM, ${VCPU} vCPU"
echo "→ AU MENU DU CHARGEUR : taper 5 puis Entrée (sinon rien ne s'affiche)"
echo "→ console série : socat - UNIX-CONNECT:$SER"
echo "→ partage SMB testable sur 127.0.0.1:$PORT une fois samba démarré"
exec qemu-system-x86_64 \
    $ACCEL -m "$RAM_MO" -smp "$VCPU" -display none -no-reboot \
    -serial "unix:$SER,server,nowait" \
    -monitor "unix:$MON,server,nowait" \
    -drive "file=$OVERLAY,if=virtio,cache=writeback" \
    -netdev "user,id=n0,hostfwd=tcp:127.0.0.1:$PORT-:445" \
    -device virtio-net-pci,netdev=n0 \
    -rtc base=utc

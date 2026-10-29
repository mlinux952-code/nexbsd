#!/bin/sh
# 31-lancer-vm-freebsd.sh — lance la VM du banc NexBSD.
#
# HISTORIQUE
#   v1 : supposait une image QEMU directe (FreeBSD-15.1-ufs.qcow2 dans ~/.cache/nexbsd-vm).
#        Or le banc reel tourne sous **libvirt** : domaine `nexbsd-test`, console serie ttyu0.
#        Le script echouait donc avec "image absente" alors que la VM existait (C-21).
#   v2 (2026-10-27) : DETECTE le mode reel avant d'agir (libvirt / QEMU direct / erreur claire).
#   v3 (2026-10-27, apres T-05a) : ajoute la PIECE MANQUANTE du reseau.
#        Constat de T-05a : sous libvirt le domaine est en interface `type='user'` (slirp) et
#        AUCUNE redirection n'est declaree ; or T-03 avait besoin de 127.0.0.1:4450 -> VM:445.
#        Sans redirection, aucune preuve de T-05a n'est rejouable (T-11 restait partiel).
#        v3 applique donc la redirection A CHAUD, de facon IDEMPOTENTE et VERIFIEE :
#          1. lit le nom du netdev slirp avec `info network`   (jamais devine)
#          2. ne l'ajoute que si `info usernet` ne le montre pas deja
#          3. relit `info usernet` pour PROUVER l'ajout
#        Limite assumee : `hostfwd_add` est une commande de moniteur, elle ne survit pas a l'arret
#        de la VM. C'est pour cela qu'elle est ici et non dans le XML du domaine.
#
# Usage :
#   sh 31-lancer-vm-freebsd.sh            # demarre la VM, applique la redirection, ouvre la console
#   sh 31-lancer-vm-freebsd.sh --reseau   # (re)applique la redirection sur une VM deja lancee
#   sh 31-lancer-vm-freebsd.sh --etat     # dit seulement quel mode serait utilise
#   sh 31-lancer-vm-freebsd.sh --stop     # arrete proprement la VM libvirt
#   sh 31-lancer-vm-freebsd.sh --aide
#
# Variable d'environnement :
#   PORT=4450   port d'ecoute sur la station (borne sur 127.0.0.1, jamais 0.0.0.0)
#
set -u

MODE="lancer"
for a in "$@"; do
    case "$a" in
        --etat) MODE="etat" ;;
        --stop) MODE="stop" ;;
        --reseau) MODE="reseau" ;;
        --aide|-h) sed -n '2,32p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
        *) echo "option inconnue : $a" >&2; exit 2 ;;
    esac
done

URI="qemu:///session"
PORT=${PORT:-4450}
GPORT=445

# ---------------------------------------------------------------------------
# appliquer_redirection DOMAINE
#   Ajoute 127.0.0.1:$PORT -> VM:$GPORT dans le slirp du domaine, si absent,
#   puis le PROUVE en relisant `info usernet`. Code retour 0 = redirection vue.
# ---------------------------------------------------------------------------
appliquer_redirection() {
    _dom="$1"

    # 1. nom du netdev slirp : on le LIT, on ne le devine pas (lecon C-24)
    _netdev=$(virsh -c "$URI" qemu-monitor-command "$_dom" --hmp "info network" 2>/dev/null \
              | tr -d '\\' \
              | awk '/type=user/ { for (i=1;i<=NF;i++) if ($i ~ /:$/) { sub(":$","",$i); print $i; exit } }')
    if [ -z "$_netdev" ]; then
        echo "  [KO]    netdev slirp introuvable (la VM n'a pas d'interface type=user ?)"
        echo "          sortie brute :"
        virsh -c "$URI" qemu-monitor-command "$_dom" --hmp "info network" 2>&1 | sed 's/^/          /'
        return 1
    fi
    echo "  [OK]    netdev slirp detecte : $_netdev"

    # 2. idempotence : deja presente ?
    if virsh -c "$URI" qemu-monitor-command "$_dom" --hmp "info usernet" 2>/dev/null \
         | grep -qE "(^|[[:space:]])${PORT}([[:space:]]|$)"; then
        echo "  [OK]    redirection 127.0.0.1:${PORT} -> VM:${GPORT} deja en place (rien ajoute)"
    else
        # 3. ajout a chaud. QEMU ne dit rien quand il reussit : le silence n'est PAS une preuve,
        #    d'ou la relecture a l'etape 4.
        virsh -c "$URI" qemu-monitor-command "$_dom" --hmp \
            "hostfwd_add ${_netdev} tcp:127.0.0.1:${PORT}-:${GPORT}" >/tmp/nexbsd-hostfwd.err 2>&1
        if [ -s /tmp/nexbsd-hostfwd.err ]; then
            echo "  [KO]    hostfwd_add a repondu :"
            sed 's/^/          /' /tmp/nexbsd-hostfwd.err
            return 1
        fi
        echo "  [OK]    hostfwd_add 127.0.0.1:${PORT} -> VM:${GPORT} (silence = succes cote QEMU)"
    fi

    # 4. PREUVE : la redirection doit apparaitre dans `info usernet`
    _ligne=$(virsh -c "$URI" qemu-monitor-command "$_dom" --hmp "info usernet" 2>/dev/null \
             | grep "HOST_FORWARD" | grep -E "(^|[[:space:]])${PORT}([[:space:]]|$)")
    if [ -n "$_ligne" ]; then
        echo "  [OK]    redirection PROUVEE par le moniteur :"
        echo "$_ligne" | sed 's/^ */          /'
        echo "          -> le partage n'est joignable que depuis CETTE station (127.0.0.1), jamais du reseau"
        return 0
    fi
    echo "  [KO]    la redirection n'apparait pas dans info usernet"
    return 1
}

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
            echo "-> console                : virsh -c $URI console $DOMAINE   (sortie : Ctrl+]"
            echo "-> reseau                 : sh $0 --reseau  (127.0.0.1:${PORT} -> VM:${GPORT})"
            exit 0 ;;
        stop)
            virsh -c "$URI" shutdown "$DOMAINE" >/dev/null 2>&1 && echo "-> arret demande ($DOMAINE)" || echo "-> arret impossible (deja arretee ?)"
            echo "-> rappel : la redirection de port disparait avec la VM, --reseau la remet"
            exit 0 ;;
        reseau)
            if [ "${ETAT:-}" != "running" ]; then
                echo "ERREUR : '$DOMAINE' n'est pas en cours d'execution (etat : ${ETAT:-inconnu})" >&2
                echo "         lancer d'abord : virsh -c $URI start $DOMAINE" >&2
                exit 1
            fi
            echo "----- redirection reseau (slirp) -----"
            appliquer_redirection "$DOMAINE" || exit 1
            exit 0 ;;
        lancer)
            if [ "$ETAT" != "running" ]; then
                virsh -c "$URI" start "$DOMAINE" || { echo "ERREUR : demarrage impossible" >&2; exit 1; }
                sleep 2
            else
                echo "-> deja en cours d'execution"
            fi
            echo "----- redirection reseau (slirp) -----"
            appliquer_redirection "$DOMAINE" || echo "  (la VM demarre quand meme, mais T-05a/T-03 ne seront pas rejouables)"
            echo "-> ouverture de la console (login root, puis Ctrl+] pour detacher)"
            exec virsh -c "$URI" console "$DOMAINE"
            ;;
    esac
fi


# ===========================================================================
# Ancien chemin : QEMU direct (conserve, il reste valable sans libvirt)
# ===========================================================================
DIR=${1:-$HOME/.cache/nexbsd-vm}
IMAGE="$DIR/FreeBSD-15.1-ufs.qcow2"
OVERLAY="$DIR/disque-test.qcow2"
SER="$DIR/console.sock"
MON="$DIR/moniteur.sock"

# --- Ressources : surchargeables par l'environnement ---------------------
# Sur une machine de 3,7 Go de RAM avec 4 threads (i3-3110M), 1536 Mo / 2 vCPU
# laissent assez au systeme hote pour rester utilisable.
RAM_MO=${RAM_MO:-1536}
VCPU=${VCPU:-2}

# --- Acceleration materielle --------------------------------------------
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
echo "→ démarrage : ${RAM_MO} Mo de RAM, ${VCPU} vCPU"
echo "→ AU MENU DU CHARGEUR : taper 5 puis Entrée (sinon rien ne s'affiche)"
echo "→ console série : socat - UNIX-CONNECT:$SER"
echo "→ partage SMB testable sur 127.0.0.1:$PORT une fois samba démarré"
exec qemu-system-x86_64 \
    $ACCEL -m "$RAM_MO" -smp "$VCPU" -display none -no-reboot \
    -serial "unix:$SER,server,nowait" \
    -monitor "unix:$MON,server,nowait" \
    -drive "file=$OVERLAY,if=virtio,cache=writeback" \
    -netdev "user,id=net0,hostfwd=tcp:127.0.0.1:${PORT}-:${GPORT}" \
    -device virtio-net-pci,netdev=net0

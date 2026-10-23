#!/usr/bin/env bash
# NexBSD — Lancer FreeBSD dans une machine virtuelle (banc de test « PC faible »)
#
# Usage :
#   bash scripts/30-qemu-freebsd.sh --create          # créer le disque virtuel si absent
#   bash scripts/30-qemu-freebsd.sh                   # démarrer (1 Go de RAM, 2 vCPU)
#   bash scripts/30-qemu-freebsd.sh --ram 512         # simuler le plancher de RAM
#   bash scripts/30-qemu-freebsd.sh --snapshot        # essai jetable (écritures perdues à l'arrêt)
#   bash scripts/30-qemu-freebsd.sh --nographic       # sans fenêtre graphique (économe)
#   bash scripts/30-qemu-freebsd.sh --from-installer  # amorcer sur l'image memstick (installation)
#
# Ne modifie rien sur l'hôte : tout se passe dans ~/nexbsd-vm.
set -uo pipefail

RAM=1024
CPUS=2
DISK_GB=8
VDIR="$HOME/nexbsd-vm"
IMGDIR="$HOME/nexbsd-images"
DISK="$VDIR/nexbsd-lab0.qcow2"
INSTALLER=""
CREATE=0
SNAPSHOT=0
NOGRAPHIC=0
FROM_INSTALLER=0
BOOT_ON_INSTALLER=0

while [ $# -gt 0 ]; do
  case "$1" in
    --ram) RAM="$2"; shift 2 ;;
    --cpus) CPUS="$2"; shift 2 ;;
    --disk-gb) DISK_GB="$2"; shift 2 ;;
    --installer) INSTALLER="$2"; shift 2 ;;
    --create) CREATE=1; shift ;;
    --snapshot) SNAPSHOT=1; shift ;;
    --nographic) NOGRAPHIC=1; shift ;;
    --from-installer) FROM_INSTALLER=1; BOOT_ON_INSTALLER=1; shift ;;
    -h|--help) sed -n '2,14p' "$0"; exit 0 ;;
    *) echo "option inconnue : $1" >&2; exit 2 ;;
  esac
done

command -v qemu-system-x86_64 >/dev/null 2>&1 || {
  echo "qemu n'est pas installé. Exécuter :" >&2
  echo "  sudo apt install qemu-system-x86 qemu-utils" >&2
  exit 1
}

mkdir -p "$VDIR" "$IMGDIR"

# --- image d'installation : recherche automatique ---
if [ -z "$INSTALLER" ]; then
  INSTALLER="$(ls -1 "$IMGDIR"/*memstick*.img "$IMGDIR"/*disc1*.iso "$IMGDIR"/*.iso 2>/dev/null | head -1 || true)"
fi

# --- création du disque virtuel ---
if [ "$CREATE" -eq 1 ]; then
  if [ -f "$DISK" ]; then
    echo "Le disque existe déjà : $DISK"
  else
    echo "Création de $DISK (${DISK_GB}G, format qcow2, allocation dynamique)"
    qemu-img create -f qcow2 "$DISK" "${DISK_GB}G" || exit 1
  fi
fi
[ -f "$DISK" ] || { echo "Disque absent : lancer d'abord avec --create" >&2; exit 1; }

# --- accélération ---
if [ -e /dev/kvm ]; then
  ACCEL=(-enable-kvm)
  echo "KVM détecté : accélération matérielle active."
else
  ACCEL=()
  echo "KVM absent : émulation logicielle (lent ; privilégier --nographic avec 512 Mo)."
fi

# --- mémoire : avertissement contre le dépassement ---
freemb=$(awk '/MemAvailable/{print int($2/1024)}' /proc/meminfo 2>/dev/null || echo 0)
if [ "$freemb" -gt 0 ] && [ "$RAM" -gt $((freemb - 256)) ]; then
  echo "ATTENTION : $RAM Mo demandés alors que ~${freemb} Mo sont disponibles sur l'hôte." >&2
  echo "            Le poste risque de saturer (swap). Réduire --ram." >&2
fi

cmd=(qemu-system-x86_64
  -machine q35
  -m "$RAM"
  -smp "$CPUS"
  -drive "file=$DISK,if=virtio,format=qcow2"
  -netdev user,id=n0
  -device virtio-net-pci,netdev=n0
  -device virtio-rng-pci
)
[ "${#ACCEL[@]}" -gt 0 ] && cmd+=("${ACCEL[@]}")
[ "$SNAPSHOT" -eq 1 ] && cmd+=(-snapshot)

if [ "$NOGRAPHIC" -eq 1 ]; then
  cmd+=(-nographic -serial mon:stdio)
else
  cmd+=(-vga std -display default)
fi

if [ -n "$INSTALLER" ] && { [ "$FROM_INSTALLER" -eq 1 ] || [ "$BOOT_ON_INSTALLER" -eq 1 ] || [ ! -s "$DISK" ]; }; then
  [ -f "$INSTALLER" ] || { echo "Image d'installation introuvable dans $IMGDIR" >&2; exit 1; }
  cmd+=(-drive "file=$INSTALLER,format=raw,if=virtio,readonly=on" -boot order=dc)
  echo "Amorçage sur l'image : $INSTALLER"
else
  cmd+=(-boot order=c)
  echo "Amorçage sur le disque virtuel."
fi

echo "RAM : $RAM Mo · vCPU : $CPUS · disque : $DISK"
echo "Pour arrêter la VM : menu « Machine → Quit » , ou Ctrl-A puis X en mode --nographic."
echo "--------------------------------------------------------------"
set -x
"${cmd[@]}"

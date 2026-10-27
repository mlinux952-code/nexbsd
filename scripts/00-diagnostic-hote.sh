#!/usr/bin/env bash
# NexBSD — Diagnostic du poste de préparation (LECTURE SEULE)
# Aucune de ces commandes ne modifie le système.
# Usage : bash scripts/00-diagnostic-hote.sh
set -uo pipefail

echo "=============================================================="
echo " NexBSD — diagnostic de la station de préparation"
echo " date : $(date -Is)"
echo " NOTE : lecture seule, aucune modification effectuée"
echo "=============================================================="

section() { printf '\n--- %s ---\n' "$1"; }

section "Système"
uname -a
if [ -r /etc/os-release ]; then . /etc/os-release; echo "Distribution : ${PRETTY_NAME:-inconnue}"; fi

section "Processeur"
if command -v lscpu >/dev/null 2>&1; then
  lscpu | grep -Ei 'architecture|model name|^cpu\(s\)|thread|core|socket|virtualisation|hypervisor' || true
  echo "Cœurs logiques : $(nproc 2>/dev/null || echo '?')"
  if lscpu | grep -qiE '(vmx|svm)'; then echo "Extensions de virtualisation : présentes (vmx/svm)"; else echo "Extensions de virtualisation : NON détectées"; fi
else
  grep -m1 'model name' /proc/cpuinfo || true
fi

section "Mémoire"
free -h 2>/dev/null || cat /proc/meminfo | head -3

section "Disques et espace"
lsblk -o NAME,SIZE,TYPE,TRAN,MODEL,MOUNTPOINT 2>/dev/null || true
echo
df -h / /home 2>/dev/null | awk 'NR==1 || !seen[$0]++'

section "Virtualisation"
if [ -e /dev/kvm ]; then
  echo "KVM : disponible (/dev/kvm présent)"
  ls -l /dev/kvm
else
  echo "KVM : ABSENT — les VM fonctionneront en émulation logicielle (lent, mais utilisable en mode texte)"
fi
command -v qemu-system-x86_64 >/dev/null 2>&1 \
  && echo "qemu-system-x86_64 : installé ($(qemu-system-x86_64 --version | head -1))" \
  || echo "qemu-system-x86_64 : non installé (sudo apt install qemu-system-x86 qemu-utils)"

section "Outils utiles"
for t in wget curl sha256sum sha512sum lsblk dd; do
  if command -v "$t" >/dev/null 2>&1; then echo "  OK    $t"; else echo "  MANQUE $t"; fi
done

section "Périphériques USB amovibles"
lsblk -o NAME,SIZE,TRAN,RM,MODEL 2>/dev/null | awk 'NR==1 || $3=="usb" || $4=="1"'


section "Verdict pour le banc NexBSD (calcul automatique)"
# Règles issues de docs/23-banc-sur-mint.md — dites franchement, sans optimisme.
RAM_MO=$(awk '/MemTotal/{print int($2/1024)}' /proc/meminfo)
LIBRE_GO=$(df -BG --output=avail /home 2>/dev/null | tail -1 | tr -dc '0-9')
[ -z "${LIBRE_GO:-}" ] && LIBRE_GO=0

if grep -qiE '^flags.*(vmx|svm)' /proc/cpuinfo; then
    VIRT="matérielle disponible (VT-x/AMD-V actif)"
    VIRT_OK=oui
else
    VIRT="ABSENTE — soit le processeur ne la propose pas, soit elle est désactivée dans le BIOS"
    VIRT_OK=non
fi
[ -e /dev/kvm ] && KVM="oui" || KVM="non"

echo "Mémoire totale      : ${RAM_MO} Mo"
echo "Espace libre /home  : ${LIBRE_GO} Go"
echo "Virtualisation      : ${VIRT}"
echo "KVM utilisable      : ${KVM}"
echo
echo "┌─────────────────────────────────────────────────────────────┐"

# 1. Héberger une VM FreeBSD pour les tests : 2 Go de RAM et 20 Go libres suffisent.
if [ "$RAM_MO" -ge 3500 ] && [ "$LIBRE_GO" -ge 20 ]; then
    echo "│ 1. VM DE TEST (FreeBSD + Samba + LDAP) ............ POSSIBLE │"
elif [ "$RAM_MO" -ge 2500 ] && [ "$LIBRE_GO" -ge 20 ]; then
    echo "│ 1. VM DE TEST ................ POSSIBLE MAIS SERRÉ         │"
else
    echo "│ 1. VM DE TEST ............................. IMPOSSIBLE ICI │"
fi

# 2. Construire une image NexBSD (buildworld) : >= 8 Go RAM, >= 40 Go, plusieurs heures.
if [ "$RAM_MO" -ge 7500 ] && [ "$LIBRE_GO" -ge 40 ]; then
    echo "│ 2. CONSTRUCTION D'IMAGE NEXBSD .................... POSSIBLE │"
else
    echo "│ 2. CONSTRUCTION D'IMAGE NEXBSD ...... IMPOSSIBLE SUR CETTE  │"
    echo "│    MACHINE (il faut >= 8 Go de RAM et >= 40 Go libres)      │"
fi
echo "└─────────────────────────────────────────────────────────────┘"
echo
echo "Ces deux verdicts sont calculés, pas devinés. Le premier ouvre les tests ;"
echo "le second ouvre NexBSD lui-même (docs/22-delta-nexbsd.md §6)."

section "Résumé à reporter dans docs/hardware.md"
echo "Date du relevé : $(date -I)"
echo "À remplir : CPU / cœurs / RAM / espace libre /home / KVM oui-non"
echo
echo "Fin du diagnostic — rien n'a été modifié."

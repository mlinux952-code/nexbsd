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

section "Résumé à reporter dans docs/hardware.md"
echo "Date du relevé : $(date -I)"
echo "À remplir : CPU / cœurs / RAM / espace libre /home / KVM oui-non"
echo
echo "Fin du diagnostic — rien n'a été modifié."

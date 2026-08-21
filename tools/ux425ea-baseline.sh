#!/usr/bin/env bash

# Collect read-only evidence from a running UX425EA/Aurora system.
# This script intentionally does not change system state or install packages.
set -uo pipefail

OUTPUT_DIR="${1:-./ux425ea-baseline-$(date -u +%Y%m%dT%H%M%SZ)}"
mkdir -p "${OUTPUT_DIR}"

run_capture() {
  local name="$1"
  shift
  {
    printf '$'
    printf ' %q' "$@"
    printf '\n\n'
    if command -v "$1" >/dev/null 2>&1; then
      "$@"
    else
      printf 'NOT AVAILABLE: %s\n' "$1"
    fi
  } >"${OUTPUT_DIR}/${name}.txt" 2>&1 || printf '\nCOMMAND EXITED %s\n' "$?" >>"${OUTPUT_DIR}/${name}.txt"
}

run_shell() {
  local name="$1"
  local command_line="$2"
  {
    printf '$ %s\n\n' "${command_line}"
    bash -c "${command_line}"
  } >"${OUTPUT_DIR}/${name}.txt" 2>&1 || printf '\nCOMMAND EXITED %s\n' "$?" >>"${OUTPUT_DIR}/${name}.txt"
}

cat >"${OUTPUT_DIR}/README.txt" <<EOF
UX425EA baseline evidence
=========================
Collected: $(date -u --iso-8601=seconds)
Host: $(hostname)
Output: ${OUTPUT_DIR}

This collection is read-only. Review files before sharing them; hardware and
kernel information may identify the machine. Run once on the current image and
again after each image change under comparable AC/battery and display conditions.
EOF

run_capture bootc-status sudo bootc status
run_capture kernel uname -a
run_shell cmdline 'cat /proc/cmdline'
# The single-quoted commands are intentionally expanded by the nested bash.
# shellcheck disable=SC2016
run_shell dmi 'for f in sys-vendor product-name product-version bios-version; do printf "%s: " "$f"; cat "/sys/class/dmi/id/$f" 2>/dev/null || true; done'
run_capture pci lspci -nnk
run_capture cpu lscpu
run_capture memory free -h
run_capture memory-topology lshw -C memory
# shellcheck disable=SC2016
run_shell graphics-devices 'ls -l /dev/dri 2>/dev/null || true; for f in /sys/class/drm/card*/device/{vendor,device,driver/module/version}; do [ -e "$f" ] && printf "%s: " "$f" && cat "$f"; done'
run_capture glxinfo glxinfo -B
run_capture vulkan vulkaninfo --summary
run_capture vaapi vainfo
run_capture drm drm_info
run_shell i915-log 'journalctl -b -k --no-pager | grep -Ei "i915|drm|guc|huc|firmware|gpu" || true'
# shellcheck disable=SC2016
run_shell i915-parameters 'for f in /sys/module/i915/parameters/{enable_psr,enable_guc,enable_fbc,enable_dc}; do [ -e "$f" ] && printf "%s: " "$f" && cat "$f"; done'
run_capture power-profile powerprofilesctl get
run_capture power-profile-list powerprofilesctl list
# shellcheck disable=SC2016
run_shell platform-profile 'for f in /sys/firmware/acpi/platform_profile /sys/firmware/acpi/platform_profile_choices; do [ -e "$f" ] && printf "%s: " "$f" && cat "$f"; done'
run_capture thermald-systemctl systemctl status thermald --no-pager
run_capture power-profiles-systemctl systemctl status power-profiles-daemon --no-pager
run_shell sysctl-custom 'sysctl kernel.numa_balancing net.core.default_qdisc 2>/dev/null || true'
# shellcheck disable=SC2016
run_shell nvme-scheduler 'for f in /sys/block/nvme*/queue/scheduler; do [ -e "$f" ] && printf "%s: " "$f" && cat "$f"; done'
run_capture zram zramctl
run_shell rpm-graphics 'rpm -qa | sort | grep -Ei "mesa|vulkan|vaapi|libva|firmware|i915|power-profiles|thermald|tuned|zram" || true'
run_capture display-login loginctl show-session "$(loginctl list-sessions --no-legend 2>/dev/null | awk 'NR==1 {print $1}')" -p Type -p Remote -p State
run_capture journal-errors journalctl -b -p warning..alert --no-pager

printf 'Baseline evidence written to %s\n' "${OUTPUT_DIR}"
printf 'No system changes were made.\n'

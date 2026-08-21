#!/usr/bin/env bash

# Compare existing TuneD profiles with a repeatable Vulkan workload.
# The selected profile is restored when this script exits.
set -uo pipefail

OUTPUT_DIR="${1:-./ux425ea-profile-benchmark-$(date -u +%Y%m%dT%H%M%SZ)}"
REPEATS="${REPEATS:-5}"
DURATION="${DURATION:-20}"
PROFILES=(throughput-performance balanced)
mkdir -p "${OUTPUT_DIR}"

if ! command -v tuned-adm >/dev/null 2>&1 || ! command -v vkcube >/dev/null 2>&1; then
  printf 'tuned-adm and vkcube are required\n' >&2
  exit 1
fi

ORIGINAL_PROFILE="$(tuned-adm active 2>/dev/null | sed -n 's/^Current active profile: //p' | head -n1)"
if [[ -z "${ORIGINAL_PROFILE}" ]]; then
  printf 'Unable to determine the active TuneD profile\n' >&2
  exit 1
fi

restore_profile() {
  tuned-adm profile "${ORIGINAL_PROFILE}" >/dev/null 2>&1 ||
    printf 'WARNING: failed to restore TuneD profile %s\n' "${ORIGINAL_PROFILE}" >&2
}
trap restore_profile EXIT

cat >"${OUTPUT_DIR}/README.txt" <<EOF
UX425EA TuneD profile benchmark
===============================
Collected: $(date -u --iso-8601=seconds)
Original profile: ${ORIGINAL_PROFILE}
Repeats per profile: ${REPEATS}
Vulkan workload duration: ${DURATION}s (Wayland vkcube)

This test temporarily selects existing TuneD profiles and restores the original
profile on exit. It is not a game benchmark. Compare results only under the same
AC/battery, display, HDR, resolution, and background-load conditions.
EOF

read_value() {
  local path="$1"
  if [[ -r "${path}" ]]; then
    cat "${path}"
  else
    printf 'NA'
  fi
}

measure_once() {
  local profile="$1"
  local iteration="$2"
  local prefix="${OUTPUT_DIR}/${profile}-${iteration}"
  local before after start end

  tuned-adm profile "${profile}" >"${prefix}-profile.log" 2>&1 || return 1
  sleep 5
  before="$(read_value /sys/class/powercap/intel-rapl:0/energy_uj)"
  start="$(date +%s%N)"
  timeout "${DURATION}s" vkcube --wsi wayland --c 600 --suppress_popups >"${prefix}-vkcube.log" 2>&1
  local workload_status=$?
  end="$(date +%s%N)"
  after="$(read_value /sys/class/powercap/intel-rapl:0/energy_uj)"

  {
    printf 'profile=%s\niteration=%s\nworkload_exit=%s\nelapsed_ns=%s\n' \
      "${profile}" "${iteration}" "${workload_status}" "$((end - start))"
    printf 'rapl_before_uj=%s\nrapl_after_uj=%s\n' "${before}" "${after}"
    if [[ "${before}" =~ ^[0-9]+$ && "${after}" =~ ^[0-9]+$ ]]; then
      printf 'rapl_delta_uj=%s\n' "$((after - before))"
    else
      printf 'rapl_delta_uj=NA\n'
    fi
    printf 'platform_profile=%s\nscaling_governor=%s\nepp=%s\ngpu_freq_mhz=%s\n' \
      "$(read_value /sys/firmware/acpi/platform_profile)" \
      "$(read_value /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor)" \
      "$(read_value /sys/devices/system/cpu/cpu0/cpufreq/energy_performance_preference)" \
      "$(read_value /sys/class/drm/card1/gt_cur_freq_mhz)"
    sensors 2>/dev/null || true
  } >"${prefix}.txt"
}

for profile in "${PROFILES[@]}"; do
  for ((iteration = 1; iteration <= REPEATS; iteration++)); do
    printf 'Measuring %s (%d/%d)\n' "${profile}" "${iteration}" "${REPEATS}"
    measure_once "${profile}" "${iteration}" ||
      printf 'WARNING: measurement failed for %s iteration %d\n' "${profile}" "${iteration}" >&2
  done
done

printf 'Benchmark evidence written to %s\n' "${OUTPUT_DIR}"
printf 'TuneD profile restored to %s\n' "${ORIGINAL_PROFILE}"

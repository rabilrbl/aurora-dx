#!/bin/bash

set -ouex pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HARDWARE_PROFILE="${AURORA_HW_PROFILE:-ux425ea}"

bash "${SCRIPT_DIR}/core-main.sh"

declare -a PROFILE_SLICES=()
case "${HARDWARE_PROFILE}" in
  ux425ea)
    PROFILE_SLICES=(
      "hw-graphics.sh"
      "hw-reliability.sh"
      "hw-peripherals.sh"
      "hw-power.sh"
    )
    ;;
  none)
    PROFILE_SLICES=()
    ;;
  *)
    echo "Unsupported hardware profile: ${HARDWARE_PROFILE}" >&2
    exit 1
    ;;
esac

for slice_script in "${PROFILE_SLICES[@]}"; do
  bash "${SCRIPT_DIR}/${slice_script}"
done

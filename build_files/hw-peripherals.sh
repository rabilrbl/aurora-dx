#!/bin/bash

set -ouex pipefail

if [[ "$(uname -m)" != "x86_64" ]]; then
  echo "UX425EA peripherals slice supports x86_64 only." >&2
  exit 1
fi

PERIPHERAL_PACKAGES=(
  alsa-sof-firmware
  bluez
  NetworkManager-wifi
  pipewire-utils
  v4l-utils
  wireless-regdb
  wireplumber
)

dnf5 install -y --allowerasing "${PERIPHERAL_PACKAGES[@]}"

install -d -m0755 /etc/systemd/system/bluetooth.target.wants
ln -sf /usr/lib/systemd/system/bluetooth.service /etc/systemd/system/bluetooth.target.wants/bluetooth.service

for required_cmd in wpctl v4l2-ctl nmcli bluetoothctl; do
  if ! command -v "${required_cmd}" >/dev/null 2>&1; then
    echo "Missing required peripheral command: ${required_cmd}" >&2
    exit 1
  fi
done

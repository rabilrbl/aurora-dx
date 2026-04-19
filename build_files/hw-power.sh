#!/bin/bash

set -ouex pipefail

if [[ "$(uname -m)" != "x86_64" ]]; then
  echo "UX425EA power slice supports x86_64 only." >&2
  exit 1
fi

POWER_PACKAGES=(
  power-profiles-daemon
  powerstat
  powertop
  thermald
)

dnf5 install -y --allowerasing "${POWER_PACKAGES[@]}"

tee /usr/lib/systemd/system/ux425ea-balanced-power.service >/dev/null <<'EOF'
[Unit]
Description=Set balanced power profile for UX425EA defaults
After=multi-user.target

[Service]
Type=oneshot
ExecStart=/usr/bin/powerprofilesctl set balanced

[Install]
WantedBy=multi-user.target
EOF

ln -sf /usr/lib/systemd/system/thermald.service /etc/systemd/system/multi-user.target.wants/thermald.service
ln -sf /usr/lib/systemd/system/ux425ea-balanced-power.service /etc/systemd/system/multi-user.target.wants/ux425ea-balanced-power.service

for required_cmd in powerprofilesctl powerstat powertop; do
  if ! command -v "${required_cmd}" >/dev/null 2>&1; then
    echo "Missing required power command: ${required_cmd}" >&2
    exit 1
  fi
done

#!/bin/bash

set -ouex pipefail

if [[ "$(uname -m)" != "x86_64" ]]; then
  echo "UX425EA reliability slice supports x86_64 only." >&2
  exit 1
fi

RELIABILITY_PACKAGES=(
  bolt
  drm_info
)

dnf5 install -y --allowerasing "${RELIABILITY_PACKAGES[@]}"

install -Dm0644 /dev/null /etc/modprobe.d/90-ux425ea-i915.conf
cat >/etc/modprobe.d/90-ux425ea-i915.conf <<'EOF'
options i915 enable_psr=0
EOF

ln -sf /usr/lib/systemd/system/bolt.service /etc/systemd/system/multi-user.target.wants/bolt.service

for required_cmd in boltctl drm_info; do
  if ! command -v "${required_cmd}" >/dev/null 2>&1; then
    echo "Missing required reliability command: ${required_cmd}" >&2
    exit 1
  fi
done

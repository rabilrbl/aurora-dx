#!/bin/bash

set -ouex pipefail

if [[ "$(uname -m)" != "x86_64" ]]; then
  echo "UX425EA graphics slice supports x86_64 only." >&2
  exit 1
fi

GRAPHICS_PACKAGES=(
  linux-firmware
  mesa-dri-drivers
  mesa-libEGL
  mesa-libGL
  mesa-libgbm
  mesa-va-drivers
  mesa-vulkan-drivers
  mesa-demos
  libva-intel-media-driver
  libva-utils
  vulkan-tools
  igt-gpu-tools
)

dnf5 install -y --allowerasing "${GRAPHICS_PACKAGES[@]}"

install -Dm0644 /dev/null /etc/environment.d/90-ux425ea-graphics.conf
cat >/etc/environment.d/90-ux425ea-graphics.conf <<'EOF'
LIBVA_DRIVER_NAME=iHD
VDPAU_DRIVER=va_gl
EOF

for required_cmd in glxinfo vulkaninfo vainfo; do
  if ! command -v "${required_cmd}" >/dev/null 2>&1; then
    echo "Missing required graphics validation command: ${required_cmd}" >&2
    exit 1
  fi
done

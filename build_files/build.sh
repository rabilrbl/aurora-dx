#!/bin/bash

set -ouex pipefail

# Kernel swap flow adapted from:
# https://github.com/sihawken/cachyos-kernel-bazzite-dx

sed -i '/^\[main\]/a max_parallel_downloads=10' /etc/dnf/dnf.conf || true

cd /usr/lib/kernel/install.d
mv 05-rpmostree.install 05-rpmostree.install.bak
mv 50-dracut.install 50-dracut.install.bak
printf '%s\n' '#!/bin/sh' 'exit 0' > 05-rpmostree.install
printf '%s\n' '#!/bin/sh' 'exit 0' > 50-dracut.install
chmod +x 05-rpmostree.install 50-dracut.install
cd -

REMOVE_PACKAGES=(
  kernel
  kernel-core
  kernel-modules
  kernel-modules-core
  kernel-modules-extra
  kernel-devel
  kernel-devel-matched
)

for optional_package in kernel-uki-virt kmod-xone; do
  if dnf5 list --installed "${optional_package}" >/dev/null 2>&1; then
    REMOVE_PACKAGES+=("${optional_package}")
  fi
done

dnf5 -y copr enable bieszczaders/kernel-cachyos
dnf5 remove -y --setopt=protect_running_kernel=false "${REMOVE_PACKAGES[@]}"
rm -rf /lib/modules/*
dnf5 install -y kernel-cachyos kernel-cachyos-devel-matched --allowerasing

dnf5 -y copr enable bieszczaders/kernel-cachyos-addons

rm -f /usr/lib/systemd/coredump.conf

dnf5 remove -y code || true
rm -f /etc/yum.repos.d/vscode.repo

if [[ -f /etc/yum.repos.d/terra.repo ]]; then
  sed -i 's/^enabled=0/enabled=1/' /etc/yum.repos.d/terra.repo
else
  dnf5 install -y --nogpgcheck --repofrompath 'terra,https://repos.fyralabs.com/terra$releasever' terra-release
fi

dnf5 install -y curl tar xz zed

if [[ "$(uname -m)" != "x86_64" ]]; then
  echo "Spotify native RPM is only available for x86_64." >&2
  exit 1
fi

cat >/etc/yum.repos.d/warpdotdev.repo <<'EOF'
[warpdotdev]
name=warpdotdev
baseurl=https://releases.warp.dev/linux/rpm/stable
enabled=1
gpgcheck=1
gpgkey=https://releases.warp.dev/linux/keys/warp.asc
EOF
mkdir -p /opt/warpdotdev
dnf5 install -y warp-terminal

curl -fsSL https://negativo17.org/repos/fedora-spotify.repo -o /etc/yum.repos.d/fedora-spotify.repo
dnf5 install -y spotify-client
rm -f /etc/yum.repos.d/fedora-spotify.repo

case "$(uname -m)" in
  x86_64)
    ZEN_ARCH="x86_64"
    ;;
  aarch64 | arm64)
    ZEN_ARCH="aarch64"
    ;;
  *)
    echo "Zen Browser native tarball is only available for x86_64 and aarch64." >&2
    exit 1
    ;;
esac

ZEN_RELEASE_JSON="$(mktemp)"
curl -fsSL https://api.github.com/repos/zen-browser/desktop/releases/latest -o "${ZEN_RELEASE_JSON}"
ZEN_TARBALL_URLS="$(grep -Eo 'https://[^"]+zen[^"]*linux[^"]*'"${ZEN_ARCH}"'[^"]*\.tar\.(xz|bz2)' "${ZEN_RELEASE_JSON}" || true)"
ZEN_TARBALL_URL="$(printf '%s\n' "${ZEN_TARBALL_URLS}" | sed -n '1p')"
rm -f "${ZEN_RELEASE_JSON}"

if [[ -z "${ZEN_TARBALL_URL}" ]]; then
  echo "Unable to find Zen Browser ${ZEN_ARCH} Linux tarball in latest release." >&2
  exit 1
fi

case "${ZEN_TARBALL_URL}" in
  *.tar.xz)
    ZEN_TAR_ARGS=(-xJ)
    ;;
  *.tar.bz2)
    ZEN_TAR_ARGS=(-xj)
    ;;
  *)
    echo "Unsupported Zen Browser tarball format: ${ZEN_TARBALL_URL}" >&2
    exit 1
    ;;
esac

rm -rf /usr/lib/zen-browser /usr/lib/zen
curl -fsSL "${ZEN_TARBALL_URL}" | tar "${ZEN_TAR_ARGS[@]}" -C /usr/lib
mv /usr/lib/zen /usr/lib/zen-browser
ln -sf /usr/lib/zen-browser/zen /usr/bin/zen

for icon_size in 256 128 64 48 32 16; do
  ZEN_ICON="/usr/lib/zen-browser/browser/chrome/icons/default/default${icon_size}.png"
  if [[ -f "${ZEN_ICON}" ]]; then
    install -Dm0644 "${ZEN_ICON}" "/usr/share/icons/hicolor/${icon_size}x${icon_size}/apps/zen-browser.png"
    break
  fi
done

cat >/usr/share/applications/zen-browser.desktop <<'EOF'
[Desktop Entry]
Version=1.0
Name=Zen Browser
GenericName=Web Browser
Comment=Browse the web with Zen Browser
Exec=/usr/bin/zen %u
Icon=zen-browser
Terminal=false
Type=Application
Categories=Network;WebBrowser;
MimeType=text/html;text/xml;application/xhtml+xml;x-scheme-handler/http;x-scheme-handler/https;
StartupNotify=true
StartupWMClass=zen
EOF

dnf5 install -y libcap-ng libcap-ng-devel procps-ng procps-ng-devel
dnf5 install -y cachyos-settings cachyos-ksm-settings --allowerasing

tee /usr/lib/systemd/system/ksmd.service >/dev/null <<'EOF'
[Unit]
Description=Activates Kernel Samepage Merging
ConditionPathExists=/sys/kernel/mm/ksm

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/usr/bin/ksmctl -e
ExecStop=/usr/bin/ksmctl -d

[Install]
WantedBy=multi-user.target
EOF

ln -sf /usr/lib/systemd/system/ksmd.service /etc/systemd/system/multi-user.target.wants/ksmd.service

cd /usr/lib/kernel/install.d
mv -f 05-rpmostree.install.bak 05-rpmostree.install
mv -f 50-dracut.install.bak 50-dracut.install
cd -

KERNEL_VERSION="$(dnf5 repoquery --installed --latest-limit=1 --qf '%{VERSION}-%{RELEASE}.%{ARCH}' kernel-cachyos)"
depmod -a "${KERNEL_VERSION}"
export DRACUT_NO_XATTR=1
/usr/bin/dracut --no-hostonly --kver "${KERNEL_VERSION}" --reproducible -v --add ostree -f "/lib/modules/${KERNEL_VERSION}/initramfs.img"
chmod 0600 "/lib/modules/${KERNEL_VERSION}/initramfs.img"

dnf5 -y clean all

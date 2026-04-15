#!/bin/bash

set -ouex pipefail

source /usr/lib/os-release
FEDORA_VERSION="${VERSION_ID}"
BASEARCH="$(arch)"

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
dnf5 remove -y "${REMOVE_PACKAGES[@]}"
rm -rf /lib/modules/*
dnf5 install -y kernel-cachyos kernel-cachyos-devel-matched --allowerasing

dnf5 -y copr disable bieszczaders/kernel-cachyos || true

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

#!/bin/bash

set -ouex pipefail

FEDORA_VERSION="$(rpm -E %fedora)"
CACHY_REPO_PATH="/etc/yum.repos.d/bieszczaders-kernel-cachyos-fedora-${FEDORA_VERSION}.repo"

curl -fsSL \
  "https://copr.fedorainfracloud.org/coprs/bieszczaders/kernel-cachyos/repo/fedora-${FEDORA_VERSION}/bieszczaders-kernel-cachyos-fedora-${FEDORA_VERSION}.repo" \
  -o "${CACHY_REPO_PATH}"

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
  if rpm -q "${optional_package}" >/dev/null 2>&1; then
    REMOVE_PACKAGES+=("${optional_package}")
  fi
done

dnf5 remove -y "${REMOVE_PACKAGES[@]}"
dnf5 install -y kernel-cachyos kernel-cachyos-devel-matched

rm -f "${CACHY_REPO_PATH}"
dnf5 clean all

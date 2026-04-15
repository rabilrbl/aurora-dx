#!/bin/bash

set -ouex pipefail

FEDORA_VERSION="$(rpm -E %fedora)"
CACHY_REPO_PATH="/etc/yum.repos.d/bieszczaders-kernel-cachyos-fedora-${FEDORA_VERSION}.repo"

curl -fsSL \
  "https://copr.fedorainfracloud.org/coprs/bieszczaders/kernel-cachyos/repo/fedora-${FEDORA_VERSION}/bieszczaders-kernel-cachyos-fedora-${FEDORA_VERSION}.repo" \
  -o "${CACHY_REPO_PATH}"

rpm-ostree override remove \
  kernel \
  kernel-core \
  kernel-modules \
  kernel-modules-core \
  kernel-modules-extra \
  kernel-devel \
  kernel-devel-matched \
  --install kernel-cachyos \
  --install kernel-cachyos-devel-matched

rm -f "${CACHY_REPO_PATH}"
dnf5 clean all

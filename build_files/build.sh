#!/bin/bash

set -ouex pipefail

### Install packages

# Packages can be installed from any enabled yum repo on the image.
# RPMfusion repos are available by default in ublue main images
# List of rpmfusion packages can be found here:
# https://mirrors.rpmfusion.org/mirrorlist?path=free/fedora/updates/43/x86_64/repoview/index.html&protocol=https&redirect=1

# this installs a package from fedora repos
# dnf5 install -y tmux 

# Use a COPR Example:
#
# dnf5 -y copr enable ublue-os/staging
# dnf5 -y install package
# Disable COPRs so they don't end up enabled on the final image:
# dnf5 -y copr disable ublue-os/staging

### Remove starship from the image
# Users who want starship should install it via their package manager (e.g., brew)
# This approach is more maintainable and allows users to have their choice of shell prompt
dnf5 remove -y starship

### Replace SDDM with plasma-login-manager
dnf5 install -y plasma-login-manager
dnf5 remove -y sddm

### Remove SDDM theme workaround no longer needed with plasma-login-manager
rm -f /usr/lib/tmpfiles.d/usr-share-sddm-themes.conf
systemctl disable usr-share-sddm-themes.mount || true

### Set plasma-login-manager as the default display manager
mkdir -p /etc/systemd/system
ln -sf /usr/lib/systemd/system/plasmalogin.service /etc/systemd/system/display-manager.service

#### Example for enabling a System Unit File

# systemctl enable podman.socket

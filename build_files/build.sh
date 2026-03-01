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

### Replace SDDM with plasma-login-manager
dnf5 install -y plasma-login-manager
dnf5 remove -y sddm

### Remove SDDM theme workaround no longer needed with plasma-login-manager
rm -f /usr/lib/tmpfiles.d/usr-share-sddm-themes.conf
systemctl disable usr-share-sddm-themes.mount || true

### Set plasma-login-manager as the default display manager
mkdir -p /etc/systemd/system
ln -sf /usr/lib/systemd/system/plasmalogin.service /etc/systemd/system/display-manager.service

### Fix: Screen freeze after password entry with USB-C DisplayPort external monitor
# When a USB-C DP monitor is connected, the KScreen KWin plugin in the login session
# triggers an output reconfiguration at the exact moment authentication completes,
# causing kwin_wayland to freeze during the session handoff.
# Fix: disable the KScreen plugin in the DM's kwin instance, and add a udev rule
# to ensure DP Alt Mode link training is complete before the greeter is shown.

# Ensure plasmalogin config directory exists with correct ownership
mkdir -p /var/lib/plasmalogin/.config

# Disable the KScreen KWin plugin in the login session.
# This prevents kscreen from re-probing outputs during the auth/session-start
# transition, which is the root cause of the freeze with USB-C DP monitors.
cat > /var/lib/plasmalogin/.config/kwinrc << 'EOF'
[Plugins]
kscreenEnabled=false

[Wayland]
EnablePrimarySelection=true
EOF

# Also disable the kscreen config daemon for the DM session so it doesn't
# interfere with output state during the login → user-session handoff.
cat > /var/lib/plasmalogin/.config/kscreenrc << 'EOF'
[General]
autoChangeEnabled=false
EOF

chown -R plasmalogin:plasmalogin /var/lib/plasmalogin/.config 2>/dev/null || true

# Udev rule: delay DRM connector event processing for USB-C DP outputs to ensure
# DisplayPort Alt Mode link training is fully settled before the DM starts or
# handles hotplug events. Without this the kernel may fire a connector change
# event mid-login that causes kwin to re-enumerate outputs and freeze.
cat > /etc/udev/rules.d/99-usbc-dp-login-fix.rules << 'EOF'
# Wait for USB-C DisplayPort Alt Mode link training to complete before
# notifying compositors of connector changes. Prevents kwin_wayland freeze
# after password entry on the login screen when a USB-C DP monitor is connected.
ACTION=="change", SUBSYSTEM=="drm", ENV{HOTPLUG}=="1", \
    ATTRS{modalias}=="usb:*", \
    RUN+="/usr/bin/sleep 2"
EOF

udevadm control --reload-rules 2>/dev/null || true

#### Example for enabling a System Unit File

# systemctl enable podman.socket

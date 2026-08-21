#!/bin/bash

set -ouex pipefail

# Copy repository-managed system files into the image.
cp -avf "/ctx/system_files"/. /

rm -f /usr/lib/systemd/coredump.conf

dnf5 install -y curl tar xz

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

dnf5 -y clean all

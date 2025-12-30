set -e

echo "Installing NetProbe (overlay-safe method)..."

NETPROBE_ZIP="${IGconf_device_assetdir}/assets/netprobe.zip"
INSTALL_DIR="${IGconf_netprobe_install_path}"
TMP_EXTRACT="/tmp/netprobe-extract.$$"

if [ ! -f "$NETPROBE_ZIP" ]; then
  echo "ERROR: netprobe.zip not found at $NETPROBE_ZIP" >&2
  exit 1
fi

# 1️⃣ Extract OUTSIDE chroot
rm -rf "$TMP_EXTRACT"
mkdir -p "$TMP_EXTRACT"

unzip -oq "$NETPROBE_ZIP" -d "$TMP_EXTRACT"

# 2️⃣ Prepare target directory INSIDE chroot
uchroot "$1" bash -eux <<EOF
mkdir -p "$INSTALL_DIR"
chmod 755 "$INSTALL_DIR"
EOF

# 3️⃣ Copy extracted files INTO chroot (overlay-safe)
cp -a "$TMP_EXTRACT/." "$1$INSTALL_DIR/"

# 4️⃣ Fix ownership INSIDE chroot
uchroot "$1" bash -eux <<EOF
chown -R root:root "$INSTALL_DIR"
chmod -R u=rwX,go=rX "$INSTALL_DIR"
EOF

# 5️⃣ Cleanup
rm -rf "$TMP_EXTRACT"

echo "NetProbe installed successfully"

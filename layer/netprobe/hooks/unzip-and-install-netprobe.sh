#!/usr/bin/env bash
set -e

export DEBIAN_FRONTEND=noninteractive

echo "[netprobe] Installing unzip (if not present)"
apt-get update
apt-get install -y unzip

NETPROBE_DIR="/home/netmeldr/netprobe"

echo "[netprobe] Unzipping netprobe.zip into $NETPROBE_DIR"
cd "$NETPROBE_DIR"

unzip -o netprobe.zip

rm -f netprobe.zip

echo "[netprobe] Netprobe files extracted"
"$NETPROBE_DIR/install_netprobe.sh"

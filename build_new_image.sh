#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"

arch=$(uname -m)
case "$arch" in
    x86_64) network_interface=${GO2_NETWORK_INTERFACE:-enp0s31f6} ;;
    aarch64) network_interface=${GO2_NETWORK_INTERFACE:-eth0} ;;
    *) echo "Unsupported architecture: $arch" >&2; exit 1 ;;
esac

docker build -t dfki_quad_daocp:latest \
    --build-arg "HW_ARCH=$arch" \
    --build-arg "GO2_NETWORK_INTERFACE=$network_interface" docker/

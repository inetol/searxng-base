#!/bin/sh

case "${TARGETPLATFORM:?}" in
linux/amd64) XBPS_TARGET_ARCH="x86_64" ;;
linux/arm64) XBPS_TARGET_ARCH="aarch64" ;;
linux/arm/v7) XBPS_TARGET_ARCH="armv7l" ;;
*)
	echo >&2 "Unsupported platform: $TARGETPLATFORM"
	exit 1
	;;
esac

case "$XBPS_TARGET_ARCH" in
aarch64*) REPO="$XBPS_MIRROR/current/aarch64" ;;
*) REPO="$XBPS_MIRROR/current" ;;
esac

export REPO XBPS_TARGET_ARCH

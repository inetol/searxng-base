#!/usr/bin/env sh
# shellcheck shell=dash
set -eu

#MISE alias="b:space"
#MISE description="Build \"searxng/space\" base image"

#USAGE flag "--push" help="Push to registry" default="false"
#USAGE arg "<target>" default="linux/amd64,linux/arm64"

# shellcheck disable=SC2154
X_PODMAN_TARGET="$usage_target"
X_PODMAN_MANIFEST_TAG="space"

. ./.mise/snippet/podman-build.sh
. ./.mise/snippet/podman-push.sh

#!/usr/bin/env sh
# shellcheck shell=dash

# shellcheck disable=SC2154
if [ "$usage_push" != "true" ]; then
	exit 0
fi

set +u
if [ "$GITHUB_ACTIONS" != "true" ]; then
	echo >&2 "This task is intended to be run in GHA"
	exit 1
fi
set -u

podman manifest push --all "$X_PODMAN_MANIFEST"

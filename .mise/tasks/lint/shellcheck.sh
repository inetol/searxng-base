#!/usr/bin/env sh
# shellcheck shell=dash
set -eu

#MISE description="Checks shell scripts with \"shellcheck\" tool"

find . -name "*.sh" -type f -exec mise exec shellcheck -- shellcheck -x {} +

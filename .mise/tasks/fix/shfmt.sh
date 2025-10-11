#!/usr/bin/env sh
# shellcheck shell=dash
set -eu

#MISE description="Formats shell scripts with \"shfmt\" tool"

mise exec shfmt -- shfmt --list --write .

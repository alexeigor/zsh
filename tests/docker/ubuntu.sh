#!/usr/bin/env sh
# Run the test suite inside an Ubuntu 24.04 container (Tier 3, cross-distro).
#
# Validates that the config boots cleanly on Ubuntu, where bat/fd are renamed
# (batcat/fdfind) and starship/zoxide are not in apt. Requires a running Docker.
#
#   tests/docker/ubuntu.sh
#
# The repo is mounted read-only; the test sandbox is created in the container's
# /tmp, so nothing on the host is modified.

set -eu

# Repo root = two levels up from this script.
REPO="$(cd "$(dirname "$0")/../.." && pwd)"

exec docker run --rm -v "$REPO":/cfg:ro ubuntu:24.04 bash -c '
  set -e
  export DEBIAN_FRONTEND=noninteractive
  apt-get update -qq
  apt-get install -y -qq zsh zoxide curl ca-certificates tar >/dev/null

  # starship is not packaged for Ubuntu. Fetch the prebuilt binary straight
  # from GitHub releases (genuine TLS chain, full verification - no -k needed).
  # We avoid the starship.rs curl|sh installer, whose host failed TLS here.
  # Note: starship ships no aarch64-gnu build; ARM64 uses the musl variant.
  case "$(uname -m)" in
    x86_64)        target=x86_64-unknown-linux-gnu ;;
    aarch64|arm64) target=aarch64-unknown-linux-musl ;;
    *) echo "unsupported arch: $(uname -m)" >&2; exit 1 ;;
  esac
  curl -fsSL "https://github.com/starship/starship/releases/latest/download/starship-${target}.tar.gz" \
    | tar xz -C /usr/local/bin starship

  cd /cfg && exec zsh tests/run.sh
'

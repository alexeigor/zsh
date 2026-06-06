#!/usr/bin/env sh
# Render demo/demo.gif from demo/demo.tape in a reproducible container.
#
#   demo/record.sh
#
# Builds the demo image (this config + all tools + VHS), runs VHS against the
# tape mounted read-only, and copies the resulting GIF out. The GIF is written
# inside the container (owned by the vhs user) and copied out with `docker cp`,
# so there are no bind-mount uid/permission issues on Linux CI.

set -eu

REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"

echo "==> building demo image"
docker build -f demo/Dockerfile -t zsh-demo .

echo "==> rendering demo/demo.gif"
docker rm -f zsh-demo-run >/dev/null 2>&1 || true
docker run --name zsh-demo-run --hostname demo \
  -v "$REPO/demo/demo.tape:/vhs/demo.tape:ro" \
  zsh-demo demo.tape
docker cp zsh-demo-run:/vhs/demo.gif "$REPO/demo/demo.gif"
docker rm zsh-demo-run >/dev/null

echo "==> wrote demo/demo.gif ($(du -h "$REPO/demo/demo.gif" | cut -f1))"

#!/usr/bin/env zsh
# Tier 1: static syntax check. Parses every config file with `zsh -n` (no
# execution, no external tools, no network). Safe to run anywhere.
#
# Expects $REPO and the helpers from lib.sh to be already set/sourced by run.sh.

section "Tier 1: syntax (zsh -n)"

# Discover config files by glob so new modules are covered automatically.
# Exclude third-party plugins/ and the optional gitignored local.zsh.
setopt local_options null_glob
local -a files
files=( "$REPO"/.zshenv "$REPO"/.zprofile "$REPO"/.zshrc "$REPO"/*.zsh )

local f
for f in "${files[@]}"; do
  [[ -f "$f" ]] || continue
  if zsh -n -- "$f" 2>/dev/null; then
    pass "${f:t}"
  else
    fail "${f:t}"
    # Re-run to surface the parser error
    zsh -n -- "$f"
  fi
done

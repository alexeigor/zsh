#!/usr/bin/env zsh
# Tier 4: starship config integrity. Guards the two prompt bugs we hit before:
# empty language symbols (Nerd Font glyphs stripped to "") and an unparseable
# config. Also confirms hostname/username modules are wired into the format.
#
# Expects $REPO and the helpers from lib.sh to be already set/sourced by run.sh.

section "Tier 4: starship config"

local toml="$REPO/starship.toml"

# --- No language module may have an empty symbol (PUA-stripping regression) ---
local mod sym
for mod in nodejs rust golang php python; do
  # Print the first `symbol = ...` line inside the [mod] block.
  sym="$(awk -v m="[$mod]" '
    $0==m {f=1; next}
    f && /^\[/ {f=0}
    f && /^symbol[ =]/ {print; exit}
  ' "$toml")"
  if [[ -z "$sym" ]]; then
    fail "[$mod] has a symbol line"
  elif [[ "$sym" == *'""'* ]]; then
    fail "[$mod] symbol is non-empty (found empty \"\")"
  else
    pass "[$mod] symbol is set"
  fi
done

# --- Prompt format wires in the user@host modules ----------------------------
local fmt="$(awk -F'=' '/^format[ ]*=/{print; exit}' "$toml")"
assert_match '$username' "$fmt" "format includes \$username"
assert_match '$hostname' "$fmt" "format includes \$hostname"

# --- starship accepts the config (parses + renders) --------------------------
if command -v starship >/dev/null 2>&1; then
  if STARSHIP_CONFIG="$toml" starship prompt >/dev/null 2>/dev/null; then
    pass "starship parses and renders the config"
  else
    fail "starship parses and renders the config"
  fi
else
  skip "starship render (starship not installed)"
fi

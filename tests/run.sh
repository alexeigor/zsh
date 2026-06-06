#!/usr/bin/env zsh
# Test runner for this zsh configuration.
#
#   zsh tests/run.sh
#
# Runs two tiers and prints a summary. Exit code is non-zero if any test failed.
#   Tier 1  static syntax check (zsh -n) -- zero dependencies, runs anywhere.
#   Tier 2  sandboxed startup smoke test -- isolated HOME/XDG, no network, does
#           not touch the real history/cache. Skips if zoxide/starship absent.

emulate -L zsh
set -u

# Repo root = parent of this tests/ directory.
REPO="${0:A:h:h}"

source "${0:A:h}/lib.sh"
source "${0:A:h}/tier1_syntax.sh"
source "${0:A:h}/tier2_smoke.sh"

print
print -r -- "== Summary =="
print -r -- "  pass=$TESTS_PASS  fail=$TESTS_FAIL  skip=$TESTS_SKIP"

(( TESTS_FAIL == 0 ))

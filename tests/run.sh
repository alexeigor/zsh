#!/usr/bin/env zsh
# Test runner for this zsh configuration.
#
#   zsh tests/run.sh
#
# Runs the tiers below and prints a summary. Exit code is non-zero on any fail.
#   Tier 1  static syntax check (zsh -n) -- zero dependencies, runs anywhere.
#   Tier 2  sandboxed startup smoke test -- isolated HOME/XDG, no network, does
#           not touch the real history/cache. Skips if zoxide/starship absent.
#   Tier 3  behavior -- aliases, env, options, functions/widgets, and the
#           absent-tool / absent-icons graceful-degradation regressions.
#   Tier 4  starship config -- the prompt config parses and renders.
#   Tier 5  dependency presence -- every command the config calls is installed
#           (PASS) or reported absent (SKIP).

emulate -L zsh
set -u

# Repo root = parent of this tests/ directory.
REPO="${0:A:h:h}"

source "${0:A:h}/lib.sh"
source "${0:A:h}/tier1_syntax.sh"
source "${0:A:h}/tier2_smoke.sh"
source "${0:A:h}/tier3_behavior.sh"
source "${0:A:h}/tier4_starship.sh"
source "${0:A:h}/tier5_dependencies.sh"

print
print -r -- "== Summary =="
print -r -- "  pass=$TESTS_PASS  fail=$TESTS_FAIL  skip=$TESTS_SKIP"

(( TESTS_FAIL == 0 ))

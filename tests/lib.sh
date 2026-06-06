#!/usr/bin/env zsh
# Tiny test helpers shared by the test tiers. No framework, no dependencies.

# Counters (exported so sourced tier scripts share them via the same shell)
typeset -gi TESTS_PASS=0 TESTS_FAIL=0 TESTS_SKIP=0

# ANSI colours, disabled when stdout is not a terminal
if [[ -t 1 ]]; then
  _C_GREEN=$'\e[32m'; _C_RED=$'\e[31m'; _C_YELLOW=$'\e[33m'; _C_RESET=$'\e[0m'
else
  _C_GREEN=''; _C_RED=''; _C_YELLOW=''; _C_RESET=''
fi

pass() { TESTS_PASS+=1; print -r -- "  ${_C_GREEN}PASS${_C_RESET} $1"; }
fail() { TESTS_FAIL+=1; print -r -- "  ${_C_RED}FAIL${_C_RESET} $1"; }
skip() { TESTS_SKIP+=1; print -r -- "  ${_C_YELLOW}SKIP${_C_RESET} $1"; }

section() { print; print -r -- "== $1 =="; }

# assert_eq <expected> <actual> <label>
assert_eq() {
  if [[ "$1" == "$2" ]]; then
    pass "$3"
  else
    fail "$3 (expected '$1', got '$2')"
  fi
}

# assert_match <substring> <text> <label>
assert_match() {
  if [[ "$2" == *"$1"* ]]; then
    pass "$3"
  else
    fail "$3 (expected to contain '$1', got '$2')"
  fi
}

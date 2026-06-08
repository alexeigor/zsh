#!/usr/bin/env zsh
# Tier 2: sandboxed source smoke test. Sources the real config (.zshenv +
# .zshrc) in a throwaway HOME/XDG environment so it cannot touch the user's
# real history or cache, then asserts a clean startup.
#
# Expects $REPO and the helpers from lib.sh to be already set/sourced by run.sh.

section "Tier 2: sandboxed startup smoke test"

# `zoxide init` / `starship init` are now command-v guarded (Tier 3 verifies a
# clean startup when they are absent). This full smoke test still wants the real
# tools present so it exercises their actual init output; skip (don't fail) when
# they aren't installed so the suite stays honest on minimal machines.
local -a missing
local tool
for tool in zoxide starship; do
  command -v "$tool" >/dev/null 2>&1 || missing+=("$tool")
done
if (( ${#missing} )); then
  skip "full startup smoke (missing tools: ${missing[*]}; Tier 3 covers clean startup without them)"
  return 0
fi

# Throwaway sandbox; auto-cleaned on exit.
local sandbox; sandbox="$(mktemp -d)"
trap 'rm -rf "$sandbox"' EXIT INT TERM

mkdir -p \
  "$sandbox/.config/lf" \
  "$sandbox/.cache/zsh" \
  "$sandbox/.local/state/zsh" \
  "$sandbox/.local/share"
# Satisfy the unguarded `cat ~/.config/lf/icons` in .zshrc
print -r -- "" > "$sandbox/.config/lf/icons"

local out="$sandbox/out.log" err="$sandbox/err.log"

# Snapshot the real history file's mtime to prove the sandboxed run never
# touches it. stat differs on macOS (-f %m) vs GNU/Linux (-c %Y).
# GNU/Linux form (-c %Y) first, then BSD/macOS (-f %m). The order matters:
# on Linux `stat -f` means "filesystem status" and would dump block/inode info
# instead of an mtime, so the GNU form must be tried first.
_mtime() { stat -c %Y "$1" 2>/dev/null || stat -f %m "$1" 2>/dev/null; }
local real_hist="${XDG_STATE_HOME:-$HOME/.local/state}/zsh/history"
local hist_before=""; [[ -e "$real_hist" ]] && hist_before="$(_mtime "$real_hist")"

# Clean-slate env (env -i), re-injecting only what is needed. HOME drives all
# XDG_* derivation in .zshenv. ZDOTDIR points at the real repo so the config is
# found. ZSH_SKIP_PLUGIN_INSTALL prevents any network clone. `-i` loads .zshrc;
# no `-l` so .zprofile's ssh-add/cargo side effects are skipped.
env -i \
  HOME="$sandbox" \
  ZDOTDIR="$REPO" \
  ZPLUGINDIR="$REPO/plugins" \
  HISTFILE="$sandbox/.local/state/zsh/history" \
  TERM="${TERM:-xterm-256color}" \
  PATH="$PATH" \
  ZSH_SKIP_PLUGIN_INSTALL=1 \
  zsh -i -c 'exit 0' >"$out" 2>"$err"
local rc=$?

assert_eq 0 "$rc" "interactive startup exits 0"

# `zsh -i` without a controlling tty (CI, no pty) emits harmless artifacts:
# it can't start ZLE ("can't change option: zle") and can't open a terminal,
# which aborts compinit. These never happen in a real interactive shell. Drop
# them; anything left is a real error (command-not-found, cat failures, etc.).
local benign="can't change option: zle|not interactive and can't open terminal|compinit: initialization aborted"
local real_err; real_err="$(grep -vE "$benign" "$err")"
if [[ -n "$real_err" ]]; then
  fail "startup stderr is empty (ignoring benign no-tty warnings)"
  print -r -- "    --- stderr ---"
  print -r -- "$real_err" | sed 's/^/    /'
else
  pass "startup stderr is empty (ignoring benign no-tty warnings)"
fi

# Isolation: the real history file must be byte-for-byte untouched by the run.
local hist_after=""; [[ -e "$real_hist" ]] && hist_after="$(_mtime "$real_hist")"
assert_eq "$hist_before" "$hist_after" "real history file untouched"

trap - EXIT INT TERM
rm -rf "$sandbox"

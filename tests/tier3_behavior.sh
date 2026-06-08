#!/usr/bin/env zsh
# Tier 3: behavioral assertions. Verifies the config actually *configures* the
# shell (aliases, env, PATH, functions, widgets, options, LF_ICONS), not just
# that it starts cleanly. Plugin-independent: needs no network and no plugins.
#
# Expects $REPO and the helpers from lib.sh to be already set/sourced by run.sh.

section "Tier 3: behavior (config effects)"

# --- Build a throwaway sandbox and capture the resulting shell state ----------
# Note: always declare-and-assign locals in one statement. A bare `local x`
# echoes the variable when it already holds a value from an earlier sourced
# tier (Tier 2 also uses `sandbox`/`out`).
local sandbox="$(mktemp -d)"
trap 'rm -rf "$sandbox"' EXIT INT TERM
mkdir -p "$sandbox/.config/lf" "$sandbox/.cache/zsh" \
         "$sandbox/.local/state/zsh" "$sandbox/.local/share"
print -r -- "# icons" > "$sandbox/.config/lf/icons"   # so LF_ICONS gets populated

# One headless interactive zsh prints key=value lines describing its state.
# $+functions[x] / $+widgets[x] are 1 when defined; [[ -o opt ]] tests setopts.
local out="$(env -i \
  HOME="$sandbox" ZDOTDIR="$REPO" ZPLUGINDIR="$REPO/plugins" \
  HISTFILE="$sandbox/.local/state/zsh/history" TERM="${TERM:-xterm-256color}" \
  PATH="$PATH" ZSH_SKIP_PLUGIN_INSTALL=1 \
  zsh -ic '
    print -r -- "ALIAS_LS=${aliases[ls]}"
    print -r -- "ALIAS_CAT=${aliases[cat]}"
    print -r -- "ALIAS_GREP=${aliases[grep]}"
    print -r -- "ALIAS_VIM=${aliases[vim]}"
    print -r -- "ALIAS_LL=${aliases[ll]}"
    print -r -- "EDITOR=$EDITOR"
    print -r -- "VISUAL=$VISUAL"
    print -r -- "STARSHIP_BASE=${STARSHIP_CONFIG:t}"
    print -r -- "LOCALBIN=${path[(Ie)$HOME/.local/bin]}"
    print -r -- "LF_FN=$(( $+functions[lf] ))"
    print -r -- "FZF_WIDGET=$(( $+widgets[_fzf_file_no_hidden] ))"
    print -r -- "FN_FKILL=$(( $+functions[fkill] ))"
    print -r -- "FN_FCO=$(( $+functions[fco] ))"
    print -r -- "FN_FCD=$(( $+functions[fcd] ))"
    print -r -- "FN_FRG=$(( $+functions[frg] ))"
    print -r -- "SHAREHIST=$([[ -o sharehistory ]] && echo 1 || echo 0)"
    print -r -- "AUTOCD=$([[ -o autocd ]] && echo 1 || echo 0)"
    print -r -- "NUMGLOB=$([[ -o numericglobsort ]] && echo 1 || echo 0)"
    print -r -- "LF_ICONS_LEN=${#LF_ICONS}"
  ' 2>/dev/null)"

# Extract a single key's value from the captured block.
field() { print -r -- "$out" | sed -n "s/^$1=//p"; }

assert_eq "eza --icons"        "$(field ALIAS_LS)"      "alias ls -> eza"
assert_eq "bat"                "$(field ALIAS_CAT)"     "alias cat -> bat"
assert_eq "rg --color=auto"    "$(field ALIAS_GREP)"    "alias grep -> rg"
assert_eq "nvim"               "$(field ALIAS_VIM)"     "alias vim -> nvim"
assert_eq "eza -lh --icons --git" "$(field ALIAS_LL)"   "alias ll -> eza -lh"
assert_eq "nvim"               "$(field EDITOR)"        "EDITOR=nvim"
assert_eq "nvim"               "$(field VISUAL)"        "VISUAL=nvim"
assert_eq "starship.toml"      "$(field STARSHIP_BASE)" "STARSHIP_CONFIG points at starship.toml"
assert_eq "1"                  "$(field LF_FN)"         "lf cd-on-quit function defined"
assert_eq "1"                  "$(field FZF_WIDGET)"    "_fzf_file_no_hidden registered as a zle widget"
assert_eq "1"                  "$(field FN_FKILL)"      "fkill fuzzy-process-kill function defined"
assert_eq "1"                  "$(field FN_FCO)"        "fco fuzzy-branch-checkout function defined"
assert_eq "1"                  "$(field FN_FCD)"        "fcd fuzzy-cd function defined"
assert_eq "1"                  "$(field FN_FRG)"        "frg ripgrep+fzf function defined"
assert_eq "1"                  "$(field SHAREHIST)"     "SHARE_HISTORY enabled"
assert_eq "1"                  "$(field AUTOCD)"        "AUTOCD enabled"
assert_eq "1"                  "$(field NUMGLOB)"       "NUMERIC_GLOB_SORT enabled"

# PATH must include ~/.local/bin (where Ubuntu bat/fd symlinks and tools live)
if [[ "$(field LOCALBIN)" -ge 1 ]]; then pass "~/.local/bin on PATH"; else fail "~/.local/bin on PATH"; fi
# LF_ICONS populated when the icons file exists
if [[ "$(field LF_ICONS_LEN)" -ge 1 ]]; then pass "LF_ICONS populated from icons file"; else fail "LF_ICONS populated from icons file"; fi

# --- LF_ICONS guard: no icons file -> empty and NO error (regression) ---------
local sb2="$(mktemp -d)"
mkdir -p "$sb2/.cache/zsh" "$sb2/.local/state/zsh"
local lf_err="$(env -i HOME="$sb2" ZDOTDIR="$REPO" ZPLUGINDIR="$REPO/plugins" \
  HISTFILE="$sb2/.local/state/zsh/history" TERM="${TERM:-xterm-256color}" \
  PATH="$PATH" ZSH_SKIP_PLUGIN_INSTALL=1 \
  zsh -ic 'print -r -- "LEN=${#LF_ICONS}"' 2>&1 1>/dev/null | grep -i "lf/icons" || true)"
if [[ -z "$lf_err" ]]; then pass "no lf/icons error when the file is absent"; else fail "no lf/icons error when the file is absent ($lf_err)"; fi
rm -rf "$sb2"

# --- zoxide/starship guard: absent from PATH -> no command-not-found (regression)
# Reproduces the reported failure where a login shell without /opt/homebrew/bin
# on PATH printed `command not found: zoxide` and `command not found: starship`.
# Both inits are now wrapped in `command -v` guards, so a PATH that lacks those
# binaries must still start cleanly. Build a PATH with every directory holding
# zoxide or starship removed, so the guards see them as absent no matter where
# they are installed (works on machines without the tools at all, e.g. CI).
local zsh_bin="${commands[zsh]:-zsh}"   # absolute path, in case zsh shares a dir we strip
local -a safe_path=()
local d
for d in $path; do
  [[ -x "$d/zoxide" || -x "$d/starship" ]] && continue
  safe_path+=("$d")
done
local sb3="$(mktemp -d)"
mkdir -p "$sb3/.cache/zsh" "$sb3/.local/state/zsh"
local guard_err="$(env -i HOME="$sb3" ZDOTDIR="$REPO" ZPLUGINDIR="$REPO/plugins" \
  HISTFILE="$sb3/.local/state/zsh/history" TERM="${TERM:-xterm-256color}" \
  PATH="${(j.:.)safe_path}" ZSH_SKIP_PLUGIN_INSTALL=1 \
  "$zsh_bin" -ic 'print -r -- READY' 2>&1 1>/dev/null \
  | grep -iE 'command not found.*(zoxide|starship)|(zoxide|starship).*command not found' || true)"
if [[ -z "$guard_err" ]]; then
  pass "no command-not-found when zoxide/starship are absent from PATH"
else
  fail "no command-not-found when zoxide/starship are absent from PATH ($guard_err)"
fi
rm -rf "$sb3"

# --- local.zsh override hook is wired into .zshrc (static check; safe) --------
if grep -q 'source .*local.zsh' "$REPO/.zshrc"; then
  pass ".zshrc sources machine-local local.zsh"
else
  fail ".zshrc sources machine-local local.zsh"
fi

# --- Idempotency: re-sourcing .zshrc must not abort -------------------------
local resrc="$(env -i HOME="$sandbox" ZDOTDIR="$REPO" ZPLUGINDIR="$REPO/plugins" \
  HISTFILE="$sandbox/.local/state/zsh/history" TERM="${TERM:-xterm-256color}" \
  PATH="$PATH" ZSH_SKIP_PLUGIN_INSTALL=1 \
  zsh -ic 'source "$ZDOTDIR/.zshrc" >/dev/null 2>&1; print -r -- READY' 2>/dev/null)"
assert_match "READY" "$resrc" "re-sourcing .zshrc succeeds (idempotent)"

trap - EXIT INT TERM
rm -rf "$sandbox"

#!/usr/bin/env zsh
# Tier 5: dependency presence. Confirms the external tools the config relies on
# are actually installed and resolvable on PATH -- the check that was missing,
# so aliases/functions could silently point at absent commands.
#
# Missing tools are reported as SKIP (not FAIL) so the suite stays honest on the
# minimal CI images that deliberately install only a subset (see
# .github/workflows/tests.yml). On a fully provisioned machine every line is a
# PASS, making this a real "is my shell environment complete?" health check.
#
# Expects the helpers from lib.sh to be already sourced by run.sh.

section "Tier 5: dependency presence (command -v)"

# command -> what it powers in the config, so a SKIP says what you lose.
typeset -A dep_role
dep_role=(
  zsh      "the shell itself"
  nvim     "EDITOR / vim alias"
  eza      "ls / ll aliases"
  bat      "cat alias / MANPAGER"
  fd       "fzf file-search functions"
  fzf      "Ctrl-R/Ctrl-T, fco/fcd/fkill/frg"
  rg       "grep alias / frg"
  zoxide   "z directory jumping"
  starship "prompt"
  lf       "file manager"
)

# Stable display order (associative-array key order is unspecified in zsh).
local -a deps=(zsh nvim eza bat fd fzf rg zoxide starship lf)

local dep alt found
for dep in $deps; do
  found=""
  if command -v "$dep" >/dev/null 2>&1; then
    found="$dep"
  else
    # Debian/Ubuntu ship these under alternate names; the config accepts either.
    case "$dep" in
      bat) alt=batcat ;;
      fd)  alt=fdfind ;;
      *)   alt="" ;;
    esac
    [[ -n "$alt" ]] && command -v "$alt" >/dev/null 2>&1 && found="$alt"
  fi

  if [[ -n "$found" ]]; then
    pass "$dep installed (${found}) — ${dep_role[$dep]}"
  else
    skip "$dep not installed — ${dep_role[$dep]}"
  fi
done

# A Nerd Font is not a command, so `command -v` can't see it. The starship
# prompt and `eza --icons` render Nerd Font glyphs; without one they show as
# tofu. Detect an installed Nerd Font cross-platform: prefer `fc-list`
# (fontconfig, usual on Linux), else scan the macOS font directories for a
# *Nerd Font* / *NerdFont* face. (Note: this only proves the font is installed,
# not that the terminal is configured to use it -- that can't be checked here.)
local nerd_font=""
if command -v fc-list >/dev/null 2>&1; then
  fc-list 2>/dev/null | grep -iq 'nerd font' && nerd_font="fc-list"
fi
if [[ -z "$nerd_font" ]]; then
  local fdir
  for fdir in "$HOME/Library/Fonts" /Library/Fonts \
              "$HOME/.local/share/fonts" /usr/share/fonts /usr/local/share/fonts; do
    [[ -d "$fdir" ]] || continue
    if print -rl -- "$fdir"/**/*(N) 2>/dev/null | grep -iqE 'nerd[ ]?font'; then
      nerd_font="$fdir"
      break
    fi
  done
fi
if [[ -n "$nerd_font" ]]; then
  pass "Nerd Font installed (via ${nerd_font}) — starship/eza/lf glyphs"
else
  skip "no Nerd Font found — prompt/eza glyphs will render as tofu (see README step 5)"
fi

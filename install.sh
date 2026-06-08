#!/usr/bin/env bash
#
# install.sh — set up this zsh configuration end to end.
#
# Idempotent: safe to re-run; it detects what is already in place and skips it.
# Mirrors the manual steps in README.md so the README can point here as the
# source of truth. Supports macOS (Homebrew), Arch (pacman) and Debian/Ubuntu
# (apt + the bat/fd rename and lf-binary handling).
#
# Usage:
#   ./install.sh [options]
#
# Options:
#   --check        Dry run: print what would happen, change nothing.
#   --yes, -y      Non-interactive: accept defaults (font yes, chsh yes).
#   --no-font      Do not install a Nerd Font.
#   --no-chsh      Do not change the login shell.
#   --font NAME    Nerd Font to install (default: meslo-lg). Maps to the
#                  Homebrew cask font-NAME-nerd-font / Nerd Fonts release name.
#   -h, --help     Show this help.
#
set -euo pipefail

# --------------------------------------------------------------------------- #
# Settings / flags
# --------------------------------------------------------------------------- #
ZCONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/zsh"   # where the config lives
DRY_RUN=0
ASSUME_YES=0
DO_FONT="ask"        # ask | yes | no
DO_CHSH="ask"        # ask | yes | no
FONT_SLUG="meslo-lg" # -> cask font-meslo-lg-nerd-font / release Meslo.zip
REPO_URL="https://github.com/alexeigor/zsh"

# Resolve the directory this script lives in (the repo, if run from a clone).
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd -P)"

# --------------------------------------------------------------------------- #
# Output helpers
# --------------------------------------------------------------------------- #
if [[ -t 1 ]]; then
  C_GREEN=$'\033[32m'; C_YELLOW=$'\033[33m'; C_BLUE=$'\033[34m'
  C_RED=$'\033[31m';   C_BOLD=$'\033[1m';    C_RESET=$'\033[0m'
else
  C_GREEN= C_YELLOW= C_BLUE= C_RED= C_BOLD= C_RESET=
fi
info() { printf '%s==>%s %s\n' "$C_BLUE" "$C_RESET" "$*"; }
ok()   { printf '%s  ok%s  %s\n' "$C_GREEN" "$C_RESET" "$*"; }
warn() { printf '%swarn%s  %s\n' "$C_YELLOW" "$C_RESET" "$*" >&2; }
die()  { printf '%serror%s %s\n' "$C_RED" "$C_RESET" "$*" >&2; exit 1; }

# run CMD...: execute, or just print it in --check mode.
run() {
  if (( DRY_RUN )); then
    printf '%s  would run:%s %s\n' "$C_YELLOW" "$C_RESET" "$*"
  else
    "$@"
  fi
}

# ask QUESTION: yes/no prompt. Honors --yes (always yes) and --check (no change,
# defaults to no so a dry run never claims it would prompt-yes destructively).
ask() {
  local q="$1"
  (( ASSUME_YES )) && return 0
  if (( DRY_RUN )); then
    printf '%s  would ask:%s %s [y/N]\n' "$C_YELLOW" "$C_RESET" "$q"
    return 1
  fi
  local reply
  read -r -p "$q [y/N] " reply
  [[ "$reply" == [yY] || "$reply" == [yY][eE][sS] ]]
}

usage() { sed -n '3,30p' "$0" | sed 's/^# \{0,1\}//'; exit 0; }

# --------------------------------------------------------------------------- #
# Argument parsing
# --------------------------------------------------------------------------- #
while [[ $# -gt 0 ]]; do
  case "$1" in
    --check)    DRY_RUN=1 ;;
    -y|--yes)   ASSUME_YES=1 ;;
    --no-font)  DO_FONT="no" ;;
    --no-chsh)  DO_CHSH="no" ;;
    --font)     [[ $# -ge 2 ]] || die "--font needs a value"; FONT_SLUG="$2"; shift ;;
    -h|--help)  usage ;;
    *)          die "unknown option: $1 (try --help)" ;;
  esac
  shift
done
(( ASSUME_YES )) && { [[ "$DO_FONT" == "ask" ]] && DO_FONT="yes"; [[ "$DO_CHSH" == "ask" ]] && DO_CHSH="yes"; }

# --------------------------------------------------------------------------- #
# OS detection
# --------------------------------------------------------------------------- #
detect_os() {
  case "$(uname -s)" in
    Darwin) echo macos ;;
    Linux)
      if   command -v pacman  >/dev/null 2>&1; then echo arch
      elif command -v apt-get >/dev/null 2>&1; then echo debian
      else echo linux-unknown; fi ;;
    *) echo unknown ;;
  esac
}
OS="$(detect_os)"

have() { command -v "$1" >/dev/null 2>&1; }

# Canonical command names the config calls. bat/fd ship as batcat/fdfind on
# Debian, so treat those alternates as "present" too.
dep_present() {
  case "$1" in
    bat) have bat || have batcat ;;
    fd)  have fd  || have fdfind ;;
    *)   have "$1" ;;
  esac
}

# --------------------------------------------------------------------------- #
# Step 1 — dependencies
# --------------------------------------------------------------------------- #
DEPS=(zsh nvim eza bat fd fzf zoxide starship rg lf)

install_deps_macos() {
  have brew || die "Homebrew not found. Install it from https://brew.sh first."
  local -a missing=()
  local d
  for d in zsh neovim eza bat fd fzf zoxide starship ripgrep lf; do
    case "$d" in
      neovim) dep_present nvim || missing+=("$d") ;;
      ripgrep) dep_present rg  || missing+=("$d") ;;
      *)       dep_present "$d" || missing+=("$d") ;;
    esac
  done
  if (( ${#missing[@]} )); then
    info "Installing via Homebrew: ${missing[*]}"
    run brew install "${missing[@]}"
  else
    ok "all Homebrew dependencies already installed"
  fi
}

install_deps_arch() {
  info "Installing via pacman (sudo)"
  run sudo pacman -S --needed --noconfirm \
    zsh neovim eza bat fd fzf zoxide starship ripgrep lf
}

install_deps_debian() {
  info "Installing via apt (sudo)"
  run sudo apt-get update -qq
  run sudo apt-get install -y -qq zsh neovim eza bat fd-find fzf ripgrep curl ca-certificates tar
  have zoxide   || run sh -c 'curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh'
  have starship || run sh -c 'curl -sS https://starship.rs/install.sh | sh -s -- -y'
  run mkdir -p "$HOME/.local/bin"
  # Debian names: bat->batcat, fd->fdfind. Symlink so the config finds them.
  if have batcat && ! have bat; then run ln -sf "$(command -v batcat)" "$HOME/.local/bin/bat"; fi
  if have fdfind && ! have fd;  then run ln -sf "$(command -v fdfind)" "$HOME/.local/bin/fd"; fi
  if ! have lf; then
    local arch=amd64; [[ "$(uname -m)" == aarch64 || "$(uname -m)" == arm64 ]] && arch=arm64
    info "Fetching lf release binary (linux-$arch)"
    run sh -c "curl -fsSL https://github.com/gokcehan/lf/releases/latest/download/lf-linux-${arch}.tar.gz | tar xz -C '$HOME/.local/bin' lf"
  fi
}

install_deps() {
  info "Step 1/7: dependencies"
  case "$OS" in
    macos)  install_deps_macos ;;
    arch)   install_deps_arch ;;
    debian) install_deps_debian ;;
    *)      warn "unrecognised OS ($OS) — skipping dependency install; install these yourself: ${DEPS[*]}" ;;
  esac
}

# --------------------------------------------------------------------------- #
# Step 2 — repository
# --------------------------------------------------------------------------- #
ensure_repo() {
  info "Step 2/7: config at $ZCONFIG"
  if [[ "$SCRIPT_DIR" == "$ZCONFIG" ]]; then
    ok "running from inside $ZCONFIG"
  elif [[ -e "$ZCONFIG/.zshrc" ]]; then
    ok "$ZCONFIG already present"
  else
    info "Cloning $REPO_URL -> $ZCONFIG"
    run git clone "$REPO_URL" "$ZCONFIG"
  fi
}

# --------------------------------------------------------------------------- #
# Step 3 — runtime directories
# --------------------------------------------------------------------------- #
make_dirs() {
  info "Step 3/7: state/cache directories"
  run mkdir -p "${XDG_STATE_HOME:-$HOME/.local/state}/zsh" \
               "${XDG_CACHE_HOME:-$HOME/.cache}/zsh" \
               "${XDG_CONFIG_HOME:-$HOME/.config}/lf"
  ok "history + completion-cache + lf dirs ready"
}

# --------------------------------------------------------------------------- #
# Step 4 — lf icons (optional, only if missing)
# --------------------------------------------------------------------------- #
install_lf_icons() {
  info "Step 4/7: lf icons"
  local icons="${XDG_CONFIG_HOME:-$HOME/.config}/lf/icons"
  if [[ -s "$icons" ]]; then
    ok "lf icons already present"
  else
    run sh -c "curl -fsSL https://raw.githubusercontent.com/gokcehan/lf/master/etc/icons.example -o '$icons'"
  fi
}

# --------------------------------------------------------------------------- #
# Step 5 — ZDOTDIR bootstrap (~/.zshenv) + Homebrew shellenv (macOS)
# --------------------------------------------------------------------------- #
setup_bootstrap() {
  info "Step 5/7: shell bootstrap"

  # Warn (do not touch) if an existing ~/.zshrc will be bypassed by ZDOTDIR.
  if [[ -f "$HOME/.zshrc" && ! -L "$HOME/.zshrc" ]]; then
    warn "~/.zshrc exists and will be IGNORED once ZDOTDIR points at $ZCONFIG."
    warn "It is left untouched. Migrate anything you need into $ZCONFIG/local.zsh."
  fi

  # ~/.zshenv: the one file zsh reads before ZDOTDIR is known. Idempotent.
  local zshenv="$HOME/.zshenv"
  if [[ -f "$zshenv" ]] && grep -q 'ZDOTDIR=' "$zshenv"; then
    ok "~/.zshenv already sets ZDOTDIR"
  else
    [[ -f "$zshenv" ]] && { warn "backing up existing ~/.zshenv -> ~/.zshenv.bak"; run cp "$zshenv" "$zshenv.bak"; }
    info "writing ~/.zshenv (ZDOTDIR -> $ZCONFIG)"
    if (( DRY_RUN )); then
      printf '%s  would write:%s ~/.zshenv\n' "$C_YELLOW" "$C_RESET"
    else
      cat >> "$zshenv" <<EOF

# Bootstrap: point zsh at the config in ~/.config/zsh. This pointer must live
# here because ~/.zshenv is the only file zsh reads before ZDOTDIR is known.
export ZDOTDIR="\$HOME/.config/zsh"
[[ -f "\$ZDOTDIR/.zshenv" ]] && source "\$ZDOTDIR/.zshenv"
EOF
    fi
  fi

  # macOS: Homebrew must be on PATH before .zshrc runs zoxide/starship init.
  # Put it in $ZCONFIG/.zprofile (gitignored, login shells, runs before .zshrc).
  if [[ "$OS" == "macos" ]]; then
    local zprofile="$ZCONFIG/.zprofile"
    if [[ -f "$zprofile" ]] && grep -q 'brew shellenv' "$zprofile"; then
      ok "$ZCONFIG/.zprofile already runs brew shellenv"
    else
      info "writing $ZCONFIG/.zprofile (Homebrew shellenv)"
      if (( DRY_RUN )); then
        printf '%s  would write:%s %s\n' "$C_YELLOW" "$C_RESET" "$zprofile"
      else
        cat >> "$zprofile" <<'EOF'

# Machine-local login-shell setup (gitignored).
# Homebrew (Apple Silicon or Intel) — puts brew's bin on PATH before .zshrc,
# which initializes zoxide/starship.
for _b in /opt/homebrew/bin/brew /usr/local/bin/brew; do
  [[ -x "$_b" ]] && { eval "$("$_b" shellenv)"; break; }
done
unset _b
EOF
      fi
    fi
  fi
}

# --------------------------------------------------------------------------- #
# Step 6 — Nerd Font (optional)
# --------------------------------------------------------------------------- #
nerd_font_installed() {
  if command -v fc-list >/dev/null 2>&1; then
    fc-list 2>/dev/null | grep -iq 'nerd font' && return 0
  fi
  local dir
  for dir in "$HOME/Library/Fonts" /Library/Fonts \
             "$HOME/.local/share/fonts" /usr/share/fonts /usr/local/share/fonts; do
    [[ -d "$dir" ]] || continue
    find "$dir" -iname '*nerd*font*' -print -quit 2>/dev/null | grep -q . && return 0
  done
  return 1
}

install_font() {
  info "Step 6/7: Nerd Font"
  [[ "$DO_FONT" == "no" ]] && { ok "skipped (--no-font)"; return 0; }
  if nerd_font_installed; then ok "a Nerd Font is already installed"; return 0; fi
  if [[ "$DO_FONT" == "ask" ]]; then
    ask "Install the $FONT_SLUG Nerd Font? (needed so prompt/eza icons aren't tofu)" || { warn "skipping font install"; return 0; }
  fi
  case "$OS" in
    macos)
      have brew || { warn "no brew; cannot install font"; return 0; }
      run brew install --cask "font-${FONT_SLUG}-nerd-font" ;;
    arch|debian|*)
      # Map common slugs to Nerd Fonts release zip names.
      local zip="Meslo"
      case "$FONT_SLUG" in
        meslo-lg|meslo) zip="Meslo" ;;
        jetbrains-mono|jetbrainsmono) zip="JetBrainsMono" ;;
        *) zip="$FONT_SLUG" ;;
      esac
      info "downloading Nerd Font '$zip' into ~/.local/share/fonts"
      run mkdir -p "$HOME/.local/share/fonts"
      run sh -c "curl -fsSL -o /tmp/${zip}.zip https://github.com/ryanoasis/nerd-fonts/releases/latest/download/${zip}.zip && unzip -o /tmp/${zip}.zip -d '$HOME/.local/share/fonts/${zip}' >/dev/null"
      have fc-cache && run fc-cache -f ;;
  esac
  warn "Remember to select the Nerd Font in your terminal's settings."
}

# --------------------------------------------------------------------------- #
# Step 7 — default shell (optional)
# --------------------------------------------------------------------------- #
set_default_shell() {
  info "Step 7/7: default shell"
  [[ "$DO_CHSH" == "no" ]] && { ok "skipped (--no-chsh)"; return 0; }
  local zsh_path; zsh_path="$(command -v zsh)"
  if [[ "${SHELL:-}" == "$zsh_path" ]]; then ok "login shell is already $zsh_path"; return 0; fi
  if [[ "$DO_CHSH" == "ask" ]]; then
    ask "Set $zsh_path as your login shell (chsh)?" || { warn "skipping chsh"; return 0; }
  fi
  run chsh -s "$zsh_path"
}

# --------------------------------------------------------------------------- #
# Main
# --------------------------------------------------------------------------- #
main() {
  printf '%szsh configuration installer%s  (OS: %s%s)\n' "$C_BOLD" "$C_RESET" "$OS" "$( ((DRY_RUN)) && echo ', dry run' )"
  install_deps
  ensure_repo
  make_dirs
  install_lf_icons
  setup_bootstrap
  install_font
  set_default_shell
  printf '\n%sDone.%s Open a new terminal (or run %sexec zsh%s).' "$C_GREEN" "$C_RESET" "$C_BOLD" "$C_RESET"
  printf ' Verify with: %szsh %s/tests/run.sh%s\n' "$C_BOLD" "$ZCONFIG" "$C_RESET"
}
main

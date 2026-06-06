# =========================================================
# Plugins
# =========================================================

ZPLUGINDIR="${ZDOTDIR:-$HOME/.config/zsh}/plugins"

_zplugin_load() {
  local plugin_path="${ZPLUGINDIR}/${2}"
  if [[ ! -d "$plugin_path" ]]; then
    # Skip cloning in test/CI sandboxes (no network, no side effects)
    [[ -n "$ZSH_SKIP_PLUGIN_INSTALL" ]] && return 0
    mkdir -p "$ZPLUGINDIR"
    echo "Installing ${2}..."
    git clone --depth=1 "https://github.com/${1}/${2}" "$plugin_path" \
      || { echo "ERROR: failed to install ${2}" >&2; return 1; }
  fi

  local plugin_file="${plugin_path}/${2}.plugin.zsh"
  [[ -f "$plugin_file" ]] || { echo "ERROR: ${2} plugin file missing" >&2; return 1; }

  # Compile to bytecode for faster sourcing; rebuild when the source is newer
  if [[ ! -f "${plugin_file}.zwc" || "$plugin_file" -nt "${plugin_file}.zwc" ]]; then
    zcompile "$plugin_file" 2>/dev/null
  fi

  source "$plugin_file"
}

zplugin-update() {
  local dir
  for dir in "${ZPLUGINDIR}"/*/; do
    echo "Updating ${dir:t}..."
    git -C "$dir" pull --ff-only
  done
}

_zplugin_load zsh-users zsh-autosuggestions
_zplugin_load zsh-users zsh-history-substring-search
_zplugin_load jeffreytse zsh-vi-mode
_zplugin_load zdharma-continuum fast-syntax-highlighting

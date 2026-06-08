# zsh

Powerful but tastefully minimal zsh configuration.

![demo](demo/demo.gif)

> The demo above is generated automatically with [VHS](https://github.com/charmbracelet/vhs).
> Regenerate it with `demo/record.sh` (requires Docker); CI refreshes it when the tape or config changes.

## Dependencies

### Arch

```sh
paru -S zsh neovim eza bat fd fzf zoxide starship ripgrep lf
```

### Ubuntu

```sh
sudo apt install zsh neovim eza bat fd-find fzf ripgrep
# install zoxide and starship separately
curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh
curl -sS https://starship.rs/install.sh | sh
# Ubuntu installs bat and fd under different names, symlink them so everything works
ln -s $(which batcat) ~/.local/bin/bat
ln -s $(which fdfind) ~/.local/bin/fd
# lf is not packaged in apt; grab the latest release binary (use lf-linux-arm64 on ARM)
curl -fsSL https://github.com/gokcehan/lf/releases/latest/download/lf-linux-amd64.tar.gz | tar xz -C ~/.local/bin lf
```

### macOS

```sh
brew install zsh neovim eza bat fd fzf zoxide starship ripgrep lf
```

## Setup

### Quick start (scripted)

```sh
git clone https://github.com/alexeigor/zsh ~/.config/zsh
~/.config/zsh/install.sh          # add --check for a dry run
```

`install.sh` is idempotent and runs the manual steps below on macOS (Homebrew),
Arch (pacman), and Debian/Ubuntu (apt). It installs dependencies, creates the
runtime directories, wires up the `ZDOTDIR` bootstrap, and *prompts* before
installing a Nerd Font or changing your login shell. Flags: `--check` (dry run),
`--yes`, `--no-font`, `--no-chsh`, `--font NAME`. It never overwrites an existing
`~/.zshrc` — it warns and leaves it in place.

### Manual setup

**1. Clone the repo**

```sh
git clone https://github.com/alexeigor/zsh ~/.config/zsh
```

**2. Point zsh at the config directory**

Add the following to `/etc/zsh/zshenv`:

```sh
if [[ -z "$XDG_CONFIG_HOME" ]]
then
    export XDG_CONFIG_HOME="$HOME/.config"
fi

if [[ -d "$XDG_CONFIG_HOME/zsh" ]]
then
    export ZDOTDIR="$XDG_CONFIG_HOME/zsh"
fi
```

**3. Set zsh as your default shell**

```sh
chsh -s $(which zsh)
```

**4. Create required directories**

```sh
mkdir -p ~/.local/state/zsh   # history
mkdir -p ~/.cache/zsh         # completion cache
```

**5. Install a Nerd Font**

The starship prompt, `eza --icons`, and the optional `lf` icons all use [Nerd Font](https://www.nerdfonts.com) glyphs. Without a Nerd Font installed **and selected in your terminal**, those symbols render as tofu (blank boxes). Any Nerd Font works; [MesloLG](https://github.com/ryanoasis/nerd-fonts/tree/master/patched-fonts/Meslo) is a good default.

```sh
# macOS (Homebrew)
brew install --cask font-meslo-lg-nerd-font

# Arch
paru -S ttf-meslo-nerd

# Ubuntu / manual: download a font from the Nerd Fonts releases and install it
# into ~/.local/share/fonts, then refresh the font cache
mkdir -p ~/.local/share/fonts
curl -fsSL -o /tmp/Meslo.zip \
  https://github.com/ryanoasis/nerd-fonts/releases/latest/download/Meslo.zip
unzip -o /tmp/Meslo.zip -d ~/.local/share/fonts/Meslo
fc-cache -f
```

Then set it as your terminal's font:

- **iTerm2**: Settings → Profiles → Text → Font → `MesloLGS Nerd Font`
- **Terminal.app**: Settings → Profiles → Text → Change Font → `MesloLGS Nerd Font`
- **Alacritty / kitty / WezTerm / GNOME Terminal**: set the font family to `MesloLGS Nerd Font` (or the family name of whichever Nerd Font you installed) in the relevant config or preferences.

**6. Install lf icons (optional)**

`.zshrc` exports `LF_ICONS` from `~/.config/lf/icons` to give the [lf](https://github.com/gokcehan/lf) file manager file-type icons. The config skips this gracefully when the file is absent, so this step is optional. To enable icons, drop in the example file from the lf project (requires a [Nerd Font](https://www.nerdfonts.com), see step 5):

```sh
mkdir -p ~/.config/lf
curl -fsSL https://raw.githubusercontent.com/gokcehan/lf/master/etc/icons.example -o ~/.config/lf/icons
```

For colored icons instead, use `etc/icons_colored.example` from the same path.

**7. Start a new shell**

Plugins are installed automatically on first launch via the built-in plugin manager.

## Plugins

Managed without a third-party plugin manager. Plugins are cloned into `$ZDOTDIR/plugins/` on first launch.

| Plugin | Purpose |
|--------|---------|
| [fast-syntax-highlighting](https://github.com/zdharma-continuum/fast-syntax-highlighting) | Syntax highlighting |
| [zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions) | Fish-style inline suggestions |
| [zsh-history-substring-search](https://github.com/zsh-users/zsh-history-substring-search) | Up/down arrow history filtering |
| [zsh-vi-mode](https://github.com/jeffreytse/zsh-vi-mode) | Vi keybindings |

To update all plugins:

```sh
zplugin-update
```

## Keybindings

| Key | Action |
|-----|--------|
| `Ctrl+R` | Fuzzy history search (fzf) |
| `Ctrl+T` | Fuzzy file search including hidden files (fzf + fd) |
| `Ctrl+F` | Fuzzy file search excluding hidden files (fzf + fd) |
| `Ctrl+→` | Move forward one word |
| `Ctrl+←` | Move backward one word |
| `↑` / `↓` | History search by prefix |
| `Ctrl+\` | Toggle autosuggestions |

## Commands

fzf-powered helper functions (run by name, defined in [`fzf.zsh`](./fzf.zsh)). They need only tools already listed as dependencies.

| Command | Action |
|---------|--------|
| `fkill [signal]` | Fuzzy-pick process(es) and signal them (default `TERM`; `Tab` to multi-select) |
| `fco` | Fuzzy-checkout a git branch (local + remote), most recent first |
| `fcd [path]` | Fuzzy-`cd` into a subdirectory |
| `frg <pattern>` | ripgrep a pattern, pick a match in fzf, open it in `$EDITOR` at the line |

## Starship Config

Included in the repo at [`starship.toml`](./starship.toml) and loaded automatically via `STARSHIP_CONFIG` in `.zshenv`. Requires a [Nerd Font](https://www.nerdfonts.com) installed and selected in your terminal — see [Setup step 5](#setup).

## Credits

Originally based on [radleylewis/zsh](https://github.com/radleylewis/zsh) by Radley Sidwell-Lewis. This fork, maintained by [Alexey Gorodilov](https://github.com/alexeigor), adds a number of modifications and improvements while keeping the original's tastefully minimal spirit. Distributed under the MIT License; see [LICENSE](./LICENSE).

### What this fork adds

For a detailed tour of how each feature is wired up, see [`FEATURES.md`](./FEATURES.md).

- **Prompt** (starship): `user@host`, full untruncated path, a two-line layout, a Python module (also triggered by a `.venv` directory), and filled-in language icons for Node, Rust, Go, and PHP.
- **Faster startup**: plugins compiled to `.zwc` bytecode, lazy-loaded nvm, and a cached `compinit` (full security audit runs at most once a day).
- **Robustness**: guarded `lf` icons and `compdef` so a fresh machine starts without errors, plus a sourced `local.zsh` for machine-local overrides.
- **Tests**: a dependency-free zsh suite (syntax check, sandboxed startup smoke test, behavior assertions, and starship config checks), run with `zsh tests/run.sh`.
- **CI** (GitHub Actions): runs the suite on Ubuntu 22.04/24.04, macOS, and Ubuntu 26.04 + Arch Linux containers.
- **Automated demo**: a reproducible [VHS](https://github.com/charmbracelet/vhs) recording (`demo/`) regenerated by CI.
- **Housekeeping**: `lf` added to the dependency lists with icon-install steps, a `CLAUDE.md` guide, and a hardened `.gitignore`.

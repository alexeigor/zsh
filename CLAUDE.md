# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

A personal zsh configuration that lives at `$ZDOTDIR` (`~/.config/zsh`). There is no build or test step. Changes are validated by sourcing a file or starting a new shell. For a feature-by-feature explanation of the config, see `FEATURES.md`.

## Common commands

- Apply changes without restarting: `source ~/.config/zsh/.zshrc` (or `exec zsh` for a clean reload).
- Run the test suite: `zsh tests/run.sh` (Tier 1 = `zsh -n` syntax check on every config file; Tier 2 = sandboxed startup smoke test in a throwaway `$HOME`/XDG so it never touches real history/cache. Tier 2 skips if `zoxide`/`starship` are absent).
- Update all plugins: `zplugin-update` (defined in `plugins.zsh`).
- Refresh completion cache after changing completion config: `rm -f $XDG_CACHE_HOME/zsh/zcompdump && exec zsh`.

## Startup load order

zsh sources files in a fixed order; this is the most important thing to understand before editing.

1. `.zshenv` — sourced for *every* shell (including non-interactive/scripts). Sets XDG dirs, `EDITOR`, `MANPAGER`, `STARSHIP_CONFIG`, and base `PATH`. `ZDOTDIR` itself is **not** set here; it is set in `/etc/zsh/zshenv` (see README) so zsh can find this directory in the first place.
2. `.zprofile` — login shells only. Machine-specific PATH and tooling (Homebrew, Python, Rust/cargo, LLVM, bun, etc.) and one-time login actions (`ssh-add`, `ulimit`). This file is the macOS-local layer and is the right place for host-specific env, not `.zshenv`.
3. `.zshrc` — interactive shells only. The orchestrator: configures history, shell options, completion, and fzf shell integration, then sources the modular files below in order, then initializes nvm.

`.zshrc` sources, in this order: `fzf.zsh`, `aliases.zsh`, `bindings.zsh`, `plugins.zsh`, `prompt.zsh`. Order matters — e.g. `bindings.zsh` references `_fzf_file_no_hidden` which is defined in `fzf.zsh`.

## Module responsibilities

- `aliases.zsh` — aliases and small functions. Note tools are aliased over their coreutils equivalents (`ls`→eza, `cat`→bat, `grep`→rg). The `lf` function is a wrapper that makes the file manager change the shell's cwd on exit.
- `bindings.zsh` — keybindings and zsh-vi-mode cursor/highlight config. **Custom bindings must go inside `zvm_after_init()`**: zsh-vi-mode resets all keybindings on init, so anything bound at top level is silently clobbered.
- `fzf.zsh` — fzf env vars (`FZF_DEFAULT_COMMAND` uses `fd`, preview uses `bat`), the `_fzf_file_no_hidden` ZLE widget bound to Ctrl+F, and the typed-command fzf helpers (`fkill`, `fco`, `fcd`, `frg`). Helpers are run by name rather than bound to keys (the `lf()` pattern), so they sidestep the zsh-vi-mode binding reset. When adding one, avoid the name `fd` (it shadows the fd CLI) and add a `$+functions[...]` assertion to `tests/tier3_behavior.sh`.
- `plugins.zsh` — self-contained plugin manager. `_zplugin_load <github-user> <repo>` clones to `plugins/<repo>` on first run and sources `<repo>.plugin.zsh`. To add a plugin, add another `_zplugin_load` line. The `plugins/` dir is gitignored, so plugins are not vendored — they install on first shell launch.
- `prompt.zsh` — initializes starship; config is `starship.toml` in this repo.

## Conventions

- Code is heavily commented with inline explanations of non-obvious flags and escape codes (e.g. terminal key sequences like `^[[1;5C`). Match this density when editing.
- Cross-platform: fzf integration and dependency install paths branch per OS (macOS Homebrew Intel/ARM, Arch, Ubuntu). Ubuntu renames `bat`→`batcat` and `fd`→`fdfind`, handled via the `MANPAGER` fallback in `.zshenv` and symlinks in the README.
- Files reading from `$ZDOTDIR` assume this repo is cloned to `~/.config/zsh`.

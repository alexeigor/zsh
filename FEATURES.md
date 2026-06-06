# Features

A detailed tour of what this config does and how each piece is wired up. For the
high-level load order and module responsibilities, see [`CLAUDE.md`](./CLAUDE.md);
this document goes deeper on the *why* behind each feature, with `file:line`
references you can jump to.

## Table of contents

- [Prompt: starship](#prompt-starship)
- [Plugins](#plugins)
  - [fast-syntax-highlighting](#fast-syntax-highlighting)
  - [zsh-autosuggestions](#zsh-autosuggestions)
  - [zsh-history-substring-search](#zsh-history-substring-search)
  - [zsh-vi-mode](#zsh-vi-mode)
- [Navigation: zoxide, fzf, fd](#navigation-zoxide-fzf-fd)
- [Lazy-loaded nvm](#lazy-loaded-nvm)
- [Cached compinit](#cached-compinit)
- [Bytecode compilation](#bytecode-compilation)
- [Tests](#tests)
- [Multi-OS CI](#multi-os-ci)

---

## Prompt: starship

**What.** [Starship](https://starship.rs) renders a fast, cross-shell prompt. This
config uses a two-line layout: line one shows `user@host`, the full untruncated
working directory, git branch and a rich git status, plus language version
modules (Node, Rust, Go, PHP, Python); line two is the prompt character (green
on success, red on error, blue in vi command mode).

**Why.** Starship moves prompt logic out of zsh and into a single compiled binary,
which keeps prompt rendering snappy and the same across machines and shells. The
two-line layout keeps the command you type aligned at the left margin regardless
of how deep the current path is.

**How it is wired.**
- `prompt.zsh:8` runs `eval "$(starship init zsh)"` (the last module sourced by
  `.zshrc`, so the prompt is set up after everything else).
- `prompt.zsh` also sets `VIRTUAL_ENV_DISABLE_PROMPT=1` so Python virtualenvs do
  not inject their own prefix and fight starship's `python` module.
- The config itself lives in [`starship.toml`](./starship.toml); `.zshenv:26`
  exports `STARSHIP_CONFIG="$ZDOTDIR/starship.toml"` so starship finds the
  repo-checked-in config rather than `~/.config/starship.toml`.

**Gotcha.** The language and OS modules use Nerd Font glyphs, so the terminal needs
a [Nerd Font](https://www.nerdfonts.com) or those symbols render as tofu.
`tests/tier4_starship.sh` guards against an accidental empty-symbol regression.

## Plugins

All four plugins are managed by the small, dependency-free plugin manager in
[`plugins.zsh`](./plugins.zsh) -- no oh-my-zsh / zinit / antidote. `_zplugin_load
<github-user> <repo>` (`plugins.zsh:7`) clones the repo into `plugins/<repo>` on
first launch (`plugins.zsh:14`), compiles it to bytecode, and sources its
`*.plugin.zsh`. The four `_zplugin_load` lines are `plugins.zsh:37-40`. `plugins/`
is gitignored, so plugins install on first shell launch rather than being vendored.
`zplugin-update` (`plugins.zsh:29`) `git pull --ff-only`s each one.

Set `ZSH_SKIP_PLUGIN_INSTALL=1` to skip cloning entirely (`plugins.zsh:11`) -- this
is how the test suite and CI run without network access.

### fast-syntax-highlighting

**What.** Colorizes the command line as you type: valid commands, paths, strings,
options, and errors each get a distinct color.

**Why.** Immediate visual feedback -- a misspelled command or unclosed quote is
obvious before you press enter. The "fast" implementation is noticeably lighter
than the older `zsh-syntax-highlighting` on long lines.

**How.** `plugins.zsh:40`. It must be sourced after the other plugins so it can wrap
their widgets, which is why it is last in the load list.

### zsh-autosuggestions

**What.** Suggests a completion of the current line in dim text, drawn from history.
Press the right arrow (or `End`) to accept it.

**Why.** Fish-style "type a little, accept a lot" -- the single biggest day-to-day
speedup for repeated commands.

**How.** `plugins.zsh:37`. A binding to toggle suggestions on/off is set at
`bindings.zsh:28` (`Ctrl+\`), handy when recording the screen.

### zsh-history-substring-search

**What.** Type a fragment, then press up/down to walk through only the history
entries containing that fragment.

**Why.** Faster than repeatedly pressing up when you remember a word from a command
but not when you ran it.

**How.** `plugins.zsh:38`. The up/down arrows are bound to its widgets at
`bindings.zsh:31-32`.

### zsh-vi-mode

**What.** Full vi/vim modal editing on the command line (normal/insert/visual
modes, motions, text objects), plus per-mode cursor shapes.

**Why.** Modal editing for anyone who lives in vim; the cursor changes shape so the
current mode is always visible (`bindings.zsh:6-8`: beam in insert, block in
normal/visual).

**How.** `plugins.zsh:39`. **Important caveat:** zsh-vi-mode *resets all keybindings*
when it initializes, so any custom `bindkey` set at top level is silently clobbered.
Every custom binding in this config therefore lives inside the `zvm_after_init()`
hook (`bindings.zsh:17-33`), which runs after the reset. This is the single most
important thing to know before adding a keybinding here.

## Navigation: zoxide, fzf, fd

**What.** A trio that replaces blind `cd` and `find`/`ls` hunting with smart,
fuzzy, and frequency-ranked navigation.

- **zoxide** -- a smarter `cd` that learns your most-used directories. `z foo`
  jumps to the best-matching directory you have visited before.
- **fzf** -- a general-purpose fuzzy finder. Built-in bindings: `Ctrl+R` fuzzy
  history search, `Ctrl+T` fuzzy file insertion.
- **fd** -- a fast, gitignore-aware `find` replacement that feeds fzf its file
  and directory lists.

**Why.** Together they cut the keystrokes for "get to a place / find a thing" to a
few fuzzy characters, and they respect `.gitignore` by default so results are not
buried in `node_modules`.

**How it is wired.**
- zoxide is initialized at `.zshrc:47` (`eval "$(zoxide init zsh)"`).
- fzf shell integration is sourced from whichever path exists for the platform
  (`.zshrc:79-101`: Homebrew ARM/Intel, Arch, Ubuntu).
- [`fzf.zsh`](./fzf.zsh) configures fzf: `FZF_DEFAULT_COMMAND` uses `fd`
  (`fzf.zsh:5`), the UI options (`fzf.zsh:11-18`), and a `bat`-powered preview
  (`fzf.zsh:20-21`).
- `_fzf_file_no_hidden` (`fzf.zsh:24`) is a ZLE widget bound to `Ctrl+F`
  (`bindings.zsh:25`): a file picker that, unlike the built-in `Ctrl+T`, excludes
  hidden files.

**Helper commands.** `fzf.zsh` also defines four typed-command helpers (run by name,
not bound to keys -- the same pattern as the `lf()` wrapper in `aliases.zsh`):

| Command | What it does |
|---------|--------------|
| `fkill [signal]` | Fuzzy-pick one or more processes (`Tab` to multi-select) and signal them (default `TERM`). |
| `fco` | Fuzzy-checkout a git branch (local + remote), most-recently-committed first, with a commit-log preview. |
| `fcd [path]` | Fuzzy-`cd` into a subdirectory, with a one-level `eza` tree preview. |
| `frg <pattern>` | `ripgrep` -> fzf, then open the chosen match in `$EDITOR` at the line. |

Every binary these helpers call (fzf, git, rg, fd, eza, bat) is already a declared
dependency, so they add no new requirements. None is named `fd`, which would shadow
the fd CLI.

## Lazy-loaded nvm

**What.** nvm (Node Version Manager) is loaded on first use instead of at every
shell startup.

**Why.** Sourcing `nvm.sh` on every shell costs hundreds of milliseconds -- a tax
paid even in shells where you never touch Node. Lazy loading removes that from
startup entirely.

**How.** `.zshrc:130-141`. The trick: define lightweight stub functions for `nvm`,
`node`, `npm`, and `npx`. The first time you call any of them, the stub
(`_load_nvm`) removes all four stubs, sources the real `nvm.sh`, and then re-runs
your command against the real binary. After that first call the stubs are gone and
there is zero ongoing overhead.

## Cached compinit

**What.** The zsh completion system (`compinit`) is initialized from a cached dump
file, with the expensive security audit run at most once a day.

**Why.** `compinit` normally audits every directory in `$fpath` for insecure
permissions on every startup, which is slow. Caching the result makes subsequent
startups fast while still re-auditing periodically.

**How.** `.zshrc:60-66`. The dump lives at `$XDG_CACHE_HOME/zsh/zcompdump`. The glob
qualifier `(#qN.mh+24)` matches the file only if it is missing or modified more
than 24 hours ago; in that case the full `compinit` runs, otherwise the fast path
`compinit -C` skips the audit. To force a rebuild after changing completion config:
`rm -f $XDG_CACHE_HOME/zsh/zcompdump && exec zsh`.

## Bytecode compilation

**What.** Plugin files are compiled to zsh word-code (`.zwc`) so zsh can load them
without re-parsing the script text.

**Why.** Parsing shell scripts on every startup is wasted work when the source has
not changed; loading precompiled bytecode is faster.

**How.** `plugins.zsh:22-24`. On load, if the `.zwc` is missing or older than its
source (`"$plugin_file" -nt "${plugin_file}.zwc"`), `zcompile` rebuilds it;
otherwise zsh transparently prefers the existing `.zwc`. The `*.zwc` files are
gitignored (machine-specific build artifacts).

## Tests

**What.** A dependency-free test suite, run with `zsh tests/run.sh`
([`tests/run.sh`](./tests/run.sh)), organized into four tiers:

1. **Tier 1 -- syntax** (`tests/tier1_syntax.sh`): `zsh -n` parse check on every
   config file. Globs the modules, so new `*.zsh` files are covered automatically.
2. **Tier 2 -- smoke** (`tests/tier2_smoke.sh`): starts an interactive shell in a
   throwaway `$HOME`/XDG sandbox, asserts it exits 0, emits no real errors, and does
   not touch the real history file. Skips if `zoxide`/`starship` are absent.
3. **Tier 3 -- behavior** (`tests/tier3_behavior.sh`): asserts the config actually
   *configures* the shell -- aliases resolve, env vars/options are set, functions
   and widgets (including the fzf helpers) are defined, and re-sourcing `.zshrc` is
   idempotent.
4. **Tier 4 -- starship** (`tests/tier4_starship.sh`): checks `starship.toml`
   integrity (non-empty language symbols, `$username`/`$hostname` in the format,
   and that starship can parse and render it).

**Why.** A shell config is easy to break in ways that only show up at the next
launch. The suite catches syntax errors, startup regressions, and silent
misconfiguration before they reach a real shell -- and it runs without installing
anything, so it works in CI containers.

**How.** `tests/lib.sh` provides `pass`/`fail`/`skip`/`assert_eq`/`assert_match`
and the counters. The tiers run in sandboxes built with `env -i` and `mktemp -d`
so they never read or write real history, cache, or config. There is also a
`tests/docker/ubuntu.sh` for exercising Ubuntu's renamed tools (`batcat`/`fdfind`).

## Multi-OS CI

**What.** GitHub Actions runs the test suite across native and containerized
operating systems on every push and pull request.

**Why.** This config branches on OS (Homebrew Intel/ARM, Arch, Ubuntu, and Ubuntu's
renamed binaries), so cross-platform coverage is the only way to know a change does
not break a platform you are not currently sitting at.

**How.** [`.github/workflows/tests.yml`](./.github/workflows/tests.yml) defines
three jobs:
- **ubuntu** (`tests.yml:10-29`): native `ubuntu-22.04` and `ubuntu-24.04` runners.
- **macos** (`tests.yml:34-49`): `macos-latest` (Apple Silicon), exercising the
  macOS fzf/MANPAGER branches; tools installed via Homebrew.
- **container** (`tests.yml:52-77`): `ubuntu:26.04` and `archlinux:latest` via
  Docker, for distros without a hosted runner.

A separate workflow (`.github/workflows/demo.yml`) regenerates the README demo GIF
when the tape or config changes.

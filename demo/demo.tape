# VHS tape: a feature tour of this zsh config. Rendered by demo/record.sh.
# Docs: https://github.com/charmbracelet/vhs

Output demo.gif

Set Shell zsh
Set FontFamily "JetBrainsMono Nerd Font"
Set FontSize 18
Set Width 1200
Set Height 720
Set Padding 18
Set Theme "Catppuccin Mocha"
Set Framerate 60
Set TypingSpeed 55ms

# ---------------------------------------------------------------------------
# Setup (not filmed): a deterministic sample repo, plus seeded history and
# zoxide database so Ctrl+R and `z` have something to find.
# ---------------------------------------------------------------------------
Hide
# VHS starts zsh without our rc files (its own minimal prompt). Re-exec a normal
# interactive zsh so /etc/zsh/zshenv's ZDOTDIR loads this actual config.
Type "exec zsh" Enter
Sleep 1s
Type "git config --global user.email demo@example.com && git config --global user.name Demo && git config --global init.defaultBranch main" Enter
Type "rm -rf ~/demo ~/projects && mkdir -p ~/projects/widget ~/demo && cd ~/demo" Enter
Type "printf 'def add(a, b):\n    return a + b\n\nprint(add(2, 3))\n' > app.py" Enter
Type "printf 'PI = 3.14159\n\ndef area(r):\n    return PI * r * r\n' > utils.py" Enter
Type "printf '# Demo Project\n\nA sample repository used by the VHS demo.\n' > README.md" Enter
Type "git init -q && git add -A && git commit -qm 'init demo project'" Enter
Type "printf '\nprint(area(2))\n' >> app.py" Enter
# Seed zoxide (visit widget) and shell history (for Ctrl+R).
Type "cd ~/projects/widget && cd ~/demo" Enter
Type "eza -la" Enter
Type "cat README.md" Enter
Type "git status -s" Enter
Type "rg add" Enter
Type "clear" Enter
Show

# ---------------------------------------------------------------------------
# 1. Prompt + listings (starship user@host/path/git/py icon, eza, bat)
# ---------------------------------------------------------------------------
Sleep 1.2s
Type "ls" Sleep 500ms Enter
Sleep 1.5s
Type "ll" Sleep 500ms Enter
Sleep 1.5s
Type "tree" Sleep 500ms Enter
Sleep 1.5s
Type "cat app.py" Sleep 500ms Enter
Sleep 2s
# grep is aliased to ripgrep: fast, coloured content search
Type "grep def" Sleep 500ms Enter
Sleep 2s

# ---------------------------------------------------------------------------
# 2. fzf file picker (Ctrl+F) with a bat preview; the pick is inserted inline
# ---------------------------------------------------------------------------
Type "bat "
Sleep 400ms
Ctrl+F
Sleep 1.8s
Type "utils"
Sleep 1.8s
Enter
Sleep 900ms
Enter
Sleep 2s

# ---------------------------------------------------------------------------
# 3. Live git status: stage a change, watch the prompt segment update
# ---------------------------------------------------------------------------
Type "git add app.py" Sleep 500ms Enter
Sleep 1.8s
Type "git restore --staged app.py" Sleep 500ms Enter
Sleep 1.6s

# ---------------------------------------------------------------------------
# 4. Plugins
# ---------------------------------------------------------------------------
# autosuggestions: a gray completion from history; accept with Ctrl+E
Type "git st"
Sleep 1.2s
Ctrl+E
Sleep 800ms
Enter
Sleep 1.5s
# fast-syntax-highlighting: valid command (green) vs typo (red)
Type "eza --git"
Sleep 1.2s
Ctrl+C
Type "ezaa --git"
Sleep 1.2s
Ctrl+C
Sleep 600ms
# history-substring-search: type a prefix then Up
Type "git"
Up
Sleep 1.2s
Ctrl+C
Sleep 600ms

# ---------------------------------------------------------------------------
# 5. Navigation (AUTO_CD, zoxide, lf)
# ---------------------------------------------------------------------------
# AUTO_CD: change directory by typing a path, no `cd` needed
Type ".." Sleep 400ms Enter
Sleep 1.2s
Type "demo" Sleep 400ms Enter
Sleep 1.2s
# zoxide: jump to a frecent directory by keyword
Type "z widget" Sleep 500ms Enter
Sleep 1.5s
Type "z demo" Sleep 500ms Enter
Sleep 1.5s
# lf file manager: open, move, quit (cwd follows on exit)
Type "lf" Enter
Sleep 1.5s
Down 2
Sleep 1.2s
Type "q"
Sleep 1.5s

# ---------------------------------------------------------------------------
# 6. zsh-vi-mode (last: Esc switches the prompt to ❮ and a block cursor)
# ---------------------------------------------------------------------------
Type "echo vi-mode ready"
Sleep 800ms
Escape
Sleep 1.6s
Enter
Sleep 1.2s

Type "clear" Enter
Sleep 800ms

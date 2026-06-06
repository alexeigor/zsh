# =========================================================
# fzf
# =========================================================

export FZF_DEFAULT_COMMAND='fd --type f --hidden --strip-cwd-prefix'  # strip-cwd-prefix removes the leading ./ from results

# Ctrl-T uses fd
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"

# UI
export FZF_DEFAULT_OPTS='
  --height=60%
  --layout=reverse
  --border=rounded
  --prompt="  "
  --pointer="  "
  --preview-window=right:65%:wrap:border-left
'

export _FZF_PREVIEW_CMD='bat --color=always --style=plain,numbers --line-range=:500 {}'
export FZF_CTRL_T_OPTS="--preview '$_FZF_PREVIEW_CMD'"

# Ctrl+F: file picker excluding hidden files
_fzf_file_no_hidden() {
  local cmd result
  cmd="${FZF_DEFAULT_COMMAND/--hidden /}"
  result=$(eval "${cmd:-find . -type f}" | fzf --preview "$_FZF_PREVIEW_CMD") \
    && LBUFFER+="$result"  # LBUFFER is the text left of the cursor
  zle reset-prompt
}
zle -N _fzf_file_no_hidden

# =========================================================
# Interactive helper functions (typed commands, not bindings)
# =========================================================
# These are run by name (like the lf() wrapper in aliases.zsh), not bound to
# keys -- zsh-vi-mode resets keybindings on init, so leaving these as plain
# commands keeps them simple and binding-free. Every tool they call (fzf, git,
# rg, fd, eza, bat) is already a declared dependency. None is named `fd`: the
# upstream fzf "fd" helper would shadow the fd CLI this repo relies on.

# fkill [signal]: fuzzy-select one or more processes and signal them (default TERM).
fkill() {
  local pids
  # -e = every process, -o = custom columns. This column set is portable across
  # macOS and Linux ps. `sed 1d` drops the header row so it can't be selected.
  pids=$(ps -eo pid,user,%cpu,%mem,command | sed 1d \
    | fzf --multi --header='kill: tab to mark, enter to signal' \
    | awk '{print $1}')                       # first column is the PID
  [[ -n "$pids" ]] || return 0                # nothing picked -> no-op
  print -r -- "$pids" | xargs kill "-${1:-TERM}"
}

# fco: fuzzy-checkout a git branch, most-recently-committed first.
fco() {
  git rev-parse --is-inside-work-tree >/dev/null 2>&1 \
    || { print -u2 -- "fco: not inside a git repository"; return 1; }
  local branch
  # Local and remote branches, newest commit first. Strip the leading "origin/"
  # so a remote-only branch shows as a plain name; `awk '!seen[$0]++'` then drops
  # the duplicate when both a local and its remote tracking ref exist. Checking
  # out a remote-only name lets git's DWIM create the tracking branch for you.
  branch=$(git for-each-ref --sort=-committerdate \
             --format='%(refname:short)' refs/heads refs/remotes \
           | sed 's#^origin/##' | awk '!seen[$0]++' \
           | fzf --preview 'git log --oneline --color=always -20 {}' \
                 --header='checkout branch') || return
  [[ -n "$branch" ]] && git checkout "$branch"
}

# fcd [path]: fuzzy-cd into a subdirectory (optionally rooted at the given path).
fcd() {
  local dir
  # --strip-cwd-prefix drops the leading ./; exclude .git so its internals don't
  # flood the list. Preview shows a one-level tree of the highlighted directory.
  dir=$(fd --type d --hidden --strip-cwd-prefix --exclude .git . "$@" 2>/dev/null \
        | fzf --preview 'eza --tree --icons --level=1 --color=always {}') || return
  [[ -n "$dir" ]] && cd -- "$dir"
}

# frg <pattern>: ripgrep -> fzf, then open the chosen match in $EDITOR at the line.
frg() {
  [[ -n "$*" ]] || { print -u2 -- "frg: usage: frg <pattern>"; return 1; }
  local match file line
  # --ansi keeps rg's colors; --delimiter=: splits each line into fields so the
  # preview can address them: {1}=file, {2}=line number. +{2}+3/3 scrolls the bat
  # preview so the matched line sits 3 rows from the top.
  match=$(rg --color=always --line-number --no-heading --smart-case -- "$*" \
          | fzf --ansi --delimiter=: \
                --preview 'bat --color=always --style=numbers --highlight-line {2} {1}' \
                --preview-window='up,60%,border-bottom,+{2}+3/3') || return
  [[ -n "$match" ]] || return 0
  file=${match%%:*}                 # text before the first colon
  line=${${match#*:}%%:*}           # text between the first and second colon
  "${EDITOR:-nvim}" +"$line" -- "$file"
}

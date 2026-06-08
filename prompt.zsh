# ~/.config/zsh/prompt.zsh

# Prevent Python virtualenv from polluting the prompt
export VIRTUAL_ENV_DISABLE_PROMPT=1

FUNCNEST=100

# Guarded so a shell without starship on PATH starts cleanly (falls back to the
# default zsh prompt instead of printing "command not found").
if command -v starship >/dev/null 2>&1; then
  eval "$(starship init zsh)"
fi

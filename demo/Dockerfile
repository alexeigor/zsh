# Demo recording environment: VHS (ttyd/ffmpeg/chromium/Nerd Fonts) plus this
# zsh config and all the tools it uses, so `vhs demo.tape` renders a faithful
# GIF of the real configured shell. Built by demo/record.sh and the demo CI job.
FROM ghcr.io/charmbracelet/vhs

USER root

# Tools available in Debian apt. bat/fd ship as batcat/fdfind here.
RUN apt-get update -qq && apt-get install -y -qq --no-install-recommends \
      zsh git ripgrep bat fd-find fzf zoxide fontconfig curl ca-certificates tar \
    && rm -rf /var/lib/apt/lists/* \
    && ln -sf "$(command -v batcat)" /usr/local/bin/bat \
    && ln -sf "$(command -v fdfind)" /usr/local/bin/fd

# Tools not packaged for Debian: install prebuilt release binaries, arch-aware.
# TARGETARCH is provided automatically by BuildKit (amd64 | arm64).
ARG TARGETARCH
RUN set -eu; \
    case "$TARGETARCH" in \
      amd64) eza=x86_64-unknown-linux-gnu; star=x86_64-unknown-linux-gnu;  lf=amd64 ;; \
      arm64) eza=aarch64-unknown-linux-gnu; star=aarch64-unknown-linux-musl; lf=arm64 ;; \
      *) echo "unsupported TARGETARCH: $TARGETARCH" >&2; exit 1 ;; \
    esac; \
    curl -fsSL "https://github.com/eza-community/eza/releases/latest/download/eza_${eza}.tar.gz" \
      | tar xz -C /usr/local/bin ./eza; \
    curl -fsSL "https://github.com/starship/starship/releases/latest/download/starship-${star}.tar.gz" \
      | tar xz -C /usr/local/bin starship; \
    curl -fsSL "https://github.com/gokcehan/lf/releases/latest/download/lf-linux-${lf}.tar.gz" \
      | tar xz -C /usr/local/bin lf

# Make zsh load this config: ZDOTDIR must be set before zsh starts.
RUN printf '\nexport ZDOTDIR=/home/vhs/.config/zsh\n' >> /etc/zsh/zshenv

# Bring in the config, pre-clone the plugins (so the demo shows no install
# noise), and add the lf icons. Context is the repo root (see .dockerignore).
COPY . /home/vhs/.config/zsh
RUN ZP=/home/vhs/.config/zsh/plugins; mkdir -p "$ZP"; \
    git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions          "$ZP/zsh-autosuggestions"; \
    git clone --depth=1 https://github.com/zsh-users/zsh-history-substring-search "$ZP/zsh-history-substring-search"; \
    git clone --depth=1 https://github.com/jeffreytse/zsh-vi-mode                 "$ZP/zsh-vi-mode"; \
    git clone --depth=1 https://github.com/zdharma-continuum/fast-syntax-highlighting "$ZP/fast-syntax-highlighting"; \
    mkdir -p /home/vhs/.config/lf /home/vhs/.local/state/zsh /home/vhs/.cache/zsh; \
    curl -fsSL https://raw.githubusercontent.com/gokcehan/lf/master/etc/icons.example \
      -o /home/vhs/.config/lf/icons; \
    chown -R vhs:vhs /home/vhs; \
    chown vhs:vhs /vhs

USER vhs

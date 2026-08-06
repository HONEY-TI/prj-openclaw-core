FROM alexfariakof/openclaw-2026.7.1:latest

# ── Bash + dependências ────────────────────────────────────────────────────
RUN apk add --no-cache \
        bash \
        openssl \
    && rm -rf /var/lib/apt/lists/*

# ── eza (ls moderno) ────────────────────────────────────────────────────────
ARG EZA_VERSION=0.23.4
RUN curl -fsSL \
        "https://github.com/eza-community/eza/releases/download/v${EZA_VERSION}/eza_x86_64-unknown-linux-musl.tar.gz" \
        | tar -xzf - -C /usr/local/bin \
    && chmod +x /usr/local/bin/eza

# Cria ambiente Python compartilhado
#RUN python3 -m venv /usr/local/.venv \
#    && /usr/local/.venv/bin/pip install --upgrade pip setuptools \
#    && chown -R node:node /usr/local/.venv

# ── Bash personalizado (global, para qualquer usuário) ──────────────────────
RUN cat >> /etc/bash.bashrc   <<'EOF'
export PATH="/bin:/usr/local/bin:$PATH"

alias py='python3'
alias cls='clear'

export VIRTUAL_ENV=/usr/local/.venv
export PATH="$VIRTUAL_ENV/bin:$PATH"

if [[ $- == *i* ]]; then
    export VIRTUAL_ENV=/usr/local/.venv
    [ -f "$VIRTUAL_ENV/bin/activate" ] && source "$VIRTUAL_ENV/bin/activate"
fi

ls() {
    command eza -la --group --group-directories-first "$@"
}

alias ll='eza -lh --group --icons'
alias la='eza -lah --group'
alias lt='eza --tree --level=2 --group'

parse_git_branch() {
    local branch
    branch=$(git branch --show-current 2>/dev/null)
    [ -n "$branch" ] && printf " (%s)" "$branch"
}

PS1='\[\e[1;34m\]╭─\[\e[1;36m\]\u\[\e[0m\] \[\e[1;32m\]\w\[\e[1;33m\]$(parse_git_branch)\[\e[0m\]\n\[\e[1;34m\]╰─❯ \[\e[0m\]'
EOF

# ── Faz cada usuário carregar o bash.bashrc global ───────────────────────────
# Alpine não faz isso sozinho em shell interativo não-login
RUN for home in /root /home/*; do \
        [ -d "$home" ] && echo '[ -f /etc/bash.bashrc ] && . /etc/bash.bashrc' > "$home/.bashrc"; \
    done

# Cobre também shells não-interativas (docker exec container bash -c "...")
ENV BASH_ENV=/etc/bash.bashrc

COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod 775 /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

COPY docker-tailscaled.sh /usr/local/bin/docker-tailscaled.sh
RUN chmod 775 /usr/local/bin/docker-tailscaled.sh
RUN chmod +x /usr/local/bin/docker-tailscaled.sh \
    && mkdir -p /var/run/tailscale /var/lib/tailscale

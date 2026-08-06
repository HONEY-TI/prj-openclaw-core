FROM alexfariakof/openclaw-base:latest
USER root

# ── Dependências (Alpine usa apk, não apt) ─────────────────────────────────
RUN apk add --no-cache \
        openssh-client \
        shadow \
        sudo \
        ca-certificates 

RUN mkdir -p \
    /home/node/.vscode-server/bin \
    /home/node/.vscode-server/extensions \
    /home/node/.vscode-server/extensionsCache
RUN chown -R node:node /home/node

# ── Firewall ────────────────────────────────────────────────────────────────
COPY init-firewall.sh /usr/local/bin/init-firewall.sh
RUN chmod 755 /usr/local/bin/init-firewall.sh

# ── Entrypoint ─────────────────────────────────────────────────────────────
COPY docker-tailscaled.sh /usr/local/bin/docker-tailscaled.sh
RUN chmod 755 /usr/local/bin/docker-tailscaled.sh

COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod 755 /usr/local/bin/docker-entrypoint.sh

# sudo restrito apenas aos 3 scripts necessários — SEM sudo irrestrito
RUN echo "node ALL=(root) NOPASSWD: /usr/local/bin/init-firewall.sh, /usr/local/bin/docker-tailscaled.sh, /usr/local/bin/docker-entrypoint.sh" \
    > /etc/sudoers.d/node-dev \
    && chmod 0440 /etc/sudoers.d/node-dev

USER node

ARG GITHUB_TOKEN
RUN if [ -n "$GITHUB_TOKEN" ]; then \
      echo "${GITHUB_TOKEN}" | gh auth login --with-token || echo "gh auth falhou, seguindo sem autenticar"; \
    else \
      echo "GITHUB_TOKEN não fornecido, pulando gh auth login"; \
    fi
WORKDIR /workspace

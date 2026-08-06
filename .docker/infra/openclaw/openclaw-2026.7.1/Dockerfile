FROM node:24.18-alpine

# Pacotes necessários
RUN apk add --no-cache \
        curl \
        tar

ARG TAILSCALE_VERSION=1.90.6
RUN ARCH=$(uname -m) \
    && if [ "$ARCH" = "x86_64" ]; then ARCH="amd64"; fi \
    && if [ "$ARCH" = "aarch64" ]; then ARCH="arm64"; fi \
    && curl -fsSL "https://pkgs.tailscale.com/stable/tailscale_${TAILSCALE_VERSION}_${ARCH}.tgz" \
      | tar -xz -C /usr/local/bin --strip-components=1

RUN curl -sL https://github.com/jqlang/jq/releases/latest/download/jq-linux-amd64 -o /usr/local/bin/jq \
    && chmod +x /usr/local/bin/jq

# ── Pacotes globais do npm ──────────────────────────────────────────────────
RUN npm install -g openclaw@2026.7.1

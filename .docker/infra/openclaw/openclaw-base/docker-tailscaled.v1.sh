#!/usr/bin/env bash
set -e

# ==========================
# Cores
# ==========================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # Sem cor

log_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

log_ok() {
    echo -e "${GREEN}✔${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}⚠${NC} $1"
}

log_error() {
    echo -e "${RED}✘${NC} $1"
}

log_step() {
    echo -e "\n${CYAN}════════════════════════════════════════════${NC}"
    echo -e "${CYAN}🚀 $1${NC}"
    echo -e "${CYAN}════════════════════════════════════════════${NC}"
}

# ==========================
# Inicialização
# ==========================

log_step "Iniciando tailscaled"

tailscaled \
    --tun=userspace-networking \
    --socket=/var/run/tailscale/tailscaled.sock \
    --state=/var/lib/tailscale/tailscaled.state &
TAILSCALED_PID=$!

sleep 3

log_ok "tailscaled iniciado (PID: $TAILSCALED_PID)"

log_step "Autenticando no Tailscale"

tailscale --socket=/var/run/tailscale/tailscaled.sock up \
    --authkey="${TAILSCALE_AUTHKEY}" \
    --hostname=openclaw

log_ok "Tailscale conectado"

log_info "Gateway Token:"
echo "🌎 ${OPENCLAW_GATEWAY_TOKEN}"

log_step "Iniciando OpenClaw"
exec openclaw gateway

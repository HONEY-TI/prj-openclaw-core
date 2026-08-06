#!/usr/bin/env bash
#http://localhost:18789/
set -e

#!/bin/bash
# Gera/atualiza ~/.openclaw/openclaw.json automaticamente com os modelos reais do Ollama
# e o provider da OpenRouter (se OPENROUTER_API_KEY estiver definida).
# Preserva gateway.mode, meta e qualquer config existente (merge, não overwrite).
# Não falha o boot se o Ollama estiver indisponível: mantém o config existente.
#
# Requer: curl, jq, openssl
#
# Uso: montar como volume e chamar a partir do entrypoint, ex:
#   /usr/local/bin/generate-openclaw-config.sh

set -euo pipefail

#!/bin/bash
set -e

readonly USER=node

# ── Realinhar UID/GID do node com o dono do /workspace (bind mount do host) ─
# Assim não depende de saber o UID/GID do host antecipadamente nem de rebuild.
HOST_UID=$(stat -c '%u' /workspace)
HOST_GID=$(stat -c '%g' /workspace)
CURRENT_UID=$(id -u "$USER")
CURRENT_GID=$(id -g "$USER")

#echo performance | tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor

echo "[entrypoint] /workspace pertence a UID:GID ${HOST_UID}:${HOST_GID}"
echo "[entrypoint] usuário '$USER' atualmente é UID:GID ${CURRENT_UID}:${CURRENT_GID}"

# -o (non-unique) evita falha caso o UID/GID alvo já esteja em uso por outro
# usuário/grupo do sistema dentro da imagem (ex: colidir com root, UID 0).
if [ "$HOST_GID" != "$CURRENT_GID" ]; then
    echo "[entrypoint] ajustando GID de '$USER' para $HOST_GID"
    groupmod -o -g "$HOST_GID" "$USER"
fi

if [ "$HOST_UID" != "$CURRENT_UID" ]; then
    echo "[entrypoint] ajustando UID de '$USER' para $HOST_UID"
    usermod -o -u "$HOST_UID" "$USER"
fi

# /home/node e o volume nomeado do vscode-server são gerenciados pelo Docker
# (não são arquivos reais do host), então chown -R aqui é seguro.
chown -R "$USER:$USER" /home/$USER

# /workspace é bind mount do host: depois do realinhamento acima o dono já
# deve bater. Evitamos chown -R recursivo nele (mexeria nos arquivos reais
# do projeto no host e pode ser lento em diretórios grandes); só corrigimos
# o ponto de montagem em si, como fallback.
if [ "$(stat -c '%u:%g' /workspace)" != "$HOST_UID:$HOST_GID" ]; then
    chown "$USER:$USER" /workspace
fi


OLLAMA_HOST="ollama"
OLLAMA_PORT="11434"
OLLAMA_BASE_URL="http://${OLLAMA_HOST}:${OLLAMA_PORT}"

OPENCLAW_CONFIG_DIR="/root/.openclaw"
OPENCLAW_CONFIG_FILE="${OPENCLAW_CONFIG_DIR}/openclaw.json"
OPENCLAW_TOKEN_FILE="${OPENCLAW_CONFIG_DIR}/.gateway-token"

echo "[entrypoint] config set gateway.mode local..."
openclaw config set gateway.mode local

mkdir -p "$OPENCLAW_CONFIG_DIR"
chmod 700 "$OPENCLAW_CONFIG_DIR"

if ! command -v jq >/dev/null 2>&1; then
    echo "[openclaw-config] erro: 'jq' não está instalado" >&2
    exit 1
fi

# ── Garante que existe um openclaw.json válido com gateway.mode ────────────
if [ ! -f "$OPENCLAW_CONFIG_FILE" ] || ! jq empty "$OPENCLAW_CONFIG_FILE" 2>/dev/null; then
    echo "[openclaw-config] criando config base (gateway.mode=local)"
    openclaw config set gateway.mode local
fi

if [ -z "$(jq -r '.gateway.mode // empty' "$OPENCLAW_CONFIG_FILE")" ]; then
    echo "[openclaw-config] gateway.mode ausente — corrigindo"
    openclaw config set gateway.mode local
fi

# ── Provider OpenRouter (merge, só se a chave estiver definida) ────────────
if [ -n "${OPENROUTER_API_KEY:-}" ]; then
    echo "[openclaw-config] configurando provider OpenRouter"

    OPENROUTER_PATCH=$(jq -n \
        --arg apiKey "$OPENROUTER_API_KEY" \
        '{
            models: {
                providers: {
                    openrouter: {
                        baseUrl: "https://openrouter.ai/api/v1",
                        apiKey: $apiKey,
                        api: "openai"
                    }
                },
                defaults: {
                    provider: "openrouter"
                },
                entries: {
                    "nvidia/nemotron-3-ultra-550b-a55b:free": {
                        provider: "openrouter"
                    },
                    "nvidia/nemotron-3-super-120b-a12b:free": {
                        provider: "openrouter"
                    },
                    "cohere/north-mini-code:free": {
                        provider: "openrouter"
                    }
                }
            }
        }')

    TMP=$(mktemp)
    if jq -s '.[0] * .[1]' "$OPENCLAW_CONFIG_FILE" <(echo "$OPENROUTER_PATCH") > "$TMP" \
        && jq empty "$TMP" 2>/dev/null; then
        mv "$TMP" "$OPENCLAW_CONFIG_FILE"
        chmod 600 "$OPENCLAW_CONFIG_FILE"
        echo "[openclaw-config] provider OpenRouter configurado"
    else
        echo "[openclaw-config] falha ao aplicar provider OpenRouter — config original preservado" >&2
        rm -f "$TMP"
    fi
else
    echo "[openclaw-config] OPENROUTER_API_KEY não definida — pulando provider OpenRouter"
fi

# ── Modelos do Ollama (merge, sem apagar o resto do config) ────────────────
if TAGS_JSON=$(curl -sf --max-time 3 "${OLLAMA_BASE_URL}/api/tags"); then

    mapfile -t MODEL_IDS < <(echo "$TAGS_JSON" | jq -r '.models[]?.name // empty')

    if [ "${#MODEL_IDS[@]}" -eq 0 ]; then
        echo "[openclaw-config] nenhum modelo encontrado no Ollama, config não alterado"
    else
        PRIMARY_MODEL="${MODEL_IDS[0]}"
        FALLBACK_MODELS=("${MODEL_IDS[@]:1}")

        MODEL_ENTRIES="[]"
        for mid in "${MODEL_IDS[@]}"; do
            MODEL_ENTRIES=$(jq -c \
                --arg mid "$mid" \
                '. + [{
                    id: $mid,
                    name: $mid,
                    reasoning: false,
                    input: ["text"],
                    cost: {input: 0, output: 0, cacheRead: 0, cacheWrite: 0},
                    contextWindow: 65536,
                    maxTokens: 8192
                }]' <<< "$MODEL_ENTRIES")
        done

        FALLBACKS_JSON="[]"
        for m in "${FALLBACK_MODELS[@]}"; do
            FALLBACKS_JSON=$(jq -c --arg m "ollama/$m" '. + [$m]' <<< "$FALLBACKS_JSON")
        done

        PATCH=$(jq -n \
            --arg baseUrl "$OLLAMA_BASE_URL" \
            --arg primary "ollama/${PRIMARY_MODEL}" \
            --argjson models "$MODEL_ENTRIES" \
            --argjson fallbacks "$FALLBACKS_JSON" \
            '{
                models: { providers: { ollama: {
                    baseUrl: $baseUrl, apiKey: "master", api: "ollama", models: $models
                }}},
                agents: { defaults: { model: { primary: $primary, fallbacks: $fallbacks } } }
            }')

        # merge: config atual (com gateway/meta) + patch de models/agents
        TMP=$(mktemp)
        if jq -s '.[0] * .[1]' "$OPENCLAW_CONFIG_FILE" <(echo "$PATCH") > "$TMP" \
            && jq empty "$TMP" 2>/dev/null \
            && [ -n "$(jq -r '.gateway.mode // empty' "$TMP")" ]; then
            mv "$TMP" "$OPENCLAW_CONFIG_FILE"
            chmod 600 "$OPENCLAW_CONFIG_FILE"
            echo "[openclaw-config] gerado com ${#MODEL_IDS[@]} modelo(s): $(IFS=, ; echo "${MODEL_IDS[*]}")"
            echo "[openclaw-config] primary: ollama/${PRIMARY_MODEL}"
        else
            echo "[openclaw-config] merge falhou ou resultado inválido — config original preservado" >&2
            rm -f "$TMP"
        fi
    fi
else
    echo "[openclaw-config] Ollama não respondeu em ${OLLAMA_BASE_URL} — mantendo config existente"
fi

# ── Gateway auth token (persistente entre restarts do container) ──────────
if [ -z "${OPENCLAW_GATEWAY_TOKEN:-}" ]; then
    if [ -f "$OPENCLAW_TOKEN_FILE" ]; then
        OPENCLAW_GATEWAY_TOKEN="$(cat "$OPENCLAW_TOKEN_FILE")"
    else
        OPENCLAW_GATEWAY_TOKEN="$(openssl rand -hex 32)"
        echo "$OPENCLAW_GATEWAY_TOKEN" > "$OPENCLAW_TOKEN_FILE"
        chmod 600 "$OPENCLAW_TOKEN_FILE"
        echo "[openclaw-config] novo token de gateway gerado e salvo em $OPENCLAW_TOKEN_FILE"
    fi
fi
export OPENCLAW_GATEWAY_TOKEN
openclaw config set gateway.auth.mode token
openclaw config set gateway.auth.token "$OPENCLAW_GATEWAY_TOKEN"

# ── Validação final e start do gateway ──────────────────────────────────
openclaw doctor --fix

echo "[openclaw-config] iniciando tailscaled..."
exec "$@"
#exec /usr/local/bin/docker-tailscaled.sh
#exec openclaw gateway
#openclaw gateway

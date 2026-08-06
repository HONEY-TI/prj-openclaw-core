#!/usr/bin/env bash
set -uo pipefail

echo "[entrypoint] Iniciando Ollama..."

# Para o servidor
export OLLAMA_HOST=0.0.0.0:11434

# Para o CLI ollama dentro do container
export OLLAMA_HOST=http://127.0.0.1:11434

MODELS=(
  "qwen2.5-coder:7b"
  "qwen2.5-coder:3b"
)

READY_FILE="/tmp/ollama-models-ready"
rm -f "$READY_FILE"


ollama serve &
SERVER_PID=$!


cleanup() {
    echo "[entrypoint] Encerrando Ollama..."
    kill "$SERVER_PID" 2>/dev/null || true
}

trap cleanup TERM INT


echo "[entrypoint] Aguardando API Ollama..."

SECONDS_WAIT=0

until curl -fs http://127.0.0.1:11434/api/tags >/dev/null 2>&1
do
    sleep 2
    SECONDS_WAIT=$((SECONDS_WAIT+2))

    if [ $((SECONDS_WAIT % 20)) -eq 0 ]; then
        echo "[entrypoint] API ainda não pronta (${SECONDS_WAIT}s)"
    fi
done


echo "[entrypoint] API respondeu."


echo "[entrypoint] Aguardando CLI Ollama..."

until ollama list >/dev/null 2>&1
do
    sleep 2
done


echo "[entrypoint] CLI pronto."


for MODEL in "${MODELS[@]}"
do

    if ollama list | awk 'NR>1 {print $1}' | grep -Fxq "$MODEL"
    then
        echo "[entrypoint] ✔ $MODEL já existe"

    else

        echo "[entrypoint] ⬇ Baixando $MODEL"

        ollama pull "$MODEL"

        if [ $? -eq 0 ]
        then
            echo "[entrypoint] ✔ $MODEL instalado"
        else
            echo "[entrypoint] ✖ Erro baixando $MODEL"
        fi

    fi

done


echo
echo "[entrypoint] Modelos disponíveis:"
ollama list


touch "$READY_FILE"

echo "[entrypoint] ✔ Ollama pronto"


wait "$SERVER_PID"

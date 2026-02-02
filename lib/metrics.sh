#!/bin/bash

# ============================================================================
# AI Dev Superpowers V3 - Metrics Module
# ============================================================================
# Telemetria e observabilidade para agentes e skills.
#
# Uso: source lib/metrics.sh
# ============================================================================

# Registra um evento de métrica
# Uso: metrics_track_event "skill_run" "brainstorming" 120 "success"
metrics_track_event() {
    local type="$1"
    local name="$2"
    local duration="${3:-0}"
    local status="${4:-info}"
    local metadata="${5:-{}}"
    
    local install_path="${CLI_INSTALL_PATH:-.}"
    local metrics_file="$install_path/.aidev/state/metrics.log"
    
    # Garante diretório (assume que lib/file-ops.sh está carregado ou cria manualmente)
    if command -v ensure_dir >/dev/null 2>&1; then
        ensure_dir "$(dirname "$metrics_file")"
    else
        mkdir -p "$(dirname "$metrics_file")"
    fi
    
    # Timestamp ISO-8601
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    # Debug
    # echo "DEBUG METRICS: type=$type name=$name duration=$duration status=$status meta=$metadata" >&2

    # Verifica se duration e valido
    if ! [[ "$duration" =~ ^[0-9]+$ ]]; then duration=0; fi
    # Verifica metadata
    if [[ -z "$metadata" ]]; then metadata="{}"; fi

    # Usa Python para gerar JSON (mais robusto que jq/bash)
    if command -v python3 >/dev/null 2>&1; then
        export MET_TS="$timestamp"
        export MET_TYPE="$type"
        export MET_NAME="$name"
        export MET_DUR="$duration"
        export MET_STATUS="$status"
        export MET_META="$metadata"
        
        python3 -c "import json, os
try:
    meta = json.loads(os.environ.get('MET_META', '{}'))
except:
    meta = {}

entry = {
    'timestamp': os.environ['MET_TS'],
    'type': os.environ['MET_TYPE'],
    'name': os.environ['MET_NAME'],
    'duration': int(os.environ['MET_DUR']),
    'status': os.environ['MET_STATUS'],
    'metadata': meta
}
print(json.dumps(entry, separators=(',', ':')))" >> "$metrics_file"
        
    elif command -v jq >/dev/null 2>&1; then
        # Fallback para jq
        echo "{}" | jq -c \
            --arg ts "$timestamp" \
            --arg type "$type" \
            --arg name "$name" \
            --argjson dur "$duration" \
            --arg status "$status" \
            --argjson meta "$metadata" \
            '.timestamp = $ts | .type = $type | .name = $name | .duration = $dur | .status = $status | .metadata = $meta' \
            >> "$metrics_file"
    else
        # Last resort fallback
        echo "{\"timestamp\": \"$timestamp\", \"type\": \"$type\", \"name\": \"$name\", \"duration\": $duration, \"status\": \"$status\"}" >> "$metrics_file"
    fi
}

# Inicia um timer e retorna o ID (timestamp em ms)
# Uso: timer_id=$(metrics_start_timer "task_123")
metrics_start_timer() {
    if command -v python3 >/dev/null 2>&1; then
        python3 -c 'import time; print(int(time.time()*1000))'
    else
        # Fallback para segundos (multiplicado por 1000 para ser ms)
        echo "$(date +%s)000"
    fi
}

# Para o timer e registra o evento
# Uso: metrics_stop_timer "$timer_id" "skill_run" "brainstorming" "success"
metrics_stop_timer() {
    local start_time="$1"
    local type="$2"
    local name="$3"
    local status="${4:-success}"
    local metadata="${5:-{}}"
    
    local end_time
    if command -v python3 >/dev/null 2>&1; then
        end_time=$(python3 -c 'import time; print(int(time.time()*1000))')
    else
        end_time="$(date +%s)000"
    fi
    
    local duration=0
    
    # Protecao contra IDs invalidos
    if [[ "$start_time" =~ ^[0-9]+$ ]]; then
        duration=$(( end_time - start_time ))
    fi
    
    # Proteção contra relógio ajustado (duração negativa)
    if [ "$duration" -lt 0 ]; then duration=0; fi
    
    metrics_track_event "$type" "$name" "$duration" "$status" "$metadata"
}

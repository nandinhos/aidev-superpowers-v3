#!/bin/bash
# validators.sh - Funções determinísticas de validação
# Todas retornam: 0 (válido) ou 1 (inválido)

# ============================================================================
# VALIDAÇÃO DE PATH SEGURO
# ============================================================================
validate_safe_path() {
    local path="$1"
    local forbidden_paths=("/etc" "/usr" "/var" "/root" "/sys" "/proc" "/bin" "/sbin" "/lib" "/lib64")
    
    # Verifica se path é vazio
    if [ -z "$path" ]; then
        log_validation "ERROR" "validate_safe_path" "Path não pode ser vazio"
        return 1
    fi
    
    # Verifica path raiz
    if [ "$path" = "/" ]; then
        log_validation "ERROR" "validate_safe_path" "Path raiz (/) não permitido"
        return 1
    fi
    
    # Verifica home do root
    if [[ "$path" == "~" ]] || [[ "$path" == "~"/* ]]; then
        log_validation "ERROR" "validate_safe_path" "Home do root não permitido"
        return 1
    fi
    
    # Verifica paths proibidos
    for forbidden in "${forbidden_paths[@]}"; do
        if [[ "$path" == "$forbidden" ]] || [[ "$path" == "$forbidden"/* ]]; then
            log_validation "ERROR" "validate_safe_path" "Path crítico detectado: $forbidden"
            return 1
        fi
    done
    
    return 0
}

# ============================================================================
# VALIDAÇÃO DE FORMATO DE COMMIT
# ============================================================================
validate_commit_format() {
    local msg="$1"
    
    # Regex: tipo(escopo): descrição em português
    # Tipos permitidos: feat, fix, refactor, test, docs, chore
    # Escopo: letras minúsculas, números e hífen
    # Descrição: deve começar com letra minúscula em português
    local pattern="^(feat|fix|refactor|test|docs|chore)\([a-z0-9-]+\):\s+[a-záàâãéêíóôõúç].+$"
    
    if [[ "$msg" =~ $pattern ]]; then
        # Verifica se tem Co-Authored-By (proibido)
        if validate_no_co_authored "$msg"; then
            return 0
        else
            return 1
        fi
    else
        log_validation "ERROR" "validate_commit_format" "Formato inválido: $msg"
        return 1
    fi
}

# ============================================================================
# VALIDAÇÃO DE CO-AUTHORED-BY (PROIBIDO)
# ============================================================================
validate_no_co_authored() {
    local text="$1"
    
    # Verifica variações de Co-Authored-By (case insensitive)
    if echo "$text" | grep -qiE 'Co-Authored-By|Co-authored-by|co-authored-by|coauthored|co-authored'; then
        log_validation "ERROR" "validate_no_co_authored" "Co-Authored-By é proibido em commits"
        return 1
    fi
    
    # Verifica também no corpo estendido (linhas extras)
    if echo "$text" | grep -qiE '^\s*Co-Authored-By:'; then
        log_validation "ERROR" "validate_no_co_authored" "Co-Authored-By detectado no corpo do commit"
        return 1
    fi
    
    return 0
}

# ============================================================================
# VALIDAÇÃO DE EMOJI
# ============================================================================
validate_no_emoji() {
    local text="$1"
    
    # Lista de emojis comuns bloqueados (caracteres específicos)
    local blocked_emojis="✨🔥💯🚀⭐💡⚠️❌✅📝🔍🎯💪👍🙏😀😃😄😁😆😅😂🤣😊😇🙂🙃😉😌😍🥰😘😗😙😚😋😛😝😜🤪🤨🧐🤓😎🥸🤩🥳😏😒😞😔😟😕🙁☹️😣😖😫😩🥺😢😭😤😠😡🤬🤯😳🥵🥶😱😨😰😥😓🤗🤔🤭🤫🤥😶😐😑😬🙄😯😦😧😮😲🥱😴🤤😪😵🤐🥴🤢🤮🤧😷🤒🤕🤑🤠😈👿👹👺🤡💩👻💀☠️👽👾🤖🎃😺😸😹😻😼😽🙀😿😾"
    
    # Verifica se texto contém algum emoji bloqueado
    for (( i=0; i<${#blocked_emojis}; i++ )); do
        local char="${blocked_emojis:$i:1}"
        if [[ "$text" == *"$char"* ]]; then
            log_validation "ERROR" "validate_no_emoji" "Emoji detectado: $char"
            return 1
        fi
    done
    
    # Verifica presença de emojis usando padrão Unicode (multibyte)
    if command -v perl >/dev/null 2>&1; then
        # Usa perl para melhor detecção Unicode
        # Se encontrar emoji, retorna erro (exit 1)
        if perl -CSD -ne 'exit 1 if /[\x{1F300}-\x{1F9FF}\x{2600}-\x{26FF}\x{2700}-\x{27BF}\x{1F100}-\x{1F1FF}\x{1F200}-\x{1F2FF}\x{1F600}-\x{1F64F}\x{1F680}-\x{1F6FF}\x{1F900}-\x{1F9FF}]/' <<< "$text"; then
            : # Não encontrou emoji, continua
        else
            # Encontrou emoji (perl exit 1)
            log_validation "ERROR" "validate_no_emoji" "Emoji Unicode detectado"
            return 1
        fi
    fi
    
    return 0
}

# ============================================================================
# VALIDAÇÃO DE IDIOMA (PORTUGUÊS)
# ============================================================================
validate_portuguese_language() {
    local text="$1"
    
    # Primeira palavra do texto
    local first_word=$(echo "$text" | awk '{print tolower($1)}')
    
    # Palavras comuns em inglês que indicam violação
    local english_words=("add" "fix" "update" "remove" "delete" "create" "implement" 
                        "refactor" "test" "change" "modify" "improve" "optimize"
                        "correct" "repair" "adjust" "edit" "insert" "append")
    
    for word in "${english_words[@]}"; do
        if [ "$first_word" == "$word" ]; then
            log_validation "ERROR" "validate_portuguese_language" "Texto parece estar em inglês: '$word'"
            return 1
        fi
    done
    
    return 0
}

# ============================================================================
# VALIDAÇÃO DE PADRÕES PROIBIDOS
# ============================================================================
validate_no_forbidden_patterns() {
    local content="$1"
    local context="${2:-code}"
    
    # Padrões proibidos em código
    local forbidden_code=("eval(" "innerHTML" "exec(" "system(" "rm -rf /")
    
    # Padrões proibidos em comandos shell
    local forbidden_shell=("rm -rf /" "rm -rf /*" ":(){ :|:& };:" "dd if=/dev/zero of=/dev/sda")
    
    # Verifica padrões proibidos de código
    if [ "$context" == "code" ]; then
        for pattern in "${forbidden_code[@]}"; do
            if echo "$content" | grep -qF "$pattern"; then
                log_validation "CRITICAL" "validate_no_forbidden_patterns" "Padrão proibido em código: $pattern"
                return 1
            fi
        done
    fi
    
    # Verifica padrões proibidos de shell (sempre verificar)
    for pattern in "${forbidden_shell[@]}"; do
        if echo "$content" | grep -qF "$pattern"; then
            log_validation "CRITICAL" "validate_no_forbidden_patterns" "Comando perigoso detectado: $pattern"
            return 1
        fi
    done
    
    return 0
}

# ============================================================================
# VALIDAÇÃO DE EXISTÊNCIA DE TESTE (TDD)
# ============================================================================
validate_test_exists() {
    local file="$1"
    local base_dir="${2:-.}"
    
    # Extrai extensão e nome base
    local ext="${file##*.}"
    local base="${file%.*}"
    local filename=$(basename "$file")
    local base_name="${filename%.*}"
    
    # Array de possíveis arquivos de teste
    local test_files=()
    
    case "$ext" in
        js|ts|jsx|tsx)
            test_files=(
                "${base}.test.${ext}"
                "${base}.spec.${ext}"
                "__tests__/${base_name}.${ext}"
                "tests/${base_name}.test.${ext}"
            )
            ;;
        py)
            test_files=(
                "test_${filename}"
                "${base}_test.py"
                "tests/${base_name}_test.py"
                "tests/test_${base_name}.py"
            )
            ;;
        php)
            test_files=(
                "${base}Test.php"
                "tests/${base}Test.php"
                "test/${base}Test.php"
            )
            ;;
        rb)
            test_files=(
                "${base}_test.rb"
                "test_${base_name}.rb"
                "tests/${base_name}_test.rb"
            )
            ;;
        go)
            test_files=(
                "${base}_test.go"
            )
            ;;
        rs)
            test_files=(
                "tests/${base_name}.rs"
            )
            ;;
        java)
            test_files=(
                "${base}Test.java"
                "tests/${base}Test.java"
            )
            ;;
        *)
            # Padrões genéricos para outras linguagens
            test_files=(
                "${base}.test.${ext}"
                "test_${filename}"
                "tests/${base_name}.test"
            )
            ;;
    esac
    
    # Procura por arquivos de teste nas localizações padrão
    local search_dirs=("$base_dir" "$base_dir/.." "$base_dir/../.." "." "./tests" "./test" "./__tests__")
    
    for test_file in "${test_files[@]}"; do
        for dir in "${search_dirs[@]}"; do
            if [ -f "$dir/$test_file" ]; then
                return 0
            fi
        done
    done
    
    # Verifica se existe diretório de testes com arquivo correspondente
    local test_dirs=("tests" "test" "__tests__" "spec")
    for test_dir in "${test_dirs[@]}"; do
        if [ -d "$base_dir/$test_dir" ]; then
            # Procura por qualquer arquivo que contenha o nome base
            if find "$base_dir/$test_dir" -name "*$base_name*" -type f 2>/dev/null | grep -q .; then
                return 0
            fi
        fi
    done
    
    log_validation "ERROR" "validate_test_exists" "Teste não encontrado para: $file"
    return 1
}

# ============================================================================
# LOGGING
# ============================================================================
log_validation() {
    local level="$1"
    local validator="$2"
    local message="$3"
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    # Determina cor baseado no nível
    local color=""
    case "$level" in
        "CRITICAL") color="\033[0;31m" ;;  # Vermelho
        "ERROR")    color="\033[0;31m" ;;  # Vermelho
        "WARN")     color="\033[1;33m" ;;  # Amarelo
        "INFO")     color="\033[0;34m" ;;  # Azul
        *)          color="\033[0m"    ;;  # Default
    esac
    local reset="\033[0m"
    
    # Log para stderr com cor
    echo -e "${color}[$timestamp] [$level] $validator: $message${reset}" >&2
    
    # Log para arquivo se diretório de logs existir
    if [ -d ".aidev/logs" ]; then
        echo "[$timestamp] [$level] $validator: $message" >> ".aidev/logs/validation.log"
    fi
}

# ============================================================================
# EXPORTAÇÃO (se for sourced)
# ============================================================================
if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
    # Foi sourced - funções disponíveis
    :
else
    # Foi executado diretamente - mostra ajuda
    echo "validators.sh - Funções de validação para AI Dev Superpowers"
    echo ""
    echo "Uso: source validators.sh"
    echo ""
    echo "Funções disponíveis:"
    echo "  validate_safe_path <path>"
    echo "  validate_commit_format <mensagem>"
    echo "  validate_no_emoji <texto>"
    echo "  validate_portuguese_language <texto>"
    echo "  validate_no_forbidden_patterns <codigo> [contexto]"
    echo "  validate_test_exists <arquivo> [diretorio_base]"
    echo ""
    echo "Exemplos:"
    echo '  validate_safe_path "/home/user/projeto" && echo "OK" || echo "FALHOU"'
    echo '  validate_commit_format "feat(auth): adiciona login"'
fi

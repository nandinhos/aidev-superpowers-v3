#!/bin/bash

# ============================================================================
# AI Dev Superpowers V3 - i18n Module
# ============================================================================
# Sistema de internacionalização para o CLI
# ============================================================================

# Variável global para o idioma atual
AIDEV_LANG="${AIDEV_LANG:-pt-BR}"

# Dicionários de tradução (Associative Arrays - Requer Bash 4+)
declare -A TRANSLATIONS_EN
declare -A TRANSLATIONS_PT

# ----------------------------------------------------------------------------
# Traduções em Português
# ----------------------------------------------------------------------------
TRANSLATIONS_PT["welcome"]="Bem-vindo ao AI Dev Superpowers"
TRANSLATIONS_PT["select_lang"]="Selecione seu idioma / Select your language (pt/en): "
TRANSLATIONS_PT["init_success"]="AI Dev Superpowers instalado com sucesso!"
TRANSLATIONS_PT["init_header"]="Inicializando em"
TRANSLATIONS_PT["step_structure"]="Criando estrutura de diretórios..."
TRANSLATIONS_PT["step_agents"]="Instalando agentes..."
TRANSLATIONS_PT["step_skills"]="Instalando skills..."
TRANSLATIONS_PT["step_rules"]="Instalando rules..."
TRANSLATIONS_PT["step_mcp"]="Configurando MCP..."
TRANSLATIONS_PT["step_platform"]="Configurando instruções de plataforma..."
TRANSLATIONS_PT["step_secrets"]="Configurando segredos..."
TRANSLATIONS_PT["step_gitignore"]="Configurando gitignore..."
TRANSLATIONS_PT["error_no_install"]="AI Dev não está instalado neste diretório"
TRANSLATIONS_PT["error_required_arg"]="Argumento obrigatório ausente: "
TRANSLATIONS_PT["error_ops"]="Ops! O comando falhou"
TRANSLATIONS_PT["suggest_doctor"]="Sugestão: Tente rodar 'aidev doctor --fix' para resolver problemas de ambiente."
TRANSLATIONS_PT["fix_recreating_dir"]="Recriando diretório: "
TRANSLATIONS_PT["fix_created"]=" criado"
TRANSLATIONS_PT["fix_restoring_base"]="Tentando reconstruir estrutura base..."
TRANSLATIONS_PT["fix_restored"]="Estrutura recriada."
TRANSLATIONS_PT["fix_protecting_env"]="Protegendo .env no .gitignore..."
TRANSLATIONS_PT["fix_protected_env"]=".env protegido"

# ----------------------------------------------------------------------------
# Traduções em Inglês
# ----------------------------------------------------------------------------
TRANSLATIONS_EN["welcome"]="Welcome to AI Dev Superpowers"
TRANSLATIONS_EN["select_lang"]="Select your language / Selecione seu idioma (en/pt): "
TRANSLATIONS_EN["init_success"]="AI Dev Superpowers successfully installed!"
TRANSLATIONS_EN["init_header"]="Initializing in"
TRANSLATIONS_EN["step_structure"]="Creating directory structure..."
TRANSLATIONS_EN["step_agents"]="Installing agents..."
TRANSLATIONS_EN["step_skills"]="Installing skills..."
TRANSLATIONS_EN["step_rules"]="Installing rules..."
TRANSLATIONS_EN["step_mcp"]="Configuring MCP..."
TRANSLATIONS_EN["step_platform"]="Configuring platform instructions..."
TRANSLATIONS_EN["step_secrets"]="Configuring secrets..."
TRANSLATIONS_EN["step_gitignore"]="Configuring gitignore..."
TRANSLATIONS_EN["error_no_install"]="AI Dev is not installed in this directory"
TRANSLATIONS_EN["error_required_arg"]="Missing required argument: "
TRANSLATIONS_EN["error_ops"]="Ops! Command failed"
TRANSLATIONS_EN["suggest_doctor"]="Suggestion: Try running 'aidev doctor --fix' to resolve environment issues."
TRANSLATIONS_EN["fix_recreating_dir"]="Recreating directory: "
TRANSLATIONS_EN["fix_created"]=" created"
TRANSLATIONS_EN["fix_restoring_base"]="Attempting to rebuild base structure..."
TRANSLATIONS_EN["fix_restored"]="Structure recreated."
TRANSLATIONS_EN["fix_protecting_env"]="Protecting .env in .gitignore..."
TRANSLATIONS_EN["fix_protected_env"]=".env protected"

# Função de tradução
# Uso: t "chave" [base_string_se_nao_encontrar]
t() {
    local key="$1"
    local default="${2:-$key}"
    
    if [[ "$AIDEV_LANG" == "pt-BR" || "$AIDEV_LANG" == "pt" ]]; then
        echo "${TRANSLATIONS_PT[$key]:-$default}"
    else
        echo "${TRANSLATIONS_EN[$key]:-$default}"
    fi
}

# Atalho para tradução (_ "chave")
_() {
    t "$@"
}

# Configura o idioma globalmente
set_language() {
    local lang="$1"
    if [[ "$lang" == "pt" || "$lang" == "pt-BR" ]]; then
        AIDEV_LANG="pt-BR"
    else
        AIDEV_LANG="en"
    fi
}

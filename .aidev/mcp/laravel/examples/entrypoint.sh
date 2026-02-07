#!/bin/sh
# Entrypoint script para container Laravel
# Prepara o ambiente antes de iniciar o serviço principal

set -e

echo "🚀 Iniciando Laravel Container..."

# Verificar se estamos no diretório correto
if [ ! -f "artisan" ]; then
    echo "❌ Erro: artisan não encontrado. Certifique-se de montar o volume corretamente."
    exit 1
fi

# Instalar dependências se vendor não existir
if [ ! -d "vendor" ]; then
    echo "📦 Instalando dependências..."
    composer install --no-interaction --optimize-autoloader
fi

# Criar .env se não existir
if [ ! -f ".env" ]; then
    echo "⚙️  Criando .env..."
    if [ -f ".env.example" ]; then
        cp .env.example .env
        php artisan key:generate
    else
        echo "⚠️  .env.example não encontrado"
    fi
fi

# Limpar caches
php artisan config:clear --quiet 2>/dev/null || true
php artisan cache:clear --quiet 2>/dev/null || true

# Otimizar se em produção
if [ "$APP_ENV" = "production" ]; then
    echo "⚡ Otimizando para produção..."
    php artisan config:cache
    php artisan route:cache
    php artisan view:cache
fi

# Verificar se Laravel Boost está instalado
if grep -q '"laravel/mcp"\|"antigravity/laravel-boost"' composer.json 2>/dev/null; then
    echo "✅ Laravel Boost detectado"
    
    # Publicar config se necessário
    if [ ! -f "config/mcp.php" ]; then
        echo "📄 Publicando configurações MCP..."
        php artisan vendor:publish --tag="mcp-config" --force --quiet 2>/dev/null || true
    fi
else
    echo "ℹ️  Laravel Boost não instalado (será instalado automaticamente pelo aidev-mcp-laravel)"
fi

# Verificar conexão com banco (opcional, não falha se não conseguir)
echo "🔍 Verificando serviços..."
php artisan db:monitor --timeout=5 --quiet 2>/dev/null && echo "✅ Banco de dados conectado" || echo "⚠️  Banco de dados indisponível (pode estar inicializando)"

# Ajustar permissões (se root)
if [ "$(id -u)" = "0" ]; then
    chown -R www-data:www-data storage bootstrap/cache 2>/dev/null || true
    chmod -R 775 storage bootstrap/cache 2>/dev/null || true
fi

echo "✨ Laravel pronto!"
echo ""

# Executar comando passado ou padrão
exec "$@"

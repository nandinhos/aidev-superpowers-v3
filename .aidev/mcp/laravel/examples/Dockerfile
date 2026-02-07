# Dockerfile otimizado para Laravel com suporte a MCP
# Este Dockerfile prepara o ambiente para uso com aidev-mcp-laravel

FROM php:8.2-fpm

# Argumentos
ARG USER_ID=1000
ARG GROUP_ID=1000

# Instalar dependências do sistema
RUN apt-get update && apt-get install -y \
    git \
    curl \
    libpng-dev \
    libonig-dev \
    libxml2-dev \
    zip \
    unzip \
    libzip-dev \
    libpq-dev \
    nodejs \
    npm \
    # Ferramentas úteis para debug
    net-tools \
    iputils-ping \
    procps \
    # jq para scripts MCP
    jq \
    && rm -rf /var/lib/apt/lists/*

# Instalar extensões PHP
RUN docker-php-ext-install \
    pdo_mysql \
    pdo_pgsql \
    mbstring \
    exif \
    pcntl \
    bcmath \
    gd \
    zip \
    xml

# Instalar Redis extension
RUN pecl install redis && docker-php-ext-enable redis

# Instalar Composer
COPY --from=composer:latest /usr/bin/composer /usr/local/bin/composer

# Criar usuário não-root para desenvolvimento
RUN groupadd -g ${GROUP_ID} developer && \
    useradd -u ${USER_ID} -g developer -m developer && \
    usermod -p "*" developer -s /bin/bash

# Configurar diretório de trabalho
WORKDIR /var/www/html

# Copiar composer files primeiro (para cache de layers)
COPY composer.json composer.lock* ./

# Instalar dependências (como root, depois ajustamos permissões)
RUN composer install --no-scripts --no-autoloader --no-dev --optimize-autoloader

# Copiar o resto da aplicação
COPY . .

# Gerar autoloader e executar scripts
RUN composer dump-autoload --optimize

# Configurar permissões
RUN chown -R developer:developer /var/www/html && \
    chmod -R 755 /var/www/html/storage && \
    chmod -R 755 /var/www/html/bootstrap/cache

# Criar diretórios necessários
RUN mkdir -p storage/framework/{sessions,views,cache} \
    storage/logs \
    bootstrap/cache && \
    chown -R developer:developer storage bootstrap/cache

# Script de entrypoint para preparar o ambiente
COPY docker/entrypoint.sh /usr/local/bin/entrypoint
RUN chmod +x /usr/local/bin/entrypoint

# Healthcheck para Docker
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD php artisan --version || exit 1

# Portas expostas
EXPOSE 9000

# Mudar para usuário não-root
USER developer

# Entrypoint
ENTRYPOINT ["entrypoint"]
CMD ["php-fpm"]

# Labels para detecção automática
LABEL aidev.laravel.enabled="true"
LABEL aidev.laravel.php-version="8.2"
LABEL description="Laravel application with MCP support"

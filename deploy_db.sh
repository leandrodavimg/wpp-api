#!/bin/bash
set -e

echo "🚀 Deploying database..."
echo "DATABASE_URL=$DATABASE_URL"

# Configuração default (pode sobrescrever com env)
DB_HOST=${DB_HOST:-postgres_whatsapp}
DB_PORT=${DB_PORT:-5432}
DB_USER=${DB_USER:-postgres}

# Aguarda o banco estar pronto
until pg_isready -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" > /dev/null 2>&1; do
  echo "⏳ Aguardando banco ficar disponível em $DB_HOST:$DB_PORT..."
  sleep 2
done

# Aplica as migrations
echo "📦 Aplicando migrations..."
npx prisma migrate deploy

# Gera o client Prisma
echo "🧬 Gerando Prisma Client..."
npx prisma generate

echo "✅ Banco migrado e client gerado com sucesso."
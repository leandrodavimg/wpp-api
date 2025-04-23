# BASE IMAGE
FROM --platform=$BUILDPLATFORM node:20-bullseye-slim AS base

# BUILDER STAGE
FROM base AS builder

WORKDIR /codechat

# Instalar dependências necessárias para build e runtime
RUN apt-get update && apt-get install -y \
  git \
  ffmpeg \
  postgresql-client

# Copiar e instalar dependências
COPY package*.json ./
RUN npm install --force

# Copiar arquivos necessários para build
COPY tsconfig.json ./
COPY ./src ./src
COPY ./public ./public
COPY ./docs ./docs
COPY ./prisma ./prisma
COPY ./views ./views
COPY .env.dev .env

# Gerar Prisma Client e buildar a aplicação
ENV DATABASE_URL=postgres://postgres:pass@localhost/db_test
RUN npx prisma generate
RUN npm run build

# PRODUCTION STAGE
FROM base AS production

WORKDIR /codechat

# Instalar apenas dependências de runtime (mínimas)
RUN apt-get update && apt-get install -y ffmpeg postgresql-client

# Copiar arquivos da imagem builder
COPY --from=builder /codechat/dist ./dist
COPY --from=builder /codechat/docs ./docs
COPY --from=builder /codechat/prisma ./prisma
COPY --from=builder /codechat/views ./views
COPY --from=builder /codechat/node_modules ./node_modules
COPY --from=builder /codechat/package*.json ./
COPY --from=builder /codechat/.env ./
COPY --from=builder /codechat/public ./public

# Script de deploy do banco
COPY ./deploy_db.sh ./
RUN chmod +x ./deploy_db.sh

# Diretório onde ficam as instâncias conectadas
RUN mkdir instances

ENV DOCKER_ENV=true

# Entrada do container: roda migrations e depois inicia a API
ENTRYPOINT [ "bash", "-c", "./deploy_db.sh && node ./dist/src/main" ]
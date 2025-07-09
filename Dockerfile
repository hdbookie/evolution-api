FROM node:20-alpine AS builder

RUN apk update && \
    apk add --no-cache git ffmpeg wget curl bash openssl python3 make g++

LABEL version="2.3.0" description="Api to control whatsapp features through http requests." 
LABEL maintainer="Davidson Gomes" git="https://github.com/DavidsonGomes"
LABEL contact="contato@evolution-api.com"

WORKDIR /evolution

COPY ./package.json ./tsconfig.json ./

# Set npm config to handle timeouts and retries
RUN npm config set fetch-retries 5 && \
    npm config set fetch-retry-mintimeout 20000 && \
    npm config set fetch-retry-maxtimeout 120000 && \
    npm config set loglevel verbose

# Install dependencies with force to handle peer deps
RUN npm install --force || npm install --legacy-peer-deps

COPY ./src ./src
COPY ./public ./public
COPY ./prisma ./prisma
COPY ./manager ./manager
# Don't copy .env.example to .env - use Railway environment variables
COPY ./runWithProvider.js ./
COPY ./tsup.config.ts ./

COPY ./Docker ./Docker

RUN chmod +x ./Docker/scripts/* && dos2unix ./Docker/scripts/*

# Generate Prisma client during build (doesn't need database connection)
# Use a default provider for build time
ENV DATABASE_PROVIDER=postgresql
RUN npx prisma generate --schema ./prisma/postgresql-schema.prisma

RUN npm run build

FROM node:20-alpine AS final

RUN apk update && \
    apk add tzdata ffmpeg bash openssl

ENV TZ=America/Sao_Paulo

WORKDIR /evolution

COPY --from=builder /evolution/package.json ./package.json

COPY --from=builder /evolution/node_modules ./node_modules
COPY --from=builder /evolution/dist ./dist
COPY --from=builder /evolution/prisma ./prisma
COPY --from=builder /evolution/manager ./manager
COPY --from=builder /evolution/public ./public
# Don't copy .env file
COPY --from=builder /evolution/Docker ./Docker
COPY --from=builder /evolution/runWithProvider.js ./runWithProvider.js
COPY --from=builder /evolution/tsup.config.ts ./tsup.config.ts

ENV DOCKER_ENV=true

EXPOSE 8080

# Debug and run
ENTRYPOINT ["/bin/bash", "-c", "echo '=== Environment Variables ===' && env | grep -E '(DATABASE|WEBHOOK)' | sort && echo '===========================' && . ./Docker/scripts/deploy_database.sh && npm run start:prod" ]
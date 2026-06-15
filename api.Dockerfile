FROM oven/bun:alpine AS base
WORKDIR /app

FROM base AS deps
COPY package.json bun.lock ./
RUN bun install --frozen-lockfile

FROM base AS builder
COPY --from=deps /app/node_modules ./node_modules
COPY . .
RUN bun run db:generate 2>/dev/null || true

FROM base
COPY --from=builder /app .
EXPOSE 3001
CMD ["bun", "src/index.ts"]
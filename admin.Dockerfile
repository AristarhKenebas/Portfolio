FROM oven/bun:alpine AS base
WORKDIR /app

FROM base AS deps
COPY package.json bun.lock ./
RUN bun install --frozen-lockfile

FROM base AS builder
COPY --from=deps /app/node_modules ./node_modules
COPY . .
RUN bun run build

FROM base
COPY --from=builder /app/.output ./.output
EXPOSE 3002
ENV PORT=3002
CMD ["node", ".output/server/index.mjs"]
FROM golang:1.25-bookworm AS go-builder
RUN go install github.com/steipete/wacli/cmd/wacli@latest
RUN go install github.com/steipete/gogcli/cmd/gog@latest

FROM node:22-bookworm

RUN apt-get update && apt-get install -y socat && rm -rf /var/lib/apt/lists/*

# Adds Gmail CLI (gogcli) binary (built from source)
COPY --from=go-builder /go/bin/gog /usr/local/bin/gog

# Adds WhatsApp CLI (built from source)
COPY --from=go-builder /go/bin/wacli /usr/local/bin/wacli

WORKDIR /app
COPY package.json pnpm-lock.yaml pnpm-workspace.yaml .npmrc ./
COPY ui/package.json ./ui/package.json
COPY scripts ./scripts
COPY patches ./patches

RUN corepack enable
RUN pnpm install --frozen-lockfile

COPY . .
RUN pnpm build
RUN pnpm ui:install
RUN pnpm ui:build

ENV NODE_ENV=production

# Security hardening: run as non-root user
# The node:22-bookworm image includes a 'node' user (uid 1000)
USER node

CMD ["node","dist/index.js"]
# Adds WhatsApp CLI (built from source)
FROM golang:1.23-bookworm AS go-builder
RUN go install github.com/steipete/wacli@latest
COPY --from=go-builder /go/bin/wacli /usr/local/bin/wacli

FROM node:22-bookworm

RUN apt-get update && apt-get install -y socat && rm -rf /var/lib/apt/lists/*

# Adds Gmail CLI (gogcli) binary
RUN curl -L https://github.com/steipete/gogcli/releases/download/v0.9.0/gogcli_0.9.0_linux_amd64.tar.gz \
  | tar -xz -C /usr/local/bin && mv /usr/local/bin/gogcli /usr/local/bin/gog && chmod +x /usr/local/bin/gog


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
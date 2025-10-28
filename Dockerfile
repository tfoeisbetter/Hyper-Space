# Multi-stage Dockerfile for the Hyper-Space Node.js app
# Uses Node 20 (matches engines in package.json)

FROM node:20-bullseye-slim AS builder
WORKDIR /app

# Install minimal build tools for native modules at build time
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        build-essential \
        python3 \
        ca-certificates \
        curl \
        git \
    && rm -rf /var/lib/apt/lists/*

# Use Corepack (bundled with Node 20) to activate pnpm (safer than global npm install)
RUN corepack enable \
    && corepack prepare pnpm@9 --activate

# Copy lockfiles and package manifest first for better caching
# Copy package manifest and lockfile for better layer caching
# (pnpm-lock.yaml is present in this repo; if you use a different lockfile name adjust this)
COPY package.json pnpm-lock.yaml ./

# Install production dependencies according to lockfile
RUN pnpm install --frozen-lockfile --prod --reporter=silent

# Copy application source (excluding files from .dockerignore)
COPY . ./

# Final runtime image (smaller surface area)
FROM node:20-bullseye-slim AS runner
WORKDIR /app
ENV NODE_ENV=production

# Copy built app and dependencies from builder
# Use trailing slashes to avoid ambiguous "is a directory" issues on some Docker versions
COPY --from=builder /app/ /app/

# Create a non-root user to run the app
RUN useradd -m -s /bin/bash appuser && chown -R appuser:appuser /app
USER appuser

# The app listens on 6060 by default
EXPOSE 6060

# Start the app
CMD ["node", "index.js"]

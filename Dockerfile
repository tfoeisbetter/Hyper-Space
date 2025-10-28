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

# Install pnpm (repo requests pnpm >=9)
RUN npm install -g pnpm@9

# Copy lockfiles and package manifest first for better caching
COPY package.json pnpm-lock.yaml* ./

# Install production dependencies according to lockfile
RUN pnpm install --frozen-lockfile --prod

# Copy application source
COPY . .

# Final runtime image (smaller surface area)
FROM node:20-bullseye-slim AS runner
WORKDIR /app
ENV NODE_ENV=production

# Copy built app and dependencies from builder
COPY --from=builder /app /app

# Create a non-root user to run the app
RUN useradd -m -s /bin/bash appuser && chown -R appuser:appuser /app
USER appuser

# The app listens on 6060 by default
EXPOSE 6060

# Start the app
CMD ["node", "index.js"]

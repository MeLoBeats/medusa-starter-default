#!/bin/sh
set -e

echo "================================================"
echo "Starting Medusa Backend Service"
echo "================================================"

# ===========================================
# Environment Variables Validation
# ===========================================
if [ -z "$DATABASE_URL" ]; then
    echo "ERROR: DATABASE_URL is not set." >&2
    exit 1
fi

if [ -z "$REDIS_URL" ]; then
    echo "ERROR: REDIS_URL is not set." >&2
    exit 1
fi

# Set defaults for optional variables
MEDUSA_WORKER_MODE="${MEDUSA_WORKER_MODE:-server}"
DISABLE_MEDUSA_ADMIN="${DISABLE_MEDUSA_ADMIN:-false}"

echo "Configuration:"
echo "  - NODE_ENV: ${NODE_ENV}"
echo "  - Worker Mode: ${MEDUSA_WORKER_MODE}"
echo "  - Admin Disabled: ${DISABLE_MEDUSA_ADMIN}"
echo "  - Port: ${PORT}"

# ===========================================
# Wait for dependencies (optional but recommended)
# ===========================================
echo ""
echo "Waiting for database to be ready..."
until nc -z postgres 5432 2>/dev/null; do
    echo "  Waiting for PostgreSQL..."
    sleep 2
done
echo "✓ PostgreSQL is ready"

echo "Waiting for Redis to be ready..."
until nc -z redis 6379 2>/dev/null; do
    echo "  Waiting for Redis..."
    sleep 2
done
echo "✓ Redis is ready"

# ===========================================
# Database Migrations & Links Sync
# ===========================================
echo ""
echo "Running database migrations..."
npx medusa db:migrate

echo "Syncing database links..."
npx medusa db:sync-links

# ===========================================
# Start Medusa Application
# ===========================================
echo ""
echo "================================================"
echo "Starting Medusa in ${MEDUSA_WORKER_MODE} mode..."
echo "================================================"

# Check where the built files are
if [ -d "/app/.medusa/server" ]; then
    echo "Using .medusa/server directory"
    cd /app/.medusa/server
elif [ -d "/app/dist" ]; then
    echo "Using dist directory"
    cd /app/dist
else
    echo "Starting from /app root directory"
    cd /app
fi

# Start the application
exec npm run start
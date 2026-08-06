#!/usr/bin/env bash

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly ENV_FILE="$SCRIPT_DIR/.env.development"

if [[ ! -f "$ENV_FILE" ]]; then
    echo "Environment file not found: $ENV_FILE" >&2
    exit 1
fi

cd "$SCRIPT_DIR"

echo "Loading environment from .env.development..."
set -a
# shellcheck source=/dev/null
source "$ENV_FILE"
set +a

# "db" is the Docker Compose service name and is not resolvable by processes
# running directly on the host. The database port is published on localhost.
if [[ "${POSTGRES_HOST:-}" == "db" ]]; then
    export POSTGRES_HOST="localhost"
    echo "Using localhost for the local PostgreSQL connection..."
fi

echo "Applying database migrations..."
uv run alembic upgrade head

echo "Starting FastAPI at http://127.0.0.1:8000 (press Ctrl+C to stop)..."
exec uv run uvicorn app.main:app --reload --host 127.0.0.1 --port 8000

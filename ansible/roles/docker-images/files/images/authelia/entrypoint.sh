#!/bin/sh
set -eu # fail on error

CONFIG="/config/configuration.yml"
MARKER="/config/.authelia-configured"

# Wait until the database port is reachable.
until nc -z db 5432 >/dev/null 2>&1; do
  echo "Waiting for Postgres at db:5432..."
  sleep 2
done

# Run one-time schema initialization.
if [ ! -f "$MARKER" ]; then
  echo "Initialize Authelia database schema"
  authelia storage migrate up -c "$CONFIG"
  # Marker file makes first-run initialization idempotent.
  touch "$MARKER"
fi

# Hand over to the original entrypoint.
exec /app/entrypoint.sh "$@"

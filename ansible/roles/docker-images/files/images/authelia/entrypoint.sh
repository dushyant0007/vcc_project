#!/bin/sh
set -eu # fail on error

CONFIG="/config/configuration.yml"
MARKER="/config/.authelia-configured"

# TODO wait until database is alive
# Authelia image comes with netcat (nc) installed and apt is not available
until nc -z db 5432 >/dev/null 2>&1; do
  echo "Waiting for Postgres at db:5432..."
  sleep 2
done

# TODO: check if Authelia has been configured before
if [ ! -f "$MARKER" ]; then
  echo "Initialize Authelia database schema"
  authelia storage migrate up -c "$CONFIG"
# TODO: mark Authelia as configured
  # Marker file makes first-run initialization idempotent.
  touch "$MARKER"
fi

# TODO: Execute the original entrypoint
exec /app/entrypoint.sh "$@"

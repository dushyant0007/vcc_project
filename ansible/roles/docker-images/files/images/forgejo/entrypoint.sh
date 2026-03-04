#!/bin/sh
set -eu # fail on error

# Make forgejo trust our TLS certificate
update-ca-certificates

# This helper runs Forgejo admin commands with the service config.
forgejo_cli() { sudo -u git forgejo --config /data/gitea/conf/app.ini "$@"; }

# Wait until the database is ready to accept queries.
until PGPASSWORD="${POSTGRES_PASSWORD}" \
  psql -h "${POSTGRES_HOST}" -p "${POSTGRES_PORT}" -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" -c 'SELECT 1;' >/dev/null 2>&1; do
  echo "Waiting for Postgres at ${POSTGRES_HOST}:${POSTGRES_PORT}..."
  sleep 2
done

# Initialize persistent Forgejo directories on first run.
if [ ! -f /data/gitea/conf/app.ini ]; then
  echo "First run detected"
  mkdir -p /data/gitea
  mkdir -p /data/queues
  mkdir -p /data/gitea/conf
  cp /conf/app.ini /data/gitea/conf/app.ini
  # Fix permission for data directory
  chown -R git:git /data/gitea
  chown -R git:git /data/queues
fi

# DB migration
echo "Initialize forgejo database"
forgejo_cli migrate

# Create the admin user if it does not exist.
if ! forgejo_cli admin user list | grep -qE "\\b${FORGEJO_ADMIN_USERNAME}\\b"; then
  forgejo_cli admin user create \
    --admin \
    --username "${FORGEJO_ADMIN_USERNAME}" \
    --password "${FORGEJO_ADMIN_PASSWORD}" \
    --email "${FORGEJO_ADMIN_EMAIL}" \
    --must-change-password=false
fi

# Wait until the OIDC provider is healthy.
until curl -kfsS "${FORGEJO_OIDC_URL}/api/health" >/dev/null 2>&1; do
  echo "Waiting for Authelia at ${FORGEJO_OIDC_URL}..."
  sleep 2
done

# Create the OIDC auth source if missing.
if ! forgejo_cli admin auth list | grep -q "Authelia OIDC"; then
  forgejo_cli admin auth add-oauth \
    --name "Authelia OIDC" \
    --provider openidConnect \
    --key "${FORGEJO_OIDC_CLIENT_ID}" \
    --secret "${FORGEJO_OIDC_CLIENT_SECRET}" \
    --auto-discover-url "${FORGEJO_OIDC_URL}/.well-known/openid-configuration"
fi

# Hand over to the original entrypoint.
exec /usr/bin/entrypoint "$@"

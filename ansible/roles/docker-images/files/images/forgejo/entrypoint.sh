#!/bin/sh
set -eu # fail on error

# Make forgejo trust our TLS certificate
update-ca-certificates

# This helper allows to run stuff as the forgejo user
# TODO: looks like it's missing the `sudo` executable
forgejo_cli() { sudo -u git forgejo --config /data/gitea/conf/app.ini "$@"; }

# TODO wait until database is alive
#  - port alive                         (bad)
#  - a mock query like 'SELECT 1' works (better)
until PGPASSWORD="${POSTGRES_PASSWORD}" \
  psql -h "${POSTGRES_HOST}" -p "${POSTGRES_PORT}" -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" -c 'SELECT 1;' >/dev/null 2>&1; do
  echo "Waiting for Postgres at ${POSTGRES_HOST}:${POSTGRES_PORT}..."
  sleep 2
done

# TODO: check if it's the first run (see if /data/gitea/conf/app.ini exists)
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

# TODO create admin user (if it does not exists already)
# use `forgejo_cli admin user list` and `forgejo_cli admin user create`
if ! forgejo_cli admin user list | grep -qE "\\b${FORGEJO_ADMIN_USERNAME}\\b"; then
  forgejo_cli admin user create \
    --admin \
    --username "${FORGEJO_ADMIN_USERNAME}" \
    --password "${FORGEJO_ADMIN_PASSWORD}" \
    --email "${FORGEJO_ADMIN_EMAIL}" \
    --must-change-password=false
fi

# TODO wait until authentication server is alive
#  - port alive                         (bad)
#  - check that the web server responds (better)
#    Authelia exposes /api/health to check status
#    For example: curl -kfsS https://auth.vcc.local/api/health returns {"status":"OK"}
until curl -kfsS "${FORGEJO_OIDC_URL}/api/health" >/dev/null 2>&1; do
  echo "Waiting for Authelia at ${FORGEJO_OIDC_URL}..."
  sleep 2
done

# TODO setup authentication (if it does not exist)
# use `forgejo_cli admin auth list` and `forgejo_cli admin auth add-oauth`
#   --auto-discover-url is `https://auth.{{domain_name}}/.well-known/openid-configuration`
#   --provider is openidConnect
if ! forgejo_cli admin auth list | grep -q "Authelia OIDC"; then
  forgejo_cli admin auth add-oauth \
    --name "Authelia OIDC" \
    --provider openidConnect \
    --key "${FORGEJO_OIDC_CLIENT_ID}" \
    --secret "${FORGEJO_OIDC_CLIENT_SECRET}" \
    --auto-discover-url "${FORGEJO_OIDC_URL}/.well-known/openid-configuration"
fi

# TODO: Execute the original entrypoint
exec /usr/bin/entrypoint "$@"

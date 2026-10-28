#!/usr/bin/env bash
# Installs the agrekom code (modules, MageSuite, themes) on top of a Magento 2.4.9 install in MAGENTO_SRC.
# Run after ./install.sh and, optionally, ./scripts/import-production-db.sh. Safe to re-run.
set -euo pipefail
cd "$(dirname "$0")/.."
source .env
SRC=$(cd "${MAGENTO_SRC:-./src}" && pwd)
m() { docker compose exec -T php bin/magento "$@"; }

[ -f "$SRC/app/etc/env.php" ] || { echo "No Magento install in $SRC - run ./install.sh first." >&2; exit 1; }

echo "== composer: agrekom 2.x packages (git clones in vendor/)"
cp migration/composer.json migration/composer.lock "$SRC/"
docker compose up -d --build php
docker compose exec -T -u root php chown -R www-data:www-data /var/www/.composer/cache
docker compose exec -T php composer install --no-interaction

echo "== themes"
./scripts/build-themes.sh

echo "== Magento"
m setup:upgrade
m config:set --lock-env smile_elasticsuite_core_base_settings/es_client/servers opensearch:9200
m config:set catalog/search/engine elasticsuite
m config:set system/full_page_cache/caching_application 1
# Themes registered while app/design was still empty are stored as "virtual" and Magento ignores their files
docker compose exec -T db mysql -uroot -p"$MYSQL_ROOT_PASSWORD" "$MYSQL_DATABASE" \
  -e "UPDATE theme SET type = 0 WHERE theme_path LIKE 'Creativestyle/%'" 2>/dev/null
m setup:di:compile
m indexer:reindex
m cache:flush

if ! docker compose exec -T db mysql -uroot -p"$MYSQL_ROOT_PASSWORD" "$MYSQL_DATABASE" -N \
     -e "SELECT 1 FROM admin_user WHERE username = 'localadmin'" 2>/dev/null | grep -q 1; then
  m admin:user:create --admin-user=localadmin --admin-password='Admin123!' \
    --admin-email=localadmin@example.com --admin-firstname=Local --admin-lastname=Admin
fi

echo "== git: put agrekom clones on their 2.x branch"
docker compose exec -T php bash -c 'for d in vendor/agrekom/* vendor/e-warsztat/* vendor/creativestyle/theme-agrekom vendor/creativestyle/theme-ewarsztat; do
  git -C "$d" checkout -q 2.x 2>/dev/null && echo "$d: 2.x" || echo "$d: kept $(git -C "$d" describe --tags --always)"; done' 2>&1 | grep -v "yarn in PATH\|Skipping"

cat <<EOM

PL:        http://localhost:${HTTP_PORT}/
DE:        http://de.localhost:${HTTP_PORT}/
UK:        http://uk.localhost:${HTTP_PORT}/
ewarsztat: http://ewarsztat.localhost:${HTTP_PORT}/   (production DB only)
Admin:     http://localhost:${HTTP_PORT}/admin  (localadmin / Admin123!)
EOM

#!/usr/bin/env bash
# Installs the agrekom code (modules, MageSuite, themes) on top of a Magento 2.4.9 install in MAGENTO_SRC.
# Run after ./install.sh and, optionally, ./scripts/import-production-db.sh. Safe to re-run.
set -euo pipefail
cd "$(dirname "$0")/.."
source .env
SRC=$(cd "${MAGENTO_SRC:-./src}" && pwd)
m() { docker compose exec -T php bin/magento "$@"; }
# Composer files, Adobe patches: shared with the production build in the DevOps repo (submodule ./agrekom)
B=agrekom/magento/before_build
[ -f "$B/composer.json" ] || { echo "Submodule agrekom is missing - run: git submodule update --init" >&2; exit 1; }

[ -f "$SRC/app/etc/env.php" ] || { echo "No Magento install in $SRC - run ./install.sh first." >&2; exit 1; }

echo "== composer: agrekom 2.x packages (git clones in vendor/)"
cp "$B/composer.json" "$B/composer.lock" "$B/patches.json" "$B/patches.lock.json" "$SRC/"
rm -rf "$SRC/patches" && cp -R "$B/patches" "$SRC/"
docker compose up -d --build php
docker compose exec -T -u root php chown -R www-data:www-data /var/www/.composer/cache
docker compose exec -T php composer install --no-interaction

# cweagans/composer-patches only patches packages when it installs them. If the patch set changed since the
# last run, reinstall the patched packages so the new patches are applied.
applied="$SRC/vendor/composer/agrekom-patches.lock.json"
if ! cmp -s "$B/patches.lock.json" "$applied"; then
  echo "== composer: (re)applying Adobe security patches"
  docker compose exec -T php composer patches-repatch --no-interaction
  cp "$B/patches.lock.json" "$applied"
fi

echo "== themes"
./scripts/build-themes.sh

echo "== Magento"
./scripts/disable-modules.sh   # agrekom/dev/disabled-modules.txt
m setup:upgrade
# Attributes of extensions that are not installed (Facebook, Amasty, Plumrocket) break e.g. the admin product page
mkdir -p backups
docker compose exec -T php php < scripts/fix-missing-attribute-models.php >> backups/attribute-models-restore.sql
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

echo "== git: put agrekom clones on their 2.x branch (only if 2.x contains the version from composer.lock)"
docker compose exec -T php bash -c 'for d in vendor/agrekom/* vendor/e-warsztat/* vendor/creativestyle/theme-agrekom vendor/creativestyle/theme-ewarsztat; do
  git -C "$d" fetch -q origin 2>/dev/null
  if git -C "$d" merge-base --is-ancestor HEAD origin/2.x 2>/dev/null; then
    git -C "$d" checkout -q 2.x && git -C "$d" merge -q --ff-only origin/2.x && echo "$d: 2.x"
  else
    echo "$d: kept $(git -C "$d" describe --tags --always) - origin/2.x does not contain it"
  fi
done' 2>&1 | grep -v "yarn in PATH\|Skipping"
docker compose up -d nginx

cat <<EOM

PL:        http://localhost:${HTTP_PORT}/
DE:        http://de.localhost:${HTTP_PORT}/
UK:        http://uk.localhost:${HTTP_PORT}/
ewarsztat: http://ewarsztat.localhost:${HTTP_PORT}/   (production DB only)
Admin:     http://localhost:${HTTP_PORT}/admin  (localadmin / Admin123!)
EOM

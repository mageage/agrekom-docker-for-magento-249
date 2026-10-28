#!/usr/bin/env bash
# Imports a production dump (MariaDB 10.6 mysqldump) into the MySQL 8.4 container and makes it usable locally.
# Usage: ./scripts/import-production-db.sh /path/to/agrekom_sklep01.sql [database]
# WARNING: drops and recreates the target database (default: MYSQL_DATABASE from .env).
set -euo pipefail
cd "$(dirname "$0")/.."
source .env

DUMP=${1:?Usage: $0 /path/to/dump.sql [database]}
DB=${2:-$MYSQL_DATABASE}
PORT=${HTTP_PORT:-8080}
sql() { docker compose exec -T db mysql -uroot -p"$MYSQL_ROOT_PASSWORD" "$@" 2>&1 | grep -v "Using a password" || true; }

echo "Recreating database '$DB'..."
sql -e "DROP DATABASE IF EXISTS \`$DB\`; CREATE DATABASE \`$DB\` CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci; GRANT ALL ON \`$DB\`.* TO '$MYSQL_USER'@'%';"

echo "Importing $DUMP..."
# - line 1 of MariaDB dumps ("enable the sandbox mode") breaks the MySQL client
# - DEFINER=`agrekom_sklep`@`localhost` (triggers, view, procedures) does not exist locally
sed -e '1{/enable the sandbox mode/d;}' -e 's/DEFINER=`[^`]*`@`[^`]*`//g' "$DUMP" \
  | docker compose exec -T db mysql -uroot -p"$MYSQL_ROOT_PASSWORD" "$DB" 2>&1 | grep -v "Using a password" || true

echo "Pointing production URLs and services to the local stack..."
sql "$DB" <<SQL
UPDATE core_config_data SET value = REPLACE(REPLACE(REPLACE(REPLACE(value,
  'https://www.agrekom.pl/',   'http://localhost:$PORT/'),
  'https://www.agrekom.de/',   'http://de.localhost:$PORT/'),
  'https://www.agrekom.co.uk/','http://uk.localhost:$PORT/'),
  'https://www.ewarsztat.pl/', 'http://ewarsztat.localhost:$PORT/')
WHERE path LIKE 'web/%';
UPDATE core_config_data SET value = '0'
WHERE path IN ('web/secure/use_in_frontend', 'web/secure/use_in_adminhtml', 'web/secure/enable_hsts', 'web/secure/enable_upgrade_insecure');
DELETE FROM core_config_data
WHERE path IN ('web/cookie/cookie_domain', 'admin/url/use_custom', 'admin/url/custom', 'admin/url/use_custom_path', 'admin/url/custom_path');

-- all mail goes to Mailpit, never to real customers
DELETE FROM core_config_data WHERE path LIKE 'system/smtp/%';
INSERT INTO core_config_data (scope, scope_id, path, value) VALUES
  ('default', 0, 'system/smtp/disable', '0'),
  ('default', 0, 'system/smtp/transport', 'smtp'),
  ('default', 0, 'system/smtp/host', 'mailpit'),
  ('default', 0, 'system/smtp/port', '1025');
UPDATE core_config_data SET value = '0' WHERE path = 'smtp/general/enabled';

-- no tracking from the local copy: test orders and page views must not reach the real GA / Google Ads / Meta accounts
UPDATE core_config_data SET value = '0'
WHERE path IN ('google/analytics/active', 'google/adwords/active', 'google/send_order_to_google_analytics/active', 'facebook/catalog_management/catalog_sync')
   OR (path LIKE 'googletagmanager/%' AND path LIKE '%/active');
UPDATE core_config_data SET value = '<!-- tracking scripts removed in local environment -->'
WHERE path = 'design/head/includes' AND (value LIKE '%gtag%' OR value LIKE '%fbq%' OR value LIKE '%googletagmanager.com%');
DELETE FROM core_config_data WHERE path LIKE 'apptrian_facebookpixel/%';

-- no CAPTCHA on customer registration (local test registrations); other forms keep theirs
UPDATE core_config_data SET value = TRIM(BOTH ',' FROM REPLACE(CONCAT(',', value, ','), ',user_create,', ','))
WHERE path = 'customer/captcha/forms';

-- built-in full page cache instead of production Varnish
DELETE FROM core_config_data WHERE path = 'system/full_page_cache/caching_application';
INSERT INTO core_config_data (scope, scope_id, path, value) VALUES ('default', 0, 'system/full_page_cache/caching_application', '1');

SELECT scope, scope_id, value AS base_url FROM core_config_data WHERE path = 'web/unsecure/base_url' ORDER BY scope_id;
SQL

echo "Rewriting production URLs in content..."
./scripts/rewrite-production-urls.sh "$DB"

echo "Done. Next: ./scripts/setup-agrekom.sh (or bin/magento setup:upgrade if the agrekom code is already installed)."

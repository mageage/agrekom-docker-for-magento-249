#!/usr/bin/env bash
# Rewrites production shop URLs in content (CMS, Content Constructor, descriptions, checkout terms, config) to the local
# hosts, so links and images on the local copy never lead to the live shops.
# Handles http/https, with/without www, and JSON-escaped slashes (https:\/\/www.agrekom.pl in Content Constructor).
# Mail addresses (biuro@agrekom.pl) are not touched. Run by import-production-db.sh; safe to re-run.
# Usage: ./scripts/rewrite-production-urls.sh [database]
set -euo pipefail
cd "$(dirname "$0")/.."
source .env
DB=${1:-$MYSQL_DATABASE}
PORT=${HTTP_PORT:-8080}

# production domain -> local host (www variants first)
MAP="www.agrekom.pl:localhost agrekom.pl:localhost
www.agrekom.de:de.localhost agrekom.de:de.localhost
www.agrekom.co.uk:uk.localhost agrekom.co.uk:uk.localhost
www.ewarsztat.pl:ewarsztat.localhost ewarsztat.pl:ewarsztat.localhost"

# table.column holding content shown to visitors (logs are left alone)
COLUMNS="cms_page.content cms_page.content_constructor_content
cms_block.content cms_block.content_constructor_content
catalog_product_entity_text.value catalog_product_entity_varchar.value
catalog_category_entity_text.value catalog_category_entity_varchar.value
checkout_agreement.content checkout_agreement.checkbox_text
brands_entity_varchar.value brands_entity_text.value
core_config_data.value"

replace_chain() {
  local expr="\`$1\`" from host
  for scheme in https http; do
    for pair in $MAP; do
      from=${pair%%:*}; host=${pair#*:}
      expr="REPLACE($expr, '$scheme://$from', 'http://$host:$PORT')"
      # JSON-escaped form: https:\/\/www.agrekom.pl  ->  http:\/\/localhost:8080
      expr="REPLACE($expr, CONCAT('$scheme:', CHAR(92), '/', CHAR(92), '/$from'), CONCAT('http:', CHAR(92), '/', CHAR(92), '/$host:$PORT'))"
    done
  done
  # Content Constructor links without scheme: "href":"www.agrekom.pl"
  for pair in $MAP; do
    from=${pair%%:*}; host=${pair#*:}
    expr="REPLACE($expr, '\"href\":\"$from', CONCAT('\"href\":\"http:', CHAR(92), '/', CHAR(92), '/$host:$PORT'))"
  done
  echo "$expr"
}

sql() { docker compose exec -T db mysql -uroot -p"$MYSQL_ROOT_PASSWORD" -N "$DB" "$@" 2>&1 | grep -v "Using a password" || true; }

for tc in $COLUMNS; do
  table=${tc%%.*}; column=${tc#*.}
  exists=$(sql -e "SELECT COUNT(*) FROM information_schema.columns WHERE table_schema = DATABASE() AND table_name = '$table' AND column_name = '$column'")
  [ "$exists" = 1 ] || continue
  changed=$(sql -e "UPDATE \`$table\` SET \`$column\` = $(replace_chain "$column")
    WHERE \`$column\` REGEXP '(agrekom[.](pl|de|co[.]uk)|ewarsztat[.]pl)'; SELECT ROW_COUNT();")
  [ "${changed:-0}" = 0 ] || echo "  $table.$column: $changed row(s)"
done
PROD='(https?:(.?/){2}|"href":")(www[.])?(agrekom[.](pl|de|co[.]uk)|ewarsztat[.]pl)'
left=$(sql -e "SELECT (SELECT COUNT(*) FROM cms_page WHERE CONCAT_WS(' ', content, content_constructor_content) REGEXP '$PROD')
  + (SELECT COUNT(*) FROM cms_block WHERE CONCAT_WS(' ', content, content_constructor_content) REGEXP '$PROD')")
echo "Production URLs rewritten to *.localhost:$PORT (CMS pages/blocks still linking to production: $left)."

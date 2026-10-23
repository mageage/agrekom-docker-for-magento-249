#!/usr/bin/env bash
# Per-website config for PL (default scope), UK and DE
set -euo pipefail
cd "$(dirname "$0")/.."
source .env
m() { docker compose exec -T php bin/magento "$@"; }
web() { m config:set --scope=websites --scope-code="$1" "$2" "$3"; }
store() { m config:set --scope=stores --scope-code="$1" "$2" "$3"; }

m config:set catalog/price/scope 1
m config:set general/locale/weight_unit kgs
m config:set general/country/default PL
m config:set general/store_information/name "Agrekom PL"

for site in "uk uk_en GB GBP en_GB Europe/London" "de de_de DE EUR de_DE Europe/Berlin"; do
  read -r code view country currency locale tz <<<"$site"
  web "$code" web/unsecure/base_url "http://$code.localhost:${HTTP_PORT}/"
  web "$code" web/secure/base_url "http://$code.localhost:${HTTP_PORT}/"
  web "$code" general/country/default "$country"
  web "$code" general/store_information/name "Agrekom $(echo "$code" | tr a-z A-Z)"
  web "$code" currency/options/base "$currency"
  # allow both first: Magento validates default ∈ allowed in both directions
  web "$code" currency/options/allow "PLN,$currency"
  web "$code" currency/options/default "$currency"
  web "$code" currency/options/allow "$currency"
  web "$code" general/locale/timezone "$tz"
  store "$view" general/locale/code "$locale"
done
m cache:flush

#!/usr/bin/env bash
# Disables the modules listed in migration/disabled-modules.txt (skips modules that are not installed).
# Run setup:upgrade afterwards - install.sh and scripts/setup-agrekom.sh do this for you.
set -euo pipefail
cd "$(dirname "$0")/.."

wanted=$(grep -vE '^\s*(#|$)' migration/disabled-modules.txt | tr -d ' \r')
installed=$(docker compose exec -T php bin/magento module:status 2>/dev/null | grep -E '^[A-Za-z0-9]+_[A-Za-z0-9]+$' || true)
modules=$(comm -12 <(echo "$wanted" | sort) <(echo "$installed" | sort) | tr '\n' ' ')

if [ -z "${modules// /}" ]; then
  echo "Nothing to disable - none of the listed modules is installed."
  exit 0
fi
# Modules not registered in config.php yet are listed as disabled; disabling them writes 0 so setup:upgrade keeps them off.
# One call, so modules that depend on each other are disabled together
docker compose exec -T php bin/magento module:disable --clear-static-content $modules

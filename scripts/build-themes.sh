#!/usr/bin/env bash
# Builds the MageSuite themes into app/design/frontend/creativestyle of MAGENTO_SRC (parent first).
# Uses the Deployer task build:theme of the production build (theme list, Node 16, Yarn) in the deployer container,
# so no Node / nvm is needed on the host.
set -euo pipefail
cd "$(dirname "$0")/.."
source .env

SRC=$(cd "${MAGENTO_SRC:-./src}" && pwd)
themes="theme-creativeshop theme-agrekom theme-ewarsztat"
# node_modules installed by another OS (e.g. an older build on the macOS host) holds native binaries
# (gifsicle, optipng, pngquant) the Linux container cannot run - reinstall them in the container.
marker=.installed-by-deployer-container
for theme in $themes; do
  nm="$SRC/vendor/creativestyle/$theme/node_modules"
  if [ -d "$nm" ] && [ ! -f "$nm/$marker" ]; then
    echo "== $theme: removing node_modules installed outside the deployer container"
    rm -rf "$nm"
  fi
done

# MAGENTO_SRC is mounted in the deployer container as /var/www/html
./scripts/deployer.sh build:theme test -o path_build=/var/www/html
for theme in $themes; do
  touch "$SRC/vendor/creativestyle/$theme/node_modules/$marker"
done

# The static version stamp changes, so browsers drop cached requirejs-config.js / CSS
docker compose exec -T php sh -c 'rm -rf pub/static/frontend var/view_preprocessed/* pub/static/deployed_version.txt && bin/magento cache:flush' >/dev/null
echo "Themes built into ${MAGENTO_SRC:-./src}/app/design/frontend/creativestyle"

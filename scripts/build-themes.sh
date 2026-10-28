#!/usr/bin/env bash
# Builds the MageSuite themes into app/design/frontend/creativestyle (parent first).
# Runs on the host: needs nvm. The themes use webpack 4, which does not run on Node 17+.
set -euo pipefail
cd "$(dirname "$0")/.."
source .env
SRC=$(cd "${MAGENTO_SRC:-./src}" && pwd)

export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
if [ ! -s "$NVM_DIR/nvm.sh" ]; then
  echo "nvm not found in $NVM_DIR - install it from https://github.com/nvm-sh/nvm" >&2
  exit 1
fi
. "$NVM_DIR/nvm.sh"
nvm install 16 >/dev/null
nvm use 16 >/dev/null
echo "Node $(node -v)"

yarn() { npx --yes yarn@1.22.21 "$@"; }

for theme in theme-creativeshop theme-agrekom theme-ewarsztat; do
  dir="$SRC/vendor/creativestyle/$theme"
  echo "== $theme"
  if [ -d "$dir/.git" ]; then
    lock=--frozen-lockfile   # our repos: yarn.lock is committed for Node 16
  else
    lock=
  fi
  (cd "$dir" && yarn install --non-interactive --ignore-engines $lock && yarn build)
done

# The static version stamp changes, so browsers drop cached requirejs-config.js / CSS
docker compose exec -T php sh -c 'rm -rf pub/static/frontend var/view_preprocessed/* pub/static/deployed_version.txt && bin/magento cache:flush' >/dev/null
echo "Themes built into $SRC/app/design/frontend/creativestyle"

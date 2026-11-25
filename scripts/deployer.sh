#!/usr/bin/env bash
# Runs Deployer from the DevOps repo (submodule ./agrekom: deploy.php, recipe/) in the deployer container:
# PHP 8.5 and Node 16 from Docker, not from the host.
#   ./scripts/deployer.sh build test           # build into agrekom/temp/build
#   ./scripts/deployer.sh build test --plan    # show the plan only
#   ./scripts/deployer.sh deploy test          # upload the existing build + activate on the server (no build)
#   ./scripts/deployer.sh deploy:full test     # build + deploy
set -euo pipefail
cd "$(dirname "$0")/.."
source .env

[ -f agrekom/deploy.php ] || { echo "Submodule agrekom is missing - run: git submodule update --init" >&2; exit 1; }

# bash -c: deploy.php reads the PHP binary from $_SERVER['_'], which only a shell sets.
exec docker compose run --rm --build deployer bash -c 'php deployer.phar "$@"' deployer "$@"

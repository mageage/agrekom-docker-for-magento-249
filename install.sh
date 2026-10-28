#!/usr/bin/env bash
# Fresh Magento 2.4.9 install into ./src with PL (default), UK and DE websites (production codes: pl, uk, de)
set -euo pipefail
cd "$(dirname "$0")"

[ -f .env ] || cp .env.example .env
if [ ! -f auth.json ]; then
  echo "Missing auth.json - copy auth.json.example and add your repo.magento.com keys." >&2
  exit 1
fi
source .env

if [ "$MAGENTO_SRC" = "./src" ] && [ -e src/app ]; then
  echo "./src already contains Magento - remove it first for a fresh install." >&2
  exit 1
fi
mkdir -p src

m() { docker compose exec -T php bin/magento "$@"; }

docker compose up -d --build php

docker compose exec -T php composer create-project --repository-url=https://repo.magento.com/ \
  magento/project-community-edition:2.4.9 /var/www/html --no-interaction

docker compose exec -T php composer require --no-interaction \
  snowdog/language-pl_pl splendidinternet/mage2-locale-de-de

m setup:install \
  --base-url="http://localhost:${HTTP_PORT}/" \
  --db-host=db --db-name="$MYSQL_DATABASE" --db-user="$MYSQL_USER" --db-password="$MYSQL_PASSWORD" \
  --admin-firstname=Admin --admin-lastname=Local --admin-email=admin@example.com \
  --admin-user=admin --admin-password=Admin123! \
  --language=pl_PL --currency=PLN --timezone=Europe/Warsaw --use-rewrites=1 \
  --search-engine=opensearch --opensearch-host=opensearch --opensearch-port=9200 \
  --amqp-host=rabbitmq --amqp-port=5672 --amqp-user=guest --amqp-password=guest \
  --cache-backend=redis --cache-backend-redis-server=valkey --cache-backend-redis-db=0 \
  --page-cache=redis --page-cache-redis-server=valkey --page-cache-redis-db=1 \
  --session-save=redis --session-save-redis-host=valkey --session-save-redis-db=2 \
  --backend-frontname=admin

m deploy:mode:set developer
m module:disable Magento_TwoFactorAuth Magento_AdminAdobeImsTwoFactorAuth
m config:set system/smtp/host mailpit
m config:set system/smtp/port 1025

docker compose exec -T php php < scripts/create-websites.php
./scripts/configure-websites.sh

docker compose up -d nginx
cat <<EOM

PL:    http://localhost:${HTTP_PORT}/
UK:    http://uk.localhost:${HTTP_PORT}/
DE:    http://de.localhost:${HTTP_PORT}/
Admin: http://localhost:${HTTP_PORT}/admin  (admin / Admin123!)
Mail:  http://localhost:${MAILPIT_PORT}/
EOM

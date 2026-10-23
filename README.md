# Agrekom – Docker for Magento 2.4.9

Local development environment for Magento Open Source 2.4.9 with three websites: PL (default), UK and DE.

| Service    | Image                                       | Host access                              |
|------------|---------------------------------------------|------------------------------------------|
| nginx      | nginx:1.28                                  | http://localhost:8080                    |
| php        | php:8.5-fpm + Magento extensions, Composer 2 | –                                       |
| db         | mysql:8.4                                   | `localhost:3306`                         |
| opensearch | opensearch:3.1 + analysis-icu/phonetic      | –                                        |
| valkey     | valkey:8 (cache, full-page cache, sessions) | –                                        |
| rabbitmq   | rabbitmq:4.1 (management UI)                | http://localhost:15672 (`guest`/`guest`) |
| mailpit    | mailpit (catches all outgoing mail)         | http://localhost:8025                    |

Containers are named `Agrekom_249-<service>`.

## Requirements

- Docker Desktop (Compose v2), at least 8 GB RAM assigned. On macOS enable **VirtioFS** file sharing.
- Magento Marketplace access keys (https://commercemarketplace.adobe.com → My Profile → Access Keys).
- Free ports: 8080, 3306, 8025, 15672 (change them in `.env` if needed).

## Quick start (fresh Magento 2.4.9)

```bash
cp auth.json.example auth.json   # put your repo.magento.com public/private keys here
cp .env.example .env             # optional – install.sh does it if missing
./install.sh
```

`install.sh` builds the images, installs Magento 2.4.9 into `./src`, adds the PL/DE language packs,
creates the three websites and configures them. Takes ~10–20 min on first run.

| Website (code)        | Store view (code)  | URL                       | Locale | Currency |
|-----------------------|--------------------|---------------------------|--------|----------|
| Polska (`base`)       | Polski (`default`) | http://localhost:8080     | pl_PL  | PLN      |
| United Kingdom (`uk`) | English (`uk_en`)  | http://uk.localhost:8080  | en_GB  | GBP      |
| Deutschland (`de`)    | Deutsch (`de_de`)  | http://de.localhost:8080  | de_DE  | EUR      |

Admin: http://localhost:8080/admin – `admin` / `Admin123!` (2FA disabled locally).

`*.localhost` resolves to 127.0.0.1 in browsers, no `/etc/hosts` changes needed. nginx maps the host name
to the Magento website code (`nginx/default.conf` + `MAGE_RUN_CODE` in `nginx/fastcgi_params`).

## Daily use

```bash
docker compose up -d                                   # start
docker compose stop                                    # stop
docker compose exec php bin/magento cache:flush
docker compose exec php bin/magento setup:upgrade
docker compose exec php composer require vendor/module
docker compose exec php bash                           # shell (user www-data)
docker compose exec db mysql -umagento -pmagento magento
docker compose logs -f nginx php
```

Import a database dump:

```bash
docker compose exec -T db mysql -umagento -pmagento magento < dump.sql
```

Re-apply website setup (idempotent):

```bash
docker compose exec -T php php < scripts/create-websites.php
./scripts/configure-websites.sh
```

## Working with the agrekom project instead of a fresh install

1. Set `MAGENTO_SRC` in `.env` to the absolute path of your agrekom checkout and run `docker compose up -d`.
2. In the project's `app/etc/env.php` use the container host names: db `db`, OpenSearch `opensearch:9200`,
   cache/sessions `valkey`, AMQP `rabbitmq:5672` (see `src/app/etc/env.php` of a fresh install for a full example).
3. `docker compose exec php bin/magento setup:upgrade && docker compose exec php bin/magento indexer:reindex`

## Layout

```
compose.yaml           services
.env.example           ports, DB credentials, MAGENTO_SRC
auth.json.example      repo.magento.com keys template (auth.json is git-ignored)
php/                   PHP 8.5 image (Dockerfile, php.ini; mail goes to Mailpit via msmtp)
nginx/                 vhost + fastcgi_params with website routing
scripts/               website creation and per-website configuration
install.sh             full fresh install
src/                   Magento code (git-ignored)
```

## Reset everything

```bash
docker compose down -v   # removes containers AND volumes (database, search index)
rm -rf src
```

# Agrekom – Docker for Magento 2.4.9

Local development environment for the agrekom shop on Magento Open Source 2.4.9 / PHP 8.5:
PL (default), DE, UK and – with the production database – ewarsztat.

**Migration from 2.4.6: see [migration/README.md](migration/README.md)** – what changed, the `2.x` branches /
`v2.x.x` tags of our packages, themes, fixed issues and open items.

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
- For the agrekom code: an SSH key (`SSH_KEY` in `.env`, default `~/.ssh/id_rsa`) with access to
  bitbucket.org/agrekom, bitbucket.org/e-warsztat and github.com/jarekherisz, and [nvm](https://github.com/nvm-sh/nvm)
  for the theme builds (Node 16).

## Quick start

```bash
cp auth.json.example auth.json                            # repo.magento.com public/private keys
cp .env.example .env
./install.sh                                             # 1. fresh Magento 2.4.9 + PL/DE/UK websites
./scripts/import-production-db.sh ~/agrekom_sklep01.sql  # 2. optional: production database
./scripts/setup-agrekom.sh                               # 3. agrekom modules (2.x), MageSuite, themes
```

Step 2 drops the local database. Step 3 is safe to re-run (e.g. after `git pull` of this repo).

## Fresh Magento 2.4.9 only

```bash
cp auth.json.example auth.json   # put your repo.magento.com public/private keys here
cp .env.example .env             # optional – install.sh does it if missing
./install.sh
```

`install.sh` builds the images, installs Magento 2.4.9 into `./src`, adds the PL/DE language packs,
creates the three websites and configures them. Takes ~10–20 min on first run.

| Website (code)        | Store view (code)  | URL                       | Locale | Currency |
|-----------------------|--------------------|---------------------------|--------|----------|
| Polska (`pl`)         | Polski (`pl_pl`)   | http://localhost:8080     | pl_PL  | PLN      |
| United Kingdom (`uk`) | English (`en_gb`)  | http://uk.localhost:8080  | en_GB  | GBP      |
| Deutschland (`de`)    | Deutsch (`de_de`)  | http://de.localhost:8080  | de_DE  | EUR      |

Website and store view codes are the same as in production.

Admin: http://localhost:8080/admin – `admin` / `Admin123!` after `install.sh`; `setup-agrekom.sh` also creates
`localadmin` / `Admin123!` (use it with the production database). 2FA is disabled locally.

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

Import the production database (fixes the MariaDB dump, local URLs, mail to Mailpit):

```bash
./scripts/import-production-db.sh /path/to/agrekom_sklep01.sql
```

Disabled modules: edit [`migration/disabled-modules.txt`](migration/disabled-modules.txt) and apply it
(`install.sh` and `setup-agrekom.sh` do this automatically):

```bash
./scripts/disable-modules.sh && docker compose exec php bin/magento setup:upgrade
```

Rebuild the themes after changing theme sources:

```bash
./scripts/build-themes.sh
```

Work on an agrekom package – it is a git clone on branch `2.x`:

```bash
cd src/vendor/agrekom/core-module && git status
```

Re-apply website setup (idempotent):

```bash
docker compose exec -T php php < scripts/create-websites.php
./scripts/configure-websites.sh
```

## Using another Magento checkout

Set `MAGENTO_SRC` in `.env` to its absolute path and run `docker compose up -d`. Its `app/etc/env.php` must use the
container host names: db `db`, OpenSearch `opensearch:9200`, cache/sessions `valkey`, AMQP `rabbitmq:5672`.

## Layout

```
compose.yaml           services
.env.example           ports, DB credentials, MAGENTO_SRC, SSH_KEY
auth.json.example      repo.magento.com keys template (auth.json is git-ignored)
php/                   PHP 8.5 image (Dockerfile, php.ini; mail goes to Mailpit via msmtp)
nginx/                 vhost + fastcgi_params with website routing
scripts/               websites, production DB import, theme build, agrekom setup
migration/             2.4.9 composer.json / composer.lock, disabled-modules.txt, migration README
install.sh             fresh Magento 2.4.9 install
src/                   Magento code (git-ignored)
```

## Reset everything

```bash
docker compose down -v   # removes containers AND volumes (database, search index)
rm -rf src
```

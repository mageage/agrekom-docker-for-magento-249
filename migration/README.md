# Agrekom – migration to Magento 2.4.9

Migration of the agrekom shop (agrekom.pl, agrekom.de, agrekom.co.uk, ewarsztat.pl) from
**Magento 2.4.6-p14 / PHP 8.2** to **Magento Open Source 2.4.9 / PHP 8.5**.

Status (2026-10-28): the four storefronts and the admin run locally on 2.4.9 with the production
database, without PHP or browser console errors. Not deployed anywhere yet.

## Platform

| Component      | Production (before)     | 2.4.9 (this repo)                          |
|----------------|-------------------------|--------------------------------------------|
| Magento        | 2.4.6-p14               | 2.4.9                                      |
| PHP            | 8.2                     | 8.5                                        |
| Database       | MariaDB 10.6            | MySQL 8.4                                  |
| Search         | ElasticSuite 2.12       | ElasticSuite 2.12.2.1 / OpenSearch 3.1     |
| Cache/sessions | files / Varnish         | Valkey 8, built-in full page cache         |
| Queue          | –                       | RabbitMQ 4.1                               |
| Mail           | Mageplaza SMTP          | Mailpit (local only)                       |

## Websites

Same codes as production, so a production dump works without changes.

| Website (code)   | Store view | Theme                          | Local URL                          |
|------------------|------------|--------------------------------|------------------------------------|
| PL (`pl`)        | `pl_pl`    | Creativestyle/theme-agrekom    | http://localhost:8080              |
| DE (`de`)        | `de_de`    | Creativestyle/theme-agrekom    | http://de.localhost:8080           |
| UK (`uk`)        | `en_gb`    | Creativestyle/theme-agrekom    | http://uk.localhost:8080           |
| ewarsztat (`ewarsztat`) | `ewarsztat` | Creativestyle/theme-ewarsztat | http://ewarsztat.localhost:8080 |

ewarsztat only exists with the production database; a fresh install creates PL, DE and UK.

## Our code: 2.x branches and v2.x.x tags

All agrekom packages have a **`2.x` branch** for Magento 2.4.9. Releases are tagged **`v2.x.x`**
(first release: `v2.0.0`). The `1.x` tags keep serving the 2.4.6 production shop.

| Package                                              | Repository                                                        | 2.4.9 change in v2.0.0 |
|------------------------------------------------------|-------------------------------------------------------------------|------------------------|
| agrekom/aitoc-advanced-permissions-module            | bitbucket.org/agrekom/aitoc-advanced-permissions-module           | – |
| agrekom/alior-bank-raty-module                       | bitbucket.org/agrekom/alior-bank-raty-module                      | explicit nullable types |
| agrekom/category-module                              | bitbucket.org/agrekom/category-module                             | – |
| agrekom/contact-module                               | bitbucket.org/agrekom/contact-module                              | – |
| agrekom/core-module                                  | bitbucket.org/agrekom/core-module                                 | explicit nullable types |
| agrekom/customer-module                              | bitbucket.org/agrekom/customer-module                             | – |
| agrekom/customization-email-template                 | bitbucket.org/agrekom/customization-email-template                | – |
| agrekom/customization-magesuite-lowest-price-logger-frontend | bitbucket.org/agrekom/customization-magesuite-lowest-price-logger-frontend | – |
| agrekom/customization-payment                        | bitbucket.org/agrekom/customization-payment                       | – |
| agrekom/filter-url-alias-module                      | bitbucket.org/agrekom/filter-url-alias-module                     | – |
| agrekom/flipbook-module                              | bitbucket.org/agrekom/flipbook-module                             | – |
| agrekom/imoje-payment-gateway-module                 | bitbucket.org/agrekom/imoje-payment-gateway                       | explicit nullable types (12 files) |
| agrekom/language-de_de                               | bitbucket.org/agrekom/de_de-language-package                      | – |
| agrekom/language-pl_pl                               | bitbucket.org/agrekom/pl_pl-language-package                      | – |
| agrekom/olegnax-hotspot-quick-view-module            | bitbucket.org/agrekom/olegnax-hotspot-quick-view                  | – |
| agrekom/olegnax-quick-view-module                    | bitbucket.org/agrekom/olegnax-quick-view                          | removed `jquery-ui-modules/core` dependency |
| agrekom/product-configurator-module                  | bitbucket.org/agrekom/product-configurator-module                 | explicit nullable types |
| agrekom/product-module                               | bitbucket.org/agrekom/product-module                              | – |
| agrekom/send-order-to-google-analytics-module        | bitbucket.org/agrekom/send-order-to-google-analytics-module       | explicit nullable types, declares `jflight/gacookie` |
| agrekom/video-promotional-campaign-module            | bitbucket.org/agrekom/video-promotional-campaign                  | removed duplicate `Agrekom::top_level` admin menu |
| e-warsztat/core-module                               | bitbucket.org/e-warsztat/core-module                              | – |
| creativestyle/theme-agrekom                          | github.com/jarekherisz/agrekom_frontend                           | 2.4.9 `root.phtml`, parent `^19.13`, Node 16 `yarn.lock` |
| creativestyle/theme-ewarsztat                        | github.com/jarekherisz/ewarsztat_frontend                         | 2.4.9 `root.phtml`, parent `^19.13`, Node 16 `yarn.lock` |

"–" means `v2.0.0` is the same commit as the last 1.x tag (the code already worked on 2.4.9).

### Working on a package

`composer.json` installs these packages **from source** (`preferred-install: source`), so every
`vendor/agrekom/*`, `vendor/e-warsztat/*` and both theme folders are git clones.
`scripts/setup-agrekom.sh` leaves them on the `2.x` branch.

```bash
cd src/vendor/agrekom/core-module          # git clone, branch 2.x
git checkout -b feature/my-change          # or commit on 2.x directly
# ... change, test, commit, push, merge into 2.x ...
git tag -a v2.0.1 -m "v2.0.1" && git push origin 2.x v2.0.1
cd ../../.. && docker compose exec php composer update agrekom/core-module
```

Rules:
- New releases for 2.4.9 are `v2.x.x` tags on the `2.x` branch. Do not tag `v1.x.x` from `2.x`.
- Fixes needed by the 2.4.6 production shop go to the old default branch (`master` / `main`) as `v1.x.x`
  and are merged forward into `2.x`.
- `composer.json` requires `^2.0`, so `composer update` picks up new `v2.x.x` tags automatically.

## composer.json

The 2.4.9 project files are in [`migration/composer.json`](composer.json) and
[`migration/composer.lock`](composer.lock). `scripts/setup-agrekom.sh` copies them into `src/`.

Changes against the 2.4.6 project (`Sites/agrekom/composer.json`):

- `magento/product-community-edition` `2.4.6-p14` → `2.4.9`; PHP constraint from Magento 2.4.9.
- One `vcs` repository per agrekom package (SSH URLs); `preferred-install` = `source` for
  `agrekom/*`, `e-warsztat/*` and the two themes.
- `agrekom/*`, `e-warsztat/core-module`, `creativestyle/theme-agrekom`, `creativestyle/theme-ewarsztat`: `^2.0`.
- `creativestyle/magesuite` `^13.0` with `creativestyle/theme-creativeshop` `^19.13` (19.13.2) – the same
  pair as production. MageSuite 14–16 require Creativeshop 20–22, which our child themes cannot build against
  (see Themes).
- `creativestyle/magesuite-email-attachments` `4.1.1 as 3.99.0` – v3 (required by MageSuite 13) targets the old
  laminas mail stack; 2.4.9 sends mail through Symfony Mailer and v4.1.1 supports it.
- `jflight/gacookie` `dev-master`, `minimum-stability: dev` + `prefer-stable: true`.
- `snowdog/language-pl_pl`, `splendidinternet/mage2-locale-de-de` as before.
- Not migrated yet (in 2.4.6 `composer.json`, not in 2.4.9): `amasty/module-google-rich-snippets`,
  `experius/module-wysiwygdownloads`, `facebook/facebook-for-magento2`, `magepal/magento2-google-analytics4`,
  `mageplaza/module-core`, `mageplaza/module-smtp`, `plumrocket/module-cookie-consent`,
  `stripe/stripe-payments`, `symfony/var-dumper`.
- No longer pinned (installed through MageSuite in its current 1.x version): `creativestyle/magesuite-google-api`
  (was `1.2.10`), `creativestyle/magesuite-product-positive-indicators` (was `<3.3.4`).

## Themes

MageSuite themes are built with Node, outside Magento (`scripts/build-themes.sh`):

1. `vendor/creativestyle/theme-creativeshop` (parent, 19.13.2)
2. `vendor/creativestyle/theme-agrekom`
3. `vendor/creativestyle/theme-ewarsztat`

Each build writes into `app/design/frontend/creativestyle/<theme>`.

- **Node 16 only.** The themes use `@creativestyle/magesuite-frontend-builder` 3/4 with webpack 4, which fails
  on Node 17+ (`error:0308010C:digital envelope routines::unsupported`). The script uses nvm.
- **Creativeshop 19, not 22.** The child themes compile the parent's TypeScript. Creativeshop 22's
  `tsconfig.json` (`target: ES2022`) cannot be parsed by their old `ts-loader`. Moving to Creativeshop 22
  means porting both child themes to `magesuite-frontend-builder` 5 – a separate project.
- **`root.phtml`.** Magento 2.4.8+ renders CSS/JS through `$headCritical` and `$headAssets`. Creativeshop 19's
  `root.phtml` (aligned with 2.4.6) does not print them, so pages had no CSS and no RequireJS.
  Both child themes now ship `src/Magento_Theme/templates/root.phtml` aligned with 2.4.9.
- **Build before `setup:upgrade`.** Themes registered while `app/design` is empty are stored as virtual
  (`theme.type = 1`) and Magento ignores their files. `setup-agrekom.sh` builds first and also resets
  `type = 0`.

## PHP 8.5 / Magento 2.4.9 issues found and fixed

| Problem | Where | Fix |
|---------|-------|-----|
| `Implicitly marking parameter … as nullable is deprecated` (PHP 8.4+) – fatal in developer mode | 33 parameters in 5 agrekom modules | `?Type $x = null` (php-cs-fixer `nullable_type_declaration_for_default_null_value`) |
| `Class "Jflight\GACookie\GACookie" does not exist` during `setup:di:compile` | send-order-to-google-analytics-module | require `jflight/gacookie` |
| Storefront without CSS/JS | Creativeshop 19 `root.phtml` | 2.4.9 `root.phtml` in child themes |
| `Script error for "jquery-ui-modules/core"` | olegnax-quick-view-module | jQuery UI 1.13 has no core module – dependency removed |
| Admin: `Duplicate key-sequence ['Agrekom::top_level']` in `menu.xml` | product-configurator + video-promotional-campaign | top-level menu declared once (product-configurator) |
| `ccSeparator` / `ccParagraph` not found in the browser | stale browser cache of `requirejs-config.js` | static version is bumped after theme builds (`deployed_version.txt`) |
| ElasticSuite connects to `localhost:9200` | env.php | `smile_elasticsuite_core_base_settings/es_client/servers = opensearch:9200` |

Scanned and clean on PHP 8.5: all `creativestyle/*` (MageSuite 13), `smile/elasticsuite`, `aitoc/core`, `olegnax/module-core`.

## Production database

`scripts/import-production-db.sh <dump.sql>`:

- removes the MariaDB-only first line of the dump and the `DEFINER=agrekom_sklep@localhost` clauses
  (72 triggers, 1 view, 2 procedures) – the import takes ~20 s for the 193 MB dump;
- rewrites base URLs to `*.localhost:8080`, disables HTTPS-only settings, the cookie domain and the custom admin URL;
- sends all mail to Mailpit and disables Mageplaza SMTP;
- switches the full page cache from Varnish to the built-in cache.

`setup-agrekom.sh` then runs `setup:upgrade` (2.4.6 → 2.4.9 schema) and creates the admin user
`localadmin / Admin123!` (production admin users are kept unchanged).

Production encrypted values (payment keys, SMTP passwords) cannot be decrypted locally – payments
(Stripe, imoje, Alior, Braintree) are not usable; `Braintree … merchantId needs to be set` in `system.log` is expected.

## Setting up (other developers)

```bash
git clone git@github.com:mageage/agrekom-docker-for-magento-249.git && cd agrekom-docker-for-magento-249
cp auth.json.example auth.json        # repo.magento.com keys
cp .env.example .env                  # SSH_KEY must reach bitbucket.org/agrekom and github.com/jarekherisz
./install.sh                          # fresh Magento 2.4.9 + PL/DE/UK websites
./scripts/import-production-db.sh ~/agrekom_sklep01.sql   # optional
./scripts/setup-agrekom.sh            # agrekom 2.x code, MageSuite, themes, upgrade, reindex
```

Needs on the host: Docker Desktop, nvm (Node 16 is installed by the script), SSH access to the
Bitbucket and GitHub repositories above.

## Open items

- Migrate the remaining third-party extensions (list under composer.json) or decide to drop them.
- Theme modernisation: port theme-agrekom / theme-ewarsztat to Creativeshop 22 + `magesuite-frontend-builder` 5,
  then upgrade MageSuite to 16.
- ElasticSuite 2.12 officially supports OpenSearch 2; it works with 3.1 locally – verify on the target hosting.
- Payments, checkout and order e-mails need testing with sandbox credentials.
- Production hosting: PHP 8.5, MySQL 8.4 (or MariaDB 11.4), OpenSearch, Valkey/Redis, RabbitMQ, Node 16 for theme builds.

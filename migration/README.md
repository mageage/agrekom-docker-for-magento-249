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
| creativestyle/theme-agrekom                          | github.com/jarekherisz/agrekom_frontend                           | 2.4.9 `root.phtml`, parent `^19.13`, Node 16 `yarn.lock`; v2.0.1: customer login template; v2.0.2: non-empty `_module.less` overrides |
| creativestyle/theme-ewarsztat                        | github.com/jarekherisz/ewarsztat_frontend                         | 2.4.9 `root.phtml`, parent `^19.13`, Node 16 `yarn.lock`; v2.0.1: customer login template; v2.0.2: non-empty `_module.less` overrides |

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
- Not migrated yet – see [Missing extensions](#missing-extensions).
- No longer pinned (installed through MageSuite in its current 1.x version): `creativestyle/magesuite-google-api`
  (was `1.2.10`), `creativestyle/magesuite-product-positive-indicators` (was `<3.3.4`).

## Disabled modules

[`disabled-modules.txt`](disabled-modules.txt) lists modules turned off locally; `scripts/disable-modules.sh`
applies it in one `module:disable` call (dependent modules must go together) and skips modules that are not
installed. `install.sh` and `setup-agrekom.sh` run it before `setup:upgrade`.

| Module(s) | Why |
|-----------|-----|
| `Magento_TwoFactorAuth`, `Magento_AdminAdobeImsTwoFactorAuth` | local admin login without 2FA |
| `Magento_WebapiAsync` | async/bulk REST API not used |
| `Dotdigitalgroup_Chat`, `_Sms`, `_Email` | not bundled with 2.4.9 any more – kept on the list for other versions |
| `Vertex_AddressValidation` | not bundled with 2.4.9 any more – kept on the list for other versions |
| `MageSuite_Gdpr` | not used |
| `PayPal_Braintree`, `PayPal_BraintreeGraphQl` + `CustomerBalance`, `GiftCard`, `GiftCardAccount`, `GiftWrapping`, `Reward` | no Braintree credentials; the add-ons depend on `PayPal_Braintree` |
| `Magento_PaymentServices*` (Base, Paypal, PaypalGraphQl, Dashboard, SaaSExport) + `Magento_ServiceProxy` | Adobe Payment Services, bundled with 2.4.9 and not configured; its LESS needs Magento blank theme variables that Creativeshop removes and broke `css/styles-m.css` |

Expected log noise: every `cache:flush` logs `No cache server(s) could be purged` – `MageSuite_Cache` purges its
search-suggest cache on Varnish even when the built-in full page cache is used.

## Missing extensions

Packages required by the 2.4.6 project (`Sites/agrekom/composer.json`) that are not in 2.4.9, with the modules
production has enabled from them (checked 2026-10-28):

| Package (prod version) | Modules | Source | Note |
|------------------------|---------|--------|------|
| `facebook/facebook-for-magento2` (1.4.6) | Facebook_BusinessExtension | Packagist | last release 1.4.6 (2023-01) – unmaintained; product attributes `google_product_category`, `facebook_*` |
| `stripe/stripe-payments` (4.7.0 → `stripe/module-payments` 4.7.1, `stripe/module-tax` 1.2.5) | StripeIntegration_Payments, StripeIntegration_Tax | Stripe / Marketplace, not Packagist | production config has Stripe active |
| `mageplaza/module-smtp` (4.7.25), `mageplaza/module-core` (pinned 1.5.15) | Mageplaza_Smtp, Mageplaza_Core | Packagist (4.7.27 / 1.6.1 available) | production mail transport |
| `magepal/magento2-google-analytics4` (1.7.13) | MagePal_Core, MagePal_GoogleAnalytics4, MagePal_GoogleTagManager | composer.magepal.com | GA4 / GTM on PL, DE, UK |
| `amasty/module-google-rich-snippets` (1.10.1) | Amasty_Base, Amasty_SeoRichData | composer.amasty.com | product attribute `am_offer_item_condition` |
| `plumrocket/module-cookie-consent` (1.6.1) + `module-extended-admin-ui`, `module-geo-ip-lookup` | Plumrocket_Base, _CookieConsent, _ExtendedAdminUi, _GeoIPLookup | plumrocket.com/repo | cookie banner; entity `pr_cookie` |
| `experius/module-wysiwygdownloads` (1.3.0) | Experius_WysiwygDownloads | Packagist (1.3.0, PHP ^8) | file downloads in the WYSIWYG editor |

Gone with Magento 2.4.9 itself: `Magento_Elasticsearch7` (replaced by OpenSearch / ElasticSuite),
`Magento_GoogleShoppingAds`, `Temando_ShippingRemover`.

Found during the check: `agrekom/customization-email-template` only contains `etc/module.xml`, and that file declares
`MageSuite_LowestPriceLoggerFrontend` instead of `Agrekom_CustomizationEmailTemplate` (copy-paste; same in production).
The package has no code, so nothing is lost – fix the name or drop the package.

### Attributes of missing extensions

Their EAV attributes stay in the database and point to classes that no longer exist, which broke the admin product
edit page (`Class "Facebook\BusinessExtension\Model\Config\Source\Product\GoogleProductCategory" does not exist`).
`scripts/fix-missing-attribute-models.php` (run by `setup-agrekom.sh`) clears every missing source/backend/frontend
model; product dropdowns become text fields so their values survive a product save. It prints restore SQL
(`backups/attribute-models-restore.sql`) for when an extension is installed again. Affected now: 6 Facebook and
1 Amasty product attributes, 2 Plumrocket `pr_cookie` attributes.

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
- **`login.phtml`.** Creativeshop 19's customer login template reads `login_button_view_model`; 2.4.9 passes
  `button_lock_manager` instead. Both child themes ship `src/Magento_Customer/templates/form/login.phtml`
  (Creativeshop's template with only that change).
- **Empty `_module.less`.** Creativeshop switches off Magento_Bundle, Magento_PurchaseOrder and Magento_NegotiableQuote
  styles with empty files; 2.4.8+ refuses empty LESS sources. Both child themes ship comment-only replacements.
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
| `css/styles-l.css` 404: `Unable to get content for '…/Magento_Bundle/css/source/_module.less' after 3 attempts` | Creativeshop 19 empty `_module.less` (Bundle, PurchaseOrder, NegotiableQuote); 2.4.8+ refuses empty sources | comment-only overrides in the child themes (theme v2.0.2) |
| `css/styles-m.css` 404: `variable @checkout-shipping-address__max-width is undefined` | Magento_PaymentServicesPaypal LESS (bundled with 2.4.9) | Payment Services modules disabled (`disabled-modules.txt`) |
| Customer login page: `Call to a member function disabled() on null` | Creativeshop 19 `Magento_Customer/templates/form/login.phtml` (`login_button_view_model`, removed in 2.4.9) | child themes override it using `button_lock_manager` (theme v2.0.1) |
| `Script error for "jquery-ui-modules/core"` | olegnax-quick-view-module | jQuery UI 1.13 has no core module – dependency removed |
| New customer's first order saves the same address twice (default shipping + default billing) – also in production 2.4.6 | Magento core: `shipping.js` sets `save_in_address_book = 1` (snake_case) on the new shipping address; `select-billing-address.js` clears only `saveInAddressBook` on the same-as-shipping billing copy, so billing is saved again | `agrekom/core-module`: mixin `Agrekom_Core/js/action/select-billing-address-mixin` clears the snake_case flag too – one address, default billing + shipping |
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
- turns off all tracking (Google Analytics / GA4 / GTM, Google Ads conversions, the order-to-GA module,
  Meta Pixel and the gtag/pixel scripts in *HTML Head → Scripts*), so local orders never reach the real accounts.
  theme-agrekom also hard-codes the Google Ads tag `AW-670082924` in
  `src/Magento_Theme/templates/head/additional_tags.phtml` – it is not controlled by configuration (open item);
- switches the full page cache from Varnish to the built-in cache;
- rewrites production shop URLs in content to the local hosts (`scripts/rewrite-production-urls.sh`): CMS pages and
  blocks incl. Content Constructor JSON (escaped `https:\/\/` and scheme-less `"href":"www.agrekom.pl"`), product and
  category texts, checkout terms, brands, config. Links and images on the local copy never lead to the live shops
  (media files are local). Logs are not touched.

`setup-agrekom.sh` then runs `setup:upgrade` (2.4.6 → 2.4.9 schema) and creates the admin user
`localadmin / Admin123!` (production admin users are kept unchanged).

Production encrypted values (payment keys, SMTP passwords) cannot be decrypted locally – payments
(Stripe, imoje, Alior) are not usable locally. Braintree is disabled (see Disabled modules).

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
Bitbucket and GitHub repositories above, and a `~/.gitconfig` with `user.name` / `user.email` – it is mounted
into the php container (`GITCONFIG` in `.env`) so commits made there carry your identity.

## Test customers and checkout test (2026-10-28)

`scripts/create-test-customers.php` creates `test.<website>@example.test` (pl, de, uk, ewarsztat) with password
`Test1234!` and a default address (customer accounts are per website). Run:
`docker compose exec -T php php < scripts/create-test-customers.php`.

Tested on all four stores: login, account pages (dashboard, addresses, account edit, orders, newsletter, reviews,
wishlist), checkout as customer and as guest (bank transfer / cash on delivery; courier, free shipping, pickup),
order confirmation and welcome e-mails in Mailpit (store language and sender), orders in the admin.

Second run in Chrome (2026-10-28): on every store homepage → category → product page → cart page → checkout as
guest, then registration through the storefront form (`new.<website>@example.test` / `Test1234!`) and the same
journey signed in (new address entered at checkout). 8 orders (000002371/2372, 4000000986/987, 5000000367/368,
7000000025/026), 14 e-mails in Mailpit (4 welcome, 8 order confirmations, 2 UK staff copies), no console errors,
no new `system.log` / `exception.log` entries. Out-of-stock products correctly show no add-to-cart button.

`import-production-db.sh` removes `user_create` from `customer/captcha/forms` (no CAPTCHA on local registration).

Notes: the DE website only offers free shipping above 150 EUR (production config), so smaller DE carts cannot be
shipped; the UK store sends a copy of order e-mails to hello@agrekom.co.uk (caught by Mailpit locally).

## Open items

- theme-agrekom: make the hard-coded Google Ads tag configurable (e.g. only when `google/adwords/active`).
- Intermittent `Error during Content Constructor component rendering: Call to a member function toHtml() on null`
  in `system.log` – seen 8× during testing, not reproducible on request; pages render.
- Migrate the remaining third-party extensions (list under composer.json) or decide to drop them.
- Theme modernisation: port theme-agrekom / theme-ewarsztat to Creativeshop 22 + `magesuite-frontend-builder` 5,
  then upgrade MageSuite to 16.
- ElasticSuite 2.12 officially supports OpenSearch 2; it works with 3.1 locally – verify on the target hosting.
- Payments, checkout and order e-mails need testing with sandbox credentials.
- Production hosting: PHP 8.5, MySQL 8.4 (or MariaDB 11.4), OpenSearch, Valkey/Redis, RabbitMQ, Node 16 for theme builds.

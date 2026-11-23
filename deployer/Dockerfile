# Deployer runner: the same PHP 8.5 as the php service, plus Node 16 (nvm), rsync and ssh,
# so builds and deploys do not depend on the PHP / Node installed on the host.
FROM php:8.5-cli

COPY --from=mlocati/php-extension-installer /usr/bin/install-php-extensions /usr/local/bin/

RUN apt-get update && apt-get install -y --no-install-recommends \
      git openssh-client rsync unzip curl ca-certificates python3 make g++ \
 && rm -rf /var/lib/apt/lists/* \
 && install-php-extensions bcmath gd intl pdo_mysql soap sockets xsl zip ftp opcache \
 && cp /usr/local/etc/php/php.ini-production /usr/local/etc/php/php.ini \
 && printf 'memory_limit = -1\nmax_execution_time = 0\n' > /usr/local/etc/php/conf.d/zz-deployer.ini

# Host keys: package repositories baked in, the host's known_hosts (mounted) for the deploy servers.
RUN mkdir -p /var/www/.composer/cache /var/www/.ssh \
 && ssh-keyscan -t rsa,ecdsa,ed25519 bitbucket.org github.com > /var/www/.ssh/known_hosts 2>/dev/null \
 && printf 'Host *\n  UserKnownHostsFile /var/www/.ssh/known_hosts /var/www/.ssh/known_hosts_host\n' \
      > /etc/ssh/ssh_config.d/agrekom.conf \
 && chown -R www-data:www-data /var/www

USER www-data
ENV HOME=/var/www NVM_DIR=/var/www/.nvm COMPOSER_HOME=/var/www/.composer

# recipe/build/theme.php loads nvm and runs `nvm install {{node_version}}` (16).
RUN curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | PROFILE=/dev/null bash \
 && . "$NVM_DIR/nvm.sh" && nvm install 16 && nvm cache clear

WORKDIR /project

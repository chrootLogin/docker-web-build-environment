FROM debian:jessie
MAINTAINER Simon Erhardt <me+dockerootlogin.ch>

ARG TINI_VERSION="v0.10.0"
ARG DEPLOYER_VERSION="v3.3.0"
ARG DEPLOYER_SHA1="417e9fce37d6e18bcefd633f012306ac7af63730"

# Install a tiny init
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /usr/local/bin/tini
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini.asc /usr/local/bin/tini.asc
RUN gpg --keyserver ha.pool.sks-keyservers.net --recv-keys 595E85A6B1B4779EA4DAAEC70B588DFF0527A9B7 \
  && gpg --verify /usr/local/bin/tini.asc \
  && rm -f /usr/local/bin/tini.asc \
  && chmod +x /usr/local/bin/tini

ENTRYPOINT ["/usr/local/bin/tini", "--"]

# Install dependencies
RUN apt-get update \
  && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
  wget \
  bash \
  curl \
  ssh-client \
  sshpass \
  rsync \
  ca-certificates \
  build-essential \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

# Add dotdeb repository
RUN echo "deb http://packages.dotdeb.org jessie all" > /etc/apt/sources.list.d/dotdeb.list \
  && wget -O /tmp/dotdeb.gpg https://www.dotdeb.org/dotdeb.gpg \
  && apt-key add /tmp/dotdeb.gpg \
  && rm /tmp/dotdeb.gpg

# Install php 5
RUN apt-get update \
  && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
  php5-common \
  php5-cli \
  php5-curl \
  php5-gd \
  php5-intl \
  php5-json \
  php5-mcrypt \
  php5-mysql \
  php5-sqlite \
  php5-twig \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

# Install php 7
RUN apt-get update \
  && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
  php7.0-bz2 \
  php7.0-cli \
  php7.0-common \
  php7.0-curl \
  php7.0-gd \
  php7.0-gmp \
  php7.0-imagick \
  php7.0-intl \
  php7.0-json \
  php7.0-mbstring \
  php7.0-mcrypt \
  php7.0-mysql \
  php7.0-readline \
  php7.0-sqlite3 \
  php7.0-ssh2 \
  php7.0-xml \
  php7.0-zip \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

# Install composer
RUN EXPECTED_SIGNATURE=$(wget https://composer.github.io/installer.sig -O - -q) \
  && php7.0 -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" \
  && ACTUAL_SIGNATURE=$(php -r "echo hash_file('SHA384', 'composer-setup.php');") \
  && if [ "$EXPECTED_SIGNATURE" != "$ACTUAL_SIGNATURE" ]; then echo "Composer: Signature mismatch!" && exit 1; fi \
  && php7.0 composer-setup.php --quiet \
  && rm composer-setup.php \
  && mv composer.phar /usr/local/bin/composer

# Install deployer
RUN wget -O /tmp/deployer http://deployer.org/releases/${DEPLOYER_VERSION}/deployer.phar \
  && EXPECTED_SIGNATURE=$(sha1sum /tmp/deployer | awk '{print $1}') \
  && if [ "$EXPECTED_SIGNATURE" != "$DEPLOYER_SHA1" ]; then echo "Deployer: Signature mismatch!" && exit 1; fi \
  && mv /tmp/deployer /usr/local/bin/dep \
  && chmod +x /usr/local/bin/dep

# Install NodeJS
RUN curl -sL https://deb.nodesource.com/setup_6.x | bash - \
  && DEBIAN_FRONTEND=noninteractive apt-get install -y \
  nodejs \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

# Install gulp
RUN npm install -g gulp

CMD ["/bin/bash"]

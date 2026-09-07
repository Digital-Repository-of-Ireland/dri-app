# syntax=docker/dockerfile:1
 
FROM ubuntu:22.04
 
ARG RUBY_VERSION=3.3.6
ARG RUBY_INSTALL_VERSION=0.9.3
 
ENV DEBIAN_FRONTEND=noninteractive \
    RAILS_ENV=development \
    BUNDLE_PATH=/usr/local/bundle \
    LANG=C.UTF-8
 
# Build deps for compiling Ruby, plus what the app itself needs at runtime
# (mysql client libs, git+ssh for private gems, curl for healthchecks).
RUN apt-get update -qq && apt-get install -y --no-install-recommends \
      build-essential \
      autoconf \
      bison \
      libssl-dev \
      libyaml-dev \
      libreadline-dev \
      zlib1g-dev \
      libffi-dev \
      libgdbm-dev \
      default-libmysqlclient-dev \
      default-mysql-client \
      git \
      openssh-client \
      curl \
      ca-certificates \
      pkg-config \
    && rm -rf /var/lib/apt/lists/*
 
# ruby-install compiles Ruby from source and installs it to /usr/local, so it's
# on PATH without any extra config. This layer is cached, so it only costs
# build time once (a few minutes) as long as RUBY_VERSION doesn't change.
RUN curl -fsSL "https://github.com/postmodern/ruby-install/archive/refs/tags/v${RUBY_INSTALL_VERSION}.tar.gz" -o ruby-install.tar.gz \
    && tar -xzf ruby-install.tar.gz \
    && cd "ruby-install-${RUBY_INSTALL_VERSION}" \
    && make install \
    && cd .. && rm -rf ruby-install*
 
RUN ruby-install --system ruby "${RUBY_VERSION}" -- --disable-install-doc

RUN apt-get update -qq && apt-get install -y --no-install-recommends \
      apt-transport-https \
      nodejs \
      gnupg \
      imagemagick \
      zlib1g-dev \
      libreadline-dev \
      libsqlite3-dev \
      sqlite3 \
      libxml2-dev \
      libxslt1-dev \
      libcurl4-openssl-dev \
      libffi-dev \
      libgmp-dev \
      wget \
      rsync \
      npm \
      software-properties-common \
    && rm -rf /var/lib/apt/lists/*
 
RUN /usr/bin/add-apt-repository ppa:openjdk-r/ppa
RUN apt-add-repository ppa:ansible/ansible
RUN apt-get update
RUN apt-get install -y openjdk-21-jre ansible python3-pip python3-dev python3-venv libsasl2-dev gcc
RUN npm install n -g
RUN n stable
RUN npm install --global yarn

# Trust GitHub's host key so the git clone during bundle install doesn't
# hang on an interactive host-key prompt.
RUN mkdir -p -m 0700 /root/.ssh && \
    ssh-keyscan github.com >> /root/.ssh/known_hosts

WORKDIR /app

COPY Gemfile Gemfile.lock ./
RUN --mount=type=ssh bundle install --jobs 4 --retry 3

COPY . .

COPY docker/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

EXPOSE 3000

ENTRYPOINT ["entrypoint.sh"]
CMD ["./bin/rails", "server", "-b", "0.0.0.0"]

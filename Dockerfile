FROM alpine:3.5

MAINTAINER Nebo #15 <support@nebo15.com>

# Important!  Update this no-op ENV variable when this Dockerfile
# is updated with the current date. It will force refresh of all
# of the base images and things like `apt-get update` won't be using
# old cached versions when the Dockerfile is built.
ENV REFRESHED_AT=2017-04-18 \
    LANG=en_US.UTF-8 \
    HOME=/opt/app/ \
    # Set this so that CTRL+G works properly
    TERM=xterm \
    OTP_VERSION=19.3.1

WORKDIR /tmp/erlang-build

# Install Erlang
RUN set -xe && \
    OTP_DOWNLOAD_URL="https://github.com/erlang/otp/archive/OTP-${OTP_VERSION}.tar.gz" && \
    OTP_DOWNLOAD_SHA256="618f19e4274150a107bea7621d871d96d386291759ffb57d1a3e60f1f243a509" && \
    # Create default user and home directory, set owner to default
    mkdir -p ${HOME} && \
    adduser -s /bin/sh -u 1001 -G root -h ${HOME} -S -D default && \
    chown -R 1001:0 ${HOME} && \
    # Add edge repos tagged so that we can selectively install edge packages
    echo "@edge http://nl.alpinelinux.org/alpine/edge/main" >> /etc/apk/repositories && \
    # Upgrade Alpine and base packages
    apk --no-cache upgrade && \
    # Install Erlang/OTP deps
    apk add --no-cache pcre@edge && \
    apk add --no-cache \
      ca-certificates \
      openssl-dev \
      ncurses-dev \
      unixodbc-dev \
      zlib-dev && \
    # Install Erlang/OTP build deps
    apk add --no-cache --virtual .erlang-build \
      autoconf curl \
      build-base perl-dev && \
    # Download and validate Erlang/OTP checksum
    curl -fSL -o otp-src.tar.gz "${OTP_DOWNLOAD_URL}" && \
    # echo "$OTP_DOWNLOAD_SHA256 otp-src.tar.gz" | sha256sum -c - && \
    tar -xzf otp-src.tar.gz -C /tmp/erlang-build --strip-components=1 && \
    rm otp-src.tar.gz && \
    # Erlang/OTP build env
    export ERL_TOP=/tmp/erlang-build && \
    export PATH=$ERL_TOP/bin:$PATH && \
    export CPPFlAGS="-D_BSD_SOURCE $CPPFLAGS" && \
    # Configure
    ./otp_build autoconf && \
    ./configure --prefix=/usr \
      --sysconfdir=/etc \
      --mandir=/usr/share/man \
      --infodir=/usr/share/info \
      --without-javac \
      --without-jinterface \
      --without-cosEvent \
      --without-cosEventDomain \
      --without-cosFileTransfer \
      --without-cosNotification \
      --without-cosProperty \
      --without-cosTime \
      --without-cosTransactions \
      --without-gs \
      --without-ic \
      --without-megaco \
      --without-orber \
      --without-percept \
      --without-odbc \
      --enable-kernel-poll \
      --enable-threads \
      --enable-shared-zlib \
      --enable-dynamic-ssl-lib \
      --enable-ssl=dynamic-ssl-lib \
      --enable-sctp \
      --enable-hipe \
      --enable-dirty-schedulers \
      --enable-new-purge-strategy && \
    # Build
    set -xe && \
    make -j4 && make install && \
    # Cleanup
    apk del --force .erlang-build && \
    cd $HOME && \
    rm -rf /tmp/erlang-build && \
    find /usr/local -name examples | xargs rm -rf && \
    # Update CA certificates
    update-ca-certificates --fresh

WORKDIR ${HOME}

CMD ["erl"]

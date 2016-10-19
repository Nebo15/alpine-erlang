FROM gliderlabs/alpine:3.4

MAINTAINER Paul Schoenfelder <paulschoenfelder@gmail.com>
MAINTAINER Nebo #15 <support@nebo15.com>

# Important!  Update this no-op ENV variable when this Dockerfile
# is updated with the current date. It will force refresh of all
# of the base images and things like `apt-get update` won't be using
# old cached versions when the Dockerfile is built.
ENV REFRESHED_AT=2016-10-19 \
    LANG=en_US.UTF-8 \
    HOME=/opt/app/ \
    OTP_VERSION=19.0.1 \
    # Set this so that CTRL+G works properly
    TERM=xterm

WORKDIR /tmp/erlang-build

# Install Erlang
RUN \
    # Create default user and home directory, set owner to default
    mkdir -p ${HOME} && \
    adduser -s /bin/sh -u 1001 -G root -h ${HOME} -S -D default && \
    chown -R 1001:0 ${HOME} && \
    # Add edge repos tagged so that we can selectively install edge packages
    echo "@edge http://nl.alpinelinux.org/alpine/edge/main" >> /etc/apk/repositories && \
    # Upgrade Alpine and base packages
    apk --no-cache --update upgrade && \
    # Install Erlang/OTP deps
    apk add --no-cache \
      ca-certificates \
      libressl-dev@edge \
      ncurses-dev@edge \
      unixodbc-dev@edge \
      zlib-dev@edge && \
    # Install Erlang/OTP build deps
    apk add --no-cache --virtual .erlang-build \
      git@edge autoconf@edge build-base@edge perl-dev@edge && \
    # Shallow clone Erlang/OTP 19.1.5
    git clone -b OTP-${OTP_VERSION} --single-branch --depth 1 https://github.com/erlang/otp.git . && \
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
      --without-wx \
      --without-debugger \
      --without-observer \
      --without-jinterface \
      --without-common_test \
      --without-cosEvent\
      --without-cosEventDomain \
      --without-cosFileTransfer \
      --without-cosNotification \
      --without-cosProperty \
      --without-cosTime \
      --without-cosTransactions \
      --without-dialyzer \
      --without-edoc \
      --without-erl_docgen \
      --without-et \
      --without-eunit \
      --without-gs \
      --without-ic \
      --without-megaco \
      --without-orber \
      --without-percept \
      --without-typer \
      --enable-threads \
      --enable-shared-zlib \
      --enable-ssl=dynamic-ssl-lib \
      --enable-hipe && \
    # Build
    make -j4 && make install && \
    # Cleanup
    apk del .erlang-build git  && \
    cd $HOME && \
    rm -rf /tmp/erlang-build && \
    # Update ca certificates
    rm -rf /var/cache/apk/* && \
    update-ca-certificates --fresh

WORKDIR ${HOME}

CMD ["/bin/sh"]

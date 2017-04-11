FROM alpine:3.5

MAINTAINER Paul Schoenfelder <paulschoenfelder@gmail.com>
MAINTAINER Nebo #15 <support@nebo15.com>

# Important!  Update this no-op ENV variable when this Dockerfile
# is updated with the current date. It will force refresh of all
# of the base images and things like `apt-get update` won't be using
# old cached versions when the Dockerfile is built.
ENV REFRESHED_AT=2017-04-11 \
    LANG=en_US.UTF-8 \
    HOME=/opt/app/ \
    # Set this so that CTRL+G works properly
    TERM=xterm

# Install Erlang
RUN \
    mkdir -p ${HOME} && \
    adduser -s /bin/sh -u 1001 -G root -h ${HOME} -S -D default && \
    chown -R 1001:0 ${HOME} && \
    apk --no-cache --upgrade add ca-certificates \
                                 erlang erlang-dev erlang-kernel erlang-hipe erlang-compiler \
                                 erlang-stdlib erlang-erts erlang-syntax-tools erlang-sasl \
                                 erlang-crypto erlang-public-key erlang-ssl erlang-tools \
                                 erlang-inets erlang-mnesia erlang-odbc erlang-xmerl erlang-runtime-tools \
                                 erlang-erl-interface erlang-parsetools erlang-asn1 && \
    update-ca-certificates --fresh

WORKDIR ${HOME}

CMD ["/bin/sh"]

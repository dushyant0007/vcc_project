ARG VERSION=11.0.8
FROM codeberg.org/forgejo/forgejo:${VERSION}

RUN apk add --no-cache \
    sudo \
    postgresql-client \
    curl \
    sed \
    util-linux

COPY ./entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
CMD ["/usr/bin/s6-svscan", "/etc/s6"]

ARG BUILDPLATFORM
ARG TARGETPLATFORM

ARG XBPS_MIRROR=https://repo-fastly.voidlinux.org

ARG SEARXNG_PACKAGES="xbps base-files busybox libstdc++ ca-certificates tzdata python3 wget"
ARG SEARXNG_BUILDER_PACKAGES="xbps base-files busybox gcc ca-certificates tzdata python3-devel wget uv brotli"
ARG SPACE_PACKAGES="xbps base-files busybox ca-certificates wget"

###########################################################################
FROM --platform=$BUILDPLATFORM docker.io/library/alpine:latest AS bootstrap

ARG TARGETPLATFORM
ARG XBPS_MIRROR

COPY ./setup.sh /
COPY ./keys/ /target/var/db/xbps/keys/
COPY <<EOF /target/etc/xbps.d/noextract.conf
noextract=/etc/hosts
noextract=/etc/mtab
noextract=/etc/skel*
noextract=/usr/lib/dracut*
noextract=/usr/lib/gconv*
noextract=/usr/lib/modprobe.d*
noextract=/usr/lib/python*/EXTERNALLY-MANAGED
noextract=/usr/lib/sysctl.d*
noextract=/usr/lib/udev*
noextract=/usr/share/bash-completion*
noextract=/usr/share/fish/vendor_completions.d*
noextract=/usr/share/info*
noextract=/usr/share/licenses*
noextract=/usr/share/man*
noextract=/usr/share/zsh/site-functions*
EOF

RUN --mount=type=cache,sharing=locked,id=xbps,target=/target/var/cache/xbps set -eux; \
    . /setup.sh; \
    apk add --no-cache ca-certificates curl; \
    curl "$XBPS_MIRROR/static/xbps-static-latest.$(uname -m)-musl.tar.xz" | tar -C / -vJx; \
    xbps-install -S -R "$REPO" -r /target/

##########################################################
FROM --platform=$BUILDPLATFORM bootstrap AS rootfs-searxng

ARG TARGETPLATFORM
ARG XBPS_MIRROR
ARG SEARXNG_PACKAGES

RUN --mount=type=cache,sharing=locked,id=xbps,target=/target/var/cache/xbps set -eux; \
    . /setup.sh; \
    xbps-install -y -R "$REPO" -r /target/ $SEARXNG_PACKAGES

##################################################################
FROM --platform=$BUILDPLATFORM bootstrap AS rootfs-searxng-builder

ARG TARGETPLATFORM
ARG XBPS_MIRROR
ARG SEARXNG_BUILDER_PACKAGES

RUN --mount=type=cache,sharing=locked,id=xbps,target=/target/var/cache/xbps set -eux; \
    . /setup.sh; \
    xbps-install -y -R "$REPO" -r /target/ $SEARXNG_BUILDER_PACKAGES

########################################################
FROM --platform=$BUILDPLATFORM bootstrap AS rootfs-space

ARG TARGETPLATFORM
ARG XBPS_MIRROR
ARG SPACE_PACKAGES

RUN --mount=type=cache,sharing=locked,id=xbps,target=/target/var/cache/xbps set -eux; \
    . /setup.sh; \
    xbps-install -y -R "$REPO" -r /target/ $SPACE_PACKAGES

##################################################
FROM --platform=$TARGETPLATFORM scratch AS searxng

COPY --from=rootfs-searxng /target/ /

RUN set -eu; \
    for app in $(/usr/bin/busybox --list); do \
    [ ! -f "/usr/bin/$app" ] && /usr/bin/busybox ln -sf busybox "/usr/bin/$app"; \
    done; \
    install -dm1777 /tmp/; \
    xbps-reconfigure -fa; \
    xbps-remove -Rofy xbps; \
    rm -rf /var/cache/* /var/libexec/xbps* /etc/xbps* /var/db/; \
    find /usr/lib/python*/ -type f -name "*.opt-[12].pyc" -delete

COPY <<EOF /etc/group
root:x:0:
searxng:x:977:
EOF

COPY <<EOF /etc/passwd
root:x:0:0:root:/usr/local/searxng/:/usr/bin/sh
searxng:x:977:977:searxng:/usr/local/searxng/:/usr/bin/sh
EOF

RUN set -eux; \
    install -dm0555 -o 977 -g 977 /usr/local/searxng/; \
    install -dm0755 -o 977 -g 977 /etc/searxng/; \
    install -dm0755 -o 977 -g 977 /var/cache/searxng/

ENV PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin" \
    SSL_CERT_DIR="/etc/ssl/certs" \
    SSL_CERT_FILE="/etc/ssl/certs/ca-certificates.crt" \
    HISTFILE="/dev/null" \
    CONFIG_PATH="/etc/searxng" \
    DATA_PATH="/var/cache/searxng"

WORKDIR /usr/local/searxng/
ENTRYPOINT ["/usr/bin/sh"]

##########################################################
FROM --platform=$TARGETPLATFORM scratch AS searxng-builder

COPY --from=rootfs-searxng-builder /target/ /

RUN set -eu; \
    for app in $(/usr/bin/busybox --list); do \
    [ ! -f "/usr/bin/$app" ] && /usr/bin/busybox ln -sf busybox "/usr/bin/$app"; \
    done; \
    install -dm1777 /tmp/; \
    xbps-reconfigure -fa; \
    rm -rf /var/cache/*; \
    find /usr/lib/python*/ -type f -name "*.opt-[12].pyc" -delete

ENV PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin" \
    SSL_CERT_DIR="/etc/ssl/certs" \
    SSL_CERT_FILE="/etc/ssl/certs/ca-certificates.crt" \
    HISTFILE="/dev/null"

WORKDIR /usr/local/searxng/
ENTRYPOINT ["/usr/bin/sh"]

################################################
FROM --platform=$TARGETPLATFORM scratch AS space

COPY --from=rootfs-space /target/ /

RUN set -eu; \
    for app in $(/usr/bin/busybox --list); do \
    [ ! -f "/usr/bin/$app" ] && /usr/bin/busybox ln -sf busybox "/usr/bin/$app"; \
    done; \
    install -dm1777 /tmp/; \
    xbps-reconfigure -fa; \
    xbps-remove -Rofy xbps; \
    rm -rf /var/cache/* /var/libexec/xbps* /etc/xbps* /var/db/

COPY <<EOF /etc/group
root:x:0:
searxng:x:977:
EOF

COPY <<EOF /etc/passwd
root:x:0:0:root:/usr/local/searxng-space/:/usr/bin/sh
searxng:x:977:977:searxng:/usr/local/searxng-space/:/usr/bin/sh
EOF

RUN set -eu; \
    install -dm0555 -o 977 -g 977 /usr/local/searxng-space/

ENV PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin" \
    SSL_CERT_DIR="/etc/ssl/certs" \
    SSL_CERT_FILE="/etc/ssl/certs/ca-certificates.crt" \
    HISTFILE="/dev/null"

WORKDIR /usr/local/searxng-space/
ENTRYPOINT ["/usr/bin/sh"]

FROM base/archlinux

MAINTAINER kfei <kfei@kfei.net>

RUN pacman -Syy && \
    pacman -S --noconfirm --quiet --needed base-devel curl libunistring && \
    pacman -S --noconfirm --quiet --needed --asdeps git jshon expac

ADD build.sh /

ENTRYPOINT ["/build.sh"]

VOLUME /dist

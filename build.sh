#!/usr/bin/env bash 
#
# This script is a fork from:
# https://github.com/jprjr/docker-misc/blob/s6-builder/dockerfiles/arch-s6-builder/build.sh
#
# Official build instructions are available at:
# http://www.skarnet.org/software/s6/install.html

set -e
set -x

musl_version=1.0.4
skalibs_version=1.6.0.0
execline_version=1.3.1.1
s6_version=1.1.3.2

function build_skarnet_package {
  echo musl-gcc                 > conf-compile/conf-cc
  echo musl-gcc -static         > conf-compile/conf-ld
  echo musl-gcc                 > conf-compile/conf-dynld
  echo /usr/bin                 > conf-compile/conf-install-command
  rm -f conf-compile/flag-slashpackage
  touch conf-compile/flag-allstatic
  package/compile
  rm -f package/library.so.exported
}

function install_skarnet_package {
  for i in package/*.exported 
  do
    case $(basename $i) in
    library.so.exported) d=/lib                    ;;
    include.exported)    d=/usr/include/skalibs    ;;
    sysdeps.exported)    d=/usr/lib/skalibs/sysdeps;;
    library.exported)    d=/usr/lib/skalibs        ;;
    command.exported)    d=/usr/bin                ;;
    esac
    f=$(basename $i|sed 's/.exported//')
    mkdir -p $1$d
    install -D `sed s,^,$f/, $i` "$1$d"
  done
}

mkdir /package  

mkdir -p /build && cd /build

# install musl
curl -R -L -O http://www.musl-libc.org/releases/musl-${musl_version}.tar.gz
tar xf musl-${musl_version}.tar.gz
cd musl-${musl_version}

CFLAGS="-fno-toplevel-reorder -fno-stack-protector" ./configure --prefix=/usr/musl --exec-prefix=/usr --disable-shared
make
make install

# install skalibs
cd /build
curl -R -L -O http://skarnet.org/software/skalibs/skalibs-${skalibs_version}.tar.gz
tar xf skalibs-${skalibs_version}.tar.gz
cd prog/skalibs-${skalibs_version}

# configure skalibs-specific items
echo /usr/lib/skalibs         > conf-compile/conf-install-library
echo /usr/include/skalibs     > conf-compile/conf-install-include
echo /usr/lib/skalibs/sysdeps > conf-compile/conf-install-sysdeps

build_skarnet_package 
install_skarnet_package

install -D -m644 etc/leapsecs.dat /etc/leapsecs.dat

#install execline
cd /build
curl -R -L -O http://skarnet.org/software/execline/execline-${execline_version}.tar.gz
tar xf execline-${execline_version}.tar.gz
cd admin/execline-${execline_version}

# configure execline-specific items
echo /usr/lib/skalibs/sysdeps > conf-compile/import
echo /usr/libexec/execline    > conf-compile/conf-install-command
echo /usr/lib/execline        > conf-compile/conf-install-library
echo /usr/include/execline    > conf-compile/conf-install-include
echo /usr/include/skalibs     > conf-compile/path-include
echo /usr/lib/skalibs         > conf-compile/path-library

build_skarnet_package
install_skarnet_package
install_skarnet_package /package
rm -rf /package/usr/lib
rm -rf /package/usr/include
XZ_OPT=-9 tar -Jcf /dist/execline-${execline_version}-musl-static.tar -C /package .
rm -rf /package/*

# install s6
cd /build
curl -R -L -O http://www.skarnet.org/software/s6/s6-${s6_version}.tar.gz
tar xf s6-${s6_version}.tar.gz
cd admin/s6-${s6_version}

echo /usr/lib                 > conf-compile/conf-install-library
echo /usr/include             > conf-compile/conf-install-include
echo /usr/lib/skalibs/sysdeps > conf-compile/import
echo /usr/include/skalibs     > conf-compile/path-include
echo /usr/include/execline    >>conf-compile/path-include
echo /usr/lib/skalibs         > conf-compile/path-library
echo /usr/lib/execline        >>conf-compile/path-library

build_skarnet_package
install_skarnet_package /package
install -D -m644 /etc/leapsecs.dat /package/etc/leapsecs.dat
rm -rf /package/usr/lib
rm -rf /package/usr/include
XZ_OPT=-9 tar -Jcf /dist/s6-${s6_version}-musl-static.tar.xz -C /package .

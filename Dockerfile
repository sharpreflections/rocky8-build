###############################################################################
# Parameters
###############################################################################

ARG prefix=/opt
ARG qt_prefix=/p

###############################################################################
# Base Image
###############################################################################

FROM quay.io/sharpreflections/rocky8-build-base AS base

###############################################################################
# Clazy Image
###############################################################################

FROM base AS build-clazy
WORKDIR /build/
RUN yum -y install git make cmake gcc gcc-c++ llvm-devel clang-devel && \
    git clone https://github.com/KDE/clazy.git --branch 1.15 && \
    mkdir clazy-build && cd clazy-build && \
    cmake ../clazy -DUSER_LIBS=-lstdc++fs -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/opt/clazy-1.15 && \
    make --jobs=$(nproc --all) && make install && \
    rm -rf /build/*

###############################################################################
# Builder Image
###############################################################################

FROM base AS builder

RUN yum -y install 'dnf-command(config-manager)' \
 && yum config-manager --enable powertools \
 && yum -y clean all \
 && yum -y upgrade \
 && yum -y install \
# our build dependencies \
        xorg-x11-server-utils \
        libX11-devel \
        libSM-devel \
        libxml2-devel \
        libGL-devel \
        libGLU-devel \
        libibverbs-devel \
        freetype-devel \
        which \
        libXtst \
        libXext-devel \
        autoconf \
        automake \
        libtool \
        patch \
        bison \
        flex \
        tcl \
        rpm-build \
        nss-devel \
# we need some basic fonts and manpath for the mklvars.sh script
        urw-fonts \
        man \
# clang, gcc and svn
        make \
        cmake3 \
        gcc-c++ \
        libatomic \
        libgomp \
        libomp-devel \
# Misc (developer) tools and xvfb for QTest
        strace \
        valgrind \
        bc \
        vim \
        nano \
        mc \
        psmisc \
        xorg-x11-server-Xvfb \
        libXcomposite \
        wget \
        python3-pip \
# For Squish
        tigervnc-server \
        nc \
	@llvm-toolset \
	gcc-toolset-9 \
	clang-tools-extra \
	ninja-build \
&& yum -y clean all --enablerepo='*' \
# python2 installation for building mesa...
&& wget https://www.python.org/ftp/python/2.7.18/Python-2.7.18.tgz \
&& tar -xvf Python-2.7.18.tgz \
&& cd Python-2.7.18/ \
&& ./configure \
&& make -j24 \
&& make altinstall \
# install numpy and scipy python packages
# python3
&& pip3 install numpy \
&& pip3 install scipy

###############################################################################
# Final Image
###############################################################################
FROM builder

WORKDIR /

RUN mkdir /p

COPY --from=quay.io/sharpreflections/centos7-build-protobuf /opt /opt
COPY --from=quay.io/sharpreflections/centos7-build-qt /p /p
COPY --from=build-clazy    /opt /opt
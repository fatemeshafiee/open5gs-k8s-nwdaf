FROM ubuntu:22.04 AS builder

ENV DEBIAN_FRONTEND=noninteractive
ENV LD_LIBRARY_PATH=/open5gs/install/lib/x86_64-linux-gnu
WORKDIR /microhttpd-build
RUN apt-get update && apt-get install -y wget
RUN apt-get install binutils binutils-common -y
RUN apt-get install make build-essential -y
RUN wget https://ftp.gnu.org/gnu/libmicrohttpd/libmicrohttpd-1.0.1.tar.gz
RUN tar -xzvf libmicrohttpd-1.0.1.tar.gz
RUN (cd libmicrohttpd-1.0.1 && ./configure && make install)

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
    python3-pip python3-setuptools python3-wheel \
    ninja-build build-essential flex bison git cmake \
    libsctp-dev libgnutls28-dev libgcrypt-dev libssl-dev \
    libidn11-dev libmongoc-dev libbson-dev libyaml-dev \
    libnghttp2-dev libmicrohttpd-dev libcurl4-gnutls-dev \
    libtins-dev libtalloc-dev meson
RUN apt-get update && \
    apt-get install -y make nginx libjansson-dev gdb libcurl4-openssl-dev libcurl4-openssl-dev
WORKDIR /open5gs

RUN git clone -b main https://fatemeshafiee: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@github.com/fatemeshafiee/open5gs .  && \ 
git checkout 4006d907c21a8666bafccd68cbd5a109889b3ae9

ENV CFLAGS="-Wno-error"
ENV CXXFLAGS="-Wno-error"
RUN meson build --prefix=/open5gs/install -DfreeDiameter:werror=false -Dprometheus-client-c:werror=false \
    && CFLAGS="-Wno-error" CXXFLAGS="-Wno-error" ninja -C build \
    && CFLAGS="-Wno-error" CXXFLAGS="-Wno-error" ninja -C build install

FROM ubuntu:22.04
ENV DEBIAN_FRONTEND=noninteractive
ENV LD_LIBRARY_PATH=/open5gs/install/lib/x86_64-linux-gnu

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
    libsctp-dev libgnutls28-dev libgcrypt-dev libssl-dev \
    libidn11-dev libmongoc-dev libbson-dev libyaml-dev \
    libnghttp2-dev libmicrohttpd-dev libcurl4-gnutls-dev \
    libtins-dev libtalloc-dev ca-certificates \
    vim tcpdump iputils-ping iproute2 iptables \
    && apt-get autoremove -y && apt-get autoclean

RUN apt-get install binutils binutils-common -y
RUN apt-get install make build-essential -y
RUN apt-get install wget -y


WORKDIR /microhttpd-build
RUN wget https://ftp.gnu.org/gnu/libmicrohttpd/libmicrohttpd-1.0.1.tar.gz
RUN tar -xzvf libmicrohttpd-1.0.1.tar.gz
RUN (cd libmicrohttpd-1.0.1 && ./configure && make install)

RUN apt-get install libjansson-dev  -y
RUN apt-get install libcurl4-openssl-dev libcurl4-openssl-dev  -y

RUN mkdir -p /open5gs/install
RUN update-ca-certificates

WORKDIR /open5gs/install/bin

COPY --from=builder /open5gs/install /open5gs/install
COPY --from=builder /open5gs/install/etc /etc/open5gs/


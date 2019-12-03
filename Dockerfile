FROM ubuntu:18.04
MAINTAINER MIJ <https://github.com/mijinc0>

###########
#  build  #
###########

WORKDIR /tmp

# --no-install-recommendsは付けないこと。
RUN apt-get update -y && apt-get upgrade -y && apt-get install -y \
 autoconf \
 libtool \
 curl \
 git \
 xz-utils \
 libatomic-ops-dev \
 libunwind-dev \
 gdb \
 libgflags-dev \
 libsnappy-dev \
 ninja-build \
 python3 \
 python3-ply

# gcc9
RUN apt-get install software-properties-common \
 add-apt-repository ppa:ubuntu-toolchain-r/test \
 apt-get update \
 apt-get install g++-9-multilib \
 update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-9 30 \
 update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-9 30

# cmake(at least 3.14)
RUN curl -o cmake-3.15.2.tar.gz -SL https://github.com/Kitware/CMake/releases/download/v3.15.2/cmake-3.15.2.tar.gz \
 tar -zxvf cmake-3.15.2.tar.gz \
 cd cmake-3.15.2 \
 ./bootstrap \
 make \
 make install

# install boost
RUN curl -o boost_1_71_0.tar.gz -SL https://dl.bintray.com/boostorg/release/1.71.0/source/boost_1_71_0.tar.gz \
 && tar -xzf boost_1_71_0.tar.gz \
 && mkdir boost-build-1.71.0 \
 && cd boost_1_71_0 \
 && ./bootstrap.sh --prefix=/tmp/boost-build-1.71.0/ \
 && ./b2 --prefix=/tmp/boost-build-1.71.0 --without-python -j 4 stage release \
 && ./b2 install --prefix=/tmp/boost-build-1.71.0 --without-python \
 && cd /tmp

# install google test
RUN git clone https://github.com/google/googletest.git googletest.git \
 && cd googletest.git/ \
 && git checkout release-1.8.1 \
 && mkdir _build \
 && cd _build \
 && cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_POSITION_INDEPENDENT_CODE=ON .. \
 && make \
 && make install \
 && cd /tmp

# install google benchmark
RUN git clone https://github.com/google/benchmark.git google.benchmark.git \
 && cd google.benchmark.git \
 && git checkout v1.5.0 \
 && mkdir _build \
 && cd _build \
 && cmake -DCMAKE_BUILD_TYPE=Release -DBENCHMARK_ENABLE_GTEST_TESTS=OFF .. \
 && make \
 && make install \
 && cd /tmp

# install mongo c
RUN git clone https://github.com/mongodb/mongo-c-driver.git mongo-c-driver.git \
 && cd mongo-c-driver.git \
 && git checkout 1.15.1 \
 && mkdir _build \
 && cd _build \
 && cmake -DENABLE_AUTOMATIC_INIT_AND_CLEANUP=OFF -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr/local .. \
 && make \
 && make install \
 && cd /tmp

# install mongo cxx (nem)
RUN git clone https://github.com/nemtech/mongo-cxx-driver.git mongo-cxx-driver.git\
 && cd mongo-cxx-driver.git \
 && git checkout r3.4.0-nem \
 && mkdir _build \
 && cd _build \
 && cmake -DCMAKE_CXX_STANDARD=17 -DLIBBSON_DIR=/usr/local -DLIBMONGOC_DIR=/usr/local -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr/local .. \
 && make \
 && make install \
 && cd /tmp

# install lib zmq
RUN git clone git://github.com/zeromq/libzmq.git libzmq.git \
 && cd libzmq.git \
 && git checkout v4.3.2 \
 && mkdir _build \
 && cd _build \
 && cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr/local .. \
 && make install \
 && cd /tmp

# install cpp zmq
RUN git clone https://github.com/zeromq/cppzmq.git cppzmq.git \
 && cd cppzmq.git \
 && git checkout v4.4.1 \
 && mkdir _build \
 && cd _build \
 && cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr/local .. \
 && make \
 && make install \
 && cd /tmp

# install rocks db
RUN git clone https://github.com/nemtech/rocksdb.git rocksdb.git \
 && cd rocksdb.git \
 && git checkout v6.2.4-nem \
 && mkdir _build \
 && cd _build \
 && cmake -DCMAKE_BUILD_TYPE=Release -DWITH_TESTS=OFF -DCMAKE_INSTALL_PREFIX=/usr/local .. \
 && make \
 && make install \
 && cd /tmp

# build catapult
RUN git clone https://github.com/nemtech/catapult-server.git -b v0.9.0.1
# && cd catapult-server \
# && mkdir _build \
# && cd _build \
# && cmake -DBOOST_ROOT=/tmp/boost-build-1.71.0 -DCMAKE_BUILD_TYPE=Release -G Ninja .. \
# && ninja publish \
# && ninja -j4 \
# && cd /tmp

RUN /bin/bash

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
 cmake \
 curl \
 git \
 xz-utils \
 libatomic-ops-dev \
 libunwind-dev \
 g++ \
 gdb \
 libgflags-dev \
 libsnappy-dev \
 ninja-build \
 python3 \
 python3-ply

# install boost
RUN curl -o boost_1_69_0.tar.gz -SL https://dl.bintray.com/boostorg/release/1.69.0/source/boost_1_69_0.tar.gz \
 && tar -xzf boost_1_69_0.tar.gz \
 && mkdir boost-build-1.69.0 \
 && cd boost_1_69_0 \
 && ./bootstrap.sh --prefix=/tmp/boost-build-1.69.0/ \
 && ./b2 --prefix=/tmp/boost-build-1.69.0 -j 4 stage release \
 && ./b2 install --prefix=/tmp/boost-build-1.69.0 \
 && cd /tmp

# install google test
RUN git clone https://github.com/google/googletest.git googletest.git \
 && cd googletest.git/ \
 && git checkout release-1.8.0 \
 && mkdir _build \
 && cd _build \
 && cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_POSITION_INDEPENDENT_CODE=ON .. \
 && make \
 && make install \
 && cd /tmp

# install google benchmark
RUN git clone https://github.com/google/benchmark.git google.benchmark.git \
 && cd google.benchmark.git \
 && git checkout v1.4.1 \
 && mkdir _build \
 && cd _build \
 && cmake -DCMAKE_BUILD_TYPE=Release -DBENCHMARK_ENABLE_GTEST_TESTS=OFF .. \
 && make \
 && make install \
 && cd /tmp

# install mongo c
RUN git clone https://github.com/mongodb/mongo-c-driver.git mongo-c-driver.git \
 && cd mongo-c-driver.git \
 && git checkout 1.13.0 \
 && mkdir _build \
 && cd _build \
 && cmake -DENABLE_AUTOMATIC_INIT_AND_CLEANUP=OFF -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr/local .. \
 && make \
 && make install \
 && cd /tmp

# install mongo cxx
RUN git clone https://github.com/mongodb/mongo-cxx-driver.git mongo-cxx-driver.git \
 && cd mongo-cxx-driver.git \
 && git checkout r3.4.0 \
 && sed -i 's/kvp("maxAwaitTimeMS", count)/kvp("maxAwaitTimeMS", static_cast<int64_t>(count))/' src/mongocxx/options/change_stream.cpp \
 && mkdir _build \
 && cd _build \
 && cmake -DLIBBSON_DIR=/usr/local -DBOOST_ROOT=/tmp/boost-build-1.69.0 -DLIBMONGOC_DIR=/usr/local -DBSONCXX_POLY_USE_BOOST=1 -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr/local .. \
 && make \
 && make install \
 && cd /tmp

# install lib zmq
RUN git clone git://github.com/zeromq/libzmq.git libzmq.git \
 && cd libzmq.git \
 && mkdir _build \
 && cd _build \
 && cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr/local .. \
 && make install \
 && cd /tmp

# install cpp zmq
RUN git clone https://github.com/zeromq/cppzmq.git cppzmq.git \
 && cd cppzmq.git \
 && mkdir _build \
 && cd _build \
 && cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr/local .. \
 && make \
 && make install \
 && cd /tmp

# install rocks db
RUN git clone https://github.com/facebook/rocksdb.git rocksdb.git \
 && cd rocksdb.git \
 && git checkout -B "5.18.fb" "origin/5.18.fb" \
 && mkdir _build \
 && cd _build \
 && cmake -DCMAKE_BUILD_TYPE=Release -DWITH_TESTS=OFF -DCMAKE_INSTALL_PREFIX=/usr/local .. \
 && make \
 && make install \
 && cd /tmp

# build catapult
RUN mkdir catapult-server
COPY catapult-server /tmp/catapult-server/

RUN cd catapult-server \
 && mkdir _build \
 && cd _build \
 && cmake -DBOOST_ROOT=/tmp/boost-build-1.69.0 -DCMAKE_BUILD_TYPE=Release -G Ninja .. \
 && ninja publish \
 && ninja -j4 \
 && cd /tmp

# ここまでは https://github.com/nemtech/catapult-server/blob/master/BUILDING.md に書いてあるとおり。

######################
#  generate nemesis  #
######################

WORKDIR /tmp/catapult-server/_build/bin

# config群のコピー
COPY nemgen_properties /tmp/catapult-server/_build/resources/
COPY node_configs/resources /tmp/catapult-server/_build/resources/

# ブロックデータが入るディレクトリを生成する
RUN mkdir -p /tmp/catapult-server/_build/data/00000

# nemesis blockが生成されるディレクトリを生成する
RUN mkdir -p /tmp/catapult-server/_build/seed/mijin-test/00000

# hashes.datを生成
RUN touch touch /tmp/catapult-server/_build/seed/mijin-test/00000/hashes.dat \
  && echo -n 0000000000000000000000000000000000000000000000000000000000000000 > /tmp/catapult-server/_build/seed/mijin-test/00000/hashes.dat

# catapult.tools.nemgenによりnemesis blockを生成
RUN /tmp/catapult-server/_build/bin/catapult.tools.nemgen -r /tmp/catapult-server/_build/ -p /tmp/catapult-server/_build/resources/nemgen.properties

# 生成されたnemesis blockデータを移す
RUN cp /tmp/catapult-server/_build/seed/mijin-test/00000/* /tmp/catapult-server/_build/data/00000/

###########
#  after  #
###########

# この後は各ノード、ネットワークの設定と、ハーベスティングの設定をする。
# config-node.properties       : portなど
# cat peers-p2p.json           : 初期接続ノードの登録(Peerノードはこっち)
# cat peers-p2p.json           : 初期接続ノードの登録(Apiノードはこっち)
# config-harvesting.properties : 初期分配で設定したハーベスト対象モザイクを持つアドレスの秘密鍵を設定

# 起動は /tmp/catapult-server/_build/bin/catapult.server

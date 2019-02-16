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
RUN curl -o boost_1_64_0.tar.gz -SL https://dl.bintray.com/boostorg/release/1.64.0/source/boost_1_64_0.tar.gz \
 && tar -xzf boost_1_64_0.tar.gz \
 && mkdir boost-build-1.64.0 \
 && cd boost_1_64_0 \
 && ./bootstrap.sh --prefix=/tmp/boost-build-1.64.0/ \
 && ./b2 --prefix=/tmp/boost-build-1.64.0 -j 4 stage release \
 && ./b2 install --prefix=/tmp/boost-build-1.64.0 \
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
 && cmake -DLIBBSON_DIR=/usr/local -DBOOST_ROOT=/tmp/boost-build-1.64.0 -DLIBMONGOC_DIR=/usr/local -DBSONCXX_POLY_USE_BOOST=1 -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr/local .. \
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
 && mkdir _build \
 && cd _build \
 && cmake -DCMAKE_BUILD_TYPE=Release -DWITH_TESTS=OFF -DCMAKE_INSTALL_PREFIX=/usr/local .. \
 && make \
 && make install \
 && cd /tmp

# build catapult
RUN git clone https://github.com/nemtech/catapult-server.git \
 && cd catapult-server \
 && mkdir _build \
 && cd _build \
 && cmake -DBOOST_ROOT=/tmp/boost-build-1.64.0 -DCMAKE_BUILD_TYPE=Release -G Ninja .. \
 && ninja publish \
 && ninja -j4 \
 && cd /tmp

# ここまでは https://github.com/nemtech/catapult-server/blob/master/BUILDING.md に書いてあるとおり。

######################
#  generate nemesis  #
######################

WORKDIR /tmp/catapult-server/_build/bin

# config群のコピー
RUN cp /tmp/catapult-server/resources/* /tmp/catapult-server/_build/resources

# ブロックデータが入るディレクトリを生成する
RUN mkdir -p /tmp/catapult-server/_build/data/00000

# nemesis blockの作成
# 作成用のpropertiesファイルをコピー
RUN cp /tmp/catapult-server/tools/nemgen/resources/mijin-test.properties /tmp/catapult-server/_build/resources/

# nemesis block生成用ファイルを編集する

# cppFile の値部分は不要
RUN sed '18ccppFile =' -i /tmp/catapult-server/_build/resources/mijin-test.properties

# いくつかの初期分配アドレスを置換

# [distribution>cat:currency]

# private key: 8090859AAD6F6BFCEFC01CDA254B5725AD6BDEC57B8C3AB3ED67F70866672140
#  public key: 13FE2C16845AFAC934099BE4EF4B55445733650D484ECC9B680071008CED047E
RUN sed -e 's/SAAA244WMCB2JXGNQTQHQOS45TGBFF4V2MJBVOUI/SCWWMIHGPBVMH7KYPTOBJX5HEOIWCXZHYW46MIOX/g' -i /tmp/catapult-server/_build/resources/mijin-test.properties

# private key: 43EE8DCCFEE1DA19550CC7E1DAECE4B4BACDE3EE148972D1280177F5E43032F2
#  public key: AEC221105D04DE2BF15AD847CDA89D115AE46443DBD9B65E8C47B6679E1B81CF
RUN sed -e 's/SAAA34PEDKJHKIHGVXV3BSKBSQPPQDDMO2ATWMY3/SBAPZWUKMYGGXRDSGSZM3OB7HQOFYE2TZILY4BPC/g' -i /tmp/catapult-server/_build/resources/mijin-test.properties

# private key: 428D9BDB8E17CC89799A4760BAB6DFAD8E46052CC9A074CB0FBFB397B1C30967
#  public key: 539FF9A764B79311D71C4A08F78AA80BF8DAC353CAB9AD789C58FA5819CC8162
RUN sed -e 's/SAAA467G4ZDNOEGLNXLGWUAXZKC6VAES74J7N34D/SDTXXRKGMM6A3TWB6XBSPOAH4QPNWUEXUPIO33F6/g' -i /tmp/catapult-server/_build/resources/mijin-test.properties

# private key: 203FE70724C14DD370C00A09D6D01D94E12C040A4A8F78F4F66339B97B970D43
#  public key: EBD7C7F2CE6E3C260733AD2310245A9C283EB157884F31002D3FEBAD08676146
RUN sed -e 's/SAAA57DREOPYKUFX4OG7IQXKITMBWKD6KXTVBBQP/SCLBJF66DOPGBHCQJXI4LCIIXNFHAIH3XVWAH3II/g' -i /tmp/catapult-server/_build/resources/mijin-test.properties

# [distribution>cat:harvest]

# private key: 100A4A72DA5F41D06B5F2A0C37F0F57C60E9C8A05BEECDD5EDF74015FDD280DE
#  public key: 8FAF52338697C307B2F7C8B2CAE9FE8A75B8290E531B3E9EA775E6FEABC69F55
RUN sed -e 's/SCWWMIHGPBVMH7KYPTOBJX5HEOIWCXZHYW46MIOX/SD3UKYBC25RU6TZY3U36ONAQU34EOX6I3FZSGH7F/g' -i /tmp/catapult-server/_build/resources/mijin-test.properties

# private key: 356EA5D7DE972DB12D65078B523F053AE19842AD8EF795A8380321294A3FB4D4
#  public key: 9048FCA9442ADD2C7C81F7357EABFADC235A5F3F77CECDB427C6986DE362D2EF
RUN sed -e 's/SAAA34PEDKJHKIHGVXV3BSKBSQPPQDDMO2ATWMY3/SBVX7EW3DMP3ZMSSSWUDZTA63SKW6CSEVFV5XF6I/g' -i /tmp/catapult-server/_build/resources/mijin-test.properties

# private key: F2A8F02C16E07A0DB87FD8C7B76C96B53F635DBC4B3BF6455BAA627AB9AD6E0B
#  public key: 5F215A966A1B1926DC59539F8C862E3D1E1887550EDE720785C10875358AC88F
RUN sed -e 's/SAAA467G4ZDNOEGLNXLGWUAXZKC6VAES74J7N34D/SAQM2ARFLOHJ4WP5QZE3YJRNS36XUCZZBERMZLF4/g' -i /tmp/catapult-server/_build/resources/mijin-test.properties

# config-networkのtotalChainImportanceと[mosaic>cat:harvest]の数値を合わせる
# (SAAA66EEZKK3HGBRV57E6TOK335NK22BF2KGOEDS の供給量を減らして調整)
RUN sed '75y/17'000'000/15'000'000/' -i /tmp/catapult-server/_build/resources/mijin-test.properties \
 && sed '86y/4'000'000/2'000'000/' -i /tmp/catapult-server/_build/resources/mijin-test.properties

# nemesis blockが生成されるディレクトリを生成する
RUN mkdir -p /tmp/catapult-server/_build/seed/mijin-test/00000

# hashes.datを生成
RUN touch touch /tmp/catapult-server/_build/seed/mijin-test/00000/hashes.dat \
  && echo -n 0000000000000000000000000000000000000000000000000000000000000000 > /tmp/catapult-server/_build/seed/mijin-test/00000/hashes.dat

# catapult.tools.nemgenによりnemesis blockを生成
RUN /tmp/catapult-server/_build/bin/catapult.tools.nemgen -r /tmp/catapult-server/_build/ -p /tmp/catapult-server/_build/resources/mijin-test.properties

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

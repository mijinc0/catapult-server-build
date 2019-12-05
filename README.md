**catapult server Githubリポジトリ**  
https://github.com/nemtech/catapult-server

**catapult serverのビルド手順**  
https://github.com/nemtech/catapult-server/blob/master/BUILDING.md

# catapult version

`version : 0.9.0.1`

# Dockerイメージのビルド

Dokcerfileのあるディレクトリ上で`docker build .`

# Nemesisブロック(最初のブロック)の生成からサーバーの起動、ハーベスティングまで

作業ディレクトリ : `catapult-server/_build/bin`

```no_attr
// configファイル群のコピー
$ cp ../../resources/* ../resources/
$ cp ../../tools/nemgen/resources/mijin-test.properties ../resources/

// ディレクトリの用意
$ mkdir -p ../data/00000 ../seed/mijin-test/00000

// アドレスを用意
$ ./catapult.tools.address -n mijin-test > ../address.txt

// nemesis設定ファイルの書き換え(詳細は下記)
$ vim ../resources/mijin-test.properties

// モザイクIDの確認(詳細は下記)
$ ./catapult.tools.nemgen -p ../resources/mijin-test.properties

// network設定ファイルの書き換え(詳細は下記)
$ vim ../resources/config-network.properties

// hashes.datの作成
$ dd if=/dev/zero of=../seed/mijin-test/00000/hashes.dat bs=64 count=1

// nemesisブロックの生成
$ ./catapult.tools.nemgen -p ../resources/mijin-test.properties

// nemesisブロックデータの移植
$ cp -r ../seed/mijin-test/* ../data/

// ハーベスティン設定ファイルの書き換え(詳細は下記)
$ vim ../resources/config-harvesting.properties

// サーバーの起動
$ ./catapult.server
```

### nemesis設定ファイルの書き換え

nemesisGenerationHash = (address.txtから好きなものに)  

nemesisSignerPrivateKey = (address.txtから好きなものに)

cppFile =  
※削除

4いくつかのアドレスを生成したものに書き換える

### モザイクIDの確認

出力ログの`Mosaic Summary`より確認。

```
2019-06-30 07:05:11.699398 0x00007f7e2f7e7180: <debug> (nemgen::NemesisConfigurationLoader.cpp@57) Mosaic Summary
2019-06-30 07:05:11.699432 0x00007f7e2f7e7180: <debug> (nemgen::NemesisConfigurationLoader.cpp@32)  - cat:currency (0DC67FBE1CAD29E3)
2019-06-30 07:05:11.699471 0x00007f7e2f7e7180: <debug> (nemgen::NemesisConfigurationLoader.cpp@66)  - Owner: B4F12E7C9F6946091E2CB8B6D3A12B50D17CCBBF646386EA27CE2946A7423DCF
 - Supply: 8999999998000000
 - Divisibility: 6
 - Duration: 0 blocks (0 = eternal)
 - IsTransferable: true
 - IsSupplyMutable: falseｖ


2019-06-30 07:05:11.699530 0x00007f7e2f7e7180: <debug> (nemgen::NemesisConfigurationLoader.cpp@32)  - cat:harvest (26514E2A1EF33824)
2019-06-30 07:05:11.699569 0x00007f7e2f7e7180: <debug> (nemgen::NemesisConfigurationLoader.cpp@66)  - Owner: B4F12E7C9F6946091E2CB8B6D3A12B50D17CCBBF646386EA27CE2946A7423DCF
 - Supply: 17000000
 - Divisibility: 3
 - Duration: 0 blocks (0 = eternal)
 - IsTransferable: true
 - IsSupplyMutable: true
```

上記の場合、`cat:currency (0DC67FBE1CAD29E3)`、`cat:harvest (26514E2A1EF33824)`により確認。括弧内のhex文字列がモザイクID。

### ネットワーク設定ファイルの書き換え

publicKey = (nemesis設定ファイルの10行目の秘密鍵に対応する公開鍵)

generationHash = (nemesis設定ファイルの9行目と同じ値)

currencyMosaicId = (上記で確認したモザイクID)

harvestingMosaicId = (上記で確認したモザイクID)

initialCurrencyAtomicUnits = 8'999'999'998'000'000
※ 少し値が違うことがあるので、nemesisファイルの`cat:currency`の総量合わせる

totalChainImportance = 17'000'000
※ 少し値が違うことがあるので、nemesisファイルの`cat:harvest`の総量に合わせる

### ハーベスティング設定ファイルの書き換え

harvestKey = (`cat:harvest`を保持するアドレスに対応する秘密鍵)

isAutoHarvestingEnabled = true

# その他、設定でよく触るところ

### config-node.properties

```no_attr
47 [localnode]
48
49 host = ホストのアドレス
50 friendlyName = 名前（何でも良い）
51 version = 0
52 roles = Peer (Apiにしたいときは書き換える)
```

### config-user.properties

```no_attr
1 [account]
2
3 # keys should look like 3485D98EFD7EB07ADAFCFD1A157D89DE2796A95E780813C0258AF3F5F84ED8CB
4 bootKey = 32byte分のhex
```

### config-logging-XXX.properties

各ファイル（`server`,`broker`,`recovery`）の`level`を`Info`から`Debug`に書き換える。これで、より詳細なログが出力される。

### peers-api.json,peers-p2p.json

初期接続ノードの情報を書く。

# 注意

### nemesisブロック生成に関して

nemesisブロック生成時、nemesis設定ファイルとネットワーク設定ファイルの内容に矛盾が生じると、 **nemesisブロックは生成されるが実行時にエラーが出る** 現象がよく起きる。  
実行時エラーの内容だけでは何が原因かわかりにくいので、nemesisブロック生成時は矛盾が生じないように注意すること。

### よく見るエラー

#### Throwing exception: harvesting outflows (XXX) do not add up to power ten multiple of expected importance (XXX)  

ネットワーク設定ファイルの`harvestingMosaicId`または`totalChainImportance`が間違っている。

```no_attr
2019-06-30 07:26:33.263016 0x00007f51ae0e1000: <info> (plugins::PluginLoader.cpp@50) registering dynamic plugin catapult.plugins.transfer
2019-06-30 07:26:33.263384 0x00007f51ae0e1000: <info> (utils::StackLogger.h@35) pushing scope 'booting local node'
2019-06-30 07:26:33.269218 0x00007f51ae0e1000: <error> (extensions::NemesisBlockLoader.cpp@113) Throwing exception: harvesting outflows (17000000) do not add up to power ten multiple of expected importance (15000000)
2019-06-30 07:26:33.269974 0x00007f51ae0e1000: <info> (utils::StackLogger.h@41) popping scope 'booting local node' (6ms)
2019-06-30 07:26:33.270131 0x00007f51ae0e1000: <fatal> (local::HostUtils.h@42) unhandled exception while boot!
../src/catapult/extensions/NemesisBlockLoader.cpp(113): Throw in function void catapult::extensions::{anonymous}::CheckImportanceAndBalanceConsistency(catapult::Importance, catapult::Amount)
Dynamic exception type: boost::wrapexcept<catapult::catapult_error<std::invalid_argument> >
std::exception::what: harvesting outflows (17000000) do not add up to power ten multiple of expected importance (15000000)

2019-06-30 07:26:33.270479 0x00007f51ae0e1000: <error> (local::HostUtils.h@43) Throwing exception: harvesting outflows (17000000) do not add up to power ten multiple of expected importance (15000000)
2019-06-30 07:26:33.270745 0x00007f51ae0e1000: <fatal> (process::ProcessMain.cpp@64)
thread: Process Main (s
unhandled exception while running local node!
../src/catapult/local/HostUtils.h(43): Throw in function std::unique_ptr<_Tp> catapult::local::CreateAndBootHost(TArgs&& ...) [with THost = catapult::local::{anonymous}::DefaultLocalNode; TArgs = {std::unique_ptr<catapult::extensions::ProcessBootstrapper, std::default_delete<catapult::extensions::ProcessBootstrapper> >, const catapult::crypto::KeyPair&}]
Dynamic exception type: boost::wrapexcept<catapult::catapult_error<std::runtime_error> >
std::exception::what: harvesting outflows (17000000) do not add up to power ten multiple of expected importance (15000000)
```

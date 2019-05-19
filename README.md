This is not official. Personal.

## testnet

Nodes built with this Dockerfile connect to the following testnet.

https://github.com/AnthonyLaw/catapult-service-bootstrap/tree/testnet-node

## catapult server version

v0.3.0.2

## usage

```no_attr
$ git clone -b testnet git@github.com:mijinc0/try_to_start_catapult_cow.git

# you should change version if you need.

$ cd try_to_start_catapult_cow

$ git clone https://github.com/nemtech/catapult-server.git

$ docker build .
```

And you will have to set `bootkey`,`known peer`,`node info (like a friendly-name)` in configs.

```no_attr
# start server
/tmp/catapult-server/_build/bin$ ./catapult.server
```

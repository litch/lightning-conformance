#!/bin/bash

docker exec bitcoin bitcoin-cli -datadir=config createwallet rpcwallet
docker exec bitcoin bitcoin-cli -datadir=config -rpcwallet=rpcwallet -generate=100



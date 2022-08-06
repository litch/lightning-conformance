#!/bin/bash

docker exec bitcoin bitcoin-cli -datadir=config createwallet rpcwallet

address=$(docker exec bitcoin bitcoin-cli -rpcwallet=rpcwallet --datadir=config getnewaddress)

docker exec bitcoin bitcoin-cli --datadir=config generatetoaddress 100 $address

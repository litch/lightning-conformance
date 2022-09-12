#!/bin/bash

numblocks=$1

if [ -z  $numblocks ]; then
  while true; do
    docker exec bitcoin bitcoin-cli -datadir=config -rpcwallet=rpcwallet -generate=1
    sleep 30 
  done
else
  address=$(docker exec bitcoin bitcoin-cli -rpcwallet=rpcwallet --datadir=config getnewaddress)

  docker exec bitcoin bitcoin-cli --datadir=config generatetoaddress $numblocks $address
fi

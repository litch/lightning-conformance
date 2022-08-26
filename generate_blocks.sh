#!/bin/bash

while true; do
    docker exec bitcoin bitcoin-cli -datadir=config -rpcwallet=rpcwallet -generate=1
    sleep 30 
done

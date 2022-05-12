#!/bin/bash

while true; do
    docker exec bitcoin bitcoin-cli -datadir=config -rpcwallet=rpcwallet -generate=1 >> output.txt
    sleep 10
done

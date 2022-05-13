#!/bin/bash

addr=$(docker exec cln-remote lightning-cli --network=regtest newaddr bech32 | jq '.bech32' -r)

docker exec bitcoin bitcoin-cli -datadir=config -rpcwallet=rpcwallet sendtoaddress "$addr" 2

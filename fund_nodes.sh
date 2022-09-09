#!/bin/bash

addr_hub=$(docker exec cln-hub lightning-cli --network=regtest newaddr bech32 | jq '.bech32' -r)
addr_c1=$(docker exec cln-c1 lightning-cli --network=regtest newaddr bech32 | jq '.bech32' -r)

# We send a bunch of transactions in order to generate a bunch of UTXO's on the hub
docker exec bitcoin bitcoin-cli -datadir=config -rpcwallet=rpcwallet sendtoaddress "$addr_hub" 2
docker exec bitcoin bitcoin-cli -datadir=config -rpcwallet=rpcwallet sendtoaddress "$addr_hub" 2
docker exec bitcoin bitcoin-cli -datadir=config -rpcwallet=rpcwallet sendtoaddress "$addr_hub" 2
docker exec bitcoin bitcoin-cli -datadir=config -rpcwallet=rpcwallet sendtoaddress "$addr_hub" 2
docker exec bitcoin bitcoin-cli -datadir=config -rpcwallet=rpcwallet -generate=1
docker exec bitcoin bitcoin-cli -datadir=config -rpcwallet=rpcwallet sendtoaddress "$addr_hub" 2
docker exec bitcoin bitcoin-cli -datadir=config -rpcwallet=rpcwallet sendtoaddress "$addr_hub" 2
docker exec bitcoin bitcoin-cli -datadir=config -rpcwallet=rpcwallet sendtoaddress "$addr_hub" 2
docker exec bitcoin bitcoin-cli -datadir=config -rpcwallet=rpcwallet sendtoaddress "$addr_c1" 2

docker exec bitcoin bitcoin-cli -datadir=config -rpcwallet=rpcwallet -generate=1

addr_r=$(docker exec cln-remote lightning-cli --network=regtest newaddr bech32 | jq '.bech32' -r)

docker exec bitcoin bitcoin-cli -datadir=config -rpcwallet=rpcwallet sendtoaddress "$addr_r" 2

addr_lnd=$(docker exec lnd lncli --network=regtest newaddress p2wkh | jq '.address' -r)
docker exec bitcoin bitcoin-cli -datadir=config -rpcwallet=rpcwallet sendtoaddress "$addr_lnd" 1.5

addr_lnd2=$(docker exec lnd2 lncli --network=regtest newaddress p2wkh | jq '.address' -r)
docker exec bitcoin bitcoin-cli -datadir=config -rpcwallet=rpcwallet sendtoaddress "$addr_lnd2" 3

addr_lnd150=$(docker exec lnd2 lncli --network=regtest newaddress p2wkh | jq '.address' -r)
docker exec bitcoin bitcoin-cli -datadir=config -rpcwallet=rpcwallet sendtoaddress "$addr_lnd150" 3

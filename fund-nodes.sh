#!/bin/bash
source ./variables.sh

addr_hub=$(docker exec cln-hub lightning-cli --network=regtest newaddr bech32 | jq '.bech32' -r)
addr_c1=$(docker exec cln-c1 lightning-cli --network=regtest newaddr bech32 | jq '.bech32' -r)
addr_c3=$(docker exec cln-c3 lightning-cli --network=regtest newaddr bech32 | jq '.bech32' -r)
addr_clnremote=$(docker exec cln-remote lightning-cli --network=regtest newaddr bech32 | jq '.bech32' -r)
addr_spaz=$(docker exec cln-spaz lightning-cli --network=regtest newaddr bech32 | jq '.bech32' -r)
addr_c2=$(docker exec cln-c2 lightning-cli --network=regtest newaddr bech32 | jq '.bech32' -r)

# We send a bunch of transactions in order to generate a bunch of UTXO's on the hub
docker exec bitcoin bitcoin-cli -datadir=config -rpcwallet=rpcwallet sendtoaddress "$addr_hub" 2
docker exec bitcoin bitcoin-cli -datadir=config -rpcwallet=rpcwallet sendtoaddress "$addr_hub" 2
docker exec bitcoin bitcoin-cli -datadir=config -rpcwallet=rpcwallet sendtoaddress "$addr_hub" 2
docker exec bitcoin bitcoin-cli -datadir=config -rpcwallet=rpcwallet sendtoaddress "$addr_hub" 2
docker exec bitcoin bitcoin-cli -datadir=config -rpcwallet=rpcwallet -generate=1
docker exec bitcoin bitcoin-cli -datadir=config -rpcwallet=rpcwallet sendtoaddress "$addr_hub" 2
docker exec bitcoin bitcoin-cli -datadir=config -rpcwallet=rpcwallet sendtoaddress "$addr_hub" 2
docker exec bitcoin bitcoin-cli -datadir=config -rpcwallet=rpcwallet sendtoaddress "$addr_hub" 0.5
docker exec bitcoin bitcoin-cli -datadir=config -rpcwallet=rpcwallet sendtoaddress "$addr_hub" 0.5
docker exec bitcoin bitcoin-cli -datadir=config -rpcwallet=rpcwallet sendtoaddress "$addr_hub" 0.5
docker exec bitcoin bitcoin-cli -datadir=config -rpcwallet=rpcwallet sendtoaddress "$addr_hub" 0.5
docker exec bitcoin bitcoin-cli -datadir=config -rpcwallet=rpcwallet sendtoaddress "$addr_hub" 0.5
docker exec bitcoin bitcoin-cli -datadir=config -rpcwallet=rpcwallet sendtoaddress "$addr_hub" 0.5
docker exec bitcoin bitcoin-cli -datadir=config -rpcwallet=rpcwallet sendtoaddress "$addr_c2" 0.5
docker exec bitcoin bitcoin-cli -datadir=config -rpcwallet=rpcwallet sendtoaddress "$addr_c2" 0.5
docker exec bitcoin bitcoin-cli -datadir=config -rpcwallet=rpcwallet sendtoaddress "$addr_c2" 0.5
docker exec bitcoin bitcoin-cli -datadir=config -rpcwallet=rpcwallet sendtoaddress "$addr_spaz" 0.5
docker exec bitcoin bitcoin-cli -datadir=config -rpcwallet=rpcwallet sendtoaddress "$addr_spaz" 0.5
docker exec bitcoin bitcoin-cli -datadir=config -rpcwallet=rpcwallet sendtoaddress "$addr_spaz" 0.5
docker exec bitcoin bitcoin-cli -datadir=config -rpcwallet=rpcwallet sendtoaddress "$addr_spaz" 0.5
docker exec bitcoin bitcoin-cli -datadir=config -rpcwallet=rpcwallet sendtoaddress "$addr_spaz" 0.5
docker exec bitcoin bitcoin-cli -datadir=config -rpcwallet=rpcwallet sendtoaddress "$addr_spaz" 0.5
docker exec bitcoin bitcoin-cli -datadir=config -rpcwallet=rpcwallet sendtoaddress "$addr_c1" 1
docker exec bitcoin bitcoin-cli -datadir=config -rpcwallet=rpcwallet sendtoaddress "$addr_clnremote" 0.75
docker exec bitcoin bitcoin-cli -datadir=config -rpcwallet=rpcwallet sendtoaddress "$addr_clnremote" 0.75
docker exec bitcoin bitcoin-cli -datadir=config -rpcwallet=rpcwallet sendtoaddress "$addr_clnremote" 0.75
docker exec bitcoin bitcoin-cli -datadir=config -rpcwallet=rpcwallet sendtoaddress "$addr_clnremote" 0.75
docker exec bitcoin bitcoin-cli -datadir=config -rpcwallet=rpcwallet sendtoaddress "$addr_c3" 1

docker exec bitcoin bitcoin-cli -datadir=config -rpcwallet=rpcwallet -generate=1

addr_r=$(docker exec cln-remote lightning-cli --network=regtest newaddr bech32 | jq '.bech32' -r)
docker exec bitcoin bitcoin-cli -datadir=config -rpcwallet=rpcwallet sendtoaddress "$addr_r" 2

fund_lnd_node () {
    _addr=$(docker exec $1 lncli --network=regtest newaddress p2wkh | jq '.address' -r)
    docker exec bitcoin bitcoin-cli -datadir=config -rpcwallet=rpcwallet sendtoaddress "$_addr" 0.88
    docker exec bitcoin bitcoin-cli -datadir=config -rpcwallet=rpcwallet sendtoaddress "$_addr" 0.88
    docker exec bitcoin bitcoin-cli -datadir=config -rpcwallet=rpcwallet sendtoaddress "$_addr" 0.88
    docker exec bitcoin bitcoin-cli -datadir=config -rpcwallet=rpcwallet sendtoaddress "$_addr" 0.88
    docker exec bitcoin bitcoin-cli -datadir=config -rpcwallet=rpcwallet sendtoaddress "$_addr" 0.88
    docker exec bitcoin bitcoin-cli -datadir=config -rpcwallet=rpcwallet sendtoaddress "$_addr" 0.88
    docker exec bitcoin bitcoin-cli -datadir=config -rpcwallet=rpcwallet sendtoaddress "$_addr" 0.88
}

for node in "${lnd_nodes[@]}"
do
    fund_lnd_node $node
    docker exec bitcoin bitcoin-cli -datadir=config -rpcwallet=rpcwallet -generate=1
done

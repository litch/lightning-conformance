#!/bin/bash
source ./variables.sh

send_to_address () {
    docker exec bitcoin bitcoin-cli -datadir=config -rpcwallet=rpcwallet sendtoaddress "$1" 0.88
}

fund_lnd_node () {
    _addr=$(docker exec $1 lncli --network=regtest newaddress p2wkh | jq '.address' -r)
    fund_address $_addr $2
}

fund_cln_node () {
    _addr=$(docker exec $1 lightning-cli --network=regtest newaddr bech32 | jq '.bech32' -r)
    fund_address $_addr $2
}

fund_address () {
    _addr=$1
    _count=$2

    if [ -z "$_count" ]
    then
        _count=1
    fi

    for i in $(seq 1 $_count)
    do

        send_to_address $_addr 
    done
}

for node in "${lnd_nodes[@]}"
do
    fund_lnd_node $node 4
    docker exec bitcoin bitcoin-cli -datadir=config -rpcwallet=rpcwallet -generate=1
done

for node in "${cln_nodes[@]}"
do
    fund_cln_node $node 4
    docker exec bitcoin bitcoin-cli -datadir=config -rpcwallet=rpcwallet -generate=1
done

# Now we fund the hubs a bunch of times
fund_cln_node cln-hub 20
fund_lnd_node lnd2 20

docker exec bitcoin bitcoin-cli -datadir=config -rpcwallet=rpcwallet -generate=10
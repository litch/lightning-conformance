#!/bin/bash
source ./variables.sh

channel_lnd () {
    node=$1
    destination=$2
    channel_size=$3
    push_amt=$4

    echo "Opening channel from $node to $destination (Size: $channel_size, Amount: $push_amt)"
    docker exec $node lncli --network=regtest openchannel $destination $channel_size $push_amt
}

channel_cln () {
    node=$1
    destination=$2
    channel_size=$3
    push_amt=$4    
    
    echo "Opening channel from $node to $destination (Size: $channel_size, Amount: $push_amt)"
    docker exec $node lightning-cli -k --network=regtest fundchannel id=$destination amount=$channel_size push_msat=$push_amt
}

generate_blocks () {
    address=$(docker exec bitcoin bitcoin-cli -rpcwallet=rpcwallet --datadir=config getnewaddress)
    docker exec bitcoin bitcoin-cli --datadir=config generatetoaddress $1 $address
}

echo "Hub and spoke CLN nodes to cln-hub"
for node in "${cln_nodes[@]}"; do
    if [[ "$node" == 'cln-hub' ]]; then
        continue
    fi
    echo "Opening from cln-hub to $node"
    addr=$(docker exec $node lightning-cli --network=regtest getinfo | jq '.id' -r)
    channel_cln cln-hub $addr 10000000 2000000
done


echo "Hub and spoke LND nodes to lnd2"
for node in "${lnd_nodes[@]}"; do
    if [[ "$node" == 'lnd2' ]]; then
        continue
    fi
    echo "Opening from lnd2 to $node"
    addr=$(docker exec $node lncli --network=regtest getinfo | jq '.identity_pubkey' -r)
    channel_lnd lnd2 $addr 11000000 2000000
done

echo "Joining those graphs"
pubkey_lnd=$(docker exec lnd lncli --network=regtest getinfo | jq '.identity_pubkey' -r)
channel_cln cln-hub $pubkey_lnd 12000000 2000000

generate_blocks 6
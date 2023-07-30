#!/bin/bash
source ./variables.sh

pubkey_hub=$(docker exec cln-hub lightning-cli --network=regtest getinfo | jq '.id' -r)
pubkey_lnd=$(docker exec lnd lncli --network=regtest getinfo | jq '.identity_pubkey' -r)

channel_lnd () {
    node=$1
    destination=$2
    
    channel_size=$(awk 'BEGIN {srand(); print int(500000000 + (10000000 - 1000000) * rand())}')
    push_prop=$(awk 'BEGIN {srand(); print int(20 + (60 - 20) * rand())}')
    push_amt=$(echo "$channel_size*$push_prop/100" | bc)
    echo "Opening channel from $node to $destination (Size: $channel_size, Amount: $push_amt)"
    _pubkey=$(docker exec $destination lncli --network=regtest getinfo | jq '.identity_pubkey' -r)
    docker exec $node lncli --network=regtest connect $_pubkey@$destination 9735
    docker exec $node lncli --network=regtest openchannel $_pubkey $channel_size $push_amt
}

channel_lnd lnd lnd2
channel_lnd lnd lnd-15-3
channel_lnd lnd lnd-15-2
# channel_lnd lnd $pubkey_hub
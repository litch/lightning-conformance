#!/bin/bash
source ./variables.sh

pubkey_r=$(docker exec cln-remote lightning-cli --network=regtest getinfo | jq '.id' -r)
pubkey_hub=$(docker exec cln-hub lightning-cli --network=regtest getinfo | jq '.id' -r)
pubkey_c1=$(docker exec cln-c1 lightning-cli --network=regtest getinfo | jq '.id' -r)
pubkey_c2=$(docker exec cln-c2 lightning-cli --network=regtest getinfo | jq '.id' -r)
pubkey_c3=$(docker exec cln-c3 lightning-cli --network=regtest getinfo | jq '.id' -r)
pubkey_c4=$(docker exec cln-c4 lightning-cli --network=regtest getinfo | jq '.id' -r)
pubkey_sluggish=$(docker exec cln-sluggish lightning-cli --network=regtest getinfo | jq '.id' -r)
pubkey_spaz=$(docker exec cln-spaz lightning-cli --network=regtest getinfo | jq '.id' -r)

pubkey_lnd=$(docker exec lnd lncli --network=regtest getinfo | jq '.identity_pubkey' -r)
pubkey_lnd153=$(docker exec lnd-15-3 lncli --network=regtest getinfo | jq '.identity_pubkey' -r)
pubkey_lnd2=$(docker exec lnd2 lncli --network=regtest getinfo | jq '.identity_pubkey' -r)

pubkey_lnd155=$(docker exec lnd-15-5 lncli --network=regtest getinfo | jq '.identity_pubkey' -r)

channel_lnd () {
    node=$1
    destination=$2
    
    channel_size=$(awk 'BEGIN {srand(); print int(10000000 + (10000000 - 1000000) * rand())}')
    push_prop=$(awk 'BEGIN {srand(); print int(20 + (60 - 20) * rand())}')
    push_amt=$(echo "$channel_size*$push_prop/100" | bc)
    echo "Opening channel from $node to $destination (Size: $channel_size, Amount: $push_amt)"
    docker exec $node lncli --network=regtest openchannel $destination $channel_size $push_amt
}

channel_cln () {
    node=$1
    destination=$2
    
    channel_size=$(awk 'BEGIN {srand(); print int(1000000 + (10000000 - 1000000) * rand())}')
    push_prop=$(awk 'BEGIN {srand(); print int(20 + (60 - 20) * rand())}')
    push_amt=$(echo "$channel_size*$push_prop/100" | bc)
    echo "Opening channel from $node to $destination (Size: $channel_size, Amount: $push_amt)"
    docker exec $node lightning-cli -k --network=regtest fundchannel id=$destination amount=$channel_size push_msat=$push_amt
}

generate_blocks () {
    address=$(docker exec bitcoin bitcoin-cli -rpcwallet=rpcwallet --datadir=config getnewaddress)
    docker exec bitcoin bitcoin-cli --datadir=config generatetoaddress $1 $address
}

generate_blocks 7
sleep 5

docker exec lnd lncli --network=regtest connect ${pubkey_lnd155}@lnd-15-5:9735

channel_lnd lnd $pubkey_lnd155
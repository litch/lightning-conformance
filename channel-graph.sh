#!/bin/zsh
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

channel_lnd () {
    node=$1
    destination=$2
    
    channel_size_sci=`seq 1000000 100000 10000000 | shuf | head -n1`
    channel_size=`printf '%5i\n' $channel_size_sci`
    push_prop=`seq 0.2 .01 0.6 | shuf | head -n1`
    push_amt=`printf '%5i\n' $(($channel_size*$push_prop))`
    echo "Opening channel from $node to $destination (Size: $channel_size, Amount: $push_amt)"
    docker exec $node lncli --network=regtest openchannel $destination $channel_size $push_amt
}

channel_cln () {
    node=$1
    destination=$2
    
    channel_size_sci=`seq 1000000 100000 10000000 | shuf | head -n1`
    channel_size=`printf '%5i\n' $channel_size_sci`
    push_prop=`seq 0.1 .01 0.6 | shuf | head -n1`
    push_amt=`printf '%5i\n' $(($channel_size*$push_prop*1000))`
    echo "Opening channel from $node to $destination (Size: $channel_size, Amount: $push_amt)"
    docker exec $node lightning-cli -k --network=regtest fundchannel id=$destination amount=$channel_size push_msat=$push_amt
}

generate_blocks () {
    address=$(docker exec bitcoin bitcoin-cli -rpcwallet=rpcwallet --datadir=config getnewaddress)
    docker exec bitcoin bitcoin-cli --datadir=config generatetoaddress $1 $address
}

generate_blocks 7
sleep 1

channel_cln cln-hub $pubkey_lnd153
channel_lnd lnd $pubkey_lnd153

#we will route over this pair
channel_cln cln-c1 $pubkey_lnd
channel_cln cln-c1 $pubkey_sluggish
channel_cln cln-c3 $pubkey_sluggish

channel_cln cln-c2 $pubkey_spaz
channel_cln cln-spaz $addr_hub
channel_cln cln-spaz $addr_lnd2

channel_lnd lnd $pubkey_r
generate_blocks 6
sleep 1
channel_lnd lnd $pubkey_c1
channel_cln cln-remote $pubkey_lnd

generate_blocks 6
sleep 1

channel_lnd lnd $pubkey_lnd2

channel_cln cln-hub $pubkey_r

generate_blocks 6
sleep 1

channel_cln cln-hub $pubkey_c1
channel_cln cln-hub $pubkey_c2

generate_blocks 6
sleep 1

channel_cln cln-hub $pubkey_c3
channel_cln cln-hub $pubkey_c4

echo "Again hub and spoke LND nodes to lnd2"
for node in "${lnd_nodes[@]}"; do
    if [[ "$node" == 'lnd' ]]; then
        continue
    fi
    if [[ "$node" == 'lnd2' ]]; then
        continue
    fi
    echo "Opening from lnd2 to $node"
    addr=$(docker exec $node lncli --network=regtest getinfo | jq '.identity_pubkey' -r)
    channel_lnd lnd2 $addr
done

generate_blocks 6
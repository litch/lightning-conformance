#!/bin/zsh

addr_r=$(docker exec cln-remote lightning-cli --network=regtest getinfo | jq '.id' -r)
addr_hub=$(docker exec cln-hub lightning-cli --network=regtest getinfo | jq '.id' -r)
addr_c1=$(docker exec cln-c1 lightning-cli --network=regtest getinfo | jq '.id' -r)
addr_c2=$(docker exec cln-c2 lightning-cli --network=regtest getinfo | jq '.id' -r)
addr_c3=$(docker exec cln-c3 lightning-cli --network=regtest getinfo | jq '.id' -r)
addr_c4=$(docker exec cln-c4 lightning-cli --network=regtest getinfo | jq '.id' -r)
addr_lnd=$(docker exec lnd lncli --network=regtest getinfo | jq '.identity_pubkey' -r)
addr_lnd150=$(docker exec lnd-15-0 lncli --network=regtest getinfo | jq '.identity_pubkey' -r)
addr_lnd2=$(docker exec lnd2 lncli --network=regtest getinfo | jq '.identity_pubkey' -r)

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

channel_cli () {
    node=$1
    destination=$2
    
    channel_size_sci=`seq 1000000 100000 10000000 | shuf | head -n1`
    channel_size=`printf '%5i\n' $channel_size_sci`
    push_prop=`seq 0 .01 1 | shuf | head -n1`
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

channel_cli cln-hub $addr_lnd150
channel_lnd lnd $addr_lnd150

#we will route over this pair
channel_cli cln-c1 $addr_lnd
channel_lnd lnd $addr_r
generate_blocks 6
sleep 1
channel_lnd lnd $addr_c1
channel_cli cln-remote $addr_lnd

generate_blocks 6
sleep 1

channel_lnd lnd2 $addr_r
channel_lnd lnd $addr_lnd2

channel_cli cln-hub $addr_r

generate_blocks 6
sleep 1

channel_cli cln-hub $addr_c1
channel_cli cln-hub $addr_c2

generate_blocks 6
sleep 1

channel_cli cln-hub $addr_c3
channel_cli cln-hub $addr_c4

#!/bin/zsh
source ./variables.sh

addr_lnd153=$(docker exec lnd-15-3 lncli --network=regtest getinfo | jq '.identity_pubkey' -r)

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

generate_blocks () {
    address=$(docker exec bitcoin bitcoin-cli -rpcwallet=rpcwallet --datadir=config getnewaddress)
    docker exec bitcoin bitcoin-cli --datadir=config generatetoaddress $1 $address
}

generate_blocks 1
channel_lnd lnd $addr_lnd153

echo "I'm going to sleep for awhile, please inspect and hope there's a pending channel"
sleep 20
generate_blocks 1
echo "Generated one block"


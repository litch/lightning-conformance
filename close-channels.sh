#!/bin/bash
generate_blocks () {
    address=$(docker exec bitcoin bitcoin-cli -rpcwallet=rpcwallet --datadir=config getnewaddress)
    docker exec bitcoin bitcoin-cli --datadir=config generatetoaddress 7 $address
}

close_cln_channels () {
    node=$1
    docker exec $node lightning-cli --network=regtest listfunds | jq '.channels[] | select(.state == "CHANNELD_NORMAL") | .short_channel_id' -r | xargs -I {} docker exec $node lightning-cli --network=regtest close {}   
}

docker exec lnd lncli --network=regtest closeallchannels
generate_blocks

close_cln_channels cln-hub

close_cln_channels cln-remote

close_cln_channels cln-c1

close_cln_channels cln-c2

close_cln_channels cln-c3

close_cln_channels cln-c4



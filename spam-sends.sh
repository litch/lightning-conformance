#!/bin/bash

trap ctrl_c INT

ctrl_c () {
    echo "** Trapped CTRL-C"
    after=$(docker exec lnd lncli --network=regtest listpayments --max_payments=1 | jq '.last_index_offset' -r)        
    echo "Starting value: $before, Ending: $after"
    exit 0
}

before=$(docker exec lnd lncli --network=regtest listpayments --max_payments=1 | jq '.last_index_offset' -r)

keysend_from_lnd () {
    source=$1
    destination=$2
    dest_addr=$(docker exec $destination lncli --network=regtest getinfo | jq '.identity_pubkey' -r)
    ceil=10000000
    floor=10000
    amount=$(((RANDOM % $(($ceil- $floor))) + $floor))

    docker exec $source lncli --network=regtest sendpayment --dest $dest_addr --amt=$amount --keysend
}



while true
do
keysend_from_lnd lnd lnd2 &
keysend_from_lnd lnd lnd-15-2 &
keysend_from_lnd lnd lnd-15-3 &
wait
done
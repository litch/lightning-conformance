#!/bin/bash

trap ctrl_c INT

ctrl_c () {
    echo "** Trapped CTRL-C"
    after=$(docker exec lnd lncli --network=regtest listpayments --max_payments=1 | jq '.last_index_offset' -r)        
    echo "Starting value: $before, Ending: $after"
    exit 0
}

before=$(docker exec lnd lncli --network=regtest listpayments --max_payments=1 | jq '.last_index_offset' -r)

invoicesend_to_lnd () {
    source=$1
    destination=$2
    ceil=10000000
    floor=10000
    amount=$(((RANDOM % $(($ceil- $floor))) + $floor))
    invoice=$(docker exec $destination lncli --network=regtest addinvoice --amt=$amount | jq '.payment_request' -r)
    docker exec $source lncli --network=regtest payinvoice $invoice $amount -f

}

lnd2_pubkey=$(docker exec lnd2 lncli --network=regtest getinfo | jq '.identity_pubkey' -r)
lnd_15_2_pubkey=$(docker exec lnd-15-2 lncli --network=regtest getinfo | jq '.identity_pubkey' -r)  
lnd_15_3_pubkey=$(docker exec lnd-15-3 lncli --network=regtest getinfo | jq '.identity_pubkey' -r)
spaz_pubkey=$(docker exec cln-spaz lightning-cli --network=regtest getinfo | jq '.id' -r)
cln_c1_pubkey=$(docker exec cln-c1 lightning-cli --network=regtest getinfo | jq '.id' -r)

while true
do
invoicesend_to_lnd lnd2 lnd &
invoicesend_to_lnd lnd-15-2 lnd &
invoicesend_to_lnd lnd2-15-3 lnd &
wait
done
#!/bin/bash

before=$(docker exec lnd lncli --network=regtest fwdinghistory | jq '.last_offset_index' -r)

addr_r=$(docker exec cln-remote lightning-cli --network=regtest getinfo | jq '.id' -r)
addr_c1=$(docker exec cln-c1 lightning-cli --network=regtest getinfo | jq '.id' -r)
addr_lnd=$(docker exec lnd lncli --network=regtest getinfo | jq '.identity_pubkey' -r)

function randomize_amount() {
    ceil=10000000
    floor=10000
    invoice_amount=$(((RANDOM % $(($ceil- $floor))) + $floor))
}

send_sats_cln_cln () {
    source=$1
    destination=$2

    ceil=10000000
    floor=10000
    invoice_amount=$(((RANDOM % $(($ceil- $floor))) + $floor))

    invoice=$(docker exec $destination lightning-cli --network=regtest invoice $invoice_amount $RANDOM description | jq '.bolt11' -r)
    docker exec $source lightning-cli --network=regtest pay $invoice
}

send_sats_lnd_cln () {
    source=$1
    destination=$2

    ceil=10000000
    floor=10000
    invoice_amount=$(((RANDOM % $(($ceil- $floor))) + $floor))

    invoice=$(docker exec $destination lightning-cli --network=regtest invoice $invoice_amount $RANDOM description | jq '.bolt11' -r)
    docker exec $source lncli --network=regtest payinvoice -f $invoice
}

echo "C1 to Remote invoice"
send_sats_cln_cln cln-c1 cln-remote

echo "Remote to C1"
send_sats_cln_cln cln-remote cln-c1

echo "LND-15-0 to C3"
send_sats_lnd_cln lnd-15-0 cln-c3

echo "LND2 to C2"
send_sats_lnd_cln lnd2 cln-c2

echo "Hub -> LND 15-0"
invoice=$(docker exec lnd-15-0 lncli --network=regtest addinvoice 1219 | jq '.payment_request' -r)
docker exec cln-hub lightning-cli --network=regtest pay $invoice

randomize_amount
echo "Keysend remote -> c1"
docker exec cln-remote lightning-cli --network=regtest keysend $addr_c1 $invoice_amount
randomize_amount
echo "Keysend c1 -> remote"
docker exec cln-c1 lightning-cli --network=regtest keysend $addr_r $invoice_amount
echo "Keysend c4 -> lnd"
docker exec cln-c4 lightning-cli --network=regtest keysend $addr_lnd $invoice_amount

echo "Ok now let's just send the lnd node some sats (remote -> lnd)"
invoice=$(docker exec lnd lncli --network=regtest addinvoice 121923 | jq '.payment_request' -r)
docker exec cln-remote lightning-cli --network=regtest pay $invoice

echo "Send some sats from lnd to a couple of single hop peers"
send_sats_lnd_cln lnd cln-c1
send_sats_lnd_cln lnd cln-remote

echo "Send sats from LND to c4 (multi-hop)"
send_sats_lnd_cln lnd cln-c4

echo "Do some onchain"
addr=$(docker exec cln-hub lightning-cli --network=regtest newaddr bech32 | jq '.bech32' -r)
docker exec lnd lncli --network=regtest sendcoins "$addr" $RANDOM

after=$(docker exec lnd lncli --network=regtest fwdinghistory | jq '.last_offset_index' -r)

let diff=$after-$before
echo "Successfully sent - routed $diff transactions"

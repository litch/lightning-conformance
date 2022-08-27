#!/bin/bash

before=$(docker exec lnd lncli --network=regtest fwdinghistory | jq '.last_offset_index' -r)

addr_r=$(docker exec cln-remote lightning-cli --network=regtest getinfo | jq '.id' -r)
addr_c1=$(docker exec cln-c1 lightning-cli --network=regtest getinfo | jq '.id' -r)
addr_lnd=$(docker exec lnd lncli --network=regtest getinfo | jq '.identity_pubkey' -r)

echo "C1 to Remote invoice"
invoice=$(docker exec cln-c1 lightning-cli --network=regtest invoice $RANDOM `gdate +%s%N` description | jq '.bolt11' -r)
docker exec cln-remote lightning-cli --network=regtest pay $invoice

echo "Keysend"
docker exec cln-remote lightning-cli --network=regtest keysend $addr_c1 $RANDOM
docker exec cln-c1 lightning-cli --network=regtest keysend $addr_r $RANDOM

echo "Ok now let's just send the lnd node some sats"
invoice=$(docker exec lnd lncli --network=regtest addinvoice 1219923 | jq '.payment_request' -r)
docker exec cln-remote lightning-cli --network=regtest pay $invoice

echo "Send some sats from lnd to each of its buddies"
invoice_c1=$(docker exec cln-c1 lightning-cli --network=regtest invoice $RANDOM `gdate +%s%N` description | jq '.bolt11' -r)
invoice_remote=$(docker exec cln-remote lightning-cli --network=regtest invoice $RANDOM `gdate +%s%N` description | jq '.bolt11' -r)
docker exec lnd lncli --network=regtest payinvoice -f $invoice_c1
docker exec lnd lncli --network=regtest payinvoice -f $invoice_remote

echo "Do some onchain"
addr=$(docker exec cln-hub lightning-cli --network=regtest newaddr bech32 | jq '.bech32' -r)
docker exec lnd lncli --network=regtest sendcoins "$addr" $RANDOM

after=$(docker exec lnd lncli --network=regtest fwdinghistory | jq '.last_offset_index' -r)

let diff=$after-$before
echo "Successfully sent - routed $diff transactions"



# remote -> lnd -> c1

# c1:  02de18582350fa5d6e330440f4eb5e3ab7e0f4aa0b61c51febdbfd228a53db579f
# lnd: 029c70b8ccd6e42263b7eeefb7a44b0266c55a00714fc1a5b63278c0ce67a1bd37
# remote: 0343c8a02fda757cf087f99c5be70d90374c96390f57f53ba99287ec23a523b95b

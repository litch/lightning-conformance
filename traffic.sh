#!/bin/bash



declare -a invoices=()
invoices+=($(docker exec cln-c1 lightning-cli --network=regtest invoice 1000000 `gdate +%s%N` description | jq '.bolt11' -r))
invoices+=($(docker exec cln-c1 lightning-cli --network=regtest invoice 1000000 `gdate +%s%N` description | jq '.bolt11' -r))
invoices+=($(docker exec cln-c1 lightning-cli --network=regtest invoice 1000000 `gdate +%s%N` description | jq '.bolt11' -r))
invoices+=($(docker exec cln-c1 lightning-cli --network=regtest invoice 1000000 `gdate +%s%N` description | jq '.bolt11' -r))
invoices+=($(docker exec cln-c1 lightning-cli --network=regtest invoice 1000000 `gdate +%s%N` description | jq '.bolt11' -r))


for invoice in "${invoices[*]}"; do 
echo $invoice
# docker exec cln-remote lightning-cli --network=regtest pay $invoice
done


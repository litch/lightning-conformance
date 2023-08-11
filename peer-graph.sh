#!/bin/bash
source ./variables.sh

pubkey_lnd=$(docker exec lnd lncli --network=regtest getinfo | jq '.identity_pubkey' -r)
pubkey_lnd2=$(docker exec lnd2 lncli --network=regtest getinfo | jq '.identity_pubkey' -r)
pubkey_hub=$(docker exec cln-hub lightning-cli --network=regtest getinfo | jq '.id' -r)

echo "Let's hub and spoke CLN nodes to cln-hub"
for node in "${cln_nodes[@]}"
do
    if [[ "$node" == 'cln-hub' ]]; then
        continue
    fi
    docker exec $node lightning-cli --network=regtest connect ${pubkey_hub}@cln-hub:9735
done

echo "Let's hub and spoke LND nodes to lnd2"
for node in "${lnd_nodes[@]}"
do
    if [[ "$node" == 'lnd2' ]]; then
        continue
    fi
    docker exec $node lncli --network=regtest connect ${pubkey_lnd2}@lnd2 9735
done

echo "Let's join those graphs"
docker exec cln-hub lightning-cli --network=regtest connect ${pubkey_lnd}@lnd:9735

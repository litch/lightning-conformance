#!/bin/bash
source ./variables.sh

echo "Gathering pubkeys"
pubkey_r=$(docker exec cln-remote lightning-cli --network=regtest getinfo | jq '.id' -r)
pubkey_hub=$(docker exec cln-hub lightning-cli --network=regtest getinfo | jq '.id' -r)
pubkey_c1=$(docker exec cln-c1 lightning-cli --network=regtest getinfo | jq '.id' -r)
pubkey_c2=$(docker exec cln-c2 lightning-cli --network=regtest getinfo | jq '.id' -r)
pubkey_c3=$(docker exec cln-c3 lightning-cli --network=regtest getinfo | jq '.id' -r)
pubkey_c4=$(docker exec cln-c4 lightning-cli --network=regtest getinfo | jq '.id' -r)
pubkey_sluggish=$(docker exec cln-sluggish lightning-cli --network=regtest getinfo | jq '.id' -r)
pubkey_spaz=$(docker exec cln-spaz lightning-cli --network=regtest getinfo | jq '.id' -r)

pubkey_lnd=$(docker exec lnd lncli --network=regtest getinfo | jq '.identity_pubkey' -r)
pubkey_lnd2=$(docker exec lnd2 lncli --network=regtest getinfo | jq '.identity_pubkey' -r)

echo "Now opening peering connections"
docker exec lnd lncli --network=regtest connect ${pubkey_r}@cln-remote:9735
docker exec lnd lncli --network=regtest connect ${pubkey_c1}@cln-c1:9735
docker exec lnd2 lncli --network=regtest connect ${pubkey_r}@cln-remote:9735

docker exec lnd-15-3 lncli --network=regtest connect ${pubkey_hub}@cln-hub:9735
docker exec lnd-15-3 lncli --network=regtest connect ${pubkey_lnd}@lnd:9735

docker exec cln-c1 lightning-cli --network=regtest connect $pubkey_r cln-remote 9735
docker exec cln-c1 lightning-cli --network=regtest connect $pubkey_sluggish cln-sluggish 9735
docker exec cln-c3 lightning-cli --network=regtest connect $pubkey_sluggish cln-sluggish 9735

docker exec cln-c2 lightning-cli --network=regtest connect $pubkey_spaz cln-spaz 9735
docker exec cln-hub lightning-cli --network=regtest connect $pubkey_spaz cln-spaz 9735
docker exec cln-spaz lightning-cli --network=regtest connect $pubkey_lnd2 lnd2 9735
docker exec cln-spaz lightning-cli --network=regtest connect $pubkey_lnd lnd 9735

docker exec cln-hub lightning-cli --network=regtest connect $pubkey_r cln-remote 9735
docker exec cln-hub lightning-cli --network=regtest connect $pubkey_c1 cln-c1 9735
docker exec cln-hub lightning-cli --network=regtest connect $pubkey_c2 cln-c2 9735
docker exec cln-hub lightning-cli --network=regtest connect $pubkey_c3 cln-c3 9735
docker exec cln-hub lightning-cli --network=regtest connect $pubkey_c4 cln-c4 9735



echo "Let's hub and spoke LND nodes to lnd2"
for node in "${lnd_nodes[@]}"
do
    if [[ "$node" == 'lnd2' ]]; then
        continue
    fi
    docker exec $node lncli --network=regtest connect ${pubkey_lnd2}@lnd2 9735
done

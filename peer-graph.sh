#!/bin/bash
source ./variables.sh

echo "Gathering pubkeys"
pubkey_c1=$(docker exec cln-c1 lightning-cli --network=regtest getinfo | jq '.id' -r)
pubkey_c2=$(docker exec cln-c2 lightning-cli --network=regtest getinfo | jq '.id' -r)
pubkey_lnd=$(docker exec lnd lncli --network=regtest getinfo | jq '.identity_pubkey' -r)

echo "Now opening peering connections"
docker exec lnd lncli --network=regtest connect ${pubkey_c1}@cln-c1:9735
docker exec lnd lncli --network=regtest connect ${pubkey_c2}@cln-c2:9735

docker exec cln-c1 lightning-cli --network=regtest connect ${pubkey_c2} cln-c2 9735


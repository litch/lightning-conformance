#!/bin/bash

echo "Gathering pubkeys"
addr_r=$(docker exec cln-remote lightning-cli --network=regtest getinfo | jq '.id' -r)
addr_c1=$(docker exec cln-c1 lightning-cli --network=regtest getinfo | jq '.id' -r)
addr_c2=$(docker exec cln-c2 lightning-cli --network=regtest getinfo | jq '.id' -r)
addr_c3=$(docker exec cln-c3 lightning-cli --network=regtest getinfo | jq '.id' -r)
addr_c4=$(docker exec cln-c4 lightning-cli --network=regtest getinfo | jq '.id' -r)
addr_lnd=$(docker exec lnd lncli --network=regtest getinfo | jq '.identity_pubkey' -r)

echo "Now opening peering connections"
docker exec lnd lncli --network=regtest connect ${addr_r}@cln-remote:9735
docker exec cln-hub lightning-cli --network=regtest connect $addr_r cln-remote 9735
docker exec cln-hub lightning-cli --network=regtest connect $addr_c1 cln-c1 9735
docker exec cln-hub lightning-cli --network=regtest connect $addr_c2 cln-c2 9735
docker exec cln-hub lightning-cli --network=regtest connect $addr_c3 cln-c3 9735
docker exec cln-hub lightning-cli --network=regtest connect $addr_c4 cln-c4 9735
docker exec lnd lncli --network=regtest connect ${addr_c1}@cln-c1 9735

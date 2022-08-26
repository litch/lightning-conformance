#!/bin/bash

addr_hub=$(docker exec cln-hub lightning-cli --network=regtest getinfo | jq '.id' -r)
addr_r=$(docker exec cln-remote lightning-cli --network=regtest getinfo | jq '.id' -r)
addr_c1=$(docker exec cln-c1 lightning-cli --network=regtest getinfo | jq '.id' -r)
addr_c2=$(docker exec cln-c2 lightning-cli --network=regtest getinfo | jq '.id' -r)
addr_c3=$(docker exec cln-c3 lightning-cli --network=regtest getinfo | jq '.id' -r)
addr_c4=$(docker exec cln-c4 lightning-cli --network=regtest getinfo | jq '.id' -r)
addr_lnd=$(docker exec lnd lncli --network=regtest getinfo | jq '.identity_pubkey' -r)

docker exec cln-c1 lightning-cli --network=regtest fundchannel $addr_lnd 15000000
docker exec cln-remote lightning-cli --network=regtest fundchannel $addr_hub 15000000
docker exec cln-hub lightning-cli --network=regtest fundchannel $addr_c1 4000000
docker exec cln-hub lightning-cli --network=regtest fundchannel $addr_c2 5000000
docker exec cln-hub lightning-cli --network=regtest fundchannel $addr_c3 6000000
docker exec cln-hub lightning-cli --network=regtest fundchannel $addr_c4 7000000
docker exec lnd lncli --network=regtest openchannel $addr_r 1500000


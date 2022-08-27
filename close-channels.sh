#!/bin/bash


docker exec lnd lncli --network=regtest closeallchannels

docker exec cln-hub lightning-cli --network=regtest listfunds | jq '.channels[].short_channel_id' -r | xargs -I {} docker exec cln-hub lightning-cli --network=regtest close {}
docker exec cln-remote lightning-cli --network=regtest listfunds | jq '.channels[].short_channel_id' -r | xargs -I {} docker exec cln-remote lightning-cli --network=regtest close {}
docker exec cln-c1 lightning-cli --network=regtest listfunds | jq '.channels[].short_channel_id' -r | xargs -I {} docker exec cln-c1 lightning-cli --network=regtest close {}
docker exec cln-c2 lightning-cli --network=regtest listfunds | jq '.channels[].short_channel_id' -r | xargs -I {} docker exec cln-c2 lightning-cli --network=regtest close {}
docker exec cln-c3 lightning-cli --network=regtest listfunds | jq '.channels[].short_channel_id' -r | xargs -I {} docker exec cln-c3 lightning-cli --network=regtest close {}
docker exec cln-c4 lightning-cli --network=regtest listfunds | jq '.channels[].short_channel_id' -r | xargs -I {} docker exec cln-c4 lightning-cli --network=regtest close {}



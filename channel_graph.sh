#!/bin/bash

addr_r=$(docker exec cln-remote lightning-cli --network=regtest getinfo | jq '.id' -r)
addr_hub=$(docker exec cln-hub lightning-cli --network=regtest getinfo | jq '.id' -r)
addr_c1=$(docker exec cln-c1 lightning-cli --network=regtest getinfo | jq '.id' -r)
addr_c2=$(docker exec cln-c2 lightning-cli --network=regtest getinfo | jq '.id' -r)
addr_c3=$(docker exec cln-c3 lightning-cli --network=regtest getinfo | jq '.id' -r)
addr_c4=$(docker exec cln-c4 lightning-cli --network=regtest getinfo | jq '.id' -r)
addr_lnd=$(docker exec lnd lncli --network=regtest getinfo | jq '.identity_pubkey' -r)
addr_lnd150=$(docker exec lnd-15-0 lncli --network=regtest getinfo | jq '.identity_pubkey' -r)
addr_lnd2=$(docker exec lnd2 lncli --network=regtest getinfo | jq '.identity_pubkey' -r)

docker exec cln-hub lightning-cli -k --network=regtest fundchannel id=$addr_lnd150 amount=9000000 push_msat=5000000000
docker exec lnd lncli --network=regtest openchannel $addr_lnd150 12000000 4000000

docker exec cln-c1 lightning-cli -k --network=regtest fundchannel id=$addr_r amount=9000000 push_msat=5000000000

docker exec cln-c1 lightning-cli --network=regtest fundchannel $addr_lnd 15000000
docker exec lnd lncli --network=regtest openchannel $addr_r 1500000 400000
docker exec bitcoin bitcoin-cli -datadir=config -rpcwallet=rpcwallet -generate=6

docker exec lnd2 lncli --network=regtest openchannel $addr_r 1200000 500000
docker exec lnd lncli --network=regtest openchannel $addr_lnd2 288000000 6000000
docker exec bitcoin bitcoin-cli -datadir=config -rpcwallet=rpcwallet -generate=6

docker exec cln-remote lightning-cli --network=regtest fundchannel $addr_hub 15000000

docker exec cln-hub lightning-cli --network=regtest fundchannel $addr_c1 4000000
docker exec cln-hub lightning-cli --network=regtest fundchannel $addr_c2 5000000

docker exec bitcoin bitcoin-cli -datadir=config -rpcwallet=rpcwallet -generate=6

docker exec cln-hub lightning-cli --network=regtest fundchannel $addr_c3 6000000
docker exec cln-hub lightning-cli --network=regtest fundchannel $addr_c4 7000000

docker exec bitcoin bitcoin-cli -datadir=config -rpcwallet=rpcwallet -generate=6

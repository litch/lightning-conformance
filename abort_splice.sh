addr_c1=$(docker exec cln-c1 lightning-cli --network=regtest newaddr bech32 | jq '.bech32' -r)
addr_c2=$(docker exec cln-c2 lightning-cli --network=regtest newaddr bech32 | jq '.bech32' -r)
docker exec bitcoin bitcoin-cli -datadir=config -rpcwallet=rpcwallet sendtoaddress "$addr_c2" 0.01
docker exec bitcoin bitcoin-cli -datadir=config -rpcwallet=rpcwallet sendtoaddress "$addr_c1" 0.01

c1_pubkey=$(docker exec cln-c1 lightning-cli --network=regtest getinfo | jq -r '.id')
c2_pubkey=$(docker exec cln-c2 lightning-cli --network=regtest getinfo | jq -r '.id')

c1_c2_channel=$(docker exec cln-c1 lightning-cli --network=regtest listpeers $c2_pubkey | jq -r '.peers[0].channels[0].channel_id')

docker exec cln-c1 lightning-cli --network=regtest close $c1_c2_channel

./generate-blocks.sh 6
sleep 2
./generate-blocks.sh 700
sleep 2
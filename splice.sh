addr_c1=$(docker exec cln-c1 lightning-cli --network=regtest newaddr bech32 | jq '.bech32' -r)
addr_c2=$(docker exec cln-c2 lightning-cli --network=regtest newaddr bech32 | jq '.bech32' -r)
docker exec bitcoin bitcoin-cli -datadir=config -rpcwallet=rpcwallet sendtoaddress "$addr_c2" 0.01
docker exec bitcoin bitcoin-cli -datadir=config -rpcwallet=rpcwallet sendtoaddress "$addr_c1" 0.01

c1_pubkey=$(docker exec cln-c1 lightning-cli --network=regtest getinfo | jq -r '.id')
c2_pubkey=$(docker exec cln-c2 lightning-cli --network=regtest getinfo | jq -r '.id')

c1_c2_channel=$(docker exec cln-c1 lightning-cli --network=regtest listpeers $c2_pubkey | jq -r '.peers[0].channels[0].channel_id')

# if no channel, open one
if [ "$c1_c2_channel" == "null" ]; then
    echo "No channel between c1 and c2, opening one"
    docker exec cln-c1 lightning-cli --network=regtest connect $c2_pubkey cln-c2 9735
    docker exec cln-c1 lightning-cli --network=regtest fundchannel $c2_pubkey 1000000

    sleep 2
    ./generate-blocks.sh 6
    c1_c2_channel=$(docker exec cln-c1 lightning-cli --network=regtest listpeers $c2_pubkey | jq -r '.peers[0].channels[0].channel_id')
    echo "Sleeping 10 seconds"
    sleep 10
    ./generate-blocks.sh 6
    sleep 10
    docker exec cln-c1 lightning-cli --network=regtest listpeerchannels $c2_pubkey
fi

echo "c1_c2 channel id: $c1_c2_channel"

# if we passed an arg of "prep", then just abort here
if [ "$1" == "prep" ]; then
    echo "Exiting after prep"
    exit 0
fi

funds_psbt=$(docker exec cln-c1 lightning-cli --network=regtest fundpsbt -k satoshi=700000 feerate=urgent startweight=800 excess_as_change=true | jq -r '.psbt')

res=$(docker exec cln-c1 lightning-cli --network=regtest splice_init $c1_c2_channel 500000 $funds_psbt)
echo $res
splice_psbt=$(echo $res | jq -r '.psbt')

echo "splice_psbt: $splice_psbt"
if [ "$splice_psbt" == "null" ]; then
    echo "No splice_psbt, exiting"
    exit 1
fi

update_result=$(docker exec cln-c1 lightning-cli --network=regtest splice_update -k channel_id=$c1_c2_channel psbt="$splice_psbt")
echo "update_result: $update_result"
update=$(echo $update_result | jq -r '.psbt')
echo "update: $update"
# sign it
signed_result=$(docker exec cln-c1 lightning-cli --network=regtest signpsbt -k psbt="$update")
echo "signed_result: $signed_result"
signed_psbt=$(echo $signed_result | jq -r '.signed_psbt')


echo "************************************************************"
echo "************************************************************"
echo "Broadcastng splice" $(date)
echo "************************************************************"
echo "************************************************************"
# send it
docker exec cln-c1 lightning-cli --network=regtest splice_signed $c1_c2_channel $signed_psbt

# Let's look at the channel state
docker exec cln-c1 lightning-cli --network=regtest listpeers $c2_pubkey | jq -r '.peers[0].channels[0]'

# Let's look at the channel state
docker exec cln-c2 lightning-cli --network=regtest listpeers $c1_pubkey | jq -r '.peers[0].channels[0]'

# Wait a minute
echo "Sleeping 60 seconds"

# lnd channel count should be 2
channel_count=$(docker exec lnd lncli --network=regtest listchannels | jq '.[] | length')

if [ "$channel_count" != "2" ]; then
    echo "Channel count is not 2, exiting"
    exit 1
fi

# Now we will mine a block to confirm the splice
./generate-blocks.sh 1

# Every 10 seconds, check the channel count and print it out along with the time and block height
for i in {1..6000}
do
    echo "Sleeping 10 seconds"
    sleep 10
    ./generate-blocks.sh 1
    channel_count=$(docker exec lnd lncli --network=regtest listchannels | jq '.[] | length')
    echo "Channel count: $channel_count"
    echo "Block height: $(docker exec bitcoin bitcoin-cli -datadir=config -rpcwallet=rpcwallet getblockcount)"
    echo "Time: $(date)"
    if [ "$channel_count" == "3" ]; then
        echo "Channel count is 2, exiting"
        exit 0
    fi
done
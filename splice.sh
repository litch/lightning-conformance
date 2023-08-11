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
    ./generate-blocks.sh 4
    sleep 2
    ./generate-blocks.sh 4
    sleep 2
    ./generate-blocks.sh 4
    sleep 2
    ./generate-blocks.sh 4
    sleep 10
    
    c1_c2_channel=$(docker exec cln-c1 lightning-cli --network=regtest listpeers $c2_pubkey | jq -r '.peers[0].channels[0].channel_id')
    
    docker exec cln-c1 lightning-cli --network=regtest listpeerchannels $c2_pubkey
fi

echo "c1_c2 channel id: $c1_c2_channel"

# if we passed an arg of "prep", then just abort here
if [ "$1" == "prep" ]; then
    echo "Exiting after prep"
    exit 0
fi

bitcoind_blockheight=$(docker exec bitcoin bitcoin-cli -datadir=config getblockcount)
c1_blockheight=$(docker exec cln-c1 lightning-cli --network=regtest getinfo | jq -r '.blockheight')
c2_blockheight=$(docker exec cln-c2 lightning-cli --network=regtest getinfo | jq -r '.blockheight')

if [ "$bitcoind_blockheight" == "$c1_blockheight" ] && [ "$bitcoind_blockheight" == "$c2_blockheight" ]; then
    echo "Blockheights match - $bitcoind_blockheight"
else
    echo "Blockheights don't match, exiting"
    exit 1
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
original_scid=$(docker exec cln-c1 lightning-cli --network=regtest listpeers $c2_pubkey | jq -r '.peers[0].channels[0].short_channel_id')
scid_updated=false
docker exec cln-c1 lightning-cli --network=regtest splice_signed $c1_c2_channel $signed_psbt

sleep 60

for i in {1..6000}
do
    echo "Sleeping 30+3 seconds around blocks"
    sleep 30
    ./generate-blocks.sh 1
    sleep 3
    echo "Channel statuses: " $(date)
    if [ "$scid_updated" == "false" ]; then
        docker exec cln-c1 lightning-cli --network=regtest listpeers $c2_pubkey | jq -r '.peers[0].channels[0] | (.short_channel_id, .status)'
        docker exec cln-c2 lightning-cli --network=regtest listpeers $c1_pubkey | jq -r '.peers[0].channels[0] | (.short_channel_id, .status)'
    fi
    
    new_scid=$(docker exec cln-c1 lightning-cli --network=regtest listpeers $c2_pubkey | jq -r '.peers[0].channels[0].short_channel_id')
    if [ "$new_scid" != "$original_scid" ]; then
        echo "Channel ID changed - new SCID: $new_scid"
        original_scid=$new_scid
        scid_updated=true
    fi
    if [ "$scid_updated" == "true" ]; then
        gossiped_count=$(docker exec cln-c1 lightning-cli --network=regtest listchannels $new_scid | jq -r '.channels | length')
        echo "Gossiped count: $gossiped_count"
        if [ "$gossiped_count" == "2" ]; then
            echo "Gossiped count is 2, everything successful?"
            exit 0
        fi
    fi
    
done









# # Every 10 seconds, check the channel count and print it out along with the time and block height
# for i in {1..6000}
# do
#     echo "Sleeping 10 seconds"
#     sleep 10
#     ./generate-blocks.sh 1
#     channel_count=$(docker exec lnd lncli --network=regtest listchannels | jq '.[] | length')
#     echo "Channel count: $channel_count"
#     echo "Block height: $(docker exec bitcoin bitcoin-cli -datadir=config -rpcwallet=rpcwallet getblockcount)"
#     echo "Time: $(date)"
#     if [ "$channel_count" == "3" ]; then
#         echo "Channel count is 2, exiting"
#         exit 0
#     fi
# done
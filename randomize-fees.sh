#!/bin/bash

echo "Randomizing fees"

cln_nodes=( cln-c1 cln-hub cln-c2 cln-c3 cln-c4 cln-remote )

function randomize_cln () {
    scid=$1
    node=$2
    ceil=1000
    floor=2
    amt1=$(((RANDOM % $(($ceil - $floor))) + $floor))
    amt2=$(((RANDOM % $(($ceil - $floor))) + $floor))
    echo "Randomizing channel point:$chan_point $amt1 $amt2"
    
    docker exec $node lightning-cli --network=regtest setchannel $scid $amt1 $amt2
}
export -f randomize_cln

for node in "${cln_nodes[@]}"
do
    echo "Randomizing $node"
    docker exec $node lightning-cli --network=regtest listfunds | jq -r '.channels[].short_channel_id' | xargs -n 1 -P 10 -I {} bash -c 'randomize_cln "$@" $@ ' _ {} $node
done

lnd_nodes=( lnd lnd2 lnd-15-0)

function randomize_lnd () {
    chan_point=$1
    node=$2
    ceil=1000
    floor=2
    amt1=$(((RANDOM % $(($ceil- $floor))) + $floor))
    # amt2=$(((RANDOM % $(($ceil- $floor))) + $floor))
    base=$(($amt1 * 10))
    rate=`printf '%.6f\n' "$(printf '0x0.000%04xp1' $RANDOM)"`
    echo "Randomizing channel point:$chan_point $base $rate"
    docker exec $node lncli --network=regtest updatechanpolicy --chan_point=$chan_point $base $rate 18
}
export -f randomize_lnd

for node in "${lnd_nodes[@]}"
do
    echo "Randomizing fees for $node"
    docker exec $node lncli --network=regtest listchannels | jq -r '.channels[] | select(.state == "CHANNELD_NORMAL") | .channel_point' |  xargs -n 1 -P 10 -I {} bash -c 'randomize_lnd "$@" $@ ' _ {} $node
done
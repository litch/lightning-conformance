#!/bin/zsh

addr_r=$(docker exec cln-remote lightning-cli --network=regtest getinfo | jq '.id' -r)
addr_c1=$(docker exec cln-c1 lightning-cli --network=regtest getinfo | jq '.id' -r)

function remote_balance () {
    node=$1
    remote=$2
    r_balance=$(docker exec $node lncli --network=regtest listchannels | jq -r --arg remote $remote '[.channels | .[] | select(.remote_pubkey | contains($remote)) | .remote_balance | tonumber] | add ')
}

function local_balance () {
    node=$1
    remote=$2
    l_balance=$(docker exec $node lncli --network=regtest listchannels | jq -r --arg remote $remote '[.channels | .[] | select(.remote_pubkey | contains($remote)) | .local_balance | tonumber] | add ')
}

remote_balance lnd $addr_r
local_balance lnd $addr_r
echo "cln-remote || Remote: $r_balance | Local: $l_balance"

remote_balance lnd $addr_c1
local_balance lnd $addr_c1
echo "coreln-c1  || Remote: $r_balance | Local: $l_balance"

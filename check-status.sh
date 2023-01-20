#!/bin/bash

source ./variables.sh

lnd_status () {
    docker exec $1 lncli --network=regtest getinfo | jq -r '[.alias, .num_peers, .num_pending_channels, .num_active_channels, .num_inactive_channels, .synced_to_chain, .synced_to_graph] | @tsv'
}

cln_status () {
    docker exec $1 lightning-cli --network=regtest getinfo | jq -r '[.alias, .num_peers, .num_pending_channels, .num_active_channels, .num_inactive_channels ] | @tsv'
}
echo "\n"
printf "%-30s %-10s %-20s %-20s %-20s\n" "alias" "num_peers" "num_pending_channels" "num_active_channels" "num_inactive_channels"


for node in "${lnd_nodes[@]}"
do
    printf "%-30s %-10s %-20s %-20s %-20s %-10s %-10s\n" $(lnd_status "$node")

done

printf "%-30s %-10s %-20s %-20s %-20s %-10s %-10s\n" "alias" "num_peers" "num_pending_channels" "num_active_channels" "num_inactive_channels" "chain_sync" "graph_sync"

for node in "${cln_nodes[@]}"
do
    printf "%-30s %-10s %-20s %-20s %-20s\n" $(cln_status "$node")

done

echo "\n"
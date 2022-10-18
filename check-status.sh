source ./variables.sh

lnd_status () {
    docker exec $1 lncli --network=regtest getinfo | jq -r '[.alias, .num_peers, .num_pending_channels, .num_active_channels, .num_inactive_channels, .synced_to_chain, .synced_to_graph] | @tsv'
}

cln_status () {
    docker exec $1 lightning-cli --network=regtest getinfo | jq -r '[.alias, .num_peers, .num_pending_channels, .num_active_channels, .num_inactive_channels ] | @tsv'
}
echo "\n"
echo "alias\t\tpeers\tpending\topen\tinact\tsync"

for node in "${lnd_nodes[@]}"
do
    lnd_status $node
done

for node in "${cln_nodes[@]}"
do
    cln_status $node
done

echo "\n"
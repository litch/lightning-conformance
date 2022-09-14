#!/bin/zsh

closable_nodes=(lnd2 lnd-15-0 cln-c1 cln-c2 cln-hub)

while true; do 
    for i in {1..6}; do 
        ./route-test.py
        ./randomize-fees.sh
        ./close-random-channel.py
        ./generate-blocks.sh 6
    done
    node_to_close="$closable_nodes[RANDOM % $#closable_nodes + 1]"
    docker stop $node_to_close
    ./route_test.py
    docker start $node_to_close

    ./peer-graph.sh
    ./channel-graph.sh 
done


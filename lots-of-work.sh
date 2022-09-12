#!/bin/zsh
for i in {1..6}; do 
    for i in {1..6}; do 
    ./route-test.sh
    ./randomize-fees.sh
    ./close-random-channel.py
    ./generate-blocks.sh 6
    done

    ./peer-graph.sh
    ./channel-graph.sh 
done
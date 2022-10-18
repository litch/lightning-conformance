#!/bin/zsh

docker exec lnd lncli --network=regtest describegraph > visualize/src/graph.json
Must have senseicli available

```
./reset_everything.sh
docker-compose up
./init_bitcoind.sh
./peer_graph.sh // Will connect all the nodes
./fund_hub.sh
./channel_graph.sh // Will open channels between nodes

```
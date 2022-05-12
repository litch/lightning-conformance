# Idea

Standalone (non-nigiri docker-compose.yml

- Start bitcoin service
- createwallet
- generate 100 blocks
- generate a block every 10 secs `./generate_blocks.sh`



# get bitcoin address for a node

`docker exec cln-c1 lightning-cli --network=regtest newaddr bech32`

# fund the hub!

`./fund_hub.sh`
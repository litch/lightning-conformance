#!/bin/bash

function usage() {
    echo "Send bitcoin from the bitcoind node"
    echo ""
    echo "./send_bitcoin.sh <address> <amount>"
    echo ""
}


if [ "$2" != "" ]; then
    echo ""
else
    echo "Positional parameter 2 is empty"
    usage
    exit 1
fi

docker exec bitcoin bitcoin-cli -datadir=config -rpcwallet=rpcwallet sendtoaddress "$1" $2


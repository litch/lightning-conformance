#!/bin/zsh
source ./variables.sh

for node in "${lnd_nodes[@]}"
do
    cp volumes/$node/tls.cert visualize/server/auth/$node.cert
    cp volumes/$node/data/chain/bitcoin/regtest/admin.macaroon visualize/server/auth/$node.macaroon
    cp volumes/$node/tls.cert brutalizer/auth/$node.cert
    cp volumes/$node/data/chain/bitcoin/regtest/admin.macaroon brutalizer/auth/$node.macaroon

done


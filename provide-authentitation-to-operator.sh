#!/bin/zsh
source ./variables.sh

for node in "${lnd_nodes[@]}"
do
    cp volumes/$node/tls.cert operator/server/auth/$node.cert
    cp volumes/$node/data/chain/bitcoin/regtest/admin.macaroon operator/server/auth/$node.macaroon
    cp volumes/$node/tls.cert volumes/operator/$node.cert
    cp volumes/$node/data/chain/bitcoin/regtest/admin.macaroon volumes/operator/$node.macaroon
    
    cp volumes/$node/tls.cert volumes/thunderhub/auth/$node.cert
    cp volumes/$node/data/chain/bitcoin/regtest/admin.macaroon volumes/thunderhub/auth/$node.macaroon

done


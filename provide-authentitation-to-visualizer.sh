#!/bin/zsh

cp volumes/lnd/tls.cert visualize/server/auth/lnd.cert
cp volumes/lnd/data/chain/bitcoin/regtest/admin.macaroon visualize/server/auth/lnd.macaroon

cp volumes/lnd2/tls.cert visualize/server/auth/lnd2.cert
cp volumes/lnd2/data/chain/bitcoin/regtest/admin.macaroon visualize/server/auth/lnd2.macaroon

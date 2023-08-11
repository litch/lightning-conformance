#!/bin/bash

rm -rf volumes
mkdir -p volumes/bitcoin
cp resources/bitcoind/bitcoin.conf volumes/bitcoin/bitcoin.conf

drop_lnd () {
    directory=$1
    alias=$2

    alias_key=alias
    tls_key=tlsextradomain
    file=resources/lnd.conf
    sed "s/^\($alias_key\s*=\s*\).*\$/\1$2/" $file | sed "s/^\($tls_key\s*=\s*\).*\$/\1$2/" > volumes/$directory/lnd.conf

}

mkdir -p volumes/lnd
drop_lnd lnd lnd

mkdir -p volumes/thunderhub/auth
cp resources/thunderhub.yaml volumes/thunderhub/thunderhub.yaml
#!/bin/bash

rm -rf volumes
mkdir -p volumes/bitcoin
cp resources/bitcoind/bitcoin.conf volumes/bitcoin/bitcoin.conf

mkdir -p volumes/lnd
cp resources/lnd.conf volumes/lnd/lnd.conf

mkdir -p volumes/lnd2
cp resources/lnd2.conf volumes/lnd2/lnd.conf

mkdir -p volumes/lnd-15-0
cp resources/lnd-150.conf volumes/lnd-15-0/lnd.conf

mkdir -p volumes/lnd-15-1
cp resources/lnd-151.conf volumes/lnd-15-1/lnd.conf

mkdir -p volumes/lnd-15-2
cp resources/lnd-152.conf volumes/lnd-15-2/lnd.conf

mkdir -p volumes/lnd-15-3
cp resources/lnd-153.conf volumes/lnd-15-3/lnd.conf

mkdir -p volumes/thunderhub/auth
cp resources/thunderhub.yaml volumes/thunderhub/thunderhub.yaml
#!/bin/bash

rm -rf volumes
mkdir -p volumes/bitcoin
cp resources/bitcoind/bitcoin.conf volumes/bitcoin/bitcoin.conf

mkdir -p volumes/lnd
cp resources/lnd.conf volumes/lnd/lnd.conf

mkdir -p volumes/lnd2
cp resources/lnd2.conf volumes/lnd2/lnd.conf

mkdir -p volumes/lnd-150
cp resources/lnd-150.conf volumes/lnd-150/lnd.conf

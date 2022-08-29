#!/bin/bash

rm -rf volumes
mkdir -p volumes/bitcoin
cp resources/bitcoind/bitcoin.conf volumes/bitcoin/bitcoin.conf

mkdir -p volumes/lnd
cp resources/lnd.conf volumes/lnd/lnd.conf
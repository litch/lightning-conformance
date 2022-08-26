#!/bin/bash

API_KEY=MF92TFRV7CPNQVYS89DV7N3NQCQEV2DYFTQEJN2MS7R7T0ZBYR


go run cmd/main.go \
    --api-key=$API_KEY \
    --lnd.host=lnd --lnd.network=regtest \
    --lnd.macaroon-path=/Users/litch/code/voltage/conformance-testing/volumes/lnd/data/chain/bitcoin/regtest/admin.macaroon \
    --lnd.tls-cert-path=/Users/litch/code/voltage/conformance-testing/volumes/lnd/tls.cert \
    --consumer-endpoint=https://surge.m.staging.voltage.cloud/ingestion/v1/consume \
    --registration-endpoint=https://surge.m.staging.voltage.cloud/ingestion/v1/register





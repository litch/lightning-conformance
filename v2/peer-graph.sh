#!/bin/bash
LCLI="lightning-cli --network=regtest --conf=/root/.lightning/config --lightning-dir=/mnt/lightning"

kubectl exec -n coreln corelightning-cln1-675767c788-vxrtl -- $LCLI getinfo

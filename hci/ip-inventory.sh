#!/bin/bash

declare -A map
map[0]=X
map[1]=Y
map[2]=Z

for I in 0 1 2; do
    IP=$(bash ../crc/edpm-compute-ip.sh $I)
    OLD_IP=192.168.122.${map[$I]}
    sed -i s/$OLD_IP/$IP/ inventory-configmap.yaml
done

#!/bin/bash

if [[ $# -eq 0 ]] ; then
    TARGET=inventory-configmap.yaml
else
    TARGET=$1
fi

for I in 0 1 2; do
    IP=$(bash ../crc/edpm-compute-ip.sh $I)
    L=$(echo $I | tr 012 XYZ)
    OLD_IP=192.168.122.${L}
    sed -i s/$OLD_IP/$IP/ $TARGET
done

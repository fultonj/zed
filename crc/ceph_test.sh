#!/bin/bash

LS=1
CRUD=0
DEL=0

NAME=ceph
CONF=/etc/ceph/${NAME}.conf
KEY=$(ls /etc/ceph/*.keyring)
ID=$(basename $KEY | sed -e s/$NAME.client.// -e s/.keyring//)
POOL=$(echo ${ID}-images | sed s/-10//)
RBD="rbd --conf $CONF --keyring $KEY --id $ID --cluster $NAME -p $POOL"

for F in $CONF $KEY /usr/bin/rbd; do
    if [[ ! -e $F ]]; then
        echo "Fail: $F is missing. Unable to test Ceph."
        exit 1
    fi
done

if [[ $LS -eq 1 ]]; then
    $RBD ls
fi

if [[ $CRUD -eq 1 ]]; then
    DATA=$(date | md5sum | cut -c-12)
    echo "Creating $DATA"
    $RBD create --size 1024 $POOL/$DATA
    $RBD ls -l | grep $DATA
    echo "Deleting $DATA"
    $RBD rm $POOL/$DATA
fi

if [[ $DEL -eq 1 ]]; then
    UUID=$1
    $RBD rm $POOL/$UUID
fi

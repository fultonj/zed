#!/bin/bash

SRC=~/.ssh/id_rsa
OUT=key-configmap.yaml

SSH_PRIVATE_KEY=$(cat $SRC | sed -e 's/^/    /')

cat <<EOF > $OUT
apiVersion: v1
kind: ConfigMap
metadata:
  name: key-configmap
  namespace: openstack
data:
  ssh_key: |
$SSH_PRIVATE_KEY
EOF

echo $OUT

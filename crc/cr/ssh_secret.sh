#!/bin/bash

SRC=~/.ssh/id_rsa
OUT=ssh-key-secret.yaml

SSH_PRIVATE_KEY=$(cat $SRC | sed -e 's/^/    /')

cat <<EOF > $OUT
apiVersion: v1
kind: Secret
metadata:
  name: ssh-key-secret
  namespace: openstack
stringData:
  ssh_key: |
$SSH_PRIVATE_KEY
EOF

echo $OUT

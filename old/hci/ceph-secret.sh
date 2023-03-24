#!/bin/bash

cat <<EOF > ceph-secret.yaml
--- 
apiVersion: v1
kind: Secret
metadata:
  name: ceph-client-conf
  namespace: openstack
stringData:
  ceph.client.openstack.keyring: |
EOF

cat ceph.client.openstack.keyring | sed 's/^/    /' >> ceph-secret.yaml

cat <<EOF >> ceph-secret.yaml
  ceph.conf: |
EOF

cat ceph.conf | sed 's/^/    /' >> ceph-secret.yaml

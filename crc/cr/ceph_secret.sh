#!/bin/bash

OUT=cephSecret.yaml
SEC=~/cephBackend

declare -A cephBackend
for KEY in cephFsid cephMons cephClientKey cephUser; do
    cephBackend[$KEY]=$(grep $KEY ~/cephBackend | awk {'print $2'} | sed s/\"//g)
done;
cephBackend[glance]=$(grep glance ~/cephBackend -A 1 \
                        | tail -1 | awk {'print $2'} | sed s/\"//g)
cephBackend[cinder]=$(grep cinder ~/cephBackend -A 1 \
                        | tail -1 | awk {'print $2'} | sed s/\"//g)

cat <<EOF > $OUT
--- 
apiVersion: v1
kind: Secret
metadata:
  name: ceph-client-conf
  namespace: openstack
stringData:
  ceph.client.${cephBackend[cephUser]}.keyring: |
    [client.${cephBackend[cephUser]}]
        key = ${cephBackend[cephClientKey]}
        caps mgr = "allow *"
        caps mon = "profile rbd"
        caps osd = "profile rbd pool=${cephBackend[glance]}, profile rbd pool=${cephBackend[cinder]}"
  ceph.conf: |
    [global]
    fsid = ${cephBackend[cephFsid]}
    mon_host = ${cephBackend[cephMons]}
EOF

#oc create -f cephSecret.yaml
#oc get secret ceph-client-conf -o json | jq -r '.data."ceph.conf"' | base64 -d

#!/bin/bash

SEC=~/cephBackend
SRC=glance_v1beta1_glance.yaml
OUT=glance_v1beta1_glance_ceph.yaml
if [[ -e $OUT ]]; then
    rm -f $OUT
fi

declare -A cephBackend
for KEY in cephFsid cephMons cephClientKey cephUser; do
    cephBackend[$KEY]=$(grep $KEY ~/cephBackend | awk {'print $2'})
done;
cephBackend[cephPools]=$(tail -1 ~/cephBackend | awk {'print $2'})

cat <<EOF > cephBackend.tmp
  cephBackend:
    cephFsid: ${cephBackend[cephFsid]}
    cephMons: ${cephBackend[cephMons]}
    cephClientKey: ${cephBackend[cephClientKey]}
    cephUser: ${cephBackend[cephUser]}
    cephPools:
      glance:
        name: ${cephBackend[cephPools]}
EOF

cat $SRC cephBackend.tmp > $OUT
rm -f cephBackend.tmp

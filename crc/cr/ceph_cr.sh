#!/bin/bash

# IN:  ./ceph_cr.sh [cinder | glance]
# OUT: cinder_v1beta1_cinder_ceph.yaml or glance_v1beta1_glance_ceph.yaml
# The output file should have a cephBackend

for T in cinder glance; do
    if [[ $1 == $T ]]; then
	TYPE=$T
    fi
    OLD_OUT=${T}_v1beta1_${T}_ceph.yaml
    if [[ -e $OLD_OUT ]]; then
	rm -f $OLD_OUT
    fi
done
if [[ -z $TYPE ]]; then
    echo "USAGE $0: [cinder|glance]"
    exit 1
fi
SRC=${TYPE}_v1beta1_${TYPE}.yaml
OUT=${TYPE}_v1beta1_${TYPE}_ceph.yaml
SEC=~/cephBackend

declare -A cephBackend
for KEY in cephFsid cephMons cephClientKey cephUser; do
    cephBackend[$KEY]=$(grep $KEY ~/cephBackend | awk {'print $2'})
done;
cephBackend[cephPools]=$(grep $TYPE ~/cephBackend -A 1 | tail -1 | awk {'print $2'})

cat <<EOF > cephBackend.tmp
  cephBackend:
    cephFsid: ${cephBackend[cephFsid]}
    cephMons: ${cephBackend[cephMons]}
    cephClientKey: ${cephBackend[cephClientKey]}
    cephUser: ${cephBackend[cephUser]}
    cephPools:
      $TYPE:
        name: ${cephBackend[cephPools]}
EOF

cat $SRC cephBackend.tmp > $OUT
rm -f cephBackend.tmp

echo $OUT

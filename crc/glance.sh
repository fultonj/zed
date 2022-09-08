#!/bin/bash

if [[ ! -d ~/install_yamls ]]; then
    echo "~/install_yamls missing (did you run crc.sh?)"
    exit 1
fi

eval $(crc oc-env)
oc login -u kubeadmin -p 12345678 https://api.crc.testing:6443

pushd ~/install_yamls

# deploy glance operator
make glance

sleep 60
make glance_deploy

# modify glance to use use 1G PVs created by crc_storage
GLANCE_CR=~/install_yamls/out/openstack/glance/cr/glance_v1beta1_glanceapi.yaml

# To use external ceph, add the following to a copy of the $GLANCE_CR
# cephBackend:
#   cephFsid: "<fsid>"
#   cephMons: "<ip1>,<ip2>,<ip3>"
#   cephClientKey: "<key>"
#   cephUser: "<user>"
#   cephPools:
#     glance:
#       name: "<pool>"

if [[ -e $GLANCE_CR ]]; then
    sed -i $GLANCE_CR -e s/10G/1G/g
    echo '  storageClass: local-storage' >> $GLANCE_CR
    oc apply -f $GLANCE_CR
    sleep 60
else
    echo "WARNING: $GLANCE_CR does not exist yet. So apply it later."
    echo "oc apply -f $GLANCE_CR"
fi

# OP=$(oc get pods -l control-plane=controller-manager -o name  | grep glance)
# oc describe $OP
# oc logs $OP

popd

oc get pods -l service=glance

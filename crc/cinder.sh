#!/bin/bash

if [[ ! -d ~/install_yamls ]]; then
    echo "~/install_yamls missing (did you run crc.sh?)"
    exit 1
fi

eval $(crc oc-env)
oc login -u kubeadmin -p 12345678 https://api.crc.testing:6443

pushd ~/install_yamls
make cinder_prep
make cinder
sleep 60
make cinder_deploy
popd

CINDER_CR=~/install_yamls/out/openstack/cinder/cr/cinder_v1beta1_cinder.yaml

echo "Updating Cinder CR to use cephBackend"
pushd cr
echo "Backing up $CINDER_CR"
cp -v $CINDER_CR $(basename $CINDER_CR).bak
CR=$(bash ceph_cr.sh cinder)
oc delete -f $CINDER_CR
cp $CR $CINDER_CR
sleep 10
oc kustomize ~/install_yamls/out/openstack/cinder/cr | oc apply -f -
popd

# oc logs cinder-volume-ceph-0 cinder-volume
# oc logs cinder-volume-ceph-0 probe
# oc logs cinder-volume-ceph-0 init

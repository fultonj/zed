#!/bin/bash

MAKE=1
BACKUP=1

if [[ ! -d ~/install_yamls ]]; then
    echo "~/install_yamls missing (did you run crc.sh?)"
    exit 1
fi

eval $(crc oc-env)
oc login -u kubeadmin -p 12345678 https://api.crc.testing:6443

RABBITS=$(oc get pods | grep default-security-context | wc -l)
if [[ $RABBITS -eq 0 ]]; then
    echo "It looks like rabbit is not running. Exiting."
    echo "oc get pods | grep default-security-context"
    exit 1
fi

if [[ $MAKE -eq 1 ]]; then
    pushd ~/install_yamls
    make cinder_prep
    make cinder
    sleep 60
    make cinder_deploy
    popd
fi

CINDER_CR=~/install_yamls/out/openstack/cinder/cr/cinder_v1beta1_cinder.yaml

echo "Updating Cinder CR to use cephBackend and setting password for rabbit transport URL"
pushd cr
if [[ $BACKUP -eq 1 ]]; then
    echo "Backing up $CINDER_CR"
    cp -v $CINDER_CR $(basename $CINDER_CR).bak
fi
CR=$(bash ceph_cr.sh cinder)
# xargs trims a string as a side effect
IP=$(bash rabbit_user_ip.sh | xargs)
sed -i $CR -e "s/rabbitmq.openstack.svc/$IP/"
oc delete -f $CINDER_CR
cp $CR $CINDER_CR
sleep 10
oc kustomize ~/install_yamls/out/openstack/cinder/cr | oc apply -f -
popd

# oc logs cinder-volume-ceph-0 cinder-volume
# oc logs cinder-volume-ceph-0 probe
# oc logs cinder-volume-ceph-0 init

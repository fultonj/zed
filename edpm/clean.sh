#!/bin/bash

DPJOBS=1
EDPM=1
CONTROL=0
CEPH=0
CRC=0

# 0 and 1
NODES=1
WAIT=50

if [ $DPJOBS -eq 1 ]; then
    eval $(crc oc-env)
    oc login -u kubeadmin -p 12345678 https://api.crc.testing:6443
    oc get pods -o name | grep dataplane | xargs oc delete
    oc get pods -o name | grep nova-edpm  | xargs oc delete
fi

if [ $EDPM -eq 1 ]; then
    pushd ~/install_yamls/devsetup
    for I in $(seq 0 $NODES); do
        make edpm_compute_cleanup EDPM_COMPUTE_SUFFIX=$I;
    done
    popd
fi

if [ $CONTROL -eq 1 ]; then
    pushd ~/install_yamls
    make openstack_deploy_cleanup
    echo "Deleted control plane pods"
    date
    echo "Waiting $WAIT seconds before deleting openstack operators"
    for I in $(seq 0 $WAIT); do
        echo -n .
        sleep 1;
    done
    make openstack_cleanup
    # side effect of the new approach we're trying with
    # OpenStack operator to reduce bundle size.  
    make manila_cleanup
    popd
fi

if [ $CEPH -eq 1 ]; then
    pushd ~/install_yamls
    make ceph_cleanup
    popd
    eval $(crc oc-env)
    oc login -u kubeadmin -p 12345678 https://api.crc.testing:6443
    oc delete secret ceph-conf-files
    oc get secret | grep ceph
fi

if [ $CRC -eq 1 ]; then
    pushd ~/install_yamls
    make crc_storage_cleanup
    crc cleanup
    popd
fi

unset OPENSTACK_CTLPLANE
env | grep -i openstack

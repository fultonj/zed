#!/bin/bash

DPJOBS=1
EDPM=1
CONTROL=1
CEPH=1
CRC=0

NODES=2
WAIT=50

if [ $DPJOBS -eq 1 ]; then
    eval $(crc oc-env)
    oc login -u kubeadmin -p 12345678 https://api.crc.testing:6443
    oc get pods -o name | grep dataplane | xargs oc delete
fi

if [ $EDPM -eq 1 ]; then
    cd ~/install_yamls/devsetup
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

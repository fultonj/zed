#!/bin/bash

DPJOBS=0
EDPM=0
DATAPLANE=0
CONTROL=0
OPERATORS=0
CEPH=0
CRC=0

# node0 node1 node2
NODES=2
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

if [ $DATAPLANE -eq 1 ]; then
    bash data_plane_cr.sh DELETE
fi

if [ $CONTROL -eq 1 ]; then
    pushd ~/install_yamls
    make openstack_deploy_cleanup
    echo "Deleted control plane pods"
fi

if [ $OPERATORS -eq 1 ]; then
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
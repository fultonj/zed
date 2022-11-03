#!/bin/bash

GLANCE=1
CINDER=1
CR_DELETE=0
META=0
REPLIACS=0

eval $(crc oc-env)
oc login -u kubeadmin -p 12345678 https://api.crc.testing:6443

if [[ $GLANCE -eq 1 ]]; then
    echo "Scaling glance: replicas: $REPLIACS"
    oc get pods | grep glance
    oc get deployment | grep glance
    oc scale deployment glance-operator-controller-manager --replicas=$REPLIACS
    if [[ $REPLIACS -eq 0 ]]; then
        oc scale deployment glance-external-api --replicas=$REPLIACS
        oc scale deployment glance-internal-api --replicas=$REPLIACS
    fi
    date
    echo "sleeping 30 seconds"
    sleep 30
    echo "greping for glance pods"
    oc get pods | grep glance
fi

if [[ $CINDER -eq 1 ]]; then
    echo "Scaling cinder: replicas: $REPLIACS"
    oc get pods | grep cinder
    oc get deployment | grep cinder
    pushd cr
    bash meta_cr.sh $REPLIACS
    oc apply -f core_v1beta1_openstackcontrolplane_ceph_backend.yaml
    popd
    oc scale deployment cinder-operator-controller-manager --replicas=$REPLIACS
    if [[ $REPLIACS -eq 0 ]]; then
        oc scale deployment cinder --replicas=$REPLIACS
    fi
    echo "sleeping 30 seconds"
    sleep 30
    echo "greping for cinder pods"
    oc get pods | grep cinder
fi

if [[ $CR_DELETE -eq 1 ]]; then
    oc delete -f cr/core_v1beta1_openstackcontrolplane_default.yaml
fi

if [[ $META -eq 1 ]]; then
    for op in openstack placement; do
        oc scale deployment $op-operator-controller-manager --replicas=$REPLIACS
    done
fi

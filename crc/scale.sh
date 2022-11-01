#!/bin/bash

GLANCE=1
ALL=0
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

if [[ $ALL -eq 1 ]]; then
    for op in openstack cinder placement; do
        oc scale deployment $op-operator-controller-manager --replicas=0
    done
fi

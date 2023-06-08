#!/bin/bash

if [ -z "$1" ]; then
    OPERATOR=dataplane-operator-controller-manager
else
    OPERATOR=$1
fi

VERBOSE=1
INTERVAL=1

eval $(crc oc-env)
oc login -u kubeadmin -p 12345678 https://api.crc.testing:6443

if [[ $VERBOSE > 0 ]]; then
    oc get deploy -n openstack-operators $OPERATOR
    echo "Check every $INTERVAL second to ensure $OPERATOR is not running"
fi
    
while [ 1 ]; do
    COUNT=$(oc get deploy -n openstack-operators $OPERATOR --no-headers=true \
                | awk {'print $3'})
    if [[ $COUNT > 0 ]]; then
        oc scale deploy -n openstack-operators $OPERATOR --replicas=0
        sleep 1
        oc get deploy -n openstack-operators $OPERATOR
    fi
    if [[ $VERBOSE > 0 ]]; then
        echo -n "."
    fi
    sleep $INTERVAL
done

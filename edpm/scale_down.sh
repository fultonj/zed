#!/bin/bash

eval $(crc oc-env)
oc login -u kubeadmin -p 12345678 https://api.crc.testing:6443

VERBOSE=1
INTERVAL=1

if [[ $VERBOSE > 0 ]]; then
    oc get deploy dataplane-operator-controller-manager
    echo "Check every $INTERVAL second to ensure dataplane-operator-controller-manager is not running"
fi
    
while [ 1 ]; do
    COUNT=$(oc get deploy dataplane-operator-controller-manager --no-headers=true \
                | awk {'print $3'})
    if [[ $COUNT > 0 ]]; then
        oc scale deploy dataplane-operator-controller-manager --replicas=0
        sleep 1
        oc get deploy dataplane-operator-controller-manager
    fi
    if [[ $VERBOSE > 0 ]]; then
        echo -n "."
    fi
    sleep $INTERVAL
done

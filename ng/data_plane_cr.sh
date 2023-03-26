#!/bin/bash

THREE=1
INV=1
VERBOSE=0
DELETE=0

if [ ! -z "$1" ]; then
    if [[ $1 -eq "DELETE" ]]; then
        DELETE=1
    fi
fi

eval $(crc oc-env)
oc login -u kubeadmin -p 12345678 https://api.crc.testing:6443

if [ $THREE -eq 1 ]; then
    for TYPE in $(echo OpenStackDataPlane{,Role,Node}); do
        echo $TYPE
        oc get $TYPE
        for INSTANCE in $(oc get $TYPE --no-headers=true -o name); do
            echo $INSTANCE
            if [ $VERBOSE -eq 1 ]; then
                echo '~~~'
                oc get $INSTANCE -o yaml
                echo '~~~'
            fi
            if [ $DELETE -eq 1 ]; then
                echo "oc delete $INSTANCE"
                oc delete $INSTANCE
            fi
        done
        echo -e "\n"
    done
fi

if [ $INV -eq 1 ]; then
    echo Inventory
    oc get configmap | grep dataplane | grep inventory
    for INSTANCE in $(oc get configmap -o name | grep dataplane | grep inventory); do
        if [ $VERBOSE -eq 1 ]; then
            echo '~~~'
            oc get $INSTANCE -o yaml
            echo '~~~'
        fi
        if [ $DELETE -eq 1 ]; then
            echo "oc delete $INSTANCE"
            oc delete $INSTANCE
        fi
    done
fi

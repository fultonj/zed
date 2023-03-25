#!/bin/bash

ATTACH=0
EDPM_NODE=0
DEPS=0
OPER=0
CONTROL=0
MARIA=0
SCHED=0
EDPM_DEPLOY=0

# 0 and 1
NODES=1
WAIT=50
CONTROL_PODS=17


# Run after you have deployed CRC with something like this:
# make CPUS=56 MEMORY=262144 DISK=200 crc

if [[ ! -d ~/install_yamls ]]; then
    echo "Error: ~/install_yamls is missing"
    exit 1
fi
pushd ~/install_yamls

eval $(crc oc-env)
oc login -u kubeadmin -p 12345678 https://api.crc.testing:6443
if [[ $? -gt 0 ]]; then
    echo "Error: Unable to authenticate to OpenShift"
    exit 1
fi

if [ $ATTACH -eq 1 ]; then
    make crc_attach_default_interface
fi

if [ $EDPM_NODE -eq 1 ]; then
    pushd ~/install_yamls/devsetup
    for I in $(seq 0 $NODES); do
        make edpm_compute EDPM_COMPUTE_SUFFIX=$I;
        make edpm_compute_repos EDPM_COMPUTE_SUFFIX=$I;
    done
    popd
fi

cd ..

if [ $DEPS -eq 1 ]; then
    make crc_storage
    make input
fi

if [ $OPER -eq 1 ]; then
    make openstack
fi

if [ $CONTROL -eq 1 ]; then
    oc get pods | grep controller
    echo -e "\n\nThere should be $CONTROL_PODS Running OpenStack operator pods above."
    echo -e "(This script will wait indefinitely for all $CONTROL_PODS of them)"
    while [[ $(oc get pods | grep controller | grep Running | wc -l) -ne $CONTROL_PODS ]];
    do
        echo -n .
        sleep 1
    done
    OPENSTACK_REPO=https://github.com/openstack-k8s-operators/openstack-operator.git \
        OPENSTACK_BRANCH=master \
        make openstack_deploy
fi

if [ $MARIA -eq 1 ]; then
    # switch to a wait?
    if [[ $(oc get pods -o name | grep maria | grep -v controller | wc -l) -eq 1 ]]; then
        oc exec -it pod/mariadb-openstack -- mysql -uroot -p12345678 -e "set global max_connections = 4000;"
        oc exec -it  pod/mariadb-openstack -- mysql -uroot -p12345678 -e "show variables like \"max_connections\";"
    else
        echo "pod/mariadb-openstack is not running so unable to increase max_connections"
    fi
fi

# SCHED
# wait for nova
#oc get pods | grep nova | grep scheduler
#oc delete pod -l service=nova-scheduler

# EDPM_DEPLOY
#oc get pods --no-headers=true | egrep -v "Running|Completed" | wc -l # should be 0
#DATAPLANE_SINGLE_NODE=false make edpm_deploy

popd

#!/bin/bash

ATTACH=0
EDPM_NODE=0
EDPM_NODE_REPOS=0
FORCE_IPS=0
CRC_STORAGE=0
DEPS=0
OPER=0
CONTROL=0
MARIA=0
SCHED=0
EDPM_DEPLOY=0

# 0 and 1
NODES=1
CONTROL_PODS=16


# Run after you have deployed CRC with something like this:
# make CPUS=56 MEMORY=262144 DISK=200 crc

if [[ ! -d ~/install_yamls ]]; then
    echo "Error: ~/install_yamls is missing"
    exit 1
fi
pushd ~/install_yamls/devsetup

eval $(crc oc-env)
oc login -u kubeadmin -p 12345678 https://api.crc.testing:6443
if [[ $? -gt 0 ]]; then
    echo "Error: Unable to authenticate to OpenShift"
    exit 1
fi

function edpm_ready() {
    # Determine IP based on EDPM_COMPUTE_SUFFIX
    # sleep until that IP answers pings
    IP=$( sudo virsh -q domifaddr edpm-compute-$1 \
              | awk 'NF>1{print $NF}' | cut -d/ -f1 )
    while [ 1 ]; do
        ping -c 1 $IP
        if [[ $? -eq 0 ]]; then
            break
        fi
        sleep 1
    done
}

if [ $ATTACH -eq 1 ]; then
    make crc_attach_default_interface
fi

if [ $EDPM_NODE -eq 1 ]; then
    for I in $(seq 0 $NODES); do
        make edpm_compute EDPM_COMPUTE_SUFFIX=$I;
    done
fi

if [ $EDPM_NODE_REPOS -eq 1 ]; then
    for I in $(seq 0 $NODES); do
        edpm_ready $I
        make edpm_compute_repos EDPM_COMPUTE_SUFFIX=$I;
    done
fi

if [ $FORCE_IPS -eq 1 ]; then
    for I in $(seq 0 $NODES); do
        edpm_ready $I
    done
    # update this script to handle variable number of nodes
    bash ~/zed/edpm/force_ips.sh
fi

cd ..

if [ $CRC_STORAGE -eq 1 ]; then
    make crc_storage
fi

if [ $DEPS -eq 1 ]; then
    make input
fi

if [ $OPER -eq 1 ]; then
    make openstack
fi

if [ $CONTROL -eq 1 ]; then
    oc get pods | grep controller
    echo -e "\n\nThere should be $CONTROL_PODS Running OpenStack operator pods above."
    echo -e "(This script will wait indefinitely for all $CONTROL_PODS of them)"
    while [[ $(oc get pods | grep controller | grep Running | wc -l) -lt $CONTROL_PODS ]];
    do
        echo -n .
        sleep 1
    done
    # unset OPENSTACK_CTLPLANE
    # change repo or branch from explicit defaults as needed
    OPENSTACK_REPO=https://github.com/openstack-k8s-operators/openstack-operator.git \
        OPENSTACK_BRANCH=master \
        make openstack_deploy
fi

if [ $MARIA -eq 1 ]; then
    oc get pods  | grep maria | grep -v controller
    echo -e "\n\nThere should be at least one Running MariaDB pod above."
    echo -e "(This script will wait indefinitely for it and then increase max connections)"
    while [[ $(oc get pods | grep maria | grep -v controller | grep Running | wc -l) -lt 1 ]]; do
        echo -n .
        sleep 1
    done
    oc exec -it pod/mariadb-openstack -- mysql -uroot -p12345678 -e "set global max_connections = 4000;"
    oc exec -it  pod/mariadb-openstack -- mysql -uroot -p12345678 -e "show variables like \"max_connections\";"
fi

if [ $SCHED -eq 1 ]; then
    # we need to restart nova-scheduler to pick up cell1, this is a known issue
    oc get pods | grep nova | grep scheduler
    echo -e "\n\nThere should be at least one Running nova-scheduler pod above."
    echo -e "(This script will wait indefinitely for it)"
    while [[ $(oc get pods | grep nova | grep scheduler | grep Running | wc -l) -lt 1 ]]; do
        echo -n .
        sleep 1
    done
    oc get pods | grep cell1 | grep Running
    echo -e "\n\nThere should be two Running cell1 pods above."
    echo -e "(This script will wait indefinitely for them and then bouce scheduler)"
    while [[ $(oc get pods | grep cell1 | grep Running | wc  -l) -ne 2 ]]; do
        echo -n .
        sleep 1
    done
    echo -e "\n"
    echo "Deleting pods for service nova-scheduler so they will pick up cell1 when they restart"
    oc delete pod -l service=nova-scheduler
    sleep 1
    oc get pods | grep nova | grep scheduler
    echo "Waiting 5 seconds before checking again if it's running"
    sleep 5
    oc get pods | grep nova | grep scheduler
fi

if [ $EDPM_DEPLOY -eq 1 ]; then
    echo "Looking for pods which are not Running or Completed"
    oc get pods --no-headers=true | egrep -v "Running|Completed" # should be 0
    echo -e "\n\nThere should be zero pods listed above"
    echo -e "(This script will wait indefinitely to reach 0 before EDPM_DEPLOY)"
    while [[ $(oc get pods --no-headers=true | egrep -v "Running|Completed" |  wc -l) -ne 0 ]]; do
        echo -n .
        sleep 1
    done
    DATAPLANE_SINGLE_NODE=false make edpm_deploy

    echo -e "\n\nShould be running now. Run the following next...\n"
    echo 'watch -n 1 "oc get pods | grep edpm"'
    echo "./watch_ansible.sh"
    echo "./test.sh"
    echo -e "\n"
fi

popd

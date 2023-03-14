#!/bin/bash
# Executing Ansible with DataPlaneNode CRs

SSH_TEST=0
CHANGE_IP=1
CEPH_TEST=1
CREATE_ROLE=1
CREATE_NODE=1
INV=1
LOGS=0
CLEAN=0
KILLPODS=0

pushd /home/fultonj/zed/edpm

eval $(crc oc-env)
oc login -u kubeadmin -p 12345678 https://api.crc.testing:6443

IP=$( sudo virsh -q domifaddr edpm-compute-0 | awk 'NF>1{print $NF}' | cut -d/ -f1 )
if [ $SSH_TEST -eq 1 ]; then
    ssh -i ~/install_yamls/out/edpm/ansibleee-ssh-key-id_rsa root@$IP "uname"
fi

if [ $CEPH_TEST -eq 1 ]; then
    if [[ $(oc get secret ceph-conf-files --no-headers=true | wc -l) -eq 0 ]]; then
        oc create -f ceph-conf-files.yaml
    fi
fi

# Ensure the CR has been updated with the correct IP
if [[ ! $(grep $IP edpm-compute-0.yaml | wc -l) -gt 1 ]]; then
    echo "$IP not in edpm-compute-0.yaml"
    if [[ $CHANGE_IP -eq 1 ]]; then
        sed -i edpm-compute-0.yaml -e s/192.168.122.100/$IP/g
    else
        exit 1
    fi
fi

if [ $CLEAN -eq 1 ]; then
    bash delete_node.sh
fi

if [ $CREATE_ROLE -eq 1 ]; then
    oc create -f edpm-role-0.yaml
fi

echo -e "\nCR\n"
oc get OpenStackDataPlaneRole edpm-role-0 -o yaml

if [ $CREATE_NODE -eq 1 ]; then
    oc create -f edpm-compute-0.yaml
fi

# read
echo -e "\nCR\n"
oc get OpenStackDataPlaneNode edpm-compute-0 -o yaml

if [ $INV -eq 1 ]; then
    sleep 2
    echo -e "\nInventory\n"
    for I in $(oc get configmap -o name | grep dataplane | grep inventory); do
        oc get -o yaml $I
    done
fi

if [ $LOGS -eq 1 ]; then
    echo -e "\nWaiting for Ansible Logs"
    while [[ $(oc get pods | grep dataplane-deployment | egrep "Error|Running" | wc -l) -eq 0 ]]; do
        echo -n "."
        sleep 0.5
    done
    echo ""
    oc logs $(oc get pods | grep dataplane-deployment | egrep "Error|Running" | awk {'print $1'} | tail -1)
fi

if [ $CLEAN -eq 1 ]; then
    bash delete_node.sh
fi

if [ $KILLPODS  -eq 1 ]; then
    # kill pods left over from previous run?
    oc get pods -o name | grep dataplane-deployment | xargs oc delete
fi

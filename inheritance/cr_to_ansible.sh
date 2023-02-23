#!/bin/bash
# Executing Ansible with DataPlaneNode CRs

CREATE=1
INV=1
LOGS=1
CLEAN=1
KILLPODS=0

# This example shows how to create a OpenStackDataPlaneNode
# CR and observe Ansible configuring the network. The
# [install_yamls devsetup](https://github.com/openstack-k8s-operators/install_yamls/tree/master/devsetup)
# has been used to `make edpm_compute` nodes. This
# command also creates an SSH key pair which may be
# used to SSH to the EDPM node. To see the keypair
# use `oc get secret ansibleee-ssh-key-secret -o yaml`.
# 
# Determine the IP address of the EDPM node.
# ```
# IP=$( sudo virsh -q domifaddr edpm-compute-0 | awk 'NF>1{print $NF}' | cut -d/ -f1 )
# ```
# If you need to directly debug on one VM, SSH like this:
# ```
# ssh -i ~/install_yamls/out/edpm/ansibleee-ssh-key-id_rsa root@$IP
# ```
# Create a DataPlaneNode CR (e.g. network-edpm-compute-0.yaml) with the IP above set to the
# ansibleHost and define an additional networks list of configuration which Ansible
# will apply when it runs.
# 
# Have k8s create the resource and observe the Ansible run output.
# ```
# oc create -f network-edpm-compute-0.yaml
# oc logs $(oc get pods -o name | grep dataplane-deployment-configure-network | tail -1 )
# ```
# 
# Observe the inventory which was created.
# ```
# oc get configmap dataplanenode-network-edpm-compute-0-inventory -o yaml
# ```
# 
# Delete the resource, it's inventory and pods.

pushd /home/fultonj/zed/inheritance

eval $(crc oc-env)
oc login -u kubeadmin -p 12345678 https://api.crc.testing:6443

IP=$( sudo virsh -q domifaddr edpm-compute-0 | awk 'NF>1{print $NF}' | cut -d/ -f1 )
ssh -i ~/install_yamls/out/edpm/ansibleee-ssh-key-id_rsa root@$IP "uname"

# Ensure the CR has been updated with the correct IP
if [[ ! $(grep $IP network-edpm-compute-0.yaml | wc -l) -gt 1 ]]; then
    echo "$IP not in network-edpm-compute-0.yaml"
    exit 1
fi

if [ $CREATE -eq 1 ]; then
    oc create -f network-edpm-compute-0.yaml
fi

# read
echo -e "\nCR\n"
oc get OpenStackDataPlaneNode network-edpm-compute-0 -o yaml

if [ $INV -eq 1 ]; then
    echo -e "\nInventory\n"
    oc get configmap dataplanenode-network-edpm-compute-0-inventory -o yaml
fi

if [ $LOGS -eq 1 ]; then
    echo -e "\nWaiting for Ansible Logs"
    while [[ $(oc get pods | grep dataplane-deployment | egrep "Error" | wc -l) -eq 0 ]]; do
        echo -n "."
        sleep 0.5
    done
    echo ""
    oc logs $(oc get pods | grep dataplane-deployment | egrep "Error" | awk {'print $1'} | tail -1)
fi

if [ $CLEAN -eq 1 ]; then
    echo -e "\nCleaning\n"
    oc delete -f network-edpm-compute-0.yaml
    oc get configmap -o name | grep dataplanenode | xargs oc delete
fi

if [ $KILLPODS  -eq 1 ]; then
    # kill pods left over from previous run?
    oc get pods -o name | grep dataplane-deployment | xargs oc delete
fi

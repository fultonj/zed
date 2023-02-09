#!/bin/bash
# Its possible to create a node directly (outside of a role CR)
# and define its role. If the following CR is created:
#
# apiVersion: dataplane.openstack.org/v1beta1
# kind: OpenStackDataPlaneNode
# metadata:
#   name: openstackdataplanenode-sample-3-from
# spec:
#   role: openstackdataplanerole-sample
#   node:
#     hostName: openstackdataplanenode-sample-3.localdomain
#     networks:
#       - network: ctlplane
#         fixedIP: 192.168.122.20
#     ansibleHost: 192.168.122.20
#
# Then the role openstackdataplanerole-sample will be updated so that
# its `dataPlaneNodes` list contains the new node.
#
#   dataPlaneNodes:
#     - name: openstackdataplanenode-sample-3-from
#       nodeFrom: openstackdataplanenode-sample-3-from
#
# and the node openstackdataplanenode-sample-3-from will inherit values
# from `nodeTemplate`. The entry for the new node on dataplane node list
# won't contain it's details. Instead a nodeFrom entry will exist which
# indicates that the CR for the node can be used to determine the values.
#
# Assumes naive_inheritance.sh has been run once with CLEAN=0
# Because the role needs to exist for it to inherit from it.

VERBOSE=1
INV=1
CLEAN=1

pushd /home/fultonj/zed/inheritance

eval $(crc oc-env)
oc login -u kubeadmin -p 12345678 https://api.crc.testing:6443

NODE3_EXISTS=$(oc get openstackdataplanenodes.dataplane.openstack.org | \
                   grep from-inheritance | wc -l)

if [[ $NODE3_EXISTS -gt 0 ]]; then
    oc delete -f node3_from.yaml
fi

echo ""
echo "Creating node3_from"
echo "-------------------"
oc create -f node3_from.yaml

echo ""
echo "Showing role of node3_from"
echo "--------------------------"
oc get openstackdataplaneroles.dataplane.openstack.org -o yaml

echo ""
echo "Showing inventory of node3_from"
echo "-------------------------------"
oc get configmap -o yaml \
   dataplanenode-openstackdataplanenode-sample-3-from-inheritance-inventory

if [[ $INV -gt 0 ]]; then
    echo "Deleting inventory created by the node"
    if [[ $CLEAN -eq 1 ]]; then
        for I in $(oc get configmap | grep from-inheritance | awk {'print $1'}); do
            oc delete configmap $I
        done
    fi
fi

if [[ $CLEAN -gt 0 ]]; then
    oc delete -f node3_from.yaml
fi

#!/bin/bash
RECREATE_CRDS=1
NODE=1
ROLE=1
CLEAN=1

eval $(crc oc-env)
oc login -u kubeadmin -p 12345678 https://api.crc.testing:6443

if [[ $RECREATE_CRDS -gt 0 ]]; then
    pushd ~/dataplane-operator
    oc delete crd openstackdataplanenodes.dataplane.openstack.org
    oc delete crd openstackdataplaneroles.dataplane.openstack.org
    oc delete crd openstackdataplanes.dataplane.openstack.org
    oc apply -f config/crd/bases/
    popd
fi

pushd ~/zed/inheritance

if [[ $NODE -gt 0 ]]; then
    oc create -f node3_from.yaml
    echo "Showing node"
    echo "------------"
    oc get OpenStackDataPlaneNode openstackdataplanenode-sample-3-from-inheritance -o yaml
    echo ""
    echo "We can see the hostName and ansibleHost above."
    echo ""
    oc get OpenStackDataPlaneNode openstackdataplanenode-sample-3-from-inheritance -o yaml \
        | grep -i host
    echo ""
fi

if [[ $ROLE -gt 0 ]]; then
    oc create -f role.yaml
    echo ""
    echo "Showing role"
    echo "------------"
    oc get OpenStackDataPlaneRole openstackdataplanerole-sample-inheritance -o yaml
    echo ""
    echo "Is the hostName and ansibleHost in the dataPlaneNodes list ^ above?"
    echo ""
    oc get OpenStackDataPlaneRole openstackdataplanerole-sample-inheritance -o yaml \
        | grep -i host
    echo ""
fi

if [[ $CLEAN -gt 0 ]]; then
    if [[ $NODE -gt 0 ]]; then
        oc delete -f node3_from.yaml
    fi
    if [[ $ROLE -gt 0 ]]; then
        echo "Deleting role"
        oc delete -f role.yaml
    fi
fi

popd

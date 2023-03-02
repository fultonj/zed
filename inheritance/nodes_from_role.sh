#!/bin/bash
# CLI test of what's described here:
#   https://github.com/openstack-k8s-operators/dataplane-operator/pull/16
#
# Logic of this test should probably later be moved to:
#   https://github.com/openstack-k8s-operators/dataplane-operator/
#   blob/main/controllers/suite_test.go

VERBOSE=1
INV=1
CLEAN=1

pushd /home/fultonj/zed/inheritance

function show_nodes() {
    NODES=$(oc get openstackdataplanenodes.dataplane.openstack.org \
                | grep sample | wc -l)
    if [[ $NODES -gt 0 ]]; then
        echo "$NODES inheritance nodes were created"
         oc get openstackdataplanenodes.dataplane.openstack.org | grep sample
    else
        echo "Zero nodes were created (but two should have been)"
    fi
    if [[ $VERBOSE -eq 1 ]]; then
        # 0th+1st item of zero-indexed list (items[1]) should be sample-inheritance nodes
        oc get openstackdataplanenodes.dataplane.openstack.org -o json | jq .items[0]
        oc get openstackdataplanenodes.dataplane.openstack.org -o json | jq .items[1]
    fi
    if [[ $INV -gt 0 ]]; then
        echo "Each node has its own inventory:"
        oc get configmap | grep sample
        if [[ $VERBOSE -eq 1 ]]; then
            for I in $(oc get configmap | grep sample | awk {'print $1'}); do
                oc get configmap $I -o yaml
            done
        fi
    fi
}

eval $(crc oc-env)
oc login -u kubeadmin -p 12345678 https://api.crc.testing:6443

# Clean nodes which were not cleaned up
NODES=$(oc get openstackdataplanenodes.dataplane.openstack.org \
            | grep sample | wc -l)
if [[ $NODES -gt 0 ]]; then
    for NODE in $(oc get openstackdataplanenodes.dataplane.openstack.org | \
                      grep sample | awk {'print $1'}); do
        oc delete OpenStackDataPlaneNode $NODE
    done
fi

# Create role
oc get role-sample-inheritance 2> /dev/null
if [[ $? -gt 0 ]]; then
    oc create -f role.yaml
fi

oc get openstackdataplaneroles.dataplane.openstack.org

if [[ $VERBOSE -eq 1 ]]; then
    # second item of zero-indexed list (items[1]) should be sample-inheritance
    oc get openstackdataplaneroles.dataplane.openstack.org -o json | jq .items[1]
fi

# Were any nodes created?
show_nodes

if [[ $CLEAN -eq 1 ]]; then
    if [[ $INV -gt 0 ]]; then
        echo "Deleting inventories created by the node"
        if [[ $CLEAN -eq 1 ]]; then
            for I in $(oc get configmap | grep sample | awk {'print $1'}); do
                oc delete configmap $I
            done
        fi
    fi
    NODES=$(oc get openstackdataplanenodes.dataplane.openstack.org \
                | grep sample | wc -l)
    if [[ $NODES -gt 0 ]]; then
        echo "Deleting nodes created by role"
        for NODE in $(oc get openstackdataplanenodes.dataplane.openstack.org | \
                          grep sample | awk {'print $1'}); do
            # If we're not faking it and controller works, manually clean up
            oc delete OpenStackDataPlaneNode $NODE
        done
    fi
fi

if [[ $CLEAN -eq 1 ]]; then
    # Should this role deletion should also delete the nodes?
    echo "Deleting role"
    oc delete -f role.yaml
fi
popd

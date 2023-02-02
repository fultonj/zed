#!/bin/bash
# CLI test of what's described here:
#   https://github.com/openstack-k8s-operators/dataplane-operator/pull/16
#
# Logic of this test should probably later be moved to:
#   https://github.com/openstack-k8s-operators/dataplane-operator/
#   blob/main/controllers/suite_test.go

FAKE_IT=1
VERBOSE=1

pushd /home/fultonj/zed/inheritance

function show_nodes() {
    NODES=$(oc get openstackdataplanenodes.dataplane.openstack.org \
                | grep inheritance | wc -l)
    if [[ $NODES -gt 0 ]]; then
        echo "$NODES inheritance nodes were created"
         oc get openstackdataplanenodes.dataplane.openstack.org
    else
        echo "Zero nodes were created (but two should have been)"
    fi
    if [[ $VERBOSE -eq 1 ]]; then
        # 2nd+3rd item of zero-indexed list (items[1]) should be sample-inheritance nodes
        oc get openstackdataplanenodes.dataplane.openstack.org -o json | jq .items[1]
        oc get openstackdataplanenodes.dataplane.openstack.org -o json | jq .items[2]
    fi
}

eval $(crc oc-env)
oc login -u kubeadmin -p 12345678 https://api.crc.testing:6443

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

if [[ $FAKE_IT -eq 1 ]]; then
    echo "Faking it by directly creating node1 and node2"
    oc create -f node1.yaml
    oc create -f node2.yaml
    show_nodes
    oc delete -f node1.yaml
    oc delete -f node2.yaml
fi

oc delete -f role.yaml
popd

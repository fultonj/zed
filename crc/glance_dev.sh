#!/bin/bash

# This assumes glance.sh was run first.
# It depends on resources created by ~/install_yamls/Makefile
# which are created when you run glance.sh. This script then
# replaces the default operator with a copy built from what
# was checked out of the glance-operator git.

GIT=0
CLEAN=0
BUILD=0
OPERATOR=0
DEPLOY=0
CRD=0
LOGS=0

MET_PORT=6666

eval $(crc oc-env)
oc login -u kubeadmin -p 12345678 https://api.crc.testing:6443

pushd ~/install_yamls

if [[ $GIT -eq 1 ]]; then
    mkdir -p develop_operator
    pushd develop_operator
    ln -s ~/glance-operator
    popd
fi


if [[ $CLEAN -eq 1 ]]; then
    make glance_cleanup
    oc delete deployment glance -n openstack
    oc delete pvc glance

    echo "Now run this in another window:"
    echo "  oc delete GlanceAPI glance"
    echo "The above will hang until you run w/ BUILD=OPERATOR=1"
    echo "Then the output of /bin/manager should that the new instance "
    echo "of the operator reconciled the 'oc delete' above."

    # for i in $(oc get pv | egrep "Failed|Released" | awk {'print $1'}); do
    #     oc patch pv $i --type='json' -p='[{"op": "remove", "path": "/spec/claimRef"}]';
    # done
fi

if [[ $BUILD -eq 1 ]]; then
    pushd develop_operator/glance-operator
    make generate
    make manifests
    make build
    popd
fi

if [[ $OPERATOR -eq 1 ]]; then
    pushd develop_operator/glance-operator
    OPERATOR_TEMPLATES=$PWD/templates ./bin/manager -metrics-bind-address ":$MET_PORT"
    popd
    # Note: run the above in a separate tmux pane to observe reconciliations
fi

if [[ $DEPLOY -eq 1 ]]; then
    # If the operator is up, and the resourceDelete has been
    # reconciled all the resources, then this triggers the GlanceAPI deployment
    oc kustomize ~/install_yamls/out/openstack/glance/cr | oc apply -f -

    # Watch the operator reconcile from ./bin/manager output
    # Note:
    #   If you see 'Waiting for GlanceAPI PVC to bind'
    #   and `oc get pvc` or `oc get pv | grep local` do not
    #   show it binding, then change 'volumeBindingMode: immediate'
    #   as per https://github.com/openstack-k8s-operators/install_yamls/pull/23
fi

if [[ $CRD -eq 1 ]]; then
    # By default you don't need this since the CRD
    # exists already from running glance.sh first.
    # If a patch adds a new parameter to the crd API, then redefine it
    CRD=$(oc get crds | grep -i glance | awk {'print $1'})
    oc delete crds $CRD
    oc create -f ~/install_yamls/develop_operator/glance-operator/config/crd/bases/glance.openstack.org_glanceapis.yaml
fi

if [[ $LOGS -eq 1 ]]; then
    OP=$(oc get pods -l control-plane=controller-manager -o name  | grep glance)
    oc describe $OP
    oc logs $OP

    SVC=$(oc get pods -l service=glance | grep Running | awk {'print $1'})
    oc logs $SVC
fi

popd

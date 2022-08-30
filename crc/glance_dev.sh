#!/bin/bash

CLEAN=0
GIT=0
BUILD=0
CRD=0
OPERATOR=0
DEPLOY=0
LOGS=0

MET_PORT=6666

eval $(crc oc-env)
oc login -u kubeadmin -p 12345678 https://api.crc.testing:6443

pushd ~/install_yamls

if [[ $CLEAN -eq 1 ]]; then
    oc delete deployment glance -n openstack
    oc delete pvc glance
    oc delete GlanceAPI glance
fi

if [[ $GIT -eq 1 ]]; then
    mkdir -p develop_operator
    pushd develop_operator
    git clone git@github.com:openstack-k8s-operators/glance-operator.git
    pushd glance-operator
    echo "Work here: $PWD"
    popd
    popd
fi

if [[ $BUILD -eq 1 ]]; then
    pushd develop_operator/glance-operator
    make build
    make generate
    make manifests
    popd
fi

if [[ $CRD -eq 1 ]]; then
    # If a patch adds a new parameter to the crd API, then redefine it
    CRD=$(oc get crds | grep -i glance | awk {'print $1'})
    oc delete crds $CRD
    oc create -f ~/install_yamls/develop_operator/glance-operator/config/crd/bases/glance.openstack.org_glanceapis.yaml
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

    # Note:
    #   If you see 'Waiting for GlanceAPI PVC to bind'
    #   and `oc get pvc` or `oc get pv | grep local` do not
    #   show it binding, then change 'volumeBindingMode: immediate'
    #   as per https://github.com/openstack-k8s-operators/install_yamls/pull/23
fi

if [[ $LOGS -eq 1 ]]; then
    POD=$(oc get pods | grep glance | grep manager | awk {'print $1'})
    oc logs $POD
fi

popd

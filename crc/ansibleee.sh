#!/bin/bash

GIT=0
CRD=1
BUILD=1
PUSH=0
DEPLOY=1
OPERATOR=1
UNDEPLOY=0
LOGS=1

MET_PORT=6668
if [[ -e /usr/bin/lsof ]]; then
    lsof -i :$MET_PORT
fi

eval $(crc oc-env)
oc login -u kubeadmin -p 12345678 https://api.crc.testing:6443

pushd ~/install_yamls

if [[ $GIT -eq 1 ]]; then
    mkdir -p develop_operator
    pushd develop_operator
    ln -s ~/ansibleee-operator
    popd
fi

if [[ $CRD -eq 1 ]]; then
    pushd ~/ansibleee-operator/example
    oc create -f swift-configmap.yaml
    oc create -f test-configmap-1.yaml
    oc create -f test-configmap-2.yaml
    popd
fi

if [[ $BUILD -eq 1 ]]; then
    pushd develop_operator/ansibleee-operator
    make generate
    make manifests
    make build
    popd
fi

if [[ $PUSH -eq 1 ]]; then
    # my env has /usr/bin/docker -> podman
    pushd develop_operator/ansibleee-operator
    make docker-build docker-push IMG=quay.io/fultonj/openstack-tripleo-ansible-ee:latest
    popd
fi

if [[ $DEPLOY -eq 1 ]]; then
    oc create -f ~/zed/crc/cr/ansibleee-test.yaml
    # Watch the operator reconcile from ./bin/manager output
fi

if [[ $OPERATOR -eq 1 ]]; then
    pushd develop_operator/ansibleee-operator
    # there is no OPERATOR_TEMPLATES=$PWD/templates in ansibleee-operator
    ./bin/manager -metrics-bind-address ":$MET_PORT"
    popd
    # Note: run the above in a separate tmux pane to observe reconciliations
fi

if [[ $UNDEPLOY -eq 1 ]]; then
    oc delete -f ~/zed/crc/cr/ansibleee-test.yaml
fi

if [[ $LOGS -eq 1 ]]; then
    oc logs $(oc get pods | grep ansible | awk {'print $1'})
fi

popd

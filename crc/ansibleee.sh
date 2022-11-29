#!/bin/bash

GIT=0
CRD=0
SSH=0
CEPH=0
BUILD=0
PUSH=0
DEPLOY=0
OPERATOR=0
UNDEPLOY=0
REDEPLOY=1
LOGS=1
KILLALL=0

CR_ANSIBLE=~/zed/crc/cr/ansibleee-extra-vol-ceph.yaml

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
    HAVE_ANSIBLE_CRD=$(oc get crd \
      -o=custom-columns=NAME:.metadata.name,CR_NAME:.spec.names.singular,SCOPE:.spec.scope \
      | grep ansible | wc -l)
    if [[ $HAVE_ANSIBLE_CRD -eq 0 ]]; then
        oc create -f ~/ansibleee-operator/config/crd/bases/redhat.com_ansibleees.yaml
    fi
fi

if [[ $SSH -eq 1 ]]; then
    pushd ~/zed/crc/cr
    KEY_CR=$(bash ssh_configmap.sh)
    if [[ -e $KEY_CR ]]; then
        oc create -f $KEY_CR
    fi
    popd
fi

if [[ $CEPH -eq 1 ]]; then
    pushd ~/zed/crc/cr
    bash ceph_secret.sh
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
    oc create -f $CR_ANSIBLE
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
    oc create -f $CR_ANSIBLE
fi

if [[ $REDEPLOY -eq 1 ]]; then
    oc delete -f $CR_ANSIBLE
    oc create -f $CR_ANSIBLE
    # let playbook finish
    sleep 5
fi

if [[ $LOGS -eq 1 ]]; then
    oc logs $(oc get pods | grep ansibleee-play- | awk {'print $1'} | tail -1)
fi

if [[ $KILLALL -eq 1 ]]; then
    oc delete -f  ~/ansibleee-operator/config/crd/bases/redhat.com_ansibleees.yaml
    oc create -f  ~/ansibleee-operator/config/crd/bases/redhat.com_ansibleees.yaml
fi

popd

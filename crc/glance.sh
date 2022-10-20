#!/bin/bash

MAKE=1
CEPH=0
DELETE=0

if [[ ! -d ~/install_yamls ]]; then
    echo "~/install_yamls missing (did you run crc.sh?)"
    exit 1
fi

eval $(crc oc-env)
oc login -u kubeadmin -p 12345678 https://api.crc.testing:6443

if [[ $MAKE -eq 1 ]]; then
    pushd ~/install_yamls
    # deploy glance operator with make
    make glance
    sleep 60
    # have glance operator deploy glance with make
    make glance_deploy
    popd
fi


# modify glance to use use 1G PVs created by crc_storage
if [[ -e ~/install_yamls/out/openstack/glance/cr/glance_v1beta1_glanceapi.yaml ]]; then
    GLANCE_CR=~/install_yamls/out/openstack/glance/cr/glance_v1beta1_glanceapi.yaml
fi
if [[ -e ~/install_yamls/out/openstack/glance/cr/glance_v1beta1_glance.yaml ]]; then
    GLANCE_CR=~/install_yamls/out/openstack/glance/cr/glance_v1beta1_glance.yaml
fi

if [[ -e $GLANCE_CR ]]; then
    # sed -i $GLANCE_CR -e s/10G/1G/g
    # echo '  storageClass: local-storage' >> $GLANCE_CR
    if [[ $DELETE -eq 1 ]]; then
        echo "Deleting current Glance CR first"
        oc delete -f $GLANCE_CR
    fi
    if [[ $CEPH -eq 1 ]]; then
        # add Ceph to CR
        pushd cr
        CR=$(bash ceph_cr.sh glance)
        echo "Applying a CR with the following diff:"
        diff -u $GLANCE_CR $CR
        cp $CR $GLANCE_CR
        popd
    fi
    oc kustomize ~/install_yamls/out/openstack/glance/cr | oc apply -f -
else
    echo "WARNING: $GLANCE_CR does not exist"
fi

# OP=$(oc get pods -l control-plane=controller-manager -o name  | grep glance)
# oc describe $OP
# oc logs $OP

#oc get pods -l service=glance-default
#oc get pods -l service=glance-external
#oc get pods -l service=glance-internal
oc get pods | egrep "NAME|glance"

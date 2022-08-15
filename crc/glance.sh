#!/bin/bash

if [[ ! -d ~/install_yamls ]]; then
    echo "~/install_yamls missing (did you run crc.sh?)"
    exit 1
fi

eval $(crc oc-env)
oc login -u kubeadmin -p 12345678 https://api.crc.testing:6443

pushd ~/install_yamls

# deploy glance operator
make glance

OP=$(oc get pods -l control-plane=controller-manager -o name  | grep glance)
oc describe $OP
oc logs $OP

# deploy glance
make glance_deploy

# modify glance to use use 1G PVs created by crc_storage
GLANCE_CR=out/openstack/glance/cr/glance_v1beta1_glanceapi.yaml
sed -i $GLANCE_CR -e s/10G/1G/g
echo '  storageClass: local-storage' >> $GLANCE_CR
oc apply -f $GLANCE_CR

popd

oc get pods -l service=glance

export OS_CLOUD=default
export OS_PASSWORD=12345678

openstack service list
openstack endpoint list
openstack image list

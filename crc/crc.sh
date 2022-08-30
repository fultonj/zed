#!/bin/bash

pushd ~
if [[ ! -d install_yamls ]]; then
    git clone git@github.com:openstack-k8s-operators/install_yamls.git
fi
pushd install_yamls

pushd devsetup
if [[ ! -e pull-secret.txt ]]; then
    cp ~/pull-secret.txt pull-secret.txt
fi

make download_tools
make CPUS=56 MEMORY=262144 crc

ssh -i ~/.crc/machines/crc/id_ecdsa core@192.168.130.11 "uname -a"
ssh -i ~/.crc/machines/crc/id_ecdsa core@192.168.130.11 "cat /etc/redhat-release"

popd # out of devsetup

mkdir -p ~/bin
eval $(crc oc-env)
oc login -u kubeadmin -p 12345678 https://api.crc.testing:6443
oc whoami

# -------------------------------------------------------
# https://github.com/openstack-k8s-operators/install_yamls/pull/23

# 1. Testing 'volumeBindingMode: Immediate'
## curl https://raw.githubusercontent.com/fmount/install_yamls/85e4c5e55c313afdce104e3d53bdb22345154305/crc/storage.yaml > ~/install_yamls/crc/storage.yaml

# 2. Testing 'volumeBindingMode: WaitForFirstConsumer'
curl https://raw.githubusercontent.com/openstack-k8s-operators/install_yamls/b608987836055560dc51c772196e44c165f11aab/crc/storage.yaml > ~/install_yamls/crc/storage.yaml

make crc_storage
# -------------------------------------------------------

# Notes from the clean up:
#   oc get pv | grep local
#   for i in $(seq 2 6); do oc delete pv $i; done
#   for i in $(seq 2 6); do oc delete pv local-storage$i; done
#   NODE=$(oc get nodes | grep master | awk {'print $1'})
#   oc debug node/$NODE
#   chroot /host
#   ls /mnt/openstack/

popd # out of install_yamls
popd # out of ~

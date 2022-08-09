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

# Increase CPU/RAM
curl https://raw.githubusercontent.com/fultonj/install_yamls/99cf2ff7dc8593e737b8f510e566a4b42e5cb6d7/devsetup/scripts/crc-setup.sh > scripts/crc-setup.sh
sed \
    -e s/CPUS=4/CPUS=56/g \
    -e s/MEMORY=9216/MEMORY=262144/g \
    -i scripts/crc-setup.sh
git diff

make crc

ssh -i ~/.crc/machines/crc/id_ecdsa core@192.168.130.11 "uname -a"
ssh -i ~/.crc/machines/crc/id_ecdsa core@192.168.130.11 "cat /etc/redhat-release"

popd # out of devsetup

mkdir -p ~/bin
eval $(crc oc-env)
oc login -u kubeadmin -p 12345678 https://api.crc.testing:6443
oc whoami

make crc_storage

popd # out of install_yamls
popd # out of ~

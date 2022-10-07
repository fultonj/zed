#!/bin/bash

if [[ ! -d ~/ext/tripleo-ansible/roles/tripleo_nova_libvirt ]]; then
    echo "tripleo_nova_libvirt is missing from ~/ext/tripleo-ansible/roles"
    exit 1
fi

INV=/home/stack/ext/tripleo-ansible/tripleo_ansible/inventory
PLAY=/home/stack/ext/tripleo-ansible/tripleo_ansible/playbooks/deploy-overcloud-compute.yml

cp ansible.cfg /home/stack/ansible.cfg
sudo cp ansible.cfg /root/ansible.cfg

if [[ -e 08-ceph ]]; then
    cp -f 08-ceph $INV/
else
    echo "08-ceph is missing, run ceph_vars.py"
    exit 1
fi

# bash ../init/standalone_ceph_patches.sh nodown import libvirt update kolla
# --tags facts,tripleo_nova_compute

pushd /home/stack/
time sudo ansible-playbook -i $INV $PLAY
popd

ansible-playbook workaround.yml
sudo podman restart nova_compute

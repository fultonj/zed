#!/bin/bash

if [[ ! -d ~/ext/tripleo-ansible/roles/tripleo_nova_libvirt ]]; then
    echo "tripleo_nova_libvirt is missing from ~/ext/tripleo-ansible/roles"
    exit 1
fi

INV=/home/stack/ext/tripleo-ansible/tripleo_ansible/inventory
PLAY=/home/stack/ext/tripleo-ansible/tripleo_ansible/playbooks/deploy-overcloud-compute.yaml

cp ansible.cfg /home/stack/ansible.cfg
sudo cp ansible.cfg /root/ansible.cfg

pushd /home/stack/
sudo ansible-playbook -i $INV $PLAY
popd

# workaround
ansible-playbook placement.yml
sudo podman restart nova_compute

#!/bin/bash

INV=/home/stack/tripleo-ansible/tripleo_ansible/inventory
PLAY=/home/stack/tripleo-ansible/tripleo_ansible/playbooks/deploy-overcloud-compute.yaml

cp ansible.cfg /home/stack/ansible.cfg
sudo cp ansible.cfg /root/ansible.cfg

pushd /home/stack/
sudo ansible-playbook -i $INV $PLAY
popd

# workaround
ansible-playbook placement.yml

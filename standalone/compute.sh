#!/bin/bash

INV=tripleo-ansible/tripleo_ansible/inventory
PLAY=tripleo-ansible/tripleo_ansible/playbooks/deploy-overcloud-compute.yaml 

cp ansible.cfg /home/stack/ansible.cfg
sudo cp ansible.cfg /root/ansible.cfg

pushd /home/stack/
sudo ansible-playbook -i $INV $PLAY
popd

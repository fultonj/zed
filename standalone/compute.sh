#!/bin/bash

INV=tripleo-ansible/tripleo_ansible/inventory
PLAY=tripleo-ansible/tripleo_ansible/playbooks/deploy-overcloud-compute.yaml 

pushd /home/stack/
sudo ansible-playbook -i $INV $PLAY
popd

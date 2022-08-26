#!/bin/bash

INV=/home/stack/ext/tripleo-ansible/tripleo_ansible/inventory
PLAY=/home/stack/zed/standalone/ceph_client_playbook.yml

cp ansible.cfg /home/stack/ansible.cfg
sudo cp ansible.cfg /root/ansible.cfg

cp -f 08-ceph $INV/

pushd /home/stack/
sudo ansible-playbook -i $INV $PLAY -v
popd

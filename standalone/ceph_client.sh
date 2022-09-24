#!/bin/bash

function push_changes() {
    REPO=tripleo-ansible/tripleo_ansible
    pushd $HOME/$REPO/$ROLE
    for F in ${FILES[@]}; do
        cp -v $F $HOME/ext/$REPO/$ROLE/$F
    done
    popd
}

ROLE=roles/tripleo_ceph_client
FILES=(
    defaults/main.yml
    tasks/multiple_external_ceph_clusters.yml
)
push_changes

INV=/home/stack/ext/tripleo-ansible/tripleo_ansible/inventory
PLAY=/home/stack/zed/standalone/ceph_client_playbook.yml

cp ansible.cfg /home/stack/ansible.cfg
sudo cp ansible.cfg /root/ansible.cfg

python3 mkinv.py
cp -f 08-ceph $INV/

pushd /home/stack/
time sudo ansible-playbook -i $INV $PLAY -vvv
popd

# sudo ls -l /var/lib/tripleo-config/ceph/

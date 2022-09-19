#!/bin/bash

if [[ ! -e nova_libvirt_init_secret.sh ]]; then
    curl https://opendev.org/openstack/tripleo-heat-templates/raw/branch/master/container_config_scripts/nova_libvirt_init_secret.sh -o nova_libvirt_init_secret.sh
fi

# we want to kolla to runs this for us in our nova containers
# bash nova_libvirt_init_secret.sh ceph:openstack

INV=/home/stack/ext/tripleo-ansible/tripleo_ansible/inventory
PLAY=/home/stack/zed/standalone/ceph_nova_playbook.yml

cp ansible.cfg /home/stack/ansible.cfg
sudo cp ansible.cfg /root/ansible.cfg

# cp -f 08-ceph $INV/
pushd /home/stack/
sudo ansible-playbook -i $INV $PLAY -v
popd

#!/bin/bash

# SETUP
if [[ ! -e nova_libvirt_init_secret.sh ]]; then
    curl https://opendev.org/openstack/tripleo-heat-templates/raw/branch/master/container_config_scripts/nova_libvirt_init_secret.sh -o nova_libvirt_init_secret.sh
fi

# we want to kolla to runs this for us in our nova containers
# bash nova_libvirt_init_secret.sh ceph:openstack

INV=/home/stack/ext/tripleo-ansible/tripleo_ansible/inventory
PLAY=/home/stack/zed/standalone/ceph_nova_playbook.yml

cp ansible.cfg /home/stack/ansible.cfg
sudo cp ansible.cfg /root/ansible.cfg

# -------------------------------------------------------
# My changes

DST=~/ext/tripleo-ansible/tripleo_ansible/roles/tripleo_nova_libvirt
pushd ~/tripleo-ansible/tripleo_ansible/roles/tripleo_nova_libvirt/
cp -v tasks/configure.yml $DST/tasks/configure.yml
popd

# -------------------------------------------------------
# VARS

FSID=$(grep fsid /home/stack/ceph_client.yaml | awk {'print $2'})
CEPHX=$(grep key /home/stack/ceph_client.yaml | grep -v keys | awk {'print $2'})

cat <<EOF > 09-ceph
[tripleo_nova_libvirt:children]
Compute

[tripleo_nova_libvirt:vars]
tripleo_cinder_enable_rbd_backend=True
tripleo_ceph_cluster_name=ceph
tripleo_ceph_cluster_fsid=$FSID
tripleo_ceph_client_key=$CEPHX
EOF
cp -f 09-ceph $INV/

# -------------------------------------------------------
# RUN
pushd /home/stack/
sudo ansible-playbook -i $INV $PLAY -v
popd

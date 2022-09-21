#!/bin/bash
# Copy in my changes before running compute.sh
# -------------------------------------------------------
# FILES

DST=~/ext/tripleo-ansible/tripleo_ansible/roles/tripleo_nova_libvirt
pushd ~/tripleo-ansible/tripleo_ansible/roles/tripleo_nova_libvirt/
cp -v tasks/configure.yml $DST/tasks/configure.yml
cp -v files/nova_libvirt_init_secret.yaml $DST/files/nova_libvirt_init_secret.yaml
cp -v tasks/run.yml $DST/tasks/run.yml
cp -v files/nova_libvirt_init_secret.sh $DST/files/nova_libvirt_init_secret.sh
cp -v templates/nova_libvirt_init_secret.yaml.j2 $DST/templates/nova_libvirt_init_secret.yaml.j2
popd

# DST=~/ext/tripleo-ansible/tripleo_ansible/roles/tripleo_container_standalone/
# pushd ~/tripleo-ansible/tripleo_ansible/roles/tripleo_container_standalone/
# cp -v tasks/main.yml $DST/tasks/main.yml
# popd
# -------------------------------------------------------
# VARS

INV=/home/stack/ext/tripleo-ansible/tripleo_ansible/inventory
FSID=$(grep fsid /home/stack/ceph_client.yaml | awk {'print $2'})
CEPHX=$(grep key /home/stack/ceph_client.yaml | grep -v keys | awk {'print $2'})

cat <<EOF > 09-ceph
[tripleo_nova_libvirt:children]
Compute

[tripleo_nova_libvirt:vars]
tripleo_cinder_enable_rbd_backend=true
tripleo_ceph_cluster_fsid=$FSID
tripleo_ceph_client_key=$CEPHX
tripleo_nova_libvirt_ceph_config_path=/etc/ceph
EOF
cp -f 09-ceph $INV/

# -------------------------------------------------------
bash compute.sh

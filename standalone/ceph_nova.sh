#!/bin/bash
# Copy in my changes before running compute.sh
# -------------------------------------------------------
# FILES

function push_changes() {
    REPO=tripleo-ansible/tripleo_ansible
    pushd $HOME/$REPO/$ROLE
    for F in ${FILES[@]}; do
        cp -v $F $HOME/ext/$REPO/$ROLE/$F
    done
    popd
}

ROLE=roles/tripleo_nova_libvirt
FILES=(
    tasks/configure.yml
    files/nova_libvirt_init_secret.yaml
    tasks/run.yml
    files/nova_libvirt_init_secret.sh
    templates/nova_libvirt_init_secret.yaml.j2
)
push_changes
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

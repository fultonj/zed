#!/bin/bash
# Install the following patches in ~/ext/tripleo-ansible after "init.sh ext"
#  https://review.opendev.org/c/openstack/tripleo-ansible/+/859197 (import ceph_client role)
#  https://review.opendev.org/c/openstack/tripleo-ansible/+/859149 (update ceph_client role)
#  https://review.opendev.org/c/openstack/tripleo-ansible/+/858585 (libvirt)

TARGET=/home/stack/tripleo-ansible
if [[ ! -d $TARGET ]]; then
    echo "$TARGET is missing"
    exit 1
fi
# -------------------------------------------------------
function push_changes() {
    REPO=tripleo-ansible/tripleo_ansible
    pushd $HOME/$REPO/$ROLE
    for F in ${FILES[@]}; do
        cp -v $F $HOME/ext/$REPO/$ROLE/$F
    done
    popd
}
# -------------------------------------------------------
# ceph_client import 859197
pushd $TARGET
git review -d 859197
git branch -M ceph_client_import
popd
ROLE=playbooks
FILES=(
    deploy-tripleo-openstack-configure.yml
)
push_changes
# -------------------------------------------------------
# ceph_client update 859149
pushd $TARGET
git review -d 859149
git branch -M ceph_client_update
popd
ROLE=roles/tripleo_ceph_client
FILES=(
    defaults/main.yml
    tasks/multiple_external_ceph_clusters.yml
)
push_changes
# -------------------------------------------------------
# libvirt 858585
pushd $TARGET
git review -d 858585
git branch -M ceph_client_libvirt
popd
ROLE=roles/tripleo_nova_libvirt
FILES=(
    tasks/configure.yml
    files/nova_libvirt_init_secret.yaml
    tasks/run.yml
    files/nova_libvirt_init_secret.sh
    templates/nova_libvirt_init_secret.yaml.j2
)
push_changes

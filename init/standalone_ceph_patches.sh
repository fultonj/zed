#!/bin/bash
# Install the following patches in ~/ext/tripleo-ansible after "init.sh ext"
#  https://review.opendev.org/c/openstack/tripleo-ansible/+/859197 (import ceph_client role)
#  https://review.opendev.org/c/openstack/tripleo-ansible/+/859149 (update ceph_client role)
#  https://review.opendev.org/c/openstack/tripleo-ansible/+/858585 (libvirt)

IMPORT=0
UPDATE=0
LIBVIRT=0
COMPUTE=0
KOLLA=0
NODOWN=0

for var in "$@"; do
    if [[ $var == "import" ]]; then IMPORT=1; fi
    if [[ $var == "update" ]]; then UPDATE=1; fi
    if [[ $var == "libvirt" ]]; then LIBVIRT=1; fi
    if [[ $var == "compute" ]]; then COMPUTE=1; fi
    if [[ $var == "kolla" ]]; then KOLLA=1; fi
    if [[ $var == "nodown" ]]; then NODOWN=1; fi
done

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
if [ $IMPORT -eq 1 ]; then
    pushd $TARGET
    if [ $NODOWN -eq 1 ]; then
        # use this option only if patch is already downloaded
        git checkout ceph_client_import
    else
        git review -d 859197
        git branch -M ceph_client_import
    fi
    popd
    ROLE=playbooks
    FILES=(
        deploy-tripleo-openstack-configure.yml
    )
    push_changes
fi
# -------------------------------------------------------
# ceph_client update 859149
if [ $UPDATE -eq 1 ]; then
    pushd $TARGET
    if [ $NODOWN -eq 1 ]; then
        git checkout ceph_client_update
    else
        # use this option only if patch is already downloaded
        git review -d 859149
        git branch -M ceph_client_update
    fi
    popd
    ROLE=roles/tripleo_ceph_client
    FILES=(
        defaults/main.yml
        tasks/multiple_external_ceph_clusters.yml
    )
    push_changes
fi
# -------------------------------------------------------
# libvirt 858585
if [ $LIBVIRT -eq 1 ]; then
    pushd $TARGET
    if [ $NODOWN -eq 1 ]; then
        git checkout ceph_client_libvirt
    else
        # use this option only if patch is already downloaded
        git review -d 858585
        git branch -M ceph_client_libvirt
    fi
    popd
    ROLE=roles/tripleo_nova_libvirt
    FILES=(
        tasks/run.yml
        files/nova_libvirt_init_secret.sh
        templates/nova_libvirt_init_secret.yaml.j2
    )
    push_changes
fi
# -------------------------------------------------------
# COMPUTE (patch on top of 843659 to come later)
# -------------------------------------------------------
# kolla 860472
if [ $KOLLA -eq 1 ]; then
    pushd $TARGET
    if [ $NODOWN -eq 1 ]; then
        git checkout tripleo_container_standalone_kolla
    else
        # use this option only if patch is already downloaded
        git review -d 860472
        git branch -M tripleo_container_standalone_kolla
    fi
    popd
    ROLE=roles/tripleo_container_standalone
    FILES=(
        tasks/main.yml
        tasks/make_kolla_config_file_sub_directories.yml
    )
    push_changes
fi

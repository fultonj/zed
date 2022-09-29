#!/bin/bash

if [[ ! -d ~/ext/tripleo-ansible/roles/tripleo_nova_libvirt ]]; then
    echo "tripleo_nova_libvirt is missing from ~/ext/tripleo-ansible/roles"
    exit 1
fi

INV=/home/stack/ext/tripleo-ansible/tripleo_ansible/inventory
PLAY=/home/stack/ext/tripleo-ansible/tripleo_ansible/playbooks/deploy-overcloud-compute.yml

cp ansible.cfg /home/stack/ansible.cfg
sudo cp ansible.cfg /root/ansible.cfg

if [[ -e 08-ceph ]]; then
    cp -f 08-ceph $INV/
else
    echo "08-ceph is missing, run mkinv.py"
    exit 1
fi

# borrowing from standalone_ceph_patches.sh
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


pushd /home/stack/
time sudo ansible-playbook -i $INV $PLAY
popd

ansible-playbook workaround.yml
sudo podman restart nova_compute

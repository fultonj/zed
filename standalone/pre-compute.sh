#!/bin/bash

NET=1
HOSTS=1
CEPH=1
REPO=1
LP1982744=1
TMATE=0
INSTALL=1
CHRONY=1
ETH0=1
EXPORT=1

CONTROLLER_IP=192.168.24.2
COMPUTE_IP=192.168.24.100

if [[ $NET -eq 1 ]]; then
    sudo ip addr add $COMPUTE_IP/24 dev eth0
    ip a s eth0
    ping -c 1 $CONTROLLER_IP
    ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
        $CONTROLLER_IP -l stack "uname -a"
    if [[ ! $? -eq 0 ]]; then
        echo "Cannot ssh into $CONTROLLER_IP"
        exit 1
    fi
fi

if [[ $HOSTS -eq 1 ]]; then
    ENTRY1="$CONTROLLER_IP standalone.localdomain standalone"
    ENTRY2="$CONTROLLER_IP standalone.ctlplane.localdomain standalone.ctlplane"
    sudo sh -c "echo $ENTRY1 >> /etc/hosts"
    sudo sh -c "echo $ENTRY2 >> /etc/hosts"
fi

if [[ $CEPH -eq 1 ]]; then
    EXT_CEPH="192.168.122.253"
    ssh $OPT $EXT_CEPH -l stack "ls zed/standalone/ceph_client.yaml"
    if [[ ! $? -eq 0 ]]; then
        echo "Cannot ssh into $EXT_CEPH"
        exit 1
    fi
    scp $OPT stack@$EXT_CEPH:/home/stack/zed/standalone/ceph_client.yaml ~/ceph_client.yaml
    ls -l ~/ceph_client.yaml
fi

if [[ $REPO -eq 1 ]]; then
    if [[ ! -d ~/rpms ]]; then mkdir ~/rpms; fi
    url=https://trunk.rdoproject.org/centos9/component/tripleo/current/
    rpm_name=$(curl $url | grep python3-tripleo-repos | sed -e 's/<[^>]*>//g' | awk 'BEGIN { FS = ".rpm" } ; { print $1 }')
    rpm=$rpm_name.rpm
    curl -f $url/$rpm -o ~/rpms/$rpm
    if [[ -f ~/rpms/$rpm ]]; then
	sudo yum install -y ~/rpms/$rpm
	sudo -E tripleo-repos current-tripleo-dev ceph --stream
	sudo yum repolist
	sudo yum update -y
    else
	echo "$rpm is missing. Aborting."
	exit 1
    fi
fi

if [[ $LP1982744 -eq 1 ]]; then
    # workaround https://bugs.launchpad.net/tripleo/+bug/1982744
    sudo rpm -qa | grep selinux | sort
    sudo dnf install -y container-selinux
    sudo dnf install -y openstack-selinux
    sudo dnf install -y setools-console
    sudo seinfo --type | grep container
    sudo rpm -V openstack-selinux
    if [[ ! $? -eq 0 ]]; then
        echo "LP1982744 will block the deployment"
        exit 1
    fi
fi

if [[ $TMATE -eq 1 ]]; then
    TMATE_RELEASE=2.4.0
    curl -OL https://github.com/tmate-io/tmate/releases/download/$TMATE_RELEASE/tmate-$TMATE_RELEASE-static-linux-amd64.tar.xz
    sudo mv tmate-$TMATE_RELEASE-static-linux-amd64.tar.xz /usr/src/
    pushd /usr/src/
    sudo tar xf tmate-$TMATE_RELEASE-static-linux-amd64.tar.xz
    sudo mv /usr/src/tmate-$TMATE_RELEASE-static-linux-amd64/tmate /usr/local/bin/tmate
    sudo chmod 755 /usr/local/bin/tmate
    popd
fi

if [[ $INSTALL -eq 1 ]]; then
    sudo dnf install -y ansible-collection-containers-podman python3-tenacity ansible-collection-community-general ansible-collection-ansible-posix
fi

if [[ $CHRONY -eq 1 ]]; then
    if [[ ! -d ~/roles ]]; then mkdir ~/roles; fi
    ln -s ~/ext/ansible-role-chrony ~/roles/chrony;
fi

if [[ $ETH0 -eq 1 ]]; then
    # use eth0, not eth1, for br-ex bridge (neutron_public_interface_name)
    sed -i /home/stack/ext/tripleo-ansible/tripleo_ansible/inventory/02-computes \
        -e s/eth1/eth0/g
fi

if [[ $EXPORT -eq 1 ]]; then
    bash export.sh
fi

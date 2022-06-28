#!/bin/bash

OTHER=1
CEPH=0
REPO=1
INSTALL=0
DNS=0
EXTRAS=0
TMATE=0

if [[ $OTHER -eq 1 ]]; then
    EXT_CONTROLLER="192.168.122.252"
    # confirm compute can reach standalone controller
    ssh $EXT_CONTROLLER -l stack "uname -a"
    if [[ ! $? -eq 0 ]]; then
        echo "Cannot ssh into $EXT_CONTROLLER"
        exit 1
    fi
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

if [[ $CEPH -eq 1 ]]; then
    sudo dnf install -y cephadm util-linux lvm2
fi

if [[ $INSTALL -eq 1 ]]; then
    sudo dnf install -y ansible-collection-containers-podman python3-tenacity ansible-collection-community-general ansible-collection-ansible-posix
fi

if [[ $DNS -eq 1 ]]; then
    GW=192.168.122.1
    sudo sysctl -w net.ipv4.ping_group_range="0 1000"
    ping -c 1 $GW > /dev/null
    if [[ $? -ne 0 ]]; then
        echo "Cannot ping $GW. Aborting."
        exit 1
    fi
    if [[ $(grep $GW /etc/resolv.conf | wc -l) -eq 0 ]]; then
        sudo sh -c "echo nameserver $GW > /etc/resolv.conf"
    fi
fi

if [[ $EXTRAS -eq 1 ]]; then
    sudo dnf install -y tmux emacs-nox vim
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

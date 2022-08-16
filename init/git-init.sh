#!/usr/bin/env bash
# Clones the repos that I am interested in.
# -------------------------------------------------------
if [[ $1 == 'ext' ]]; then
    sudo rm -rf ~/ext
    declare -a repos=(
                      'openstack/tripleo-ansible' \
                      'openstack/ansible-role-chrony' \
    );
fi
# -------------------------------------------------------
if [[ $# -eq 0 ]]; then
    # uncomment whatever you want
    declare -a repos=(
                      # 'openstack/tripleo-heat-templates' \
		      # 'openstack/tripleo-common'\
                      # 'openstack/tripleo-ansible' \
                      # 'openstack/tripleo-validations' \
                      # 'openstack/python-tripleoclient' \
                      # 'openstack/ansible-role-chrony' \
		      # 'openstack-infra/tripleo-ci'\
		      # 'openstack/tripleo-specs'\
		      # 'openstack/tripleo-docs'\
		      # 'openstack/tripleo-quickstart'\
		      # 'openstack/tripleo-quickstart-extras'\
		      # 'openstack/tripleo-repos'\
                      # 'openstack/tripleo-operator-ansible' \
		      # add the next repo here
    );
fi
# -------------------------------------------------------
gerrit_user='fultonj'
git config --global user.email "fulton@redhat.com"
git config --global user.name "John Fulton"
git config --global push.default simple
git config --global gitreview.username $gerrit_user

git review --version
if [ $? -gt 0 ]; then
    echo "installing git-review and tox from pip"
    if [[ $(grep 8 /etc/redhat-release | wc -l) == 1 ]]; then
        if [[ ! -e /usr/bin/python3 ]]; then
            sudo dnf install python3 -y
        fi
    fi
    pip
    if [ $? -gt 0 ]; then
        V=$(python3 --version | awk {'print $2'} | awk 'BEGIN { FS = "." } ; { print $2 }')
        if [[ $V -eq "6" ]]; then
            curl https://bootstrap.pypa.io/pip/3.6/get-pip.py -o get-pip.py
        else
            curl https://bootstrap.pypa.io/pip/get-pip.py -o get-pip.py
        fi
        python3 get-pip.py
    fi
    pip install git-review tox
fi
if [[ $1 == 'ext' ]]; then
    mkdir -p ~/ext
    pushd ~/ext
else
    pushd ~
fi
for repo in "${repos[@]}"; do
    dir=$(echo $repo | awk 'BEGIN { FS = "/" } ; { print $2 }')
    if [ ! -d $dir ]; then
	git clone https://git.openstack.org/$repo.git
	pushd $dir
	git remote add gerrit ssh://$gerrit_user@review.openstack.org:29418/$repo.git
	git review -s
        if [ $? -gt 0 ]; then
            echo "Attempting to workaround scp error"
            cp ~/xena/workarounds/git_review/commit-msg .git/hooks/commit-msg
            chmod u+x .git/hooks/commit-msg
        fi
	popd
    else
	pushd $dir
	git pull --ff-only origin master
	popd
    fi
done
popd
# -------------------------------------------------------
if [[ $1 == 'ext' ]]; then
    if [[ ! -e /usr/bin/jq ]]; then
        sudo dnf install jq -y
    fi

    # Install and link chrony
    pushd /home/stack/ext/ansible-role-chrony
    git review -d 842223
    popd
    if [[ ! -d ~/roles ]]; then mkdir ~/roles; fi
    ln -s ~/ext/ansible-role-chrony ~/roles/chrony;

    pushd /home/stack/ext/tripleo-ansible
    # git review -d 847594
    curl https://gist.githubusercontent.com/slagle/8fbb18c90d3930a8ca5c5414ee34e78e/raw/a45412851128e7ce06ba388a738680ed42941e5b/gerrit-pull-changes.sh | bash
    git log  --graph --topo-order  --pretty='format:%h %ai %s%d (%an)' | head -40
    popd
    # this seems to get the ~20 patches we need from tripleo-ansible
    # https://review.opendev.org/q/topic:standalone-roles+project:openstack/tripleo-ansible+status:open

    # use eth0, not eth1, for br-ex bridge (neutron_public_interface_name)
    sed -i /home/stack/ext/tripleo-ansible/tripleo_ansible/inventory/02-computes \
        -e s/eth1/eth0/g
fi

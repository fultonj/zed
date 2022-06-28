#!/usr/bin/env bash
# Clones the repos that I am interested in.
# -------------------------------------------------------
if [[ $1 == 'ext' ]]; then
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
pushd ~
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
    pushd /home/stack/ansible-role-chrony
    git review -d 842223
    popd

    pushd /home/stack/tripleo-ansible
    git review -d 847594
    git log  --graph --topo-order  --pretty='format:%h %ai %s%d (%an)' | head -20
    popd

    # this seems to get the ~20 patches we need from tripleo-ansible
    # https://review.opendev.org/q/topic:standalone-roles+project:openstack/tripleo-ansible+status:open
fi

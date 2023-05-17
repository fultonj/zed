#!/bin/bash

if [[ ! -e /usr/bin/git ]]; then
    sudo dnf install git -y 
fi

git config --global user.email "fulton@redhat.com"
git config --global user.name "John Fulton"
git config --global push.default simple

ssh-keyscan github.com >> ~/.ssh/known_hosts

git clone git@github.com:fultonj/zed.git -b adopt

pushd ~/zed/adopt/standalone

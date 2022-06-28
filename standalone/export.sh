#!/bin/bash

EXT_CONTROLLER="192.168.122.252"
DEF=/home/stack/tripleo-ansible/tripleo_ansible/inventory/99-custom

if [[ ! -e $DEF ]]; then
    echo "Failing $DEF is missing"
    exit 1
fi

# ssh $EXT_CONTROLLER -l stack 

# Update $DEF with data from $EXT_CONTROLLER

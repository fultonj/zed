#!/bin/bash
# Add USERNAME w/ PASSWORD to rabbitmq service and output rabbit IP
#
# Workaround not yet having the following:
# https://github.com/openstack-k8s-operators/openstack-operator/pull/27
# https://github.com/openstack-k8s-operators/cinder-operator/pull/62

USERNAME="openstack"
PASSWORD="redhat"
RESETPASSWD=1
POD=$(oc get pods | grep default-security | grep Running | awk {'print $1'})

function rabbitmqctl {
    if [[ -z $2 ]]; then
        oc exec -ti $POD 2> /dev/null -- rabbitmqctl $1
    elif [[ -z $3 ]]; then
        oc exec -ti $POD 2> /dev/null -- rabbitmqctl $1 $2
    else
        oc exec -ti $POD 2> /dev/null -- rabbitmqctl $1 $2 $3
    fi
}

if [[ $(rabbitmqctl list_users | awk {'print $1'} | grep $USERNAME | wc -l) -eq 0 ]]; then
    #echo "Need to make $USERNAME"
    rabbitmqctl add_user $USERNAME $PASSWORD
fi
if [[ $(rabbitmqctl list_users | awk {'print $1'} | grep $USERNAME | wc -l) -eq 0 ]]; then
    #echo "Need to make $USERNAME an admin"
    rabbitmqctl set_user_tags $USERNAME administrator
    rabbitmqctl set_permissions "$USERNAME" ".*" ".*" ".*"
fi
if [[ $RESETPASSWD -eq 1 ]]; then
    #echo "Ensure username:password for rabbitmqctl is $USERNAME:$PASSWORD"
    rabbitmqctl change_password $USERNAME $PASSWORD > /dev/null
fi

oc exec -ti $POD 2> /dev/null -- hostname -I

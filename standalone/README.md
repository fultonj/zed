# Standalone and External Compute on VMs from virsh

My scripts to reproduce https://etherpad.opendev.org/p/tripleo-standalone-roles

## Get VMs

[Optional] I make my centos-stream9 VM on a hypervisor by running
- [./centos.sh](https://github.com/fultonj/tripleo-laptop/blob/master/centos.sh)
- [./clone.sh standalone](https://github.com/fultonj/tripleo-laptop/blob/master/clone.sh)
- [./clone.sh overcloud](https://github.com/fultonj/tripleo-laptop/blob/master/clone.sh)

On new standalone VM run:
- [pre.sh](pre.sh)
- [standalone.sh](standalone.sh)

The above will deploy a
[standalone](https://docs.openstack.org/project-deploy-guide/tripleo-docs/wallaby/deployment/standalone.html)
and then add an external compute node to it without using puppet or
heat.

The next move will be to get it using external ceph.

# Standalone and External Compute on VMs from virsh

My scripts to reproduce https://etherpad.opendev.org/p/tripleo-standalone-roles

## Get VMs

[Optional] I make my centos-stream9 VMs on a hypervisor by running
- [./centos.sh](https://github.com/fultonj/tripleo-laptop/blob/master/centos.sh)
- [./clone.sh standalone](https://github.com/fultonj/tripleo-laptop/blob/master/clone.sh)
- [./clone.sh overcloud](https://github.com/fultonj/tripleo-laptop/blob/master/clone.sh)

## Deploy Standalone OpenStack

On the new standalone VM run:

- [pre-standalone.sh](pre-standalone.sh)
- [standalone.sh](standalone.sh)

The above will deploy OpenStack
[standalone](https://docs.openstack.org/project-deploy-guide/tripleo-docs/latest/deployment/standalone.html).

Confirm it works.
```
[stack@standalone standalone]$ export OS_CLOUD=standalone
[stack@standalone standalone]$ openstack compute service list
+--------------------------------------+----------------+------------------------+----------+---------+-------+----------------------------+
| ID                                   | Binary         | Host                   | Zone     | Status  | State | Updated At                 |
+--------------------------------------+----------------+------------------------+----------+---------+-------+----------------------------+
| 0d261f85-6412-46a3-8469-8a503cd0ec31 | nova-conductor | standalone.localdomain | internal | enabled | up    | 2022-06-28T17:29:15.000000 |
| 4277152f-73fa-4359-85a9-b9be45760dd1 | nova-scheduler | standalone.localdomain | internal | enabled | up    | 2022-06-28T17:29:09.000000 |
| 744dd967-3993-49f9-b776-6fcd1fe38bca | nova-compute   | standalone.localdomain | nova     | enabled | up    | 2022-06-28T17:29:12.000000 |
+--------------------------------------+----------------+------------------------+----------+---------+-------+----------------------------+
[stack@standalone standalone]$ 
```

## Deploy Extra Compute Node
On the new standalone VM run:

- [git-init.sh ext](../inig/git-init.sh)
- [pre-compute.sh](pre-compute.sh)
- [export.sh](export.sh)
- [compute.sh](compute.sh)

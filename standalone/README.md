# Standalone and External Compute on VMs from virsh

My scripts to reproduce https://etherpad.opendev.org/p/tripleo-standalone-roles

## Get VMs

[Optional] I make my centos-stream9 VMs on a hypervisor by running
- [./centos.sh](https://github.com/fultonj/tripleo-laptop/blob/master/centos.sh)
- [./clone.sh ceph](https://github.com/fultonj/tripleo-laptop/blob/master/clone.sh)
- [./clone.sh standalone](https://github.com/fultonj/tripleo-laptop/blob/master/clone.sh)
- [./clone.sh overcloud](https://github.com/fultonj/tripleo-laptop/blob/master/clone.sh)

## Deploy Standalone Ceph

On the ceph VM run:

- [ceph.sh](ceph.sh)

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

On the overcloud0 VM run:

- [git-init.sh ext](../init/git-init.sh)
- [pre-compute.sh](pre-compute.sh)
- [compute.sh](compute.sh)

Note that [pre-compute.sh](pre-compute.sh) calls [export.sh](export.sh)
which exports information from the standalone deployment to
[populate local Ansible variables](https://github.com/fultonj/zed/commit/3be4554ad67a7885c5feea15dda9b806b4681031)
on the new compute node.

Note that [compute.sh](compute.sh) calls [placement.yml](placement.yml)
which contains a workaround to the symptoms of 
[LP 1850691](https://bugs.launchpad.net/charm-nova-cell-controller/+bug/1850691)
for the palcement service as well as fill in the [neutron] section of
the nova.conf. I don't know why the placement section of the nova.conf
genereated by the new tripleo-ansible standalone compute roles has a
missing placement section. This playbook just populates the missing
placement section with four variables from [export.sh](export.sh) and
other missing key/value pairs. I
[shared](https://paste.opendev.org/show/816007) this with the
author of the tripleo_nova_compute role.

On the standalone VM run [discover.sh](discover.sh) so that new
exteranl compute node becomes available for scheduling.

## Did it work?

Observe the newly running containers on the extra compute node.
```
[stack@centos standalone]$ sudo podman ps
CONTAINER ID  IMAGE                                                                COMMAND      CREATED        STATUS                      PORTS       NAMES
6e4e50574f07  quay.io/tripleomastercentos9/openstack-cron:current-tripleo          kolla_start  5 minutes ago  Up 5 minutes ago (healthy)              logrotate_crond
1ea932ebe043  quay.io/tripleomastercentos9/openstack-iscsid:current-tripleo        kolla_start  5 minutes ago  Up 5 minutes ago                        iscsid
afe55e027274  quay.io/tripleomastercentos9/openstack-nova-libvirt:current-tripleo  kolla_start  4 minutes ago  Up 4 minutes ago                        nova_virtlogd
9dbdae93acab  quay.io/tripleomastercentos9/openstack-nova-libvirt:current-tripleo  kolla_start  4 minutes ago  Up 4 minutes ago                        nova_virtsecretd
45438e3f4727  quay.io/tripleomastercentos9/openstack-nova-libvirt:current-tripleo  kolla_start  4 minutes ago  Up 4 minutes ago                        nova_virtnodedevd
231c3be65acf  quay.io/tripleomastercentos9/openstack-nova-libvirt:current-tripleo  kolla_start  4 minutes ago  Up 4 minutes ago                        nova_virtstoraged
1612c0c56061  quay.io/tripleomastercentos9/openstack-nova-libvirt:current-tripleo  kolla_start  4 minutes ago  Up 4 minutes ago                        nova_virtqemud
d165f490f0a0  quay.io/tripleomastercentos9/openstack-nova-libvirt:current-tripleo  kolla_start  4 minutes ago  Up 4 minutes ago                        nova_virtproxyd
254b15b1ba5b  quay.io/tripleomastercentos9/openstack-nova-compute:current-tripleo  kolla_start  4 minutes ago  Up 4 minutes ago                        nova_compute
[stack@centos standalone]$ 
```

Observe that the compute node is now available to have instances
scheduled on it.

```
[stack@standalone ~]$ openstack compute service list
+--------------------------------------+----------------+------------------------+----------+---------+-------+----------------------------+
| ID                                   | Binary         | Host                   | Zone     | Status  | State | Updated At                 |
+--------------------------------------+----------------+------------------------+----------+---------+-------+----------------------------+
| f15ce10c-2758-42bd-b0f8-2f029bd8e857 | nova-conductor | standalone.localdomain | internal | enabled | up    | 2022-07-30T20:01:38.000000 |
| 379f119a-6ca1-45ca-b2bd-2b34a3c6ce52 | nova-scheduler | standalone.localdomain | internal | enabled | up    | 2022-07-30T20:01:38.000000 |
| 11f15db2-2107-4422-afbb-b620095dd7cb | nova-compute   | standalone.localdomain | nova     | enabled | up    | 2022-07-30T20:01:38.000000 |
| cc95edeb-68d4-419b-8e84-f22467aebd29 | nova-compute   | centos.example.com     | nova     | enabled | up    | 2022-07-30T20:01:34.000000 |
+--------------------------------------+----------------+------------------------+----------+---------+-------+----------------------------+
[stack@standalone ~]$
```

Use [verify.sh](verify.sh) to launch an instance on the new compute node.

## Develop

Use [git-init.sh](../init/git-init.sh) (without the 'ext' argument) to
get a copy of tripleo-ansible in ~ (not in ~/ext) and write a patch
there. Copy the changed files into ~/ext to test them.

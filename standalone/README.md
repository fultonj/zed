# Standalone and External Compute on VMs from virsh

My scripts to reproduce https://etherpad.opendev.org/p/tripleo-standalone-roles
and have the compute node deployed with standalone ansible (no puppet/heat)
use external Ceph.

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
- [standalone_ceph_patches.sh import libvirt update](../init/standalone_ceph_patches.sh)
- [pre-compute.sh](pre-compute.sh)
- [compute.sh](compute.sh)

The above scritps import the tripleo patches in progress
and build an inventory (99-standalone-vars and 08-ceph)
to make an external compute node deployed with standalone
tripleo-ansible support external ceph as described in this
[docs patch](https://review.opendev.org/c/openstack/tripleo-docs/+/859142).

### Details

#### Set up unmerged patches

[git-init.sh ext](../init/git-init.sh) installs the main 
[tripleo-ansible standalone patch](https://review.opendev.org/c/openstack/tripleo-ansible/+/840509)
and all of its dependencies as described in the project
[etherpad](https://etherpad.opendev.org/p/tripleo-standalone-roles)
into /home/stack/ext/tripleo-ansible on the standalone compute node.

[standalone_ceph_patches.sh](../init/standalone_ceph_patches.sh)
installs the following patches necessary to configure a standalone
compute node to use external ceph.

- [import ceph_client role - 859197](https://review.opendev.org/c/openstack/tripleo-ansible/+/859197) 
- [update ceph_client role - 859149](https://review.opendev.org/c/openstack/tripleo-ansible/+/859149) 
- [libvirt role configures ceph secret - 858585](https://review.opendev.org/c/openstack/tripleo-ansible/+/858585)

How these patches will work described in a
[docs patch](https://review.opendev.org/c/openstack/tripleo-docs/+/859142).
The `standalone_ceph_patches.sh` scripts assumes you have used
[git-init.sh](../init/git-init.sh) (without the 'ext' argument) to
get a copy of tripleo-ansible in ~ (not in ~/ext). I do further patch
development in the different branches of this directory as needed.

#### Set up inventory with local environment variables

[pre-compute.sh](pre-compute.sh) calls [export.sh](export.sh),
which exports information from the standalone deployment to
populate local Ansible variables into 99-standalone-vars on the new
compute node. It does this by calling the
[tripleo-standalone-vars script](https://review.opendev.org/c/openstack/tripleo-ansible/+/840509/41/scripts/tripleo-standalone-vars)
in my local environment and copying the result back to the external
compute node. See the
[design and development docs on how to use the standalone roles and playbooks](https://review.opendev.org/c/openstack/tripleo-ansible/+/847347)
for more information on how 99-standalone-vars works.

[pre-compute.sh](pre-compute.sh) also connects to an existing
ceph VM environment running at 192.168.122.253 and exports its
information from the `ceph_client.yaml` file to /home/stack. Though
the `ceph_client.yaml` file is compatible with the tripleo_ceph_client
role if set to `tripleo_ceph_client_vars`, it is not the convention
of the standalone ansible roles to define a variable containing
a variable file to pass to `include_vars`. Instead there are already
variables for ceph used in new standlone roles like `tripleo_nova_*`.
The convention I'm promoting instead is to use those existing
variables plus some new ones as described this
[docs patch](https://review.opendev.org/c/openstack/tripleo-docs/+/859142).
The [ceph_vars.py](ceph_vars.py) script creates the described 08-ceph inventory.

#### Run the playbook and discover the deployed node

The [compute.sh](compute.sh) script calls the main playbook of the
[tripleo-ansible standalone patch](https://review.opendev.org/c/openstack/tripleo-ansible/+/840509).

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

### Was /var/lib/tripleo-config/ceph/ populated?

If [the patch](https://review.opendev.org/c/openstack/tripleo-ansible/+/859197)
to make the standalone playbook import the 
[tripleo_ceph_client role](https://github.com/openstack/tripleo-ansible/tree/master/tripleo_ansible/roles/tripleo_ceph_client)
and
[the patch](https://review.opendev.org/c/openstack/tripleo-ansible/+/859149)
to make the 
[tripleo_ceph_client role](https://github.com/openstack/tripleo-ansible/tree/master/tripleo_ansible/roles/tripleo_ceph_client)
handle the new
[documented](https://review.opendev.org/c/openstack/tripleo-docs/+/859142)
inventory format worked, then the directory should be correctly populated.
```
[stack@centos tripleo_ansible]$ sudo ls -l /var/lib/tripleo-config/ceph
total 8
-rw-r--r--. 1 root root 230 Sep 25 15:52 ceph.conf
-rw-------. 1 root root 211 Sep 25 15:52 ceph.openstack.keyring
[stack@centos tripleo_ansible]$
```
### Does the nova_compute container see the files it needs?

```
[stack@centos standalone]$ sudo podman exec -ti nova_compute /bin/bash
bash-5.1$ ls /etc/ceph/
ceph.conf  ceph.openstack.keyring  rbdmap
bash-5.1$ 

bash-5.1$ cat /etc/nova/secret.xml
<secret ephemeral='no' private='no'>
  <usage type='ceph'>
    <name>client.openstack secret</name>
  </usage>
  <uuid>604c9994-1d82-11ed-8ae5-5254003d6107</uuid>
</secret>
bash-5.1$
```

### Can you create an instance which uses Ceph as its backend?

Use [verify.sh](verify.sh) to launch an instance on the new compute
node.

In my case I see an instance running on the compute node which was
deployed only with Ansible (no puppet/heat):

```
+--------------------------------------+-----------------------------+--------+----------+--------+---------+
| ID                                   | Name                        | Status | Networks | Image  | Flavor  |
+--------------------------------------+-----------------------------+--------+----------+--------+---------+
| fa17d9ab-e9c2-4496-9d74-70c9dfc1febe | myserver-centos.example.com | ACTIVE |          | cirros | m1.tiny |
+--------------------------------------+-----------------------------+--------+----------+--------+---------+
```

and I see its root disk was created on my Ceph cluster:

```
[ceph: root@ceph /]# rbd ls -l vms
NAME                                              SIZE     PARENT  FMT  PROT  LOCK
fa17d9ab-e9c2-4496-9d74-70c9dfc1febe_disk           1 GiB            2
fa17d9ab-e9c2-4496-9d74-70c9dfc1febe_disk.config  474 KiB            2
[ceph: root@ceph /]#
```

# Ceph Configuration of RHEL nodes via CRs

Use a Secret and AnsibleEE CR to configure RHEL as a Ceph client

1. Use
   [fmount's notes](https://gist.github.com/fmount/ffc4cd6a048cafe2a38ae5f8727e31f9)
   to run a local copy of ansibleee-operator with extramounts
   
2. `oc create -f` a Secret CR like `ceph-client-conf` (e.g. I
   use [ceph_secret.sh](cr/ceph_secret.sh))
   
3. `oc create -f` an AnsibleEE CR like
   [ansibleee-extra-vol-ceph.yaml](cr/ansibleee-extra-vol-ceph.yaml)
   which tests the new standalone 
   [tripleo_ceph_client_files role](https://review.opendev.org/c/openstack/tripleo-ansible/+/865197/)
   with the source variable set to the mounted secret

## Example Output

My RHEL "compute node" does not have any ceph configuration:
```
[fultonj@osp-storage-01 crc]$ ssh fultonj@10.1.27.21 "ls -l /var/lib/tripleo-config/ceph/"
ls: cannot access '/var/lib/tripleo-config/ceph/': No such file or directory
[fultonj@osp-storage-01 crc]$ 
```

Create a ceph secret which 
[will work with the opentsack operator](https://github.com/fultonj/zed/blob/main/crc/config_files_to_services.md)
```
oc create -f cephSecret.yaml
oc get secret ceph-client-conf -o json | jq -r '.data."ceph.conf"' | base64 -d
```

Create the AnsibleEE CR [ansibleee-extra-vol-ceph.yaml](cr/ansibleee-extra-vol-ceph.yaml)
I use [ansibleee.sh](ansibleee.sh) as a wrapper to speed this up.
```
[fultonj@osp-storage-01 crc]$ ./ansibleee.sh 
COMMAND   PID    USER   FD   TYPE   DEVICE SIZE/OFF NODE NAME
manager 52394 fultonj    7u  IPv6 88204994      0t0  TCP *:ircu-4 (LISTEN)
Login successful.

You have access to 65 projects, the list has been suppressed. You can list all projects with 'oc projects'

Using project "openstack".
~/install_yamls ~/zed/crc
ansibleee.redhat.com "ansibleee-play" deleted
ansibleee.redhat.com/ansibleee-play created
cat: /runner/env/settings: No such file or directory
/usr/bin/tripleo_entrypoint: line 5: /runner/env/settings: Read-only file system
Identity added: /runner/artifacts/b7b27583-19a6-4136-9b63-1104ff216e81/ssh_key_data (fultonj@osp-storage-01.ospss.lab.eng.rdu2.redhat.com)

PLAY [Configure Computes as Ceph Clients] **************************************

TASK [Get list ceph files to copy from localhost tripleo_ceph_client_files_source] ***
ok: [compute-0 -> localhost]

TASK [Ensure tripleo_ceph_client_config_home (e.g. /etc/ceph) exists on all hosts] ***
changed: [compute-0]

TASK [Push files from tripleo_ceph_client_files_source to all hosts] ***********
~/zed/crc
[fultonj@osp-storage-01 crc]$ 
```

The files from my CR are now on my RHEL node.
```
[fultonj@osp-storage-01 crc]$ ssh fultonj@10.1.27.21 "ls -l /var/lib/tripleo-config/ceph/"
total 8
-rw-------. 1 root root 217 Nov 29 23:45 ceph.client.automation-10.keyring
-rw-r--r--. 1 root root  94 Nov 29 23:45 ceph.conf
[fultonj@osp-storage-01 crc]$ 
```

The tripleo_nova_libvirt role 
[can use](https://review.opendev.org/c/openstack/tripleo-ansible/+/858585)
these files to configure Nova's libvirt to connect to Ceph.

This is similar 
[an earlier demo](https://github.com/fultonj/zed/tree/main/standalone#was-varlibtripleo-configceph-populated)
except we are now getting the input parameters directly
from a CR which already works with the meta operator.

Thus, we no longer need the interface like the one we used with Heat.
So the [diff of my docs patch](https://review.opendev.org/c/openstack/tripleo-docs/+/859142/14..16/deploy-guide/source/features/ceph_external.rst)
is shorter.
This is also a solution to
[LP 1994148](https://bugs.launchpad.net/tripleo/+bug/1994148).
Rather than use the old role, `tripleo_ceph_client` which
had to support Heat environment style interface, we can
use a simpler less error-prone role like
[tripleo_ceph_client_files role](https://review.opendev.org/c/openstack/tripleo-ansible/+/865197/).

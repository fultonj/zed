# Configuring EDPM Nodes as Ceph Clients

## Prerequisites

- EDPM environment as described in [README](README.md)
- A running local copy of the [ceph_client branch](https://github.com/fultonj/dataplane-operator/tree/ceph_client) of the dataplane-operator

## Create a Ceph Secret

Create a ceph secret using
[ceph-conf-files.yaml](ceph-conf-files.yaml)
and observe its content
```
oc create -f ceph-conf-files.yaml
oc get secret ceph-conf-files -o yaml
oc get secret ceph-conf-files -o json | jq -r '.data."ceph.client.openstack.keyring"' | base64 -d
oc get secret ceph-conf-files -o json | jq -r '.data."ceph.conf"' | base64 -d
```
[ceph-conf-files.yaml](ceph-conf-files.yaml) was generated from the `make ceph`
[feature of install_yamls](https://github.com/openstack-k8s-operators/install_yamls/commit/6004b88ccaaff7751ed71115ba0093a997a1762)
and doesn't contain information for a real ceph cluster. It was
updated to have two ceph config files (ceph.conf and ceph2.conf) and
two cephx keys (ceph.client.openstack.keyring and
ceph2.client.openstack.keyring). This is how it should look (four file
entries) for configuring a client to use two Ceph clusters (or with
six files for three Ceph clusters and so on).

This file is provided to save time since it's not necessary to run
Ceph to test this feature.

## Testing

The [edpm-compute-0.yaml](edpm-compute-0.yaml) CR has an `extraMounts` field.

```
oc create -f edpm-compute-0.yaml
```

As the
[ceph_client branch](https://github.com/fultonj/dataplane-operator/tree/ceph_client)
evolves we should be able to inspect the environment and eventually
see the ceph client config files copied to `/etc/ceph` on the EDPM nodes.
```
IP=$( sudo virsh -q domifaddr edpm-compute-0 | awk 'NF>1{print $NF}' | cut -d/ -f1 )
ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i ~/install_yamls/out/edpm/ansibleee-ssh-key-id_rsa root@$IP "ls -l /etc/ceph/"
```

## Design

The [edpm-compute-0.yaml](edpm-compute-0.yaml) CR has an `extraMounts` field.
```yaml
    extraMounts:
    - extraVolType: Ceph
      volumes:
      - name: ceph
        secret:
          secretName: ceph-client-conf
      mounts:
      - name: ceph
        mountPath: "/etc/ceph"
        readOnly: true
```
Because of
[PR79](https://github.com/openstack-k8s-operators/dataplane-operator/pull/79)
the Ansible Execution Pod will mount the ceph conf files in `/etc/ceph`.

In
[pkg/deployment](https://github.com/openstack-k8s-operators/dataplane-operator/tree/main/pkg/deployment)
`deployment.go` has been updated to call a `ConfigureCephClient`
function defined in `ceph_client.go`.

`deployment.go` checks if `extraVolType: Ceph` and then calls the
[edpm_ceph_client_files role](https://github.com/openstack-k8s-operators/edpm-ansible/tree/main/edpm_ansible/roles/edpm_ceph_client_files)
like the POC [edpm-play.yaml](../crc/cr/edpm-play.yaml)

## Results

[PR85](https://github.com/openstack-k8s-operators/dataplane-operator/pull/85) is working.

Input:
- A 2n file secret for n ceph clusters, where n=4
  like [ceph-conf-files.yaml](ceph-conf-files.yaml)
- A [edpm-compute-0.yaml](edpm-compute-0.yaml) CR with an
  `extraMounts` field referencing the ceph secret.
- A [edpm-role-0.yaml](edpm-role-0.yaml) CR with `ansibleVars` 
  `edpm_ceph_client_files_config_home` and
  `edpm_ceph_client_files_source`.

We see that the `dataplane-deployment-configure-ceph-clients` pod ran
with the other pods.

```
dataplane-deployment-configure-ceph-clientscvtk-v9wtl             0/1     Completed   0               2m59s
dataplane-deployment-configure-networkg6hj9-l8764                 0/1     Completed   0               5m31s
dataplane-deployment-configure-openstackt6nlm-zctct               0/1     Completed   0               2m29s
dataplane-deployment-configure-osjjlq2-7m9lh                      0/1     Completed   0               4m10s
dataplane-deployment-install-openstack8jvnl-pmgbq                 0/1     Completed   0               2m47s
dataplane-deployment-install-oscdssl-scm55                        0/1     Completed   0               5m1s
dataplane-deployment-run-openstackvxg7p-x78vk                     0/1     Completed   0               2m3s
dataplane-deployment-run-osqrpvk-lw9z2                            0/1     Completed   0               3m39s
dataplane-deployment-validate-networkkjjsn-5sfgn                  0/1     Completed   0               5m16s
```
Ansible logs show that the 4 files were copied:
```
[fultonj@hamfast edpm]$ oc logs -f dataplane-deployment-configure-ceph-clientscvtk-v9wtl
Identity added: /runner/artifacts/3bf7ed34-aa97-4318-a21a-f50c57dd6846/ssh_key_data (fultonj@hamfast.examle.com)

PLAY [edpm_ceph_client_files] **************************************************

TASK [Gathering Facts] *********************************************************
ok: [edpm-compute-0]

TASK [edpm_ceph_client_files : Fail if edpm_ceph_client_files_source is missing] ***
skipping: [edpm-compute-0]

TASK [edpm_ceph_client_files : Get list ceph files to copy from localhost edpm_ceph_client_files_source] ***
ok: [edpm-compute-0 -> localhost]

TASK [edpm_ceph_client_files : Ensure edpm_ceph_client_config_home exists on all hosts] ***
ok: [edpm-compute-0]

TASK [edpm_ceph_client_files : Push files from edpm_ceph_client_files_source to all hosts] ***
changed: [edpm-compute-0] => (item=/etc/ceph/ceph2.conf)
changed: [edpm-compute-0] => (item=/etc/ceph/ceph2.client.openstack.keyring)
ok: [edpm-compute-0] => (item=/etc/ceph/ceph.conf)
ok: [edpm-compute-0] => (item=/etc/ceph/ceph.client.openstack.keyring)

PLAY RECAP *********************************************************************
edpm-compute-0             : ok=4    changed=1    unreachable=0    failed=0    skipped=1    rescued=0    ignored=0
[fultonj@hamfast edpm]$
```
We can see the copies on the node:
```
[fultonj@hamfast edpm]$ IP=$( sudo virsh -q domifaddr edpm-compute-0 | awk 'NF>1{print $NF}' | cut -d/ -f1 )
[fultonj@hamfast edpm]$ ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i ~/install_yamls/out/edpm/ansibleee-ssh-key-id_rsa root@$IP "ls -l /etc/ceph/"
Warning: Permanently added '192.168.122.100' (ECDSA) to the list of known hosts.
total 16
-rw-------. 1 root root 239 Mar 14 20:08 ceph2.client.openstack.keyring
-rw-r--r--. 1 root root 361 Mar 14 20:08 ceph2.conf
-rw-------. 1 root root 239 Mar 14 12:16 ceph.client.openstack.keyring
-rw-r--r--. 1 root root 361 Mar 14 12:16 ceph.conf
[fultonj@hamfast edpm]$
```

If we update [edpm-compute-0.yaml](edpm-compute-0.yaml) to remove
`extraMounts` then the `dataplane-deployment-configure-ceph-clients`
pod does not run and we see the message below before the next Ansible
execution runs.

```
1.678802374873155e+09	INFO	Skipping execution of Ansible for
ConfigureCephClient because extraMounts does not have an extraVolType
of Ceph.	{"controller": "openstackdataplanenode",
"controllerGroup": "dataplane.openstack.org", "controllerKind":
"OpenStackDataPlaneNode", "OpenStackDataPlaneNode":
{"name":"edpm-compute-0","namespace":"openstack"}, "namespace":
"openstack", "name": "edpm-compute-0", "reconcileID":
"32db4f9f-e16f-4c36-8f9a-dbb38daba5ea"}
```

### extraMounts in Role Testing

If extra `extraMounts` is moved
from [edpm-compute-0.yaml](edpm-compute-0.yaml) to
[edpm-role-0.yaml](edpm-role-0.yaml), then the same
behavior described above should happen.

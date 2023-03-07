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
and doesn't contain information for a real ceph cluster

This file is provided to save time since it's not necessary to run
Ceph to test this feature.

## Design

- [ansibleSSHPrivateKeySecret](https://github.com/openstack-k8s-operators/dataplane-operator/pull/54/files)
is an attribute of an 
[OpenStackDataPlaneNode](https://openstack-k8s-operators.github.io/dataplane-operator/openstack_dataplanenode) CR

- When a node CR is created the ansibleSSHPrivateKeySecret is mounted to the
[ansible execution pod](https://github.com/openstack-k8s-operators/dataplane-operator/blob/main/pkg/util/ansible_execution.go)

- Similarly a OpenStackDataPlaneNode could have a new attribute
  `CephSecrets` which is a list of ceph secrets like the one created
  by [ceph-conf-files.yaml](ceph-conf-files.yaml)

- The [pkg/deployment](https://github.com/openstack-k8s-operators/dataplane-operator/tree/main/pkg/deployment)
deployment.go could get a new condition for ceph clients if
`CephSecrets` is not empty and in that case a new ceph_client.go could
include the 
[edpm_ceph_client_files role](https://github.com/openstack-k8s-operators/edpm-ansible/tree/main/edpm_ansible/roles/edpm_ceph_client_files)
like the POC [edpm-play.yaml](../crc/cr/edpm-play.yaml)

- When that happens the `CephSecrets` could be mounted by the
[ansible execution pod](https://github.com/openstack-k8s-operators/dataplane-operator/blob/main/pkg/util/ansible_execution.go)
using
[extraVol](https://github.com/fultonj/zed/blob/main/crc/config_files_to_services.md)

## Alternatives

What if the dataplane nodes could directly support `extraMounts` such
that the AEE POD always mounted them?

If we could add the following to the `spec.node`
of [edpm-compute-0.yaml](edpm-compute-0.yaml) but quote it like a
string and then the AEE pod parsed it, then we could have a general
interface to have our AEE pod mount anything.
```
  extraMounts:
    - name: v1
      region: r1
      extraVol:
        - propagation:
          - Glance
          volumes:
          - name: ceph
            projected:
              sources:
              - secret:
                  name: ceph-client-conf
          mounts:
          - name: ceph
            mountPath: "/etc/ceph"
            readOnly: true
```
The dataplane node CR would be more powerful but perhaps it would
expose too much?

## Test

The [edpm-compute-0.yaml](edpm-compute-0.yaml) CR has a `CephSecrets`
field which is currently ignored since it's not defined in the CRD.
```
[fultonj@hamfast edpm]$ oc get openstackdataplanenode.dataplane.openstack.org/edpm-compute-0 -o json  | jq .spec
{
  "ansibleHost": "192.168.122.100",
  "deployStrategy": {
    "deploy": true
  },
  "node": {
    "ansibleSSHPrivateKeySecret": "dataplane-ansible-ssh-private-key-secret",
    "networks": [
      {
        "fixedIP": "192.168.122.100",
        "network": "ctlplane"
      }
    ]
  },
  "openStackAnsibleEERunnerImage": "quay.io/openstack-k8s-operators/openstack-ansibleee-runner:latest",
  "role": "edpm-role-0"
}
[fultonj@hamfast edpm]$ 
```
As the
[ceph_client branch](https://github.com/fultonj/dataplane-operator/tree/ceph_client)
evolves we should be able to inspect the environment and eventually
see the ceph client config files copied to /etc/ceph on the EDPM nodes.
```
IP=$( sudo virsh -q domifaddr edpm-compute-0 | awk 'NF>1{print $NF}' | cut -d/ -f1 )
ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i ~/install_yamls/out/edpm/ansibleee-ssh-key-id_rsa root@$IP "ls -l /etc/ceph/"
```

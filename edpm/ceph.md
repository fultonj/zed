# Configuring EDPM Nodes as Ceph Clients

## Prerequisites

- EDPM environment as described in [README](README.md)
- A running local copy of the [ceph_client branch](https://github.com/fultonj/dataplane-operator/tree/ceph_client) of the dataplane-operator
  (which is based on the [extra_mounts branch](https://github.com/fultonj/dataplane-operator/tree/extra_mounts))

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
When [PR79](https://github.com/openstack-k8s-operators/dataplane-operator/pull/79) merges
the Ansible Execution Pod will mount the ceph conf files in `/etc/ceph`.

The [pkg/deployment](https://github.com/openstack-k8s-operators/dataplane-operator/tree/main/pkg/deployment)
deployment.go could get check if `extraVolType: Ceph` and then a new
`ceph_client.go` could include the
[edpm_ceph_client_files role](https://github.com/openstack-k8s-operators/edpm-ansible/tree/main/edpm_ansible/roles/edpm_ceph_client_files)
like the POC [edpm-play.yaml](../crc/cr/edpm-play.yaml)

# Composable Services

[PR158](https://github.com/openstack-k8s-operators/dataplane-operator/pull/158/)
introduces a composable services interface. This directory helps me test it.

[Recreate your CRDs](../../edpm/recreate_crds.sh) and define the
`configure-network` data plane service:

```
oc create -f ~/dataplane-operator/config/services/dataplane_v1beta1_openstackdataplaneservice_configurenetwork.yaml
```

Run a local copy of the PR and then create a CR (similar to [ceph](../ceph)).
```
./dataplane_cr.sh > dataplane_cr.yaml
oc create -f dataplane_cr.yaml
```

Use [watch ansible](../watch_ansible.sh) and similar to watch the EDPM
nodes get configured.

```
$ watch -n 1 "oc get pods | grep edpm"
...
dataplane-deployment-configure-network-edpm-compute-gnvkt         0/1     Completed   0              8m49s
dataplane-deployment-configure-openstack-edpm-compute-t5fk5       0/1     Completed   0              93s
dataplane-deployment-configure-os-edpm-compute-xnkmm              0/1     Completed   0              4m22s
dataplane-deployment-install-openstack-edpm-compute-5v42n         0/1     Completed   0              111s
dataplane-deployment-install-os-edpm-compute-l9bqw                0/1     Completed   0              5m16s
dataplane-deployment-run-openstack-edpm-compute-jhlx9             0/1     Completed   0              59s
dataplane-deployment-run-os-edpm-compute-vmlmc                    0/1     Completed   0              2m34s
dataplane-deployment-validate-network-edpm-compute-b2p9b          0/1     Completed   0              5m26s
nova-edpm-compute-0-deploy-libvirt-qn4r8                          1/1     Running     0              20s
nova-edpm-compute-0-deploy-nova-nn7kv                             1/1     Running     0              20s
nova-edpm-compute-1-deploy-libvirt-jh9t7                          1/1     Running     0              20s
nova-edpm-compute-1-deploy-nova-xpwpg                             1/1     Running     0              20s
nova-edpm-compute-2-deploy-libvirt-mbtpv                          1/1     Running     0              20s
nova-edpm-compute-2-deploy-nova-h8nxg                             1/1     Running     0              20s
```


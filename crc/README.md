# OpenStack Operators on CRC

- [crc.sh](crc.sh): clone [install_yamls](https://github.com/openstack-k8s-operators/install_yamls) and install CRC
- [maria.sh](maria.sh): Deploy MariaDB
- [keystone.sh](keystone.sh): Deploy Keystone
- [test_keystone.sh](test_keystone.sh): Test Keystone
- [glance.sh](glance.sh): Deploy Glance
- [test_glance.sh](test_glance.sh): Test Glance
- [glance_dev.sh](glance_dev.sh): Script to help Glance Operator development
- [rabbit.sh](rabbit.sh): Deploy RabbitMQ
- [nfs.sh](nfs.sh): Set up NFS server for Cinder
- [cinder.sh](cinder.sh): Deploy Cinder
- [test_cinder.sh](test_cinder.sh): Test Cinder
- [clean.sh](clean.sh): Remove keystone, maria, cinder, crc

## Development Cycle (Glance Operator)

The [glance_dev.sh](glance_dev.sh) is supposed to help with the following cycle.

Assuming an operator is running and you want to run a new patch...

1. delete the service as below and stop the operator (ctrl-c)
   ```
   ls ~/install_yamls/out/openstack/glance/cr
   oc delete -f ~/install_yamls/out/openstack/glance/cr/glance_v1beta1_glance.yaml
   ```

2. delete the crds:
   ```
   for CRD in $(oc get crds | grep -i glance | awk {'print $1'}); do
        oc delete crds $CRD;
   done
   ```

3. run the new operator and recreate the new crds
   ```
   cd  ~/install_yamls/develop_operator/glance-operator
   make generate && make manifests && make build
   MET_PORT=6666
   OPERATOR_TEMPLATES=$PWD/templates ./bin/manager -metrics-bind-address ":$MET_PORT"
   ```

   You might observe exceptions until CRDs are created with the following.

   ```
   oc create -f ~/install_yamls/develop_operator/glance-operator/config/crd/bases/glance.openstack.org_glanceapis.yaml
   oc create -f ~/install_yamls/develop_operator/glance-operator/config/crd/bases/glance.openstack.org_glances.yaml
   ```

4. redeploy
   `oc kustomize ~/install_yamls/out/openstack/glance/cr | oc apply -f -`

The following additional cleaning commands may be necessary

```
oc delete deployment glance -n openstack
oc delete pvc glance
oc delete GlanceAPI glance
```

`oc edit pv local-storage00x` and remove the `ClaimRef`

```
for i in $(oc get pv | egrep "Failed|Released" | awk {'print $1'}); do
  oc patch pv $i --type='json' -p='[{"op": "remove", "path": "/spec/claimRef"}]';
done
```

Edit the CRD (`oc edit crd`) and remove
[finalizers](https://kubernetes.io/blog/2021/05/14/using-finalizers-to-control-deletion/)
(`- finalizers:`) which might be blocking deletion.

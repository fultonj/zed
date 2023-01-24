# DataPlane CRD Experiments

## Prerequisites

Deploy openstack operator.
```
pushd ~/install_yamls
make openstack
make openstack_deploy
popd
```
After it's running, delete the OpenStack services:
```
oc delete -f ~/install_yamls/out/openstack/openstack/cr/core_v1beta1_openstackcontrolplane.yaml
```
This has a side effect of defining CRDs the next step would otherwise
complain about. Use `oc get crds | grep openstack` to show the
OpenStack CRDs.

## Run modified openstack operator locally

Use [James' dataplane branch](https://github.com/slagle/openstack-operator/tree/dataplane)
```
git clone -b dataplane git@github.com:slagle/openstack-operator.git 
```
In my environment `~/install_yamls/develop_operator/openstack-operator`
is a symlink to the above.
```
cd ~/install_yamls/develop_operator/openstack-operator
make generate && make manifests && make build
MET_PORT=6666
OPERATOR_TEMPLATES=$PWD/templates ./bin/manager -metrics-bind-address ":$MET_PORT"
```
The manager should be running but throwing exceptions about the new
undefined CRDs. Define them with:
```
cd config/crd/bases/
oc create -f rabbitmq.openstack.org_transporturls.yaml
oc create -f core.openstack.org_openstackcontrolplanes.yaml
oc create -f core.openstack.org_openstackdataplanes.yaml
oc create -f core.openstack.org_openstackdataplanenodes.yaml
```
Observe the new DataPlane CRDs.
```
$ oc get crds | grep dataplane
openstackdataplanenodes.core.openstack.org                        2023-01-24T19:17:46Z
openstackdataplanes.core.openstack.org                            2023-01-24T20:41:51Z
$
```
```
oc get crds openstackdataplanenodes.core.openstack.org -o yaml
```

## See the operator react to new OpenStackDataPlane objects

Right now the sample objects don't do anything.
```
oc create -f ~/openstack-operator/config/samples/core_v1beta1_openstackdataplane.yaml
```
But to confirm you have the local copy running you can make a trivial
edit in the `Reconcile` function:
```
vi ~/openstack-operator/controllers/core/openstackdataplane_controller.go
```
Then re-run make and restart the manager (as above) and see the
operator react.
```
2023-01-24T22:12:37.860Z        INFO    Starting workers        {"controller": "openstackcontrolplane", "controllerGroup": "core.openstack.org", "controllerKind": "OpenStackControlPlane", "worker count": 1}
hello world
```

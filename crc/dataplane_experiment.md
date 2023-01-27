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

## Run dataplane operator locally

Clone the [dataplane-operator](https://github.com/openstack-k8s-operators/dataplane-operator).
```
git@github.com:openstack-k8s-operators/dataplane-operator.git
```
Build it and run a local copy.
```
cd ~/dataplane-operator
make generate && make manifests && make build
MET_PORT=6666
OPERATOR_TEMPLATES=$PWD/templates ./bin/manager -metrics-bind-address ":$MET_PORT"
```
The manager should be running but throwing exceptions about the new
undefined CRDs. Define them with:
```
$ oc apply -f config/crd/bases/
customresourcedefinition.apiextensions.k8s.io/openstackdataplanenodes.dataplane.openstack.org created
customresourcedefinition.apiextensions.k8s.io/openstackdataplaneroles.dataplane.openstack.org created
customresourcedefinition.apiextensions.k8s.io/openstackdataplanes.dataplane.openstack.org created
$
Observe the new DataPlane CRDs.
```
$ oc get crds | grep dataplane
openstackdataplanenodes.dataplane.openstack.org                   2023-01-27T15:34:08Z
openstackdataplaneroles.dataplane.openstack.org                   2023-01-27T15:34:08Z
openstackdataplanes.dataplane.openstack.org                       2023-01-27T15:34:08Z
$

```
```
oc get crd -o yaml openstackdataplanes.dataplane.openstack.org
```
## See the operator react to new OpenStackDataPlane objects

Right now the sample objects don't do much.
```
oc kustomize config/samples/ | oc apply -f -
```
But to confirm you have the local copy running that you can edit, make
a trivial edit in the `Reconcile` functions
```
ls ~/dataplane-operator/controllers/*.go
vi ~/dataplane-operator/controllers/openstackdataplanenode_controller.go
```
```
$ git diff | curl -F 'f:1=<-' ix.io
http://ix.io/4mm3
```
Then re-run make and restart the manager (as above) and see the
operator react.
```
1.674834292021906e+09   INFO    Starting workers        {"controller": "openstackdataplanerole", "controllerGroup": "dataplane.openstack.org", "controllerKind": "OpenStackDataPlaneRole", "worker count": 1}
hello from: dataplane node
hello from: dataplane role
```

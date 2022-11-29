# ExtraVols for AnsibleEE Notes

## Build Environment

Below are my notes from following
[fmount's notes](https://gist.github.com/fmount/ffc4cd6a048cafe2a38ae5f8727e31f9).

### Get code
```
cd ~
git clone -b extra_volumes git@github.com:fmount/lib-common.git
git clone -b extra_volumes git@github.com:fmount/ansibleee-operator.git
mv ansibleee-operator ansibleee-operator-fmount
ln -s ansibleee-operator-fmount ansibleee-operator 
mv lib-common lib-common-fmount
ln -s lib-common-fmount lib-common 
```

### Have ansibleee-operator use local lib-common
```
cd ~/ansibleee-operator
go get github.com/openstack-k8s-operators/lib-common/modules/storage
go mod edit -replace github.com/openstack-k8s-operators/lib-common/modules/storage=../lib-common/modules/storage
make
```

### Run local copy of operator (in separate tmux pane)
```
cd ~/ansibleee-operator
oc create -f config/crd/bases/redhat.com_ansibleees.yaml
MET_PORT=6668
./bin/manager -metrics-bind-address ":$MET_PORT"
```

### Ensure you have a secret

I already had a ceph-client-conf from [cr/ceph_cr.sh](cr/ceph_cr.sh)
so I [modified](https://paste.opendev.org/raw/817793) fmount's
ansibleee-extravolumes_2_secrets.yaml to use only one secret.

### Confirm ansibleEE has mounted the secret defined in extraVols
```
oc create -f examples/ansibleee-extravolumes_2_secrets.yaml
oc describe pod $(oc get pods | grep ansibleee-extra | awk {'print $1'}) | grep Mounts -A 5
```

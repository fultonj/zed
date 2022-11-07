# Providing configuration files to services
## An example using Ceph and Glance

This is a high level summary of work done already by 
[fmount](https://github.com/fmount)
and
[akrog](https://github.com/akrog).

### Patches to Merge

1. https://github.com/openstack-k8s-operators/lib-common/pull/88
2. https://github.com/openstack-k8s-operators/glance-operator/pull/75
3. https://github.com/openstack-k8s-operators/ansibleee-operator/pull/6
4. https://github.com/openstack-k8s-operators/cinder-operator/pull/65
5. https://github.com/openstack-k8s-operators/openstack-operator/pull/38

When testing, 2,3,4 and 5 all need to be able to access 1.

### Context

We deploy Glance with
[install_yamls](https://github.com/openstack-k8s-operators/install_yamls)
by running `make glance` to deploy the Glance operator and then 
`make glance_deploy` to have that operator deploy Glance. As a result
`install_yamls` has an `out` directory containing a Glance
[CR](https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources).
We can modify this CR and then `oc apply -f` it so that it can use
different storage backends. This pattern extends to other operators
(e.g. Cinder, etc).

The rest of this document describes how to modify this CR to pass
configuration files to our service. The example operator is Glance
and the example backend is Ceph but the proposed abstraction will work
for other operators and backend services.

### Steps to modify the Glance CR to use a single Ceph Backend

Create a secret by creating the following file and then `oc apply -f`
it.

```
--- 
apiVersion: v1
kind: Secret
metadata:
  name: ceph-client-conf
  namespace: openstack
stringData:
  ceph.client.openstack.keyring: |
    [client.openstack]
        key = <secret key>
        caps mgr = "allow *"
        caps mon = "profile rbd"
        caps osd = "profile rbd pool=images"
  ceph.conf: |
    [global]
    fsid = 7a1719e8-9c59-49e2-ae2b-d7eb08c695d4
    mon_host = 10.1.1.2,10.1.1.3,10.1.1.4
```

Add the following to the `spec` of the Glance CR and then `oc apply -f` it.

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

Your glance containers should then have /etc/ceph populated with a
ceph.conf and a ceph.client.openstack.keyring.

### Why is extraVol better than cephBackend?

Today we can add a `cephBackend` to the `spec` of our CR like this:
```
  cephBackend:
    cephFsid: 7a1719e8-9c59-49e2-ae2b-d7eb08c695d4
    cephMons: 10.1.1.2,10.1.1.3,10.1.1.4
    cephClientKey: <secret key>
    cephUser: openstack
    cephPools:
      glance:
        name: images
```
However, the above has the following problems:

- It's Ceph specific; other storage backends can't resuse any of the
  code which implemented the above.

- Credentials are stored in
  [ConfigMaps](https://kubernetes.io/docs/concepts/configuration/configmap)
  instead of
  [secrets](https://kubernetes.io/docs/concepts/configuration/secret)

- No support for multiple ceph clusters

- The deployer needs to open files they already have (ceph.conf and 
  ceph.client.openstack.keyring) and then copy/paste some of contained
  information into a yaml file. Why not just let them pass the full
  file?

- No distinction between Ceph data and operator specifics; just a
  large configMap. Operator code is responsible for rendering the
  config file but the deployer does not have full control of the
  rendered configuration which can be error prone.

Instead, an operator should act as a configurable black box where:

- credentials can be injected by secrets
- config snippets can be injected by the entity which is supposed to
  deploy the operator
  ([meta-operator](https://github.com/openstack-k8s-operators/openstack-operator))
  
The `extraVol` abstraction allows
[openstack-k8s-operators](https://github.com/openstack-k8s-operators)
to use [lib-common](https://github.com/openstack-k8s-operators/lib-common)
to do the above and does not need to be limited to storage.

### Example 2: Configure two Ceph Backends

Define a second secret and create it with `oc apply -f`. The secret
for the second ceph cluster has its stringData filenames start with
"ceph2" to avoid overwriting the original Ceph configuration files.

```
---
apiVersion: v1
kind: Secret
metadata:
  name: ceph2-client-conf
  namespace: openstack
stringData:
  ceph2.client.openstack.keyring: |
    [client.openstack]
        key = <secret>
        caps mgr = "allow *"
        caps mon = "profile rbd"
        caps osd = "profile rbd pool=images"
  ceph2.conf: |
    [global]
    fsid = de729141-3732-4c0c-9314-e590e9c71964
    mon_host = 10.1.2.2,10.1.2.3,10.1.2.4
```
Update the CRD to use the new secret.
```
--- glance_v1beta1_ceph_secret.yaml     2022-10-26 14:10:29.797732999 +0000
+++ glance_v1beta1_ceph_two_secrets.yaml        2022-10-27 19:09:45.695640631 +0000
@@ -36,6 +36,8 @@
               sources:
               - secret:
                   name: ceph-client-conf
+              - secret:
+                  name: ceph2-client-conf
           mounts:
           - name: ceph
             mountPath: "/etc/ceph"
```
After applying the updated CRD there should be two ceph.conf files and
two cephx secret files.
```
[fultonj@osp-storage-01 cr]$ oc exec -ti glance-external-api-5d6b9f65f6-g78vb -- ls -l /etc/ceph/ 2> /dev/null
total 0
lrwxrwxrwx. 1 root root 37 Oct 27 19:21 ceph2.client.openstack.keyring -> ..data/ceph2.client.openstack.keyring
lrwxrwxrwx. 1 root root 17 Oct 27 19:21 ceph2.conf -> ..data/ceph2.conf
lrwxrwxrwx. 1 root root 40 Oct 27 19:21 ceph.client.automation-10.keyring -> ..data/ceph.client.automation-10.keyring
lrwxrwxrwx. 1 root root 16 Oct 27 19:21 ceph.conf -> ..data/ceph.conf
[fultonj@osp-storage-01 cr]$
```

### Why does extraVol need more than just mounts and volumes?

`extraVol` is a list of containing the following types:

1. volumes list
2. mounts list
3. propagation list

The volumes list contains the secrets and we specify where in our pod
they should be mounted. The ability to
[project](https://kubernetes.io/docs/concepts/storage/projected-volumes/)
multiple volumes into the same directory is useful as seen in the
double ceph configuration.

The propagation list defines which type of pod should mount the volume.
It gives us a simple but granular syntax we can use to define which
pod gets which configuration the meta operator CR level. It can be:

- Global: e.g. `All` all pods or `Cinder` all pods deployed by the Cinder operator
- Group: e.g. `CinderVolume` all the cinder volume pods deployed by the Cinder operator
- Instance: e.g. `volume1` only the pod associated the volume1 backend

Only the volumes, mounts, and propagation lists are required. There's
also an optional `extraVolType` which is unimplemented but could be
used in the future to enforce certain types of pods not mounting
untrusted volume types if desired. There's no reason we need to
actually define an `extraVolType` in lib-common to support another
backend configuration. As long as that backend can be defined in terms
of a set of files to be accessible wtihin a pod no additional update
to lib-common should be required.

It is not mandatory to use the propagation list, but it's there for
finer grain control if you need it.


### Demo

Screencast by [fmount](https://github.com/fmount) showing the
[meta-operator](https://github.com/openstack-k8s-operators/openstack-operator)
CRD with `extraVol` propagating volumes to Glance, Cinder, and
Compute; where Compute results in the 
[ansibleee-operator](https://github.com/openstack-k8s-operators/ansibleee-operator)
having access to the Ceph configuration files (so it could then
use Ansible to distribute them to non-worker nodes).
[![asciicast](https://asciinema.org/a/533951.svg)](https://asciinema.org/a/533951)

# Notes for working with lib-common

The openstack-k8s-operators depend on 
[lib-common](https://github.com/openstack-k8s-operators/lib-common).
E.g. glance-operator/go.mod and glance-operator/api/go.mod have it
in their require list and occasionally we make 
[a simple update to our respective operators to use a new version of lib-common](https://github.com/openstack-k8s-operators/glance-operator/commit/ef8842b9bbaad4fdc461ee3573b5dcbe13e2bd55).
We do this by running the following in the operator and operator/api
directories and letting go update our go.mod files to the latest
version. We then simply push those modified files in a PR to bump the
version.

```
go get github.com/openstack-k8s-openstack/lib-common/modules/storage
```

## Using a local copy of lib-common

If a patch to your operator depends on an unpublished change to
lib-common, then you can modify your environment so your operator
uses the local copy of lib-common. This allows you to test your patch
with that version of lib-common before sending in a PR.

For example, in my home dir I have the following directories and each
contains unmerged patches to the operator nad lib-common:

```
~/glance-operator
~/lib-common
```

The ~/glance-operator modules are hard coded to pull from the github
prefixed version. When you `go get` those modules they are stored in
your $GOPATH. You can trick your system by symlinking your modified
copy into that same path.

```
sudo ln -s /home/fultonj/lib-common/ /usr/local/go/src/lib-common
```

When you then run `make generate` in your operator
(e.g. glance-operator) you can expect to see failures. You then need
to tell your copy of the patch to not use the github prefixed
version. The output of `make generate` will guide you and when you
finish `git diff` will look something like this
[local-lib-common.diff](local-lib-common.diff).

Once `make generate && make manifests && make build` builds cleanly
recreate the CRDs as described
in [glance_dev_notes.md](glance_dev_notes.md).

You can do this to have your operator use a local version of
lib-common but don't include those changes in your PR to your
operator. Instead assume that your lib-common patch will merge
first and that at that point it will be correct to pull not the local
copy but the copy from github.
# Standlone Wallaby on EDPM Node

Clone this directory to the edpm node and run the following scripts.

- `curl https://raw.githubusercontent.com/fultonj/zed/adopt/adopt/standalone/git.sh | bash`
- [pre.sh](pre.sh)
- [network.sh](network.sh)
- [ceph.sh](ceph.sh)
- [deploy.sh](deploy.sh)
- [verify.sh](verify.sh)

See [network.md](network.md) for an explanation of why
[network.sh](network.sh) is used.

The [ping_test.sh](ping_test.sh) can be used after edpm-compute-1
is configured to prove that the standalone wallaby system can
communicate on all of the isolated networks with the NG system.

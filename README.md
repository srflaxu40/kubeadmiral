# kubeadm

These scripts are utilized to stand up a master, and to join nodes to the master.  Currently, it is being
used in SpotInst for the kubernetes-redis-cluster project.

## Notes:

* Private images are pulled from DockerHub by following these instructions to utilize a secret with DockerHub registry access:
  [PullSecrets](https://kubernetes.io/docs/tasks/configure-pod-container/pull-image-private-registry/)
* These scripts are utilized for creating a master `master.sh` and joining slaves to the master `slave.sh`
* Master should be ephemeral, but don't have to be.  Slaves use the master IP, and bearer token to join.
* Although a `kubeadm init` creates a token for you, you should update it or create your own to have a non-expiring
  TTL (for the time being).
  - To list your tokens `ssh` onto the master, and run `kubeadm list tokens`.
* Your DISCOVERY_TOKEN_HASH can be found by running the following command on your master node:
```
openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt | openssl rsa -pubin -outform der 2>/dev/null | openssl dgst -sha256 -hex | sed 's/^.* //'
```
* It is also output by `kubeadm init` on cluster creation in the join command.

## Important Environment Variables:

* To run master.sh
  - ENVIRONMENT - development, staging, or production.
  - master.sh expects that your master and slaves be in the same VPC for now.
* To run slave.sh - 
  - ENVIRONMENT - development, staging, or production.
  - TOKEN - this is the token that is generated in the `master.sh` output.
  - DISCOVERY_TOKEN_HASH - the hash of the cert for joining.


## Getting Your Init Token:

* You can get your token by either running the `master.sh` script ad-hoc on the actual EC2 instance, or
  you can also gather it from the following log file path:
  * `/var/logs/cloud-output.log`

## References:
[kubeadm](https://kubernetes.io/docs/admin/kubeadm/)

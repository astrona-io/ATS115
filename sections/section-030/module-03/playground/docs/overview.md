# Overview: Manage Leases And Respond To A Leaked Credential (Playground)

This is a **playground**, not a lab. It starts a fresh cluster, installs OpenBao, initializes and unseals it, creates two applications with live tokens and certificate leases, and then waits. There is no task, no `astrona submit` and no pass or fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` Kubernetes cluster. `kubectl` is already pointed at it.
- **OpenBao v2.7.1** in the namespace `openbao` (pod `openbao-0`), **initialized and unsealed**. The lab-only unseal key and root token are in the Secret `openbao-init`.
- A KV version 2 secrets engine at `secret/` with `secret/billing/db` and `secret/inventory/db`.
- A PKI engine at `pki/` with a root certificate authority and the role `web`, which issues certificates with a lease.
- AppRole at `approle/` with the roles `billing` and `inventory`. The policy `cert-issuer` lets a token issue certificates and create child tokens.
- One login per application. The `billing` token issued two certificates and created one child token. The `inventory` token issued one certificate.
- A ConfigMap `incident` in the namespace `clients` with the accessors, the role ID and the secret ID of `billing`. Read it with `kubectl -n clients get configmap incident -o yaml`.
- The **`bao` CLI 2.7.1** and **Helm 3.22.1** on your machine, and a **tester** pod in the namespace `clients`.

Keep the port-forward running in a second terminal:

```sh
kubectl -n openbao port-forward svc/openbao 8200:8200
```

Then set these in each terminal where you work:

```sh
export BAO_ADDR=http://openbao.localtest.me:8200
export BAO_TOKEN=$(kubectl -n openbao get secret openbao-init -o jsonpath='{.data.root-token}' | base64 -d)
```

## Practice tasks

- List the leases under `pki/issue/web/` with `bao list sys/leases/lookup/pki/issue/web/` and look up one.
- Look up the `billing` token by its accessor and read its policies, parent and TTL.
- Renew a certificate lease with `-increment=30m` and read the new `lease_duration`.
- Revoke the `billing` token by its accessor, then look up its child and its certificates.
- Log in again with the leaked `billing` secret ID, then destroy it by its accessor and try again.
- Run `bao lease revoke -prefix pki/issue/web` in a second playground and observe that `inventory` loses its certificate too.
- Tune `pki/` with a two-hour `-max-lease-ttl` and request a 24-hour certificate.

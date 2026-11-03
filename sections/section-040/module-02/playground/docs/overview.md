# Overview: Tune Audit Devices For Production (Playground)

This is a **playground**, not a lab. It starts a fresh cluster, installs OpenBao, initializes and unseals it, enables a leftover raw audit device, and then waits. There is no task, no `astrona submit` and no pass or fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` Kubernetes cluster. `kubectl` is already pointed at it.
- **OpenBao v2.7.1** in the namespace `openbao` (pod `openbao-0`), **initialized and unsealed**. The lab-only unseal key and root token are in the Secret `openbao-init`.
- A KV version 2 secrets engine at `secret/` with `secret/inventory/db`, `secret/billing/db` and `secret/billing/api`.
- An audit volume mounted at `/openbao/audit`, and `unsafe_allow_api_audit_creation = true` in the server configuration.
- The audit device `debug/`, a file device at `/openbao/audit/debug.log` with `log_raw=true` and `hmac_accessor=false`.
- The `audit-sink` Deployment in the namespace `clients`, a TCP listener on port `9090` that prints every audit record it receives.
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

- Run `bao audit list -detailed` and read the options of `debug/`.
- Search `/openbao/audit/debug.log` for the string `raw-debug-leftover-7731`.
- Enable a hashed device and compare the log lines for the same write.
- Enable a device with `elide_list_responses=true`, list `secret/`, and read the response line.
- Enable a device with `prefix='@cee: '` and look at a line.
- Enable a socket device, scale the `audit-sink` Deployment to zero, and make a request with and without a file device.
- Check the size of the audit files with `kubectl -n openbao exec openbao-0 -- ls -l /openbao/audit/`.

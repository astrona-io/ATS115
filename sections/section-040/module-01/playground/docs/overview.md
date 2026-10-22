# Overview: Audit Every Request (Playground)

This is a **playground**, not a lab. It starts a fresh cluster, installs OpenBao with an audit volume, initializes and unseals it, starts a TCP listener for audit records, and then waits. There is no task, no `astrona submit` and no pass or fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` Kubernetes cluster. `kubectl` is already pointed at it.
- **OpenBao v2.7.1** in the namespace `openbao` (pod `openbao-0`), **initialized and unsealed**, with no audit device enabled. The lab-only unseal key and root token are in the Secret `openbao-init`.
- An audit volume mounted at `/openbao/audit` in `openbao-0`, and `unsafe_allow_api_audit_creation = true` in the server configuration.
- A KV version 2 secrets engine at `secret/` with `secret/inventory/db`.
- **`audit-sink`** in the namespace `clients`: a TCP listener on port `9090` (`audit-sink.clients.svc.cluster.local:9090`) that prints what it receives.
- The **`bao` CLI 2.7.1** and **Helm 3.22.1** on your machine, with the Helm repository `openbao` added.

Keep the port-forward running in a second terminal, and start it again after every restart of `openbao-0`:

```sh
kubectl -n openbao port-forward svc/openbao 8200:8200
```

Then set these in each terminal where you work:

```sh
export BAO_ADDR=http://openbao.localtest.me:8200
export BAO_TOKEN=$(kubectl -n openbao get secret openbao-init -o jsonpath='{.data.root-token}' | base64 -d)
```

## Helpers

Paste these once in each new terminal. `audit_hash` prints the hash of a value for one audit device. `unseal_openbao` unseals the pod with the lab-only key after a restart. `audit_file` prints the audit log file inside the pod.

```sh
audit_hash() { bao write -field=hash "sys/audit-hash/$1" input="$2"; }
unseal_openbao() {
  kubectl -n openbao exec openbao-0 -- bao operator unseal \
    "$(kubectl -n openbao get secret openbao-init -o jsonpath='{.data.unseal-key}' | base64 -d)"
}
audit_file() { kubectl -n openbao exec openbao-0 -- cat /openbao/audit/audit.log; }
```

Use them like this: `audit_hash file my-value`, `audit_file | grep -c "$(audit_hash file my-value)"`.

## Practice tasks

- Enable a `file` device to `stdout` and read one request and one response entry in `kubectl logs`.
- Write a secret with a number value and a string value, and compare how each appears in the log.
- Enable two `file` devices that write to different files, and compare the hashes of the same value.
- Scale `audit-sink` to zero while a socket device points at it, send requests, and watch what happens with and without a file device next to it.
- Disable a device and enable it again at the same path, and check whether the old hashes still match.
- Declare a device in the server configuration with `helm upgrade`, restart and unseal the pod, and try to disable it with `bao audit disable`.
